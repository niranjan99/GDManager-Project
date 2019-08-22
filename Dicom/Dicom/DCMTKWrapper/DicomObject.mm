//
//  DicomObjects.m
//  Dicom
//
//  Created by Bankim Debnath on 29/02/16.
//  Copyright © 2016 Carl Zeiss Meditec. All rights reserved.
//

#import "DicomObject.h"
#include "dcmtk/dcmnet/scu.h"
#include "dcmtk/dcmdata/dcpxitem.h"
#include "dcmtk/dcmdata/libi2d/i2djpgs.h"
#include "dcmtk/dcmdata/dcistrmf.h"
#include "dcmtk/dcmdata/dcostrmf.h"
#include "dcmtk/dcmnet/dimse.h"
#import "Utility.h"
#include "dcmtk/dcmnet/diutil.h"

#define Modality        "GM"
#define Manufacturer    "Carl Zeiss Meditec AG"
#define ModelName       "Extaro 300"
#define SerialNumber    "123456789"

#define PRV_PrivateCreator  DcmTag(0x0029, 0x0010, EVR_LO)
#define PRV_PrivateElement DcmTag(0x0029, 0x1000, EVR_LO)

#define PrivateCreatorName      "UNO3_CZM_INTERNAL"

// Maximum Line Size (default)
const unsigned int DCM_DumpMaxLineSize = 65535;
NSOperationQueue *uploadQueue = nil;
NSBlockOperation *uploadOperation = nil;
DcmDataset *dataset = nil;

@implementation DicomObject

+(void)createDicom:(Patient *)patientModule mediaPath:(FileDetails*)media dcmFilePath:(NSString *)dcmFilePath mediaType:(NSString*)mediaType success:(void(^)(NSString *result))success failure:(void(^)(NSError *error))failure
{
    if (uploadOperation)
        return;
    
    uploadQueue = [[NSOperationQueue alloc] init];
    uploadQueue.maxConcurrentOperationCount = 1;
    NSBlockOperation *operation = [[NSBlockOperation alloc] init];
    __weak typeof (self) weakSelf = self;
    __weak NSBlockOperation *weakOperation = operation;
    id semaphore = dispatch_semaphore_create(0);
    id executionBlock = ^{
        [weakSelf createDicom:patientModule mediaPath:media dcmFilePath:dcmFilePath mediaType:mediaType operation:weakOperation success:^(NSString *result) {
            success(result);
            dispatch_semaphore_signal(semaphore);
        } failure:^(NSError *error) {
            failure(error);
            dispatch_semaphore_signal(semaphore);
        }];
    };
    [operation addExecutionBlock:executionBlock];
    operation.completionBlock = ^{
        uploadOperation = nil;
        dispatch_semaphore_signal(semaphore);
    };
    uploadOperation = operation;
    [uploadQueue addOperation:uploadOperation];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
}

+(void)createDicom:(Patient *)patientModule mediaPath:(FileDetails*)media dcmFilePath:(NSString *)dcmFilePath mediaType:(NSString*)mediaType operation:(__weak NSBlockOperation *)weakOperation success:(void(^)(NSString *result))success failure:(void(^)(NSError *error))failure
{
    
    @autoreleasepool {
        
        NSError *operationError = [NSError errorWithDomain:@"UNO3" code:EPERM userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Download cancelled"]}];
        
        if (!patientModule.Id) {
            failure([NSError errorWithDomain:@"UNO3"
                                        code:EPERM
                                    userInfo:@{
                                               NSLocalizedDescriptionKey:@"PatientInfo not available"
                                               }]);
            return;
        }
        
        //converting nsdate to string
        NSDateFormatter *dateFormatter=[[NSDateFormatter alloc] init];
        NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        dateFormatter.dateFormat = @"yyyyMMdd";
        NSTimeZone *timeZone = [NSTimeZone systemTimeZone];
        NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        [dateFormatter setCalendar:gregorianCalendar];
        [dateFormatter setTimeZone:timeZone];
        [dateFormatter setLocale:locale];
        
        // NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        //dateFormatter.dateFormat = @"yyyyMMdd";
        
        NSString *dob = [dateFormatter stringFromDate:patientModule.dateOfBirth];
        
        Study *study = ((Study *)[patientModule.studies objectAtIndex:0]);
        
        Series *series = ((Series *)[study.series objectAtIndex:0]);
        
        NSString *seriesInstanceId = series.instanceId;
        
        dataset = new DcmDataset();
        
        //Patient level attributes
        //Patient Name, Patient ID, Issuer of Patient ID, Patient's Birth Date, Patient's Sex, Other Patient IDs, Patient Comments
        //Patient Name
        OFString dicomName;
        DcmPersonName::getStringFromNameComponents    ([patientModule.lastName UTF8String],
                                                       [patientModule.firstName UTF8String],
                                                       "",
                                                       "",
                                                       "",
                                                       dicomName
                                                       );
        dataset->putAndInsertString(DCM_PatientName, dicomName.c_str());
        
        //Patient ID
        dataset->putAndInsertString(DCM_PatientID, [patientModule.Id UTF8String]);
        
        //Issuer of Patient ID
        NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
        appName = [appName stringByReplacingOccurrencesOfString:@"\\" withString:@" "];
        if (appName.length > 64) {
            appName = [appName substringToIndex:64];
        }
        if (patientModule.patientIssuer.length) {
            dataset->putAndInsertString(DCM_IssuerOfPatientID, [patientModule.patientIssuer UTF8String]);
        } else{
            dataset->putAndInsertString(DCM_IssuerOfPatientID, [appName UTF8String]);
        }
        
        //Patient's Birth Date
        dataset->putAndInsertString(DCM_PatientBirthDate, [dob UTF8String]);
        
        //Patient's Sex
        dataset->putAndInsertString(DCM_PatientSex, [patientModule.gender UTF8String]);
        
        //Other Patient IDs
        dataset->putAndInsertOFStringArray(DCM_OtherPatientIDs, [patientModule.otherPatientIds UTF8String]);
        
        //        dataset->putAndInsertString(DCM_OtherPatientIDs, [patientModule.otherPatientIds UTF8String]);
        
        //Ethnicity
        dataset->putAndInsertString(DCM_EthnicGroup, [patientModule.ethnicity UTF8String]);
        
        dataset->putAndInsertString(DCM_PatientComments, [patientModule.comments UTF8String]);
        
        //Study level attributes
        //Study Instance UID, Referring Physicians Name, Accession Number, Study ID, Study Date, Study Time, Study Description, Referenced Study Sequence, Procedure Code Sequence
        
        //Study Instance UID
        if (study.studyInstanceUid) {
            dataset->putAndInsertString(DCM_StudyInstanceUID, [study.studyInstanceUid UTF8String]);
        }
//        else {
//            NSLog(@"study.studyInstanceUid is nil");
//
//            dataset->putAndInsertString(DCM_StudyInstanceUID, [study.instanceId UTF8String]);
//        }
        
        //Referring Physicians Name
        if (study.referringPhysicianName) {
            dataset->putAndInsertString(DCM_ReferringPhysicianName, [study.referringPhysicianName UTF8String]);
        } else {
            dataset->putAndInsertString(DCM_ReferringPhysicianName, "");
        }
        //Accession Number
        if (study.accessionNumber) {
            dataset->putAndInsertString(DCM_AccessionNumber, [study.accessionNumber UTF8String]);
        } else {
            dataset->putAndInsertString(DCM_AccessionNumber, "");
        }
        //Study ID
        dataset->putAndInsertString(DCM_StudyID, [study.Id UTF8String]);
        
        //Study Date
        dataset->putAndInsertString(DCM_StudyDate, [study.dateString UTF8String]);
        
        //Study Time
        dataset->putAndInsertString(DCM_StudyTime, [study.timeString UTF8String]);
        
        //Study Description
        dataset->putAndInsertString(DCM_StudyDescription, [study.studyDescription UTF8String]);
        
        //Study Modality
        //DICOM > Scheduled Case > modality (0008,0060) shall not be mapped from MWL
        dataset->putAndInsertString(DCM_Modality, Modality);
        /*if (study.modality.length > 0) {
            dataset->putAndInsertString(DCM_Modality, [study.modality UTF8String]);
        } else {
            dataset->putAndInsertString(DCM_Modality, Modality);
        }*/
        
        DcmItem *sequenceItem = NULL;
        
        //Referenced Study Sequence
        if (study.referencedStudySequence) {
            NSDictionary * referencedStudySequence = [NSJSONSerialization JSONObjectWithData: study.referencedStudySequence options:NSJSONReadingAllowFragments error:nil];
            NSString *referencedSOPClassUID = @"",*referencedSOPInstanceUID = @"";
            if (referencedStudySequence) {
                referencedSOPClassUID = [referencedStudySequence valueForKey:@"ReferencedSOPClassUID"];
                referencedSOPInstanceUID = [referencedStudySequence valueForKey:@"ReferencedSOPInstanceUID"];
            }
            
            if (referencedSOPClassUID.length > 0 || referencedSOPInstanceUID.length > 0) {
                if (dataset->findOrCreateSequenceItem(DCM_ReferencedStudySequence, sequenceItem, -2 /* append */).good()) {
                    if (referencedSOPClassUID.length > 0) {
                        sequenceItem->putAndInsertString(DCM_ReferencedSOPClassUID, [referencedSOPClassUID UTF8String]);
                    }
                    if (referencedSOPInstanceUID.length > 0) {
                        sequenceItem->putAndInsertString(DCM_ReferencedSOPInstanceUID, [referencedSOPInstanceUID UTF8String]);
                    }
                } //end Referenced Study Sequence
            }
        }
        //Procedure Code Sequence
        if (study.procedureCodeSequence) {
            NSDictionary * procedureCodeSequence = [NSJSONSerialization JSONObjectWithData: study.procedureCodeSequence options:NSJSONReadingAllowFragments error:nil];
            NSString *procedureCodeValue = @"",*procedureCodeMeaning = @"",*procedureCodingSchemeDesignator = @"",*procedureCodingSchemeVersion = @"";
            if (procedureCodeSequence) {
                procedureCodeValue = [procedureCodeSequence valueForKey:@"CodeValue"];
                procedureCodeMeaning = [procedureCodeSequence valueForKey:@"CodeMeaning"];
                procedureCodingSchemeDesignator = [procedureCodeSequence valueForKey:@"CodingSchemeDesignator"];
                procedureCodingSchemeVersion = [procedureCodeSequence valueForKey:@"CodingSchemeVersion"];
            }
            
            if (procedureCodeValue.length > 0 || procedureCodeMeaning.length > 0 || procedureCodingSchemeDesignator.length > 0 || procedureCodingSchemeVersion.length > 0) {
                if (dataset->findOrCreateSequenceItem(DCM_ProcedureCodeSequence, sequenceItem, -2 /* append */).good())
                {
                    if (procedureCodeValue.length > 0) {
                        sequenceItem->putAndInsertString(DCM_CodeValue, [procedureCodeValue UTF8String]);
                    }
                    if (procedureCodingSchemeDesignator.length > 0) {
                        sequenceItem->putAndInsertString(DCM_CodingSchemeDesignator, [procedureCodingSchemeDesignator UTF8String]);
                    }
                    if (procedureCodeMeaning.length > 0) {
                        sequenceItem->putAndInsertString(DCM_CodeMeaning, [procedureCodeMeaning UTF8String]);
                    }
                    if (procedureCodingSchemeVersion.length > 0) {
                        sequenceItem->putAndInsertString(DCM_CodingSchemeVersion, [procedureCodingSchemeVersion UTF8String]);
                    }
                }//end Procedure Code Sequence
            }
        }
        //Series level attributes
        
        NSString *requestedProcedureDescription = @"";
        //Request Attributes Sequence
        if (series.requestAttributesSequence) {
            NSDictionary * requestAttributesSequence = [NSJSONSerialization JSONObjectWithData: series.requestAttributesSequence options:NSJSONReadingAllowFragments error:nil];
            NSString *requestedProcedureID = @"",*scheduledProcedureStepID = @"",*scheduledProcedureStepDescription = @"",*requestedProcedureCodeValue = @"",*requestedProcedureCodeMeaning = @"",*requestedProcedureCodingSchemeDesignator = @"",*requestedProcedureCodingSchemeVersion = @"",*scheduledProtocolCodeValue = @"",*scheduledProtocolCodeMeaning = @"",*scheduledProtocolCodingSchemeDesignator = @"",*scheduledProtocolCodingSchemeVersion = @"";
            if (requestAttributesSequence) {
                requestedProcedureID = [requestAttributesSequence valueForKey:@"RequestedProcedureID"];
                requestedProcedureDescription = [requestAttributesSequence valueForKey:@"RequestedProcedureDescription"];
                scheduledProcedureStepID = [requestAttributesSequence valueForKey:@"ScheduledProcedureStepID"];
                scheduledProcedureStepDescription = [requestAttributesSequence valueForKey:@"ScheduledProcedureStepDescription"];
                
                NSDictionary *requestedProcedureCodeSequence = [requestAttributesSequence valueForKey:@"RequestedProcedureCodeSequence"];
                if (requestedProcedureCodeSequence) {
                    requestedProcedureCodeValue = [requestedProcedureCodeSequence valueForKey:@"CodeValue"];
                    requestedProcedureCodeMeaning = [requestedProcedureCodeSequence valueForKey:@"CodeMeaning"];
                    requestedProcedureCodingSchemeDesignator = [requestedProcedureCodeSequence valueForKey:@"CodingSchemeDesignator"];
                    requestedProcedureCodingSchemeVersion = [requestedProcedureCodeSequence valueForKey:@"CodingSchemeVersion"];
                }
                
                NSDictionary *scheduledProtocolCodeSequence = [requestAttributesSequence valueForKey:@"ScheduledProtocolCodeSequence"];
                if (scheduledProtocolCodeSequence) {
                    scheduledProtocolCodeValue = [scheduledProtocolCodeSequence valueForKey:@"CodeValue"];
                    scheduledProtocolCodeMeaning = [scheduledProtocolCodeSequence valueForKey:@"CodeMeaning"];
                    scheduledProtocolCodingSchemeDesignator = [scheduledProtocolCodeSequence valueForKey:@"CodingSchemeDesignator"];
                    scheduledProtocolCodingSchemeVersion = [scheduledProtocolCodeSequence valueForKey:@"CodingSchemeVersion"];
                }
            }
            
            if (dataset->findOrCreateSequenceItem(DCM_RequestAttributesSequence, sequenceItem, -2 /* append */).good())
            {
                sequenceItem->putAndInsertString(DCM_RequestedProcedureID, [requestedProcedureID UTF8String]);
                sequenceItem->putAndInsertString(DCM_RequestedProcedureDescription, [requestedProcedureDescription UTF8String]);
                sequenceItem->putAndInsertString(DCM_ScheduledProcedureStepID, [scheduledProcedureStepID UTF8String]);
                sequenceItem->putAndInsertString(DCM_ScheduledProcedureStepDescription, [scheduledProcedureStepDescription UTF8String]);
                
                //Requested Procedure Code Sequence
                DcmItem *refItem = NULL;
                if (requestedProcedureCodeValue.length > 0 ||  requestedProcedureCodingSchemeDesignator.length > 0 || requestedProcedureCodeMeaning.length > 0 || requestedProcedureCodingSchemeVersion.length > 0) {
                    if (sequenceItem->findOrCreateSequenceItem(DCM_RequestedProcedureCodeSequence, refItem, -2 /* append */).good())
                    {
                        if (requestedProcedureCodeValue.length > 0) {
                            refItem->putAndInsertString(DCM_CodeValue, [requestedProcedureCodeValue UTF8String]);
                        }
                        if (requestedProcedureCodingSchemeDesignator.length > 0) {
                            refItem->putAndInsertString(DCM_CodingSchemeDesignator, [requestedProcedureCodingSchemeDesignator UTF8String]);
                        }
                        if (requestedProcedureCodeMeaning.length > 0) {
                            refItem->putAndInsertString(DCM_CodeMeaning, [requestedProcedureCodeMeaning UTF8String]);
                        }
                        if (requestedProcedureCodingSchemeVersion.length > 0) {
                            refItem->putAndInsertString(DCM_CodingSchemeVersion, [requestedProcedureCodingSchemeVersion UTF8String]);
                        }
                    }
                }
                
                //Scheduled Protocol Code Sequence
                if (scheduledProtocolCodeValue.length > 0 || scheduledProtocolCodingSchemeDesignator.length > 0 || scheduledProtocolCodeMeaning.length > 0 || scheduledProtocolCodingSchemeVersion.length > 0) {
                    if (sequenceItem->findOrCreateSequenceItem(DCM_ScheduledProtocolCodeSequence, refItem, -2 /* append */).good())
                    {
                        if (scheduledProtocolCodeValue.length > 0) {
                            refItem->putAndInsertString(DCM_CodeValue, [scheduledProtocolCodeValue UTF8String]);
                        }
                        if (scheduledProtocolCodingSchemeDesignator.length > 0) {
                             refItem->putAndInsertString(DCM_CodingSchemeDesignator, [scheduledProtocolCodingSchemeDesignator UTF8String]);
                        }
                        if (scheduledProtocolCodeMeaning.length > 0) {
                            refItem->putAndInsertString(DCM_CodeMeaning, [scheduledProtocolCodeMeaning UTF8String]);
                        }
                        if (scheduledProtocolCodingSchemeVersion.length > 0) {
                            refItem->putAndInsertString(DCM_CodingSchemeVersion, [scheduledProtocolCodingSchemeVersion UTF8String]);
                        }
                    }
                }
            } //end Request Attributes Sequence
        }
        
        //Image specific tags
        dataset->putAndInsertString(DCM_ProtocolName, [requestedProcedureDescription UTF8String]);
        dataset->putAndInsertString(DCM_PerformedProcedureStepDescription, [requestedProcedureDescription UTF8String]);
        dataset->putAndInsertString(DCM_SOPInstanceUID, [[Utility getSOPInstanceUID]UTF8String]);
        dataset->putAndInsertString(DCM_SeriesInstanceUID, [seriesInstanceId UTF8String]);
        
        //As per Regis feedback, series date & time is equal to Acquisition date & time
//        dataset->putAndInsertString(DCM_SeriesDate, [series.dateString UTF8String]);
//        dataset->putAndInsertString(DCM_SeriesTime, [series.timeString UTF8String]);
        
        dataset->putAndInsertString(DCM_SeriesDate, [media.dateString UTF8String]);
        dataset->putAndInsertString(DCM_SeriesTime, [media.timeString UTF8String]);
        dataset->putAndInsertString(DCM_AcquisitionDate, [media.dateString UTF8String]);
        dataset->putAndInsertString(DCM_AcquisitionTime, [media.timeString UTF8String]);
        dataset->putAndInsertString(DCM_AcquisitionDateTime, [[Utility getFormattedDateTime:media.date] UTF8String]);
        
        dataset->putAndInsertString(DCM_ContentDate, [media.dateString UTF8String]);
        dataset->putAndInsertString(DCM_ContentTime, [media.timeString UTF8String]);
        
        dataset->putAndInsertString(DCM_PatientOrientation, "");
        dataset->putAndInsertString(DCM_PlanarConfiguration, "0");
        dataset->putAndInsertString(DCM_SamplesPerPixel, "3");
        dataset->putAndInsertString(DCM_BitsAllocated, "8");
        dataset->putAndInsertString(DCM_BitsStored, "8");
        dataset->putAndInsertString(DCM_HighBit, "7");
        dataset->putAndInsertString(DCM_PixelRepresentation, "0");
        dataset->putAndInsertString(DCM_LossyImageCompression, "01");
        
        dataset->putAndInsertString(DCM_PatientComments, [patientModule.comments UTF8String]); //Changed by Malleswari from studyDescription to comments
        dataset->putAndInsertString(DCM_SpecificCharacterSet, [@"ISO_IR 192" UTF8String]);
        
        dataset->putAndInsertString(DCM_InstanceCreationDate, [media.dateString UTF8String]);
        dataset->putAndInsertString(DCM_InstanceCreationTime, [media.timeString UTF8String]);
        dataset->putAndInsertString(DCM_ContentDate, [media.dateString UTF8String]);
        dataset->putAndInsertString(DCM_ContentTime, [media.timeString UTF8String]);
        //Laterality of (paired) body part examined.
        dataset->putAndInsertString(DCM_Laterality, [@"" UTF8String]);
        
        dataset->putAndInsertString(DCM_ManufacturerModelName, [appName UTF8String]);
        
        NSString *deviceName = [Utility getValidStationName:[[UIDevice currentDevice] name]];
        if (media.stationName.length) {
            dataset->putAndInsertString(DCM_StationName, [media.stationName UTF8String]);
        }else{
            dataset->putAndInsertString(DCM_StationName, [deviceName UTF8String]);
        }
        
        dataset->putAndInsertString(DCM_Manufacturer, Manufacturer);
        
        NSString *deviceIdent = [[UIDevice currentDevice] identifierForVendor].UUIDString;
        dataset->putAndInsertString(DCM_DeviceSerialNumber, [deviceIdent UTF8String]);
        
        NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        dataset->putAndInsertString(DCM_SoftwareVersions, [appVersion UTF8String]);
        
        NSString *seriesNum = [NSString stringWithFormat:@"%ld",(long)study.seriesNumber];
        dataset->putAndInsertString(DCM_SeriesNumber, [seriesNum UTF8String]); // to implement series number
        dataset->putAndInsertString(DCM_InstanceNumber, "1");
        dataset->putAndInsertString(DCM_InstitutionName, [patientModule.institutionName UTF8String]);
        //        dataset->putAndInsertString(DCM_AcquisitionDateTime, [[Utility getFormattedDateTime:series.date] UTF8String]);
        dataset->putAndInsertString(DCM_Priority, [@"LOW" UTF8String]);
        
        // Creating Sequence
        DcmItem *item = NULL;
        if (dataset->findOrCreateSequenceItem(DCM_ContributingEquipmentSequence, item, -2 /* append */).good())
        {
            DcmItem *refitem = NULL;
            if (item->findOrCreateSequenceItem(DCM_PurposeOfReferenceCodeSequence, refitem, -2 /* append */).good())
            {
                refitem->putAndInsertString(DCM_CodeValue, "109101");
                refitem->putAndInsertString(DCM_CodingSchemeDesignator, "DCM");
                refitem->putAndInsertString(DCM_CodeMeaning, "Acquisition Equipment");
            }
            
            item->putAndInsertString(DCM_Manufacturer, Manufacturer);
            item->putAndInsertString(DCM_InstitutionName, [patientModule.institutionName UTF8String]);
            if (patientModule.stationName)
            {
                NSString *stationName = [Utility getValidStationName:patientModule.stationName];
                item->putAndInsertString(DCM_StationName, [stationName UTF8String]);
            }
            else
            {
                item->putAndInsertString(DCM_StationName, [deviceName UTF8String]);
            }
            // OPMI MODEL NAME // currently not getting
            item->putAndInsertString(DCM_ManufacturerModelName, ModelName);
            // OPMI SERIAL NUMBER
            item->putAndInsertString(DCM_DeviceSerialNumber, SerialNumber);
        }
        //Laterality of (paired) body part examined.
        dataset->putAndInsertString(DCM_Laterality, [@"" UTF8String]);
        // Anotomic region Sequence
        DcmItem *regionItem = NULL;
        if (dataset->findOrCreateSequenceItem(DCM_AnatomicRegionSequence, regionItem, -2 /* append */).good())
        {
            //Old values only for dental
            /*regionItem->putAndInsertString(DCM_CodeValue, "T-51000");
             regionItem->putAndInsertString(DCM_CodingSchemeDesignator, "SRT");
             regionItem->putAndInsertString(DCM_CodeMeaning, "Mouth");*/
            
            regionItem->putAndInsertString(DCM_CodeValue, "T-D1000");
            regionItem->putAndInsertString(DCM_CodingSchemeDesignator, "SRT");
            regionItem->putAndInsertString(DCM_CodeMeaning, "Head and Neck");
        }
        
        dataset->putAndInsertString(DCM_ImageType, "ORIGINAL\\PRIMARY");
        if ([mediaType isEqual: @"jpeg"])
        {
            dataset->putAndInsertString(DCM_LossyImageCompressionMethod, "ISO_10918_1"); //ISO_13818_2
            dataset->putAndInsertString(DCM_PhotometricInterpretation, "YBR_FULL_422"); //YBR_PARTIAL_420 //YBR_FULL_422
        }
        else
        {
            //            dataset->putAndInsertString(DCM_ConversionType, "WSD");
            dataset->putAndInsertString(DCM_LossyImageCompressionMethod, "ISO_13818_2"); //ISO_10918_1
            dataset->putAndInsertString(DCM_PhotometricInterpretation, "YBR_PARTIAL_420"); //YBR_PARTIAL_420 //YBR_FULL_422
            
            if ([media.rows length] > 1 && [media.colums length] > 1){
                dataset->putAndInsertString(DCM_Rows, [media.rows UTF8String]);
                dataset->putAndInsertString(DCM_Columns, [media.colums UTF8String]);
            }else{
                dataset->putAndInsertString(DCM_Rows, "1080");
                dataset->putAndInsertString(DCM_Columns, "1920");
            }
            
            dataset->putAndInsertString(DCM_FrameTime, "33.33"); // 40 (PAL) // 33.3 (NTSC)
            dataset->putAndInsertString(DCM_CineRate, "30");
            
            if ([media.frameTime length] > 0 && media.durationSeconds )  {
                
                float aValue = [media.frameTime floatValue];
                NSString *frames = [NSString stringWithFormat:@"%.0f",aValue*media.durationSeconds];
                dataset->putAndInsertString(DCM_NumberOfFrames, [frames UTF8String]); // 40 (PAL) // 33.3 (NTSC)
                dataset->putAndInsertString(DCM_FrameIncrementPointer, [@"(0018,1063)" UTF8String]); //Tag ID of DCM_FrameTime (0018,1063)
            }
        }
        
        dataset->insertEmptyElement(DCM_AcquisitionContextSequence);
        
        // PrivateTags
        if (!dataset->tagExists(PRV_PrivateCreator) && media.tagStrings.length)
        {
            NSString *tagsString = [media.tagStrings substringToIndex:[media.tagStrings length]-1];
            dataset->putAndInsertString(PRV_PrivateCreator, PrivateCreatorName);
            dataset->putAndInsertString(PRV_PrivateElement, [tagsString UTF8String]);
        }
        
        
        Uint32 length;
        __block char *pixData;
        OFCondition cond;
        __block DcmPixelSequence *sq;
        __block DcmPixelData *pixelData = new DcmPixelData(DCM_PixelData);
        __block DcmFileFormat fileformat;
        __block I2DJpegSource *i2d = NULL;
        __block DcmPixelItem *dcmitem = new DcmPixelItem(DcmTag(DCM_Item, EVR_OB));
        __block NSData *videodata = nil;
        __block NSString *tempPath = NSTemporaryDirectory();
        
        //---------------------------------------------------------------------------------------
        //Set up a cleanup block that'll release any handles before cancellation
        void (^cleanup)(void) = ^{
            
            dataset->clear();
            fileformat.clear();
            if (sq != NULL) {
                sq = NULL;
            }
            if (pixelData != NULL) {
                pixelData = NULL;
            }
            if (dcmitem) {
                dcmitem = NULL;
            }
            if (i2d != NULL) {
                i2d = NULL;
            }
            if (videodata != nil) {
                videodata = nil;
            }
            if ([[NSFileManager defaultManager] fileExistsAtPath:tempPath])
            {
                [[NSFileManager defaultManager] removeItemAtPath:tempPath error:nil];
            }
        };
        
        if (weakOperation.cancelled)
        {
            failure(operationError);
            return;
        }
        if ([mediaType isEqual: @"jpeg"])
        {
            // UID_SecondaryCaptureImageStorage
            //Adding SOPClassUID for secondary captured image
            dataset->putAndInsertString(DCM_SOPClassUID, UID_VLMicroscopicImageStorage);
            
            i2d = new I2DJpegSource();
            i2d->setImageFile([media.mediaPath UTF8String]);
            
            Uint16 rows,cols, samplesPerPixel, bitsAlloc, bitsStored, highBit, pixelRepr, planConf, pixAspectH, pixAspectV;
            E_TransferSyntax ts;
            OFString photoMetrInt;
            OFCondition status =  i2d->readPixelData(rows, cols, samplesPerPixel, photoMetrInt, bitsAlloc, bitsStored, highBit, pixelRepr, planConf, pixAspectH, pixAspectV, pixData, length, ts);
            
            if (weakOperation.cancelled)
            {
                failure(operationError);
                return;
            }
            
            if (status != EC_Normal)
            {
                OFString temp_str;
                DCMNET_ERROR("Failed to read image data: " << DimseCondition::dump(temp_str, status));
                NSString *errorMsg = [[NSString alloc] initWithFormat:@"Failed to read image data - Error : %s",status.text()];
                failure([NSError errorWithDomain:@"UNO3"
                                            code:EPERM
                                        userInfo:@{
                                                   NSLocalizedDescriptionKey: errorMsg
                                                   }]);
                cleanup();
                return;
            }
            
            char rowschar[10];
            char colschar[10];
            sprintf(rowschar, "%d", (int) rows);
            sprintf(colschar, "%d", (int) cols);
            
            dataset->putAndInsertString(DCM_Rows, rowschar);
            dataset->putAndInsertString(DCM_Columns, colschar);
            cond = dataset->chooseRepresentation(EXS_JPEGProcess1TransferSyntax, NULL);
            if (cond != EC_Normal)
            {
                OFString temp_str;
                DCMNET_ERROR("Failed to select a specific representation: " << DimseCondition::dump(temp_str, status));
                failure([NSError errorWithDomain:@"UNO3"
                                            code:EPERM
                                        userInfo:@{
                                                   NSLocalizedDescriptionKey:@"Failed to select a specific representation"
                                                   }]);
                cleanup();
                return;
            }
            
            if (rows == 0 || strlen(pixData) == 0) {
                failure([NSError errorWithDomain:@"UNO3"
                                            code:EPERM
                                        userInfo:@{
                                                   NSLocalizedDescriptionKey:@"Image is invalid"
                                                   }]);
                cleanup();
                return;
            }
            
            sq = new DcmPixelSequence(DcmTag(DCM_PixelData, EVR_OB));
            sq->insert(dcmitem);
            
            DcmOffsetList offsetList;
            sq->storeCompressedFrame(offsetList, (unsigned char *)pixData, length, 0);
            pixelData->putOriginalRepresentation(EXS_JPEGProcess1TransferSyntax, NULL, sq);
            dataset->insert(pixelData);
            
            if (weakOperation.cancelled)
            {
                failure(operationError);
                return;
            }
            
            try {
                fileformat = DcmFileFormat(dataset);
                OFCondition status = fileformat.saveFile([dcmFilePath UTF8String], EXS_JPEGProcess1TransferSyntax);
                
                if (status == EC_Normal)
                {
                    cleanup();
                    success(dcmFilePath);
                }else{
                    OFString temp_str;
                    DCMNET_ERROR("Error: " << DimseCondition::dump(temp_str, status));
                    failure([NSError errorWithDomain:@"UNO3"
                                                code:EPERM
                                            userInfo:@{
                                                       NSLocalizedDescriptionKey:[NSString stringWithFormat:@"error : %s", status.text()]
                                                       }]);
                    cleanup();
                    return;
                }
            } catch (NSError *error) {
                failure([NSError errorWithDomain:@"UNO3"
                                            code:EPERM
                                        userInfo:@{
                                                   NSLocalizedDescriptionKey:@"Error"
                                                   }]);
                cleanup();
                return;
            }
        }
        else
        {
            
            if (weakOperation.cancelled)
            {
                failure(operationError);
                return;
            }
            
            //Adding SOPClassUID for Video VLMicroscope image
            dataset->putAndInsertString(DCM_SOPClassUID, UID_VideoMicroscopicImageStorage);
            
            tempPath = [tempPath stringByAppendingPathComponent:@"samplePixels.data"];
            [[NSFileManager defaultManager] createFileAtPath:tempPath contents:nil attributes:nil];
            NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:tempPath];
            FILE *fp = fopen([media.mediaPath UTF8String], "rb");
            if (fp == NULL)
            {
                failure([NSError errorWithDomain:@"UNO3"
                                            code:EPERM
                                        userInfo:@{
                                                   NSLocalizedDescriptionKey:@"Failed to load file"
                                                   }]);
                cleanup();
                return;
            }
            size_t readLength = 1;
            void *buffer = malloc(DCM_DumpMaxLineSize);
            while (readLength != 0)
            {
                @autoreleasepool
                {
                    readLength = fread(buffer, 1, DCM_DumpMaxLineSize, fp);
                    if (readLength > 0)
                    {
                        [fileHandle writeData:[NSData dataWithBytes:buffer length:readLength]];
                        [fileHandle synchronizeFile];
                    }
                }
                if (weakOperation.cancelled)
                    break;
            }
            if (weakOperation.cancelled)
            {
                failure(operationError);
                return;
            }
            // ADDING EXTRA BYTE IN CASE OF ODD LENGTH FILES //DICOM SUPPORTS EVEN LENGTH
            if ([fileHandle seekToEndOfFile] & 1)
            {
                [fileHandle writeData:[NSData dataWithBytes:"\0" length:1]];
                [fileHandle synchronizeFile];
            }
            
            [[NSFileManager defaultManager] setAttributes:@{NSFileModificationDate:[NSDate date]} ofItemAtPath:tempPath error:nil];
            [fileHandle closeFile];
            fclose(fp);
            
            cond = dataset->chooseRepresentation(EXS_MPEG2MainProfileAtHighLevel, NULL);
            
            if (cond != EC_Normal)
            {
                OFString temp_str;
                DCMNET_ERROR("Failed to select a specific representation: " << DimseCondition::dump(temp_str, cond));
                failure([NSError errorWithDomain:@"UNO3"
                                            code:EPERM
                                        userInfo:@{
                                                   NSLocalizedDescriptionKey:@"Failed to select a specific representation"
                                                   }]);
                cleanup();
                return;
            }
            
            sq = new DcmPixelSequence(DcmTag(DCM_PixelData, EVR_OB));
            sq->insert(dcmitem);
            /* create stream object for binary file */
            DcmInputFileStream *fileStream = new DcmInputFileStream([tempPath UTF8String]);
            OFCondition ec = fileStream->status();
            if (ec.good())
            {
                /* NB: if size is odd file will be rejected */
                size_t fileLen = OFStandard::getFileSize([tempPath UTF8String]);
                DcmPixelItem *newElement = new DcmPixelItem(DcmTag(DCM_Item, EVR_OB));
                /* read element value from binary file (requires even length) */
                ec = newElement->createValueFromTempFile(fileStream->newFactory(), Uint32(fileLen) , EBO_LittleEndian);
                if (ec.good())
                {
                    sq->insert(newElement);
                }
                else
                {
                    failure([NSError errorWithDomain:@"UNO3"
                                                code:EPERM
                                            userInfo:@{
                                                       NSLocalizedDescriptionKey:[NSString stringWithFormat:@"error : %s", ec.text()]
                                                       }]);
                    cleanup();
                    return;
                }
            }
            else
            {
                failure([NSError errorWithDomain:@"UNO3"
                                            code:EPERM
                                        userInfo:@{
                                                   NSLocalizedDescriptionKey:[NSString stringWithFormat:@"error : %s", ec.text()]
                                                   }]);
                cleanup();
                return;
            }
            
            pixelData->putOriginalRepresentation(EXS_MPEG2MainProfileAtHighLevel, NULL, sq);
            
            dataset->insert(pixelData);
            
            if (weakOperation.cancelled)
            {
                failure(operationError);
                return;
            }
            
            try
            {
                fileformat = DcmFileFormat(dataset);
                
                OFCondition status = fileformat.saveFile([dcmFilePath UTF8String], EXS_MPEG2MainProfileAtHighLevel);
                
                if (weakOperation.cancelled)
                {
                    failure(operationError);
                    return;
                }
                if (status == EC_Normal)
                {
                    cleanup();
                    success(dcmFilePath);
                }
                else
                {
                    OFString temp_str;
                    DCMNET_ERROR("Error: " << DimseCondition::dump(temp_str, status));
                    failure([NSError errorWithDomain:@"UNO3"
                                                code:EPERM
                                            userInfo:@{
                                                       NSLocalizedDescriptionKey:[NSString stringWithFormat:@"error : %s", status.text()]
                                                       }]);
                    cleanup();
                }
            }
            catch (NSError *error)
            {
                failure([NSError errorWithDomain:@"UNO3"
                                            code:EPERM
                                        userInfo:@{
                                                   NSLocalizedDescriptionKey:@"Error"
                                                   }]);
                cleanup();
            }
        }
    }
}

+(void)cancelDCMfileCreation
{
    id deleteBlock = ^{
    };
    if (uploadOperation != nil)
    {
        NSBlockOperation *deleteOperation = [[NSBlockOperation alloc] init];
        [deleteOperation addExecutionBlock:deleteBlock];
        [deleteOperation addDependency:uploadOperation];
        [uploadQueue addOperation:deleteOperation];
        [uploadOperation cancel];
    }
}
@end

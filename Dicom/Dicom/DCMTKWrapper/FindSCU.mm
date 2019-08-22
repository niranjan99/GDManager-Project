//
//  FindSCU.m
//  Dicom
//
//  Created by Bankim Debnath on 30/03/16.
//  Copyright © 2016 Carl Zeiss Meditec. All rights reserved.
//

#define WITH_OPENSSL 1

#import "FindSCU.h"
#import "Echo.h"
#import "Constants.h"
#import "AppConstants.h"
#import "DicomValidator.h"
#import "DicomLogger.h"

#include "dcmtk/dcmnet/scu.h"
#include "dcmtk/dcmnet/dfindscu.h"
#include "dcmtk/dcmtls/tlsscu.h"
#include "dcmtk/dcmnet/diutil.h"

@implementation FindSCU

- (DcmSCU *)createSCU:(ServerConfigurationModule*)configureInfoObject{
    
    NSString *callingAE = configureInfoObject.callingAE;
    NSString *calledAE = configureInfoObject.calledAE;
    NSString *calledIP = configureInfoObject.calledIP;
    NSString *port = configureInfoObject.port;
    
    DcmSCU * DicomSCU = new DcmSCU();
    DicomSCU->setAETitle([callingAE UTF8String]);
    DicomSCU->setPeerAETitle([calledAE UTF8String]);
    DicomSCU->setPeerHostName([calledIP UTF8String]);
    DicomSCU->setPeerPort([port intValue]);
    DicomSCU->setDIMSEBlockingMode(DIMSE_NONBLOCKING);
    DicomSCU->setDIMSETimeout(30);
    DicomSCU->setACSETimeout(30);
    DicomSCU->setMaxReceivePDULength(ASC_MAXIMUMPDUSIZE);
    
    return DicomSCU;
}

//- (DcmTLSSCU *)createTLSSCU:(ServerConfigurationModule*)configureInfoObject {
//    NSString *callingAE = configureInfoObject.callingAE;
//    NSString *calledAE = configureInfoObject.calledAE;
//    NSString *calledIP = configureInfoObject.calledIP;
//    NSString *port = configureInfoObject.port;
//
//    DcmTLSSCU * dicomTLSSCU = new DcmTLSSCU();
//    dicomTLSSCU->setAETitle([callingAE UTF8String]);
//    dicomTLSSCU->setPeerAETitle([calledAE UTF8String]);
//    dicomTLSSCU->setPeerHostName([calledIP UTF8String]);
//    dicomTLSSCU->setPeerPort([port intValue]);
//    dicomTLSSCU->setDIMSEBlockingMode(DIMSE_NONBLOCKING);
//    dicomTLSSCU->setDIMSETimeout(30);
//    dicomTLSSCU->setACSETimeout(30);
//    dicomTLSSCU->setMaxReceivePDULength(ASC_MAXIMUMPDUSIZE);
//
//    dicomTLSSCU->addTrustedCertFile(ServerCert);
//    //dicomTLSSCU->addTrustedCertFile("RootCA.crt");
//    dicomTLSSCU->enableAuthentication(PrivatePEMKey, ClientCert, Password, 1, 1);
//    dicomTLSSCU->setPeerCertVerification(DCV_checkCertificate);
//
//    return dicomTLSSCU;
//}

- (void)findScu:(NSString *)PatientId withStringType:(NSString *)stringType PACSConnection:(ServerConfigurationModule *)configureInfoObject success:(void(^)(NSMutableArray *result))success failure:(void(^)(NSError *error))failure {
    @autoreleasepool {
        if (configureInfoObject == nil) {
            failure([NSError errorWithDomain:@"UNO3" code:EPERM userInfo:@{
                                                                           NSLocalizedDescriptionKey:@"PACS needs to be configured correctly"
                                                                           }]);
            return;
        }
        
        const char *ID = [PatientId UTF8String];
        NSString *searchType = stringType;
        
        NSMutableArray *patientArray = [[NSMutableArray alloc] init];
        
        DcmSCU * DicomSCU = [self createSCU:configureInfoObject];
        
        OFList<OFString> TransferSyntaxes;
        //TransferSyntaxes.push_back(UID_LittleEndianExplicitTransferSyntax);
        TransferSyntaxes.push_back(UID_LittleEndianImplicitTransferSyntax);
        
        DicomSCU->addPresentationContext(UID_FINDPatientRootQueryRetrieveInformationModel, TransferSyntaxes);
        
        OFCondition result = DicomSCU->initNetwork();
        result = DicomSCU->negotiateAssociation();
        
        T_ASC_PresentationContextID cxID = NULL;
        if (result == EC_Normal) {
            cxID = DicomSCU->findPresentationContextID(UID_FINDPatientRootQueryRetrieveInformationModel, "");
        } else {
            OFString temp_str;
            DCMNET_ERROR("PACS connection details are not correct: " << DimseCondition::dump(temp_str, result));
            failure([NSError errorWithDomain:@"UNO3"
                                        code:EPERM
                                    userInfo:@{
                                               NSLocalizedDescriptionKey:@"PACS connection details are not correct"
                                               }]);
            return;
        }
        
        DcmDataset findParams = DcmDataset();
        findParams.putAndInsertString(DCM_QueryRetrieveLevel, "PATIENT");
        findParams.putAndInsertString(DCM_PatientSex, "");
        findParams.putAndInsertString(DCM_PatientAge, "");
        
        if ([searchType isEqualToString:@"ID"]) {
            findParams.putAndInsertString(DCM_PatientID, ID);
            findParams.putAndInsertString(DCM_PatientName, "");
            findParams.putAndInsertString(DCM_PatientBirthDate, "");
        } else if ([searchType isEqualToString:@"name"]) {
            findParams.putAndInsertString(DCM_PatientName, ID);
            findParams.putAndInsertString(DCM_PatientID, "");
            findParams.putAndInsertString(DCM_PatientBirthDate, "");
        } else if ([searchType isEqualToString:@"dob"]) {
            findParams.putAndInsertString(DCM_PatientBirthDate, ID);
            findParams.putAndInsertString(DCM_PatientName, "");
            findParams.putAndInsertString(DCM_PatientID, "");
        }
        
        FINDResponses responses;
        result = DicomSCU->sendFINDRequest(cxID, &findParams, &responses);
        
        DicomSCU->closeAssociation(DCMSCU_RELEASE_ASSOCIATION);
        if (result != EC_Normal)
        {
            OFString temp_str;
            DCMNET_ERROR("Failed to fetch patient data: " << DimseCondition::dump(temp_str, result));
            failure([NSError errorWithDomain:@"UNO3"
                                        code:EPERM
                                    userInfo:@{
                                               NSLocalizedDescriptionKey:@"Faild to fetch patient data"
                                               }]);
            return;
        }
        
        DcmDataset *dset = NULL;
        OFListIterator(FINDResponse*) it = responses.begin();
        
        while (it != responses.end())
        {
            FINDResponse* rsp = *it;
            dset =  rsp->m_dataset;
            
            if (dset != NULL)
            {
                OFString PatientID;
                result = dset->findAndGetOFString(DCM_PatientID, PatientID);
                NSLog(@"%s---- Patient ID ", PatientID.c_str());
                
                OFString PatientName;
                result = dset->findAndGetOFString(DCM_PatientName, PatientName);
                NSLog(@"%s---- Patient Name ", PatientName.c_str());
                
                OFString Patientsex;
                result = dset->findAndGetOFString(DCM_PatientSex, Patientsex);
                NSLog(@"%s---- Patient sex ", Patientsex.c_str());
                
                OFString PatientAge;
                result = dset->findAndGetOFString(DCM_PatientAge, PatientAge);
                NSLog(@"%s---- Patient age ", PatientAge.c_str());
                
                OFString PatientDob;
                result = dset->findAndGetOFString(DCM_PatientBirthDate, PatientDob);
                NSLog(@"%s---- Patient DOB ", PatientDob.c_str());
                
                Patient *patient = [[Patient alloc] init];
                patient.Id = [[NSString alloc] initWithUTF8String:PatientID.c_str()];
                patient.firstName = [[NSString alloc] initWithUTF8String:PatientName.c_str()];
                
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
                NSDate *date = [dateFormatter dateFromString:[[NSString alloc] initWithUTF8String:PatientDob.c_str()]];
                
                patient.dateOfBirth = date;
                patient.gender = [[NSString alloc] initWithUTF8String:Patientsex.c_str()];
                
                //                    NSMutableArray *studies = [self getStudies:[[NSString alloc] initWithUTF8String:PatientID.c_str()] PACSConnection:configureInfoObject];
                patient.studies = [NSMutableArray new];
                
                [patientArray addObject:patient];
            }
            it++;
        }
        
        // clear memory
        findParams.clear();
        if (dset != NULL)
            dset->clear();
        if (cxID)
            cxID = NULL;
        
        //Success Response
        success(patientArray);
    }
}

//- (void)findScuWithTLS:(NSString *)PatientId withStringType:(NSString *)stringType PACSConnection:(ServerConfigurationModule *)configureInfoObject success:(void(^)(NSMutableArray *result))success failure:(void(^)(NSError *error))failure {
//    @autoreleasepool {
//        if (!PatientId) {
//            failure([NSError errorWithDomain:@"UNO3" code:EPERM userInfo:@{
//                                                                           NSLocalizedDescriptionKey:@"Patient id can't be nill"
//                                                                           }]);
//            return;
//        }
//        
//        const char *ID = [PatientId UTF8String];
//        NSString *searchType = stringType;
//        
//        NSMutableArray *patientArray = [[NSMutableArray alloc] init];
//        
//        DcmTLSSCU * dicomTLSSCU = [self createTLSSCU:configureInfoObject];
//        
//        OFList<OFString> TransferSyntaxes;
//        //TransferSyntaxes.push_back(UID_LittleEndianExplicitTransferSyntax);
//        TransferSyntaxes.push_back(UID_LittleEndianImplicitTransferSyntax);
//        
//        dicomTLSSCU->addPresentationContext(UID_FINDPatientRootQueryRetrieveInformationModel, TransferSyntaxes);
//        
//        OFCondition result = dicomTLSSCU->initNetwork();
//        result = dicomTLSSCU->negotiateAssociation();
//        
//        T_ASC_PresentationContextID cxID = NULL;
//        if (result == EC_Normal) {
//            cxID = dicomTLSSCU->findPresentationContextID(UID_FINDPatientRootQueryRetrieveInformationModel, "");
//        }else{
//            OFString temp_str;
//            DCMNET_ERROR("PACS connection details are not correct: " << DimseCondition::dump(temp_str, result));
//            failure([NSError errorWithDomain:@"UNO3"
//                                        code:EPERM
//                                    userInfo:@{
//                                               NSLocalizedDescriptionKey:@"PACS connection details are not correct"
//                                               }]);
//            return;
//        }
//        
//        DcmDataset findParams = DcmDataset();
//        findParams.putAndInsertString(DCM_QueryRetrieveLevel, "PATIENT");
//        findParams.putAndInsertString(DCM_PatientSex, "");
//        findParams.putAndInsertString(DCM_PatientAge, "");
//        
//        if ([searchType isEqualToString:@"ID"]) {
//            findParams.putAndInsertString(DCM_PatientID, ID);
//            findParams.putAndInsertString(DCM_PatientName, "");
//            findParams.putAndInsertString(DCM_PatientBirthDate, "");
//        } else if ([searchType isEqualToString:@"name"]) {
//            findParams.putAndInsertString(DCM_PatientName, ID);
//            findParams.putAndInsertString(DCM_PatientID, "");
//            findParams.putAndInsertString(DCM_PatientBirthDate, "");
//        } else if ([searchType isEqualToString:@"dob"]) {
//            findParams.putAndInsertString(DCM_PatientBirthDate, ID);
//            findParams.putAndInsertString(DCM_PatientName, "");
//            findParams.putAndInsertString(DCM_PatientID, "");
//        }
//        
//        FINDResponses responses;
//        result = dicomTLSSCU->sendFINDRequest(cxID, &findParams, &responses);
//        
//        dicomTLSSCU->closeAssociation(DCMSCU_RELEASE_ASSOCIATION);
//        if (result != EC_Normal)
//        {
//            OFString temp_str;
//            DCMNET_ERROR("Failed to fetch patient data: " << DimseCondition::dump(temp_str, result));
//            failure([NSError errorWithDomain:@"UNO3"
//                                        code:EPERM
//                                    userInfo:@{
//                                               NSLocalizedDescriptionKey:@"Failed to fetch patient data"
//                                               }]);
//            return;
//        }
//        
//        DcmDataset *dset = NULL;
//        OFListIterator(FINDResponse*) it = responses.begin();
//        
//        while (it != responses.end())
//        {
//            FINDResponse* rsp = *it;
//            dset =  rsp->m_dataset;
//            
//            if (dset != NULL)
//            {
//                OFString PatientID;
//                result = dset->findAndGetOFString(DCM_PatientID, PatientID);
//                NSLog(@"%s---- Patient ID ", PatientID.c_str());
//                
//                OFString PatientName;
//                result = dset->findAndGetOFString(DCM_PatientName, PatientName);
//                NSLog(@"%s---- Patient Name ", PatientName.c_str());
//                
//                OFString Patientsex;
//                result = dset->findAndGetOFString(DCM_PatientSex, Patientsex);
//                NSLog(@"%s---- Patient sex ", Patientsex.c_str());
//                
//                OFString PatientAge;
//                result = dset->findAndGetOFString(DCM_PatientAge, PatientAge);
//                NSLog(@"%s---- Patient age ", PatientAge.c_str());
//                
//                OFString PatientDob;
//                result = dset->findAndGetOFString(DCM_PatientBirthDate, PatientDob);
//                NSLog(@"%s---- Patient DOB ", PatientDob.c_str());
//                
//                Patient *patient = [[Patient alloc] init];
//                patient.Id = [[NSString alloc] initWithUTF8String:PatientID.c_str()];
//                patient.firstName = [[NSString alloc] initWithUTF8String:PatientName.c_str()];
//                
//                //converting nsdate to string
//                NSDateFormatter *dateFormatter=[[NSDateFormatter alloc] init];
//                NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
//                dateFormatter.dateFormat = @"yyyyMMdd";
//                NSTimeZone *timeZone = [NSTimeZone systemTimeZone];
//                NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
//                [dateFormatter setCalendar:gregorianCalendar];
//                [dateFormatter setTimeZone:timeZone];
//                [dateFormatter setLocale:locale];
//
//              //  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//               // dateFormatter.dateFormat = @"yyyyMMdd";
//                NSDate *date = [dateFormatter dateFromString:[[NSString alloc] initWithUTF8String:PatientDob.c_str()]];
//                
//                patient.dateOfBirth = date;
//                patient.gender = [[NSString alloc] initWithUTF8String:Patientsex.c_str()];
//                
//                //                    NSMutableArray *studies = [self getStudies:[[NSString alloc] initWithUTF8String:PatientID.c_str()] PACSConnection:configureInfoObject];
//                patient.studies = [NSMutableArray new];
//                
//                [patientArray addObject:patient];
//            }
//            it++;
//        }
//        
//        // clear memory
//        findParams.clear();
//        if (dset != NULL)
//            dset->clear();
//        if (cxID)
//            cxID = NULL;
//        
//        //Success Response
//        success(patientArray);
//    }
//}

- (NSString*)getValidComponentForPatientName: (NSString*)patientName {
    NSArray *nameComponents = [patientName componentsSeparatedByString:@"="]; //3 component groups - alphabetical, ideographic, phonetic
    for (NSString* component in nameComponents) {
        if (component.length > 0 && component.length <= kPatientNameMaxLimit) {
            NSArray<NSString*> *nameSubcomponents = [component componentsSeparatedByString:@"^"];
            if (nameSubcomponents.count > 1) {
                if (nameSubcomponents[0].length > 0 && nameSubcomponents[1].length > 0) { //0 is last name, 1 is first name
                    return component;
                }
            }
        }
    }
    return @"";
}


- (void)findScuWithSearchCriteria:(NSDictionary*)searchFieldValueDict PACSConnection:(ServerConfigurationModule *)configureInfoObject success:(void(^)(NSMutableArray *result, BOOL status))success failure:(void(^)(NSError *error))failure {
    @autoreleasepool {
        if (configureInfoObject == nil) {
            failure([NSError errorWithDomain:@"UNO3" code:EPERM userInfo:@{
                                                                           NSLocalizedDescriptionKey:@"PACS needs to be configured correctly"
                                                                           }]);
            return;
        }
        
        Boolean isModalitySearch = false;
        
        NSMutableArray *patients = [[NSMutableArray alloc] init];
        
        DcmSCU * DicomSCU = [self createSCU:configureInfoObject];
        
        OFCondition result;
        T_ASC_PresentationContextID cxID = NULL;
        
        NSString *isModality = [searchFieldValueDict objectForKey:[NSNumber numberWithInt:DicomSearchTypeIsMWL]];
        if ([isModality isEqualToString:@""]) {
            OFList<OFString> TransferSyntaxes;
            //TransferSyntaxes.push_back(UID_LittleEndianExplicitTransferSyntax);
            TransferSyntaxes.push_back(UID_LittleEndianImplicitTransferSyntax);
            
            isModalitySearch = false;
            DicomSCU->addPresentationContext(UID_FINDPatientRootQueryRetrieveInformationModel, TransferSyntaxes);
            
            result = DicomSCU->initNetwork();
            result = DicomSCU->negotiateAssociation();
            
            if (result == EC_Normal) {
                cxID = DicomSCU->findPresentationContextID(UID_FINDPatientRootQueryRetrieveInformationModel, "");
            }
            else {
                OFString temp_str;
                DCMNET_ERROR("Failure PACS connection details are not correct: " << DimseCondition::dump(temp_str, result));

                NSString *errorString = [NSString stringWithFormat:@"PACS connection details are not correct for normal dicom search with AeTitle: %@",[configureInfoObject calledAE]];
                failure([NSError errorWithDomain:@"UNO3"
                                            code:EPERM
                                        userInfo:@{
                                                   NSLocalizedDescriptionKey: errorString
                                                   }]);
                return;
            }
            
            //set search parameters for normal dicom search
            
        } else {
            OFList<OFString> TransferSyntaxes;
            TransferSyntaxes.push_back(UID_LittleEndianImplicitTransferSyntax);
            
            isModalitySearch = true;
            DicomSCU->addPresentationContext(UID_FINDModalityWorklistInformationModel, TransferSyntaxes);
            
            result = DicomSCU->initNetwork();
            result = DicomSCU->negotiateAssociation();
            
            if (result == EC_Normal) {
                cxID = DicomSCU->findPresentationContextID(UID_FINDModalityWorklistInformationModel, "");
            }
            else {
                OFString temp_str;
                DCMNET_ERROR("Failure PACS connection details are not correct: " << DimseCondition::dump(temp_str, result));

                NSString *errorString = [NSString stringWithFormat:@"PACS connection details are not correct for MWL search with AeTitle: %@",[configureInfoObject calledAE]];
                failure([NSError errorWithDomain:@"UNO3"
                                            code:EPERM
                                        userInfo:@{
                                                   NSLocalizedDescriptionKey: errorString
                                                   }]);
                return;
            }
        }
        
        DcmDataset findParams = DcmDataset();
        DcmItem *refitem = NULL;
        //Common search parameters
        OFString dicomName;
        DcmPersonName::getStringFromNameComponents([[searchFieldValueDict objectForKey:[NSNumber numberWithInt:DicomSearchTypeLastName]] UTF8String],
                                                   [[searchFieldValueDict objectForKey:[NSNumber numberWithInt:DicomSearchTypeFirstName]] UTF8String],
                                                   "",
                                                   "",
                                                   "",
                                                   dicomName
                                                   );
        findParams.putAndInsertString(DCM_PatientID, [[searchFieldValueDict objectForKey:[NSNumber numberWithInt:DicomSearchTypePatientID]] UTF8String]);
        findParams.putAndInsertString(DCM_PatientName, dicomName.c_str());
        findParams.putAndInsertString(DCM_PatientBirthDate, [[searchFieldValueDict objectForKey:[NSNumber numberWithInt:DicomSearchTypeDob]] UTF8String]);
        findParams.putAndInsertString(DCM_PatientSex, "");
        findParams.putAndInsertString(DCM_IssuerOfPatientID, "");
        findParams.putAndInsertString(DCM_OtherPatientIDs, "");
        findParams.putAndInsertString(DCM_EthnicGroup, "");
        findParams.putAndInsertString(DCM_PatientComments, "");
        
        findParams.putAndInsertString(DCM_StudyInstanceUID, "");
        
        if (!isModalitySearch) {
            findParams.putAndInsertString(DCM_QueryRetrieveLevel, "PATIENT");
        } else {
            //MWL search parameters
            findParams.putAndInsertString(DCM_AccessionNumber, [[searchFieldValueDict objectForKey:[NSNumber numberWithInt:DicomSearchTypeAccessionNumber]] UTF8String]);
            findParams.putAndInsertString(DCM_ReferringPhysicianName, "");
            findParams.putAndInsertString(DCM_RequestedProcedureID, [[searchFieldValueDict objectForKey:[NSNumber numberWithInt:DicomSearchTypeProcedureID]] UTF8String]);
            findParams.putAndInsertString(DCM_RequestedProcedureDescription, "");
            findParams.putAndInsertString(DCM_RequestedProcedureComments, "");
            findParams.putAndInsertString(DCM_StudyTime, "");
            findParams.putAndInsertString(DCM_StudyDate, "");
            findParams.putAndInsertString(DCM_RequestedProcedureComments, "");

            ///Create ReferencedStudySequence
            if (findParams.findOrCreateSequenceItem(DCM_ReferencedStudySequence, refitem, -2 /* append */).good())
            {
                refitem->putAndInsertString(DCM_ReferencedSOPClassUID,"");
                refitem->putAndInsertString(DCM_ReferencedSOPInstanceUID, "");
            } // end ReferencedStudySequence

            ///Create ScheduledProcedureStepSequence
            if (findParams.findOrCreateSequenceItem(DCM_ScheduledProcedureStepSequence, refitem, -2 /* append */).good())
            {
                refitem->putAndInsertString(DCM_ScheduledStationAETitle,[[searchFieldValueDict objectForKey:[NSNumber numberWithInt:DicomSearchTypeAETitle]] UTF8String]);
                refitem->putAndInsertString(DCM_ScheduledProcedureStepStartDate, [[searchFieldValueDict objectForKey:[NSNumber numberWithInt:DicomSearchTypeProcedureDate]] UTF8String]);
                refitem->putAndInsertString(DCM_Modality, [[searchFieldValueDict objectForKey:[NSNumber numberWithInt:DicomSearchTypeModality]] UTF8String]);
                refitem->putAndInsertString(DCM_ScheduledProcedureStepStartTime, "");
                refitem->putAndInsertString(DCM_ScheduledProcedureStepDescription, "");
                refitem->putAndInsertString(DCM_ScheduledProcedureStepID, "");
                DcmItem *refInterItem = NULL;
                if (refitem->findOrCreateSequenceItem(DCM_ScheduledProtocolCodeSequence, refInterItem, -2 /* append */).good())
                {
                    refInterItem->putAndInsertString(DCM_CodeValue, "");
                    refInterItem->putAndInsertString(DCM_CodeMeaning, "");
                    refInterItem->putAndInsertString(DCM_CodingSchemeDesignator, "");
                    refInterItem->putAndInsertString(DCM_CodingSchemeVersion, "");
                }
            } // end ScheduledProcedureStepSequence
            
            ///Create RequestedProcedureCodeSequence
            DcmItem *requestedProcedureCodeSequence = NULL;
            if (findParams.findOrCreateSequenceItem(DCM_RequestedProcedureCodeSequence, requestedProcedureCodeSequence, -2 /* append */).good())
            {
                requestedProcedureCodeSequence->putAndInsertString(DCM_CodeValue, "");
                requestedProcedureCodeSequence->putAndInsertString(DCM_CodeMeaning, "");
                requestedProcedureCodeSequence->putAndInsertString(DCM_CodingSchemeDesignator, "");
                requestedProcedureCodeSequence->putAndInsertString(DCM_CodingSchemeVersion, "");
            } // end RequestedProcedureCodeSequence
        }
        
        //Get the values from the response
        FINDResponses responses;
        result = DicomSCU->sendFINDRequest(cxID, &findParams, &responses);
        
        DicomSCU->closeAssociation(DCMSCU_RELEASE_ASSOCIATION);
        if (result != EC_Normal) {
            OFString temp_str;
            DCMNET_ERROR("Failed to fetch patient data: " << DimseCondition::dump(temp_str, result));
            failure([NSError errorWithDomain:@"UNO3"
                                        code:EPERM
                                    userInfo:@{
                                               NSLocalizedDescriptionKey:@"Failed to fetch patient data"
                                               }]);
            return;
        }
        
        DcmDataset *dset = NULL;
        BOOL successStatus = YES;
        for (OFListIterator(FINDResponse*) it = responses.begin(); (it != responses.end()); it++) {
            FINDResponse* rsp = *it;
            dset =  rsp->m_dataset;
            UInt16 status = rsp->m_status;
            if (status == int(STATUS_FIND_Refused_OutOfResources) ||
                status == int(STATUS_FIND_Refused_SOPClassNotSupported) ||
                status == int(STATUS_FIND_Failed_IdentifierDoesNotMatchSOPClass) ||
                (status >= int(STATUS_FIND_Failed_UnableToProcess) && status <= 53247) || //C000 to CFFF
                status == int(STATUS_N_SOPClassNotSupported)) {
                successStatus = NO;
            }
            if (dset != NULL) {
                //PATIENT INFO
                OFString PatientID;
                result = dset->findAndGetOFString(DCM_PatientID, PatientID);
                NSLog(@"%s---- ModalityPatient ID ", PatientID.c_str());
                
                //Type 1 parameter - checking is part of VR validation
                if ( isModalitySearch && ![DicomValidator validateVRFor:[[NSString alloc] initWithUTF8String:PatientID.c_str()] forKey:VRKeyPatientID]) {
                    successStatus = successStatus && false;
                    [[DicomLogger sharedLogger] logError:[NSString stringWithFormat:@"Invalid PatientID %@",[[NSString alloc] initWithUTF8String:PatientID.c_str()]]];
                    continue;
                }
                
                //Type 1 parameter - Empty value checking is part of VR validation
                const char* PatientName;
                result = dset->findAndGetString(DCM_PatientName, PatientName);
                NSLog(@"%s---- ModalityPatient Name ", PatientName);
                if (isModalitySearch && ![DicomValidator validateVRFor:[[NSString alloc] initWithUTF8String:PatientName] forKey:VRKeyPersonName]) {
                    successStatus = successStatus && false;
                    [[DicomLogger sharedLogger] logError:[NSString stringWithFormat:@"Invalid PatientName %@ for Patient ID %@",[[NSString alloc] initWithUTF8String:PatientName],[[NSString alloc] initWithUTF8String:PatientID.c_str()]]];
                    continue;
                }

                //Type 2 parameter - VR validation is required if not empty
                OFString Patientsex;
                result = dset->findAndGetOFString(DCM_PatientSex, Patientsex);
                NSLog(@"%s---- ModalityPatient sex ", Patientsex.c_str());
                if (Patientsex.length() > 0) {
                    if (isModalitySearch && ![DicomValidator validateVRFor:[[NSString alloc] initWithUTF8String:Patientsex.c_str()] forKey:VRKeyPatientsex]) {
                        successStatus = successStatus && false;
                        [[DicomLogger sharedLogger] logError:[NSString stringWithFormat:@"Invalid Patient Gender %@ for Patient ID %@",[[NSString alloc] initWithUTF8String:Patientsex.c_str()],[[NSString alloc] initWithUTF8String:PatientID.c_str()]]];
                        continue;
                    }
                }

                //Type 3 parameter - VR validation is required if not empty
                OFString patientEthnicGroup;
                result = dset->findAndGetOFString(DCM_EthnicGroup, patientEthnicGroup);
                NSLog(@"%s---- Patient Ethnic Group ", patientEthnicGroup.c_str());
                if (patientEthnicGroup.length() > 0) {
                    if (isModalitySearch && ![DicomValidator validateVRFor:[[NSString alloc] initWithUTF8String:patientEthnicGroup.c_str()] forKey:VRKeyPatientEthnicGroup]) {
                        successStatus = successStatus && false;
                        [[DicomLogger sharedLogger] logError:[NSString stringWithFormat:@"Invalid Patient Ethnic group %@ for Patient ID %@",[[NSString alloc] initWithUTF8String:patientEthnicGroup.c_str()],[[NSString alloc] initWithUTF8String:PatientID.c_str()]]];
                        continue;
                    }
                }

                //Type 2 parameter - VR validation is required if not empty
                OFString PatientDob;
                result = dset->findAndGetOFString(DCM_PatientBirthDate, PatientDob);
                NSLog(@"%s---- ModalityPatient DOB ", PatientDob.c_str());
                if(PatientDob.length() > 0) {
                    if (isModalitySearch && ![DicomValidator validateVRFor:[[NSString alloc] initWithUTF8String:PatientDob.c_str()] forKey:VRKeyDate]) {
                        successStatus = successStatus && false;
                        [[DicomLogger sharedLogger] logError:[NSString stringWithFormat:@"Invalid PatientDob %@ for Patient ID %@",[[NSString alloc] initWithUTF8String:PatientDob.c_str()],[[NSString alloc] initWithUTF8String:PatientID.c_str()]]];
                        continue;
                    }
                }

                //Type 3 parameter - VR validation is required if not empty
                OFString IssuerOfPatientID;
                result = dset->findAndGetOFString(DCM_IssuerOfPatientID, IssuerOfPatientID);
                NSLog(@"%s---- ModalityPatient IssuerOfPatientID ", IssuerOfPatientID.c_str());
                if (IssuerOfPatientID.length() > 0) {
                    if (isModalitySearch && ![DicomValidator validateVRFor:[[NSString alloc] initWithUTF8String:IssuerOfPatientID.c_str()] forKey:VRKeyIssuerOfPatientID]) {
                        successStatus = successStatus && false;
                        [[DicomLogger sharedLogger] logError:[NSString stringWithFormat:@"Invalid Issuer of Patient ID %@ for Patient ID %@",[[NSString alloc] initWithUTF8String:IssuerOfPatientID.c_str()],[[NSString alloc] initWithUTF8String:PatientID.c_str()]]];
                        continue;
                    }
                }
                
                //Type 3 parameter - VR validation is required if not empty
                OFString OtherPatientIDs;
                result = dset->findAndGetOFStringArray(DCM_OtherPatientIDs, OtherPatientIDs);
                NSLog(@"%s---- ModalityPatient OtherPatientIDs ", OtherPatientIDs.c_str());
                if (isModalitySearch) {
                    Boolean validOtherPatientIds = true;
                    if (OtherPatientIDs.length() > 0) {
                        NSString *otherPatientIDsStr = [[NSString alloc] initWithUTF8String:OtherPatientIDs.c_str()];

                        NSArray *otherPatientIndividualIDs = [otherPatientIDsStr componentsSeparatedByString:@"\\"];

                        for (NSString *otherPatientID in otherPatientIndividualIDs) {
                            if (![DicomValidator validateVRFor:otherPatientID forKey:VRKeyOtherPatientIDs]) {
                                validOtherPatientIds = false;
                                successStatus = successStatus && false;
                                [[DicomLogger sharedLogger] logError:[NSString stringWithFormat:@"Invalid OtherPatientIDs %@ for Patient ID %@",[[NSString alloc] initWithUTF8String:OtherPatientIDs.c_str()],[[NSString alloc] initWithUTF8String:PatientID.c_str()]]];
                                break;
                            }
                        }
                        if (!validOtherPatientIds) {
                            continue;
                        }
                    }
                }
                
                //Type 3 parameter - VR validation is required if not empty
                OFString PatientComments;
                result = dset->findAndGetOFString(DCM_PatientComments, PatientComments);
                NSLog(@"%s---- ModalityPatient PatientComments ", PatientComments.c_str());
                if (PatientComments.length() > 0) {
                    if (isModalitySearch && ![DicomValidator validateVRFor:[[NSString alloc] initWithUTF8String:PatientComments.c_str()] forKey:VRKeyComments]) {
                        successStatus = successStatus && false;
                        [[DicomLogger sharedLogger] logError:[NSString stringWithFormat:@"Invalid Patient comments %@ for Patient ID %@",[[NSString alloc] initWithUTF8String:PatientComments.c_str()],[[NSString alloc] initWithUTF8String:PatientID.c_str()]]];
                        continue;
                    }
                }
                

                OFString requestedProcedureID,requestedProcedureComments;
                const char* requestedProcedureDescription;
                
                //Type 1 parameter - Empty value checking is part of VR validation
                result = dset->findAndGetOFString(DCM_RequestedProcedureID,requestedProcedureID);
                NSLog(@"%s---- ModalityPatient requestedProcedureID ", requestedProcedureID.c_str());
                if (isModalitySearch && ![DicomValidator validateVRFor:[[NSString alloc] initWithUTF8String:requestedProcedureID.c_str()] forKey:VRKeyRequestedProcedureID]) {
                    successStatus = successStatus && false;
                    [[DicomLogger sharedLogger] logError:[NSString stringWithFormat:@"Invalid requestedProcedureID %@ for Patient ID %@",[[NSString alloc] initWithUTF8String:requestedProcedureID.c_str()],[[NSString alloc] initWithUTF8String:PatientID.c_str()]]];
                    continue;
                }

                //Type 1C parameter - The Requested Procedure Description (0032,1060) or the Requested Procedure Code Sequence (0032,1064) or both shall be supported by the SCP.
                result = dset->findAndGetString(DCM_RequestedProcedureDescription,requestedProcedureDescription);
                NSLog(@"%s---- ModalityPatient requestedProcedureDescription ", requestedProcedureDescription);
                if (requestedProcedureDescription != NULL) {
                    if (isModalitySearch && ![DicomValidator validateVRFor:[[NSString alloc] initWithUTF8String:requestedProcedureDescription] forKey:VRKeyDescription]) {
                        successStatus = successStatus && false;
                        [[DicomLogger sharedLogger] logError:[NSString stringWithFormat:@"Invalid requestedProcedureDescription %@ for Patient ID %@",[[NSString alloc] initWithUTF8String:requestedProcedureDescription],[[NSString alloc] initWithUTF8String:PatientID.c_str()]]];
                        continue;
                    }
                }

                //Type 3 parameter - VR validation is required if not empty
                result = dset->findAndGetOFString(DCM_RequestedProcedureComments,requestedProcedureComments);
                NSLog(@"%s---- ModalityPatient DCM_RequestedProcedureComments ", requestedProcedureComments.c_str());
                if (requestedProcedureComments.length() > 0) {
                    if (isModalitySearch && ![DicomValidator validateVRFor:[[NSString alloc] initWithUTF8String:requestedProcedureComments.c_str()] forKey:VRKeyComments]) {
                        successStatus = successStatus && false;
                        [[DicomLogger sharedLogger] logError:[NSString stringWithFormat:@"Invalid requested procedure comments %@ for Patient ID %@",[[NSString alloc] initWithUTF8String:requestedProcedureComments.c_str()],[[NSString alloc] initWithUTF8String:PatientID.c_str()]]];
                        continue;
                    }
                }

                //MWL INFO
                //Type 2 parameter - VR validation is required if not empty
                OFString AccessionNumber;
                result = dset->findAndGetOFString(DCM_AccessionNumber, AccessionNumber);
                NSLog(@"%s---- ModalityWorklistOrder AccessionNumber ", AccessionNumber.c_str());
                if (AccessionNumber.length() > 0) {
                    if (isModalitySearch && ![DicomValidator validateVRFor:[[NSString alloc] initWithUTF8String:AccessionNumber.c_str()] forKey:VRKeyAccessionNumber]) {
                        successStatus = successStatus && false;
                        [[DicomLogger sharedLogger] logError:[NSString stringWithFormat:@"Invalid AccessionNumber %@ for Patient ID %@",[[NSString alloc] initWithUTF8String:AccessionNumber.c_str()],[[NSString alloc] initWithUTF8String:PatientID.c_str()]]];
                        continue;
                    }
                }

                //Type 2 parameter - VR validation is required if not empty
//                OFString ReferringPhysicianName;
//                result = dset->findAndGetOFString(DCM_ReferringPhysicianName, ReferringPhysicianName);
//                NSLog(@"%s---- ModalityWorklistOrder ReferringPhysicianName ", ReferringPhysicianName.c_str());
//
                const char* ReferringPhysicianName;
                result = dset->findAndGetString(DCM_ReferringPhysicianName, ReferringPhysicianName);
                NSLog(@"%s---- ModalityWorklistOrder ReferringPhysicianName", ReferringPhysicianName);
                if (ReferringPhysicianName != NULL) {
                    if (result.good()) {
                        if (isModalitySearch && ![DicomValidator validateVRFor:[[NSString alloc] initWithUTF8String:ReferringPhysicianName] forKey:VRKeyPersonName]) {
                            successStatus = successStatus && false;
                            [[DicomLogger sharedLogger] logError:[NSString stringWithFormat:@"Invalid ReferringPhysicianName %@ for Patient ID %@",[[NSString alloc] initWithUTF8String:ReferringPhysicianName],[[NSString alloc] initWithUTF8String:PatientID.c_str()]]];
                            continue;
                        }
                    } else {
                        successStatus = successStatus && false;
                        [[DicomLogger sharedLogger] logError:[NSString stringWithFormat:@"Invalid result: %@ for ReferringPhysicianName %@ for Patient ID %@",[[NSString alloc] initWithUTF8String:result.text()],[[NSString alloc] initWithUTF8String:ReferringPhysicianName],[[NSString alloc] initWithUTF8String:PatientID.c_str()]]];
                        continue;
                    }
                }

                //Type 1 parameter - Empty value checking is part of VR validation
                OFString studyInstanceUID;
                result = dset->findAndGetOFString(DCM_StudyInstanceUID, studyInstanceUID);
                NSLog(@"%s---- ModalityProcedure studyInstanceUID ", studyInstanceUID.c_str());
                if ( isModalitySearch && ![DicomValidator validateVRFor:[[NSString alloc] initWithUTF8String:studyInstanceUID.c_str()] forKey:VRKeyUniqueIdNotEmpty]) {
                    successStatus = successStatus && false;
                    [[DicomLogger sharedLogger] logError:[NSString stringWithFormat:@"Invalid studyInstanceUID %@ for Patient ID %@",[[NSString alloc] initWithUTF8String:studyInstanceUID.c_str()],[[NSString alloc] initWithUTF8String:PatientID.c_str()]]];
                    continue;
                }

                //Type 3 parameter - VR validation is required if not empty
                OFString studyDate;
                result = dset->findAndGetOFString(DCM_StudyDate, studyDate);
                NSLog(@"%s---- ModalityProcedure studyDate", studyDate.c_str());
                if (studyDate.length() > 0) {
                    if (isModalitySearch && ![DicomValidator validateVRFor:[[NSString alloc] initWithUTF8String:studyDate.c_str()] forKey:VRKeyDate]) {
                        successStatus = successStatus && false;
                        [[DicomLogger sharedLogger] logError:[NSString stringWithFormat:@"Invalid studyDate %@ for Patient ID %@",[[NSString alloc] initWithUTF8String:studyDate.c_str()],[[NSString alloc] initWithUTF8String:PatientID.c_str()]]];
                        continue;
                    }
                }
                
                //Type 3 parameter - VR validation is required if not empty
                OFString studyTime;
                result = dset->findAndGetOFString(DCM_StudyTime, studyTime);
                NSLog(@"%s---- ModalityProcedure studyTime", studyTime.c_str());
                if (studyTime.length() > 0) {
                    if (isModalitySearch && ![DicomValidator validateVRFor:[[NSString alloc] initWithUTF8String:studyTime.c_str()] forKey:VRKeyTime]) {
                        successStatus = successStatus && false;
                        [[DicomLogger sharedLogger] logError:[NSString stringWithFormat:@"Invalid studyTime %@ for Patient ID %@",[[NSString alloc] initWithUTF8String:studyTime.c_str()],[[NSString alloc] initWithUTF8String:PatientID.c_str()]]];
                        continue;
                    }
                }

                //Type 1C parameter - Scheduled procedure
                OFString scheduledProcedureModality,
                         scheduledProcedureStepStartDate,
                         scheduledProcedureStepStartTime,
                         scheduledProcedureStepDescription,
                         scheduledProcedureStepID,
                         scheduledProtocolCodeValue,
                         scheduledProtocolCodeMeaning,
                         scheduledProtocolCodingSchemeDesignator,
                         scheduledProtocolCodingSchemeVersion;

                DcmSequenceOfItems *scheduledProcedure_sequence = NULL;
                OFCondition scheduledCond;
                Boolean isValidScheduledProcedureSeq = true;
                scheduledCond = dset->findAndGetSequence(DCM_ScheduledProcedureStepSequence, scheduledProcedure_sequence, true);
                if (scheduledCond.good())
                {
                    Uint16 scheduledProcedures = scheduledProcedure_sequence->card();
                    for(int i=0;i<scheduledProcedures;i++)
                    {
                        DcmItem *scheduledProcedure = scheduledProcedure_sequence->getItem(i);

                        //Type 1 parameter, but exceptional case - VR validation is required if not empty
                        scheduledProcedure->findAndGetOFString(DCM_Modality,scheduledProcedureModality);
                        NSLog(@"%s---- Scheduled procedure scheduledProcedureModality ", scheduledProcedureModality.c_str());
                        if (scheduledProcedureModality.length() > 0) {
                            if (isModalitySearch) {
                                Boolean isValidModality = [DicomValidator validateVRFor:[[NSString alloc] initWithUTF8String:scheduledProcedureModality.c_str()] forKey:VRKeyModality];
                                isValidScheduledProcedureSeq = isValidScheduledProcedureSeq && isValidModality;
                                if (!isValidModality) {
                                [[DicomLogger sharedLogger] logError:[NSString stringWithFormat:@"Invalid scheduledProcedureModality %@ for Patient ID %@",[[NSString alloc] initWithUTF8String:scheduledProcedureModality.c_str()],[[NSString alloc] initWithUTF8String:PatientID.c_str()]]];
                                }
                            }
                        }

                        //Type 1 parameter - Empty value checking is part of VR validation
                        scheduledProcedure->findAndGetOFString(DCM_ScheduledProcedureStepStartDate,scheduledProcedureStepStartDate);
                        NSLog(@"%s---- Scheduled procedure scheduledProcedureStepStartDate ", scheduledProcedureStepStartDate.c_str());
                        if (isModalitySearch) {
                            Boolean isValidStepStartDate = [DicomValidator validateVRFor:[[NSString alloc] initWithUTF8String:scheduledProcedureStepStartDate.c_str()] forKey:VRKeyDate];
                            isValidScheduledProcedureSeq = isValidScheduledProcedureSeq && isValidStepStartDate;
                            if (!isValidStepStartDate) {
                                [[DicomLogger sharedLogger] logError:[NSString stringWithFormat:@"Invalid scheduledProcedureStepStartDate %@ for Patient ID %@",[[NSString alloc] initWithUTF8String:scheduledProcedureStepStartDate.c_str()],[[NSString alloc] initWithUTF8String:PatientID.c_str()]]];
                            }
                        }

                        //Type 1 parameter - Empty value checking is part of VR validation
                        scheduledProcedure->findAndGetOFString(DCM_ScheduledProcedureStepStartTime, scheduledProcedureStepStartTime);
                        NSLog(@"%s---- Scheduled procedure scheduledProcedureStepStartTime ", scheduledProcedureStepStartTime.c_str());
                        if (isModalitySearch) {
                            Boolean isValidStepStartTime = [DicomValidator validateVRFor:[[NSString alloc] initWithUTF8String:scheduledProcedureStepStartTime.c_str()] forKey:VRKeyTime];

                            isValidScheduledProcedureSeq = isValidScheduledProcedureSeq && isValidStepStartTime;
                            if (!isValidStepStartTime) {
                                [[DicomLogger sharedLogger] logError:[NSString stringWithFormat:@"Invalid scheduledProcedureStepStartTime %@ for Patient ID %@",[[NSString alloc] initWithUTF8String:scheduledProcedureStepStartTime.c_str()],[[NSString alloc] initWithUTF8String:PatientID.c_str()]]];
                            }
                        }

                        //Type 1c parameter - Either the Scheduled Procedure Step Description (0040,0007) or the Scheduled Protocol Code Sequence (0040,0008) or both shall be supported by the SCP.
                        scheduledProcedure->findAndGetOFString(DCM_ScheduledProcedureStepDescription, scheduledProcedureStepDescription);
                        NSLog(@"%s---- Scheduled procedure scheduledProcedureStepDescription ", scheduledProcedureStepDescription.c_str());
                        if (isModalitySearch) {
                            Boolean isValidScheduledProcedureStepDescription = [DicomValidator validateVRFor:[[NSString alloc] initWithUTF8String:scheduledProcedureStepDescription.c_str()] forKey:VRKeyDescription];
                            isValidScheduledProcedureSeq = isValidScheduledProcedureSeq && isValidScheduledProcedureStepDescription;
                            if (!isValidScheduledProcedureStepDescription) {
                                [[DicomLogger sharedLogger] logError:[NSString stringWithFormat:@"Invalid scheduledProcedureStepDescription %@ for Patient ID %@",[[NSString alloc] initWithUTF8String:scheduledProcedureStepDescription.c_str()],[[NSString alloc] initWithUTF8String:PatientID.c_str()]]];
                            }
                        }

                        //Type 1 parameter - Empty value checking is part of VR validation
                        scheduledProcedure->findAndGetOFString(DCM_ScheduledProcedureStepID, scheduledProcedureStepID);
                        NSLog(@"%s---- Scheduled procedure scheduledProcedureStepID ", scheduledProcedureStepID.c_str());
                        if (isModalitySearch) {
                            Boolean isValidScheduledProcedureStepID = [DicomValidator validateVRFor:[[NSString alloc] initWithUTF8String:scheduledProcedureStepID.c_str()] forKey:VRKeyScheduledProcedureStepID];
                            isValidScheduledProcedureSeq = isValidScheduledProcedureSeq && isValidScheduledProcedureStepID;
                            if (!isValidScheduledProcedureStepID) {
                                [[DicomLogger sharedLogger] logError:[NSString stringWithFormat:@"Invalid scheduledProcedureStepID %@ for Patient ID %@",[[NSString alloc] initWithUTF8String:scheduledProcedureStepID.c_str()],[[NSString alloc] initWithUTF8String:PatientID.c_str()]]];
                            }
                        }

                        //ScheduledProtocolCodeSequence
                        DcmSequenceOfItems *ScheduledProtocolCode_sequence = NULL;
                        OFCondition ScheduledProtocolCodeCond;
                        Boolean isValidScheduledProtocolCodeSeq = true;
                        ScheduledProtocolCodeCond = scheduledProcedure->findAndGetSequence(DCM_ScheduledProtocolCodeSequence, ScheduledProtocolCode_sequence, true);
                        if (ScheduledProtocolCodeCond.good())
                        {
                            Uint16 ScheduledProtocolCodes = ScheduledProtocolCode_sequence->card();
                            for(int i=0;i<ScheduledProtocolCodes;i++)
                            {
                                DcmItem *ScheduledProtocolCode = ScheduledProtocolCode_sequence->getItem(i);
                                
                                //Type 1 parameter - As it is part of 1C validation, VR should be done if not empty
                                ScheduledProtocolCode->findAndGetOFString(DCM_CodeValue,scheduledProtocolCodeValue);
                                NSLog(@"%s---- ScheduledProtocolCodeSequence scheduledProtocolCodeValue ", scheduledProtocolCodeValue.c_str());
                                if (scheduledProtocolCodeValue.length() > 0) {
                                    if (isModalitySearch) {
                                        Boolean isValidScheduledProtocolCodeValue = [DicomValidator validateVRFor:[[NSString alloc] initWithUTF8String:scheduledProtocolCodeValue.c_str()] forKey:VRKeyCodeValue];
                                        isValidScheduledProtocolCodeSeq = isValidScheduledProtocolCodeSeq && isValidScheduledProtocolCodeValue;
                                        if (!isValidScheduledProtocolCodeValue) {
                                            [[DicomLogger sharedLogger] logError:[NSString stringWithFormat:@"Invalid scheduledProtocolCodeValue %@ for scheduledProcedureStepID %@",[[NSString alloc] initWithUTF8String:scheduledProtocolCodeValue.c_str()],[[NSString alloc] initWithUTF8String:scheduledProcedureStepID.c_str()]]];
                                        }
                                    }
                                }

                                //Type 3 parameter - Validation should be done if not empty
                                ScheduledProtocolCode->findAndGetOFString(DCM_CodeMeaning,scheduledProtocolCodeMeaning);
                                NSLog(@"%s---- ScheduledProtocolCodeSequence scheduledProtocolCodeMeaning ", scheduledProtocolCodeMeaning.c_str());
                                if (scheduledProtocolCodeMeaning.length() > 0) {
                                    if (isModalitySearch) {
                                        Boolean isValidScheduledProtocolCodeMeaning = [DicomValidator validateVRFor:[[NSString alloc] initWithUTF8String:scheduledProtocolCodeMeaning.c_str()] forKey:VRKeyCodeMeaning];

                                        isValidScheduledProtocolCodeSeq = isValidScheduledProtocolCodeSeq && isValidScheduledProtocolCodeMeaning;
                                        if (!isValidScheduledProtocolCodeMeaning) {
                                            [[DicomLogger sharedLogger] logError:[NSString stringWithFormat:@"Invalid scheduledProtocolCodeMeaning %@ for scheduledProcedureStepID %@",[[NSString alloc] initWithUTF8String:scheduledProtocolCodeMeaning.c_str()],[[NSString alloc] initWithUTF8String:scheduledProcedureStepID.c_str()]]];
                                        }
                                    }
                                }

                                //Type 1 parameter - As it is part of 1C validation, VR should be done if not empty
                                ScheduledProtocolCode->findAndGetOFString(DCM_CodingSchemeDesignator,scheduledProtocolCodingSchemeDesignator);
                                NSLog(@"%s---- ScheduledProtocolCodeSequence scheduledProtocolCodingSchemeDesignator ", scheduledProtocolCodingSchemeDesignator.c_str());
                                if (scheduledProtocolCodingSchemeDesignator.length() > 0) {
                                    if (isModalitySearch) {
                                        Boolean isValidScheduledProtocolCodingSchemeDesignator = [DicomValidator validateVRFor:[[NSString alloc] initWithUTF8String:scheduledProtocolCodingSchemeDesignator.c_str()] forKey:VRKeyCodingSchemeDesignator];

                                        isValidScheduledProtocolCodeSeq = isValidScheduledProtocolCodeSeq && isValidScheduledProtocolCodingSchemeDesignator;
                                        if (!isValidScheduledProtocolCodingSchemeDesignator) {
                                            [[DicomLogger sharedLogger] logError:[NSString stringWithFormat:@"Invalid scheduledProtocolCodingSchemeDesignator %@ for scheduledProcedureStepID %@",[[NSString alloc] initWithUTF8String:scheduledProtocolCodingSchemeDesignator.c_str()],[[NSString alloc] initWithUTF8String:scheduledProcedureStepID.c_str()]]];
                                        }
                                    }
                                }

                                //Type 3 parameter - Validation should be done if not empty
                                ScheduledProtocolCode->findAndGetOFString(DCM_CodingSchemeVersion,scheduledProtocolCodingSchemeVersion);
                                NSLog(@"%s---- ScheduledProtocolCodeSequence scheduledProtocolCodingSchemeVersion ", scheduledProtocolCodingSchemeVersion.c_str());
                                if (scheduledProtocolCodingSchemeVersion.length() > 0) {
                                    if (isModalitySearch) {
                                        Boolean isValidScheduledProtocolCodingSchemeVersion = [DicomValidator validateVRFor:[[NSString alloc] initWithUTF8String:scheduledProtocolCodingSchemeVersion.c_str()] forKey:VRKeyCodingSchemeVersion];

                                        isValidScheduledProtocolCodeSeq = isValidScheduledProtocolCodeSeq && isValidScheduledProtocolCodingSchemeVersion;
                                        if (!isValidScheduledProtocolCodingSchemeVersion) {
                                            [[DicomLogger sharedLogger] logError:[NSString stringWithFormat:@"Invalid scheduledProtocolCodingSchemeVersion %@ for scheduledProcedureStepID %@",[[NSString alloc] initWithUTF8String:scheduledProtocolCodingSchemeVersion.c_str()],[[NSString alloc] initWithUTF8String:scheduledProcedureStepID.c_str()]]];
                                        }
                                    }
                                }

                            }
                        }
                        // end ScheduledProtocolCodeSequence
                    }
                }
                
                Boolean isValidType1ScheduledProcedure = false;
                isValidType1ScheduledProcedure = scheduledProcedureStepDescription.length() > 0 || (scheduledProtocolCodeValue.length() > 0 && scheduledProtocolCodingSchemeDesignator.length() > 0);
                
                if (isModalitySearch && (!isValidScheduledProcedureSeq || !isValidType1ScheduledProcedure)) {
                    successStatus = successStatus && false;
                    [[DicomLogger sharedLogger] logError:[NSString stringWithFormat:@"Invalid ScheduledProcedureSeq with seqID %@ for patientID %@",[[NSString alloc] initWithUTF8String:scheduledProcedureStepID.c_str()], [[NSString alloc] initWithUTF8String:PatientID.c_str()]]];
                    continue;
                }
                
                // end scheduled procedure
                
                //Type 1C parameter - RequestedProcedureCodeSequence
                Boolean isValidVRRequestedProcedureCodeSeq = true;
                DcmSequenceOfItems *requestedProcedureCode_sequence = NULL;
                OFString requestedProcedureCode,
                         requestedProcedureCodeMeaning,
                         requestedProcedureCodingSchemeDesignator,
                         requestedProcedureCodingSchemeVersion;
                OFCondition requestedProcedureCodeCond;
                requestedProcedureCodeCond = dset->findAndGetSequence(DCM_RequestedProcedureCodeSequence, requestedProcedureCode_sequence, true);
                if (requestedProcedureCodeCond.good())
                {
                    Uint16 requestedProcedures = requestedProcedureCode_sequence->card();
                    for(int i=0;i<requestedProcedures;i++)
                    {
                        DcmItem *requestedProcedure = requestedProcedureCode_sequence->getItem(i);
                        
                        //Type 1 parameter - As it is part of 1C validation, VR should be done if not empty
                        requestedProcedure->findAndGetOFString(DCM_CodeValue,requestedProcedureCode);
                        NSLog(@"%s---- requested procedure codeValue ", requestedProcedureCode.c_str());
                        if (requestedProcedureCode.length() > 0) {
                            if (isModalitySearch) {
                                Boolean isValidRequestedProcedureCode = [DicomValidator validateVRFor:[[NSString alloc] initWithUTF8String:requestedProcedureCode.c_str()] forKey:VRKeyCodeValue];

                                isValidVRRequestedProcedureCodeSeq = isValidVRRequestedProcedureCodeSeq && isValidRequestedProcedureCode;
                                if (!isValidRequestedProcedureCode) {
                                    [[DicomLogger sharedLogger] logError:[NSString stringWithFormat:@"Invalid requestedProcedureCode %@ for patientID %@",[[NSString alloc] initWithUTF8String:requestedProcedureCode.c_str()],[[NSString alloc] initWithUTF8String:PatientID.c_str()]]];
                                }
                            }
                        }

                        //Type 3 parameter - Validation should be done if not empty
                        requestedProcedure->findAndGetOFString(DCM_CodeMeaning,requestedProcedureCodeMeaning);
                        NSLog(@"%s---- requested procedure codeMeaning ", requestedProcedureCodeMeaning.c_str());
                        if (requestedProcedureCodeMeaning.length() > 0) {
                            if (isModalitySearch) {
                                Boolean isValidRequestedProcedureCodeMeaning = [DicomValidator validateVRFor:[[NSString alloc] initWithUTF8String:requestedProcedureCodeMeaning.c_str()] forKey:VRKeyCodeMeaning];

                                isValidVRRequestedProcedureCodeSeq = isValidVRRequestedProcedureCodeSeq && isValidRequestedProcedureCodeMeaning;
                                if (!isValidRequestedProcedureCodeMeaning) {
                                    [[DicomLogger sharedLogger] logError:[NSString stringWithFormat:@"Invalid requestedProcedureCodeMeaning %@ for PatientID %@",[[NSString alloc] initWithUTF8String:requestedProcedureCodeMeaning.c_str()],[[NSString alloc] initWithUTF8String:PatientID.c_str()]]];
                                }
                            }
                        }

                        //Type 1 parameter - As it is part of 1C validation, VR should be done if not empty
                        requestedProcedure->findAndGetOFString(DCM_CodingSchemeDesignator,requestedProcedureCodingSchemeDesignator);
                        NSLog(@"%s---- requested procedure CodingSchemeDesignator ", requestedProcedureCodingSchemeDesignator.c_str());
                        if (requestedProcedureCodingSchemeDesignator.length() > 0) {
                            if (isModalitySearch) {
                                Boolean isValidRequestedProcedureCodingSchemeDesignator = [DicomValidator validateVRFor:[[NSString alloc] initWithUTF8String:requestedProcedureCodingSchemeDesignator.c_str()] forKey:VRKeyCodingSchemeDesignator];

                                isValidVRRequestedProcedureCodeSeq = isValidVRRequestedProcedureCodeSeq && isValidRequestedProcedureCodingSchemeDesignator;
                                if (!isValidRequestedProcedureCodingSchemeDesignator) {
                                    [[DicomLogger sharedLogger] logError:[NSString stringWithFormat:@"Invalid requestedProcedureCodingSchemeDesignator %@ for PatientID %@",[[NSString alloc] initWithUTF8String:requestedProcedureCodingSchemeDesignator.c_str()],[[NSString alloc] initWithUTF8String:PatientID.c_str()]]];
                                }
                            }
                        }

                        //Type 3 parameter - Validation should be done if not empty
                        requestedProcedure->findAndGetOFString(DCM_CodingSchemeVersion,requestedProcedureCodingSchemeVersion);
                        NSLog(@"%s---- requested procedure CodingSchemeVersion ", requestedProcedureCodingSchemeVersion.c_str());
                        if (requestedProcedureCodingSchemeVersion.length() > 0) {
                            if (isModalitySearch) {
                                Boolean isValidRequestedProcedureCodingSchemeVersion = [DicomValidator validateVRFor:[[NSString alloc] initWithUTF8String:requestedProcedureCodingSchemeVersion.c_str()] forKey:VRKeyCodingSchemeVersion];

                                isValidVRRequestedProcedureCodeSeq = isValidVRRequestedProcedureCodeSeq && isValidRequestedProcedureCodingSchemeVersion;
                                if (!isValidRequestedProcedureCodingSchemeVersion) {
                                    [[DicomLogger sharedLogger] logError:[NSString stringWithFormat:@"Invalid requestedProcedureCodingSchemeVersion %@ for PatientID %@",[[NSString alloc] initWithUTF8String:requestedProcedureCodingSchemeVersion.c_str()],[[NSString alloc] initWithUTF8String:PatientID.c_str()]]];
                                }
                            }
                        }
                    }
                }
                Boolean isValidType1RequestedProcedure = false;
                NSString *requestedProcedureDescriptionStr = @"";
                if (requestedProcedureDescription != NULL) {
                    requestedProcedureDescriptionStr = [NSString stringWithUTF8String:requestedProcedureDescription];
                }
                isValidType1RequestedProcedure = requestedProcedureDescriptionStr.length > 0 || (requestedProcedureCode.length() > 0 && requestedProcedureCodingSchemeDesignator.length() > 0);

                if (isModalitySearch && (!isValidVRRequestedProcedureCodeSeq || !isValidType1RequestedProcedure)) {
                    successStatus = successStatus && false;
                    [[DicomLogger sharedLogger] logError:[NSString stringWithFormat:@"Invalid RequestedProcedureCodeSeq for patientID %@",[[NSString alloc] initWithUTF8String:PatientID.c_str()]]];
                    continue;
                }
                // end RequestedProcedureCodeSequence
                
                //Type 2 parameter - ReferencedStudySequence
                DcmSequenceOfItems *referencedStudy_Sequence = NULL;
                OFString referencedSOPClassUID,referencedSOPInstanceUID;
                OFCondition referencedStudyCond;
                referencedStudyCond = dset->findAndGetSequence(DCM_ReferencedStudySequence, referencedStudy_Sequence, true);
                if (referencedStudyCond.good())
                {
                    Boolean isValidReferencedStudySequence = true;
                    Uint16 referencedStudies = referencedStudy_Sequence->card();
                    for(int i=0;i<referencedStudies;i++)
                    {
                        DcmItem *referencedStudy = referencedStudy_Sequence->getItem(i);
                        
                        referencedStudy->findAndGetOFString(DCM_ReferencedSOPClassUID,referencedSOPClassUID);
                        NSLog(@"%s---- ReferencedStudySequence referencedSOPClassUID ", referencedSOPClassUID.c_str());
                        if (referencedSOPClassUID.length() > 0) {
                            if (isModalitySearch) {
                                Boolean isValidReferencedSOPClassUID = [DicomValidator validateVRFor:[[NSString alloc] initWithUTF8String:referencedSOPClassUID.c_str()] forKey:VRKeyUniqueId];

                                isValidReferencedStudySequence = isValidReferencedStudySequence && isValidReferencedSOPClassUID;
                                [[DicomLogger sharedLogger] logError:[NSString stringWithFormat:@"Invalid RequestedProcedureCodeSeq for patientID %@",[[NSString alloc] initWithUTF8String:PatientID.c_str()]]];
                                if (!isValidReferencedSOPClassUID) {
                                    [[DicomLogger sharedLogger] logError:[NSString stringWithFormat:@"Invalid requestedProcedureCodingSchemeVersion %@ for PatientID %@",[[NSString alloc] initWithUTF8String:referencedSOPClassUID.c_str()],[[NSString alloc] initWithUTF8String:PatientID.c_str()]]];
                                }
                            }
                        }

                        referencedStudy->findAndGetOFString(DCM_ReferencedSOPInstanceUID,referencedSOPInstanceUID);
                        NSLog(@"%s---- ReferencedStudySequence referencedSOPInstanceUID ", referencedSOPInstanceUID.c_str());
                        if (referencedSOPInstanceUID.length() > 0) {
                            if (isModalitySearch) {
                                Boolean isValidReferencedSOPInstanceUID = [DicomValidator validateVRFor:[[NSString alloc] initWithUTF8String:referencedSOPInstanceUID.c_str()] forKey:VRKeyUniqueId];

                                isValidReferencedStudySequence = isValidReferencedStudySequence && isValidReferencedSOPInstanceUID;
                                if (!isValidReferencedSOPInstanceUID) {
                                    [[DicomLogger sharedLogger] logError:[NSString stringWithFormat:@"Invalid referencedSOPInstanceUID %@ for PatientID %@",[[NSString alloc] initWithUTF8String:referencedSOPInstanceUID.c_str()],[[NSString alloc] initWithUTF8String:PatientID.c_str()]]];
                                }
                            }
                        }
                    }
                    if (isModalitySearch && (!isValidReferencedStudySequence || (referencedSOPClassUID.length() > 0 && referencedSOPInstanceUID.length() == 0) || (referencedSOPClassUID.length() == 0 && referencedSOPInstanceUID.length() > 0))) {
                        successStatus = successStatus && false;
                        [[DicomLogger sharedLogger] logError:[NSString stringWithFormat:@"Invalid ReferencedStudySequence for patientID %@",[[NSString alloc] initWithUTF8String:PatientID.c_str()]]];
                        continue;
                    }
                }
                // end ReferencedStudySequence

                
                // Create Patient Model
                Patient *patient = [[Patient alloc] init];
                
                patient.Id = [[NSString alloc] initWithUTF8String:PatientID.c_str()];
                
                //patient.firstName = [[NSString alloc] initWithUTF8String:PatientName.c_str()];
                patient.firstName = [self getValidComponentForPatientName:[[NSString alloc]initWithUTF8String:PatientName]];

                
                patient.gender = [[NSString alloc] initWithUTF8String:Patientsex.c_str()];
                
                patient.patientIssuer = [[NSString alloc] initWithUTF8String:IssuerOfPatientID.c_str()];
                patient.ethnicity = [[NSString alloc] initWithUTF8String:patientEthnicGroup.c_str()];
                patient.otherPatientIds = [[NSString alloc] initWithUTF8String:OtherPatientIDs.c_str()];
                patient.comments = [[NSString alloc] initWithUTF8String:PatientComments.c_str()];
                
                NSDateFormatter *dateFormatter=[[NSDateFormatter alloc] init];
                NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
                dateFormatter.dateFormat = @"yyyyMMdd";
                NSTimeZone *timeZone = [NSTimeZone systemTimeZone];
                NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
                [dateFormatter setCalendar:gregorianCalendar];
                [dateFormatter setTimeZone:timeZone];
                [dateFormatter setLocale:locale];
                //Malleswari - Not checking PatientDob value intentionally as the app is crashing if value for DOB is not there..
                //if (PatientDob.length() > 0) {
                    NSDate *dobDate = [dateFormatter dateFromString:[[NSString alloc] initWithUTF8String:PatientDob.c_str()]];
                    patient.dateOfBirth = dobDate;
                //}
                if (isModalitySearch) {
                    
                    ModalityWorklistOrder *modality = [[ModalityWorklistOrder alloc] init];
                    ModalityProcedure *procedure = [[ModalityProcedure alloc] init];
                    
                    modality.accessionNumber = [[NSString alloc] initWithUTF8String:AccessionNumber.c_str()];
                    if (ReferringPhysicianName != NULL) {
                        modality.referringPhysicianName = [[NSString alloc] initWithUTF8String:ReferringPhysicianName];
                    } else {
                        procedure.referringPhysicianName = @"";
                    }

                    if (![[[NSString alloc] initWithUTF8String:scheduledProcedureStepStartDate.c_str()]  isEqual: @""]) {
                        NSDate *MWLProcedureDate = [dateFormatter dateFromString:[[NSString alloc] initWithUTF8String:scheduledProcedureStepStartDate.c_str()]];
                        procedure.scheduledProcedureDate = MWLProcedureDate;
                    }

                    if (![[[NSString alloc] initWithUTF8String:studyDate.c_str()]  isEqual: @""]) {
                        NSDate *MWLStudyDate = [dateFormatter dateFromString:[[NSString alloc] initWithUTF8String:studyDate.c_str()]];
                        procedure.studyDate = MWLStudyDate;
                        procedure.studyTime = [[NSString alloc] initWithUTF8String:studyTime.c_str()];
                    }
                    procedure.studyInstanceUID = [[NSString alloc] initWithUTF8String:studyInstanceUID.c_str()];
                    procedure.accessionNumber = modality.accessionNumber;
                    procedure.scheduledProcedureTime = [[NSString alloc] initWithUTF8String:scheduledProcedureStepStartTime.c_str()];
                    if (requestedProcedureDescription != NULL) {
                        procedure.reqProcedureDesc = [[NSString alloc] initWithUTF8String:requestedProcedureDescription];
                    } else {
                        procedure.reqProcedureDesc = @"";
                    }
                    procedure.reqProcedureId = [[NSString alloc] initWithUTF8String:requestedProcedureID.c_str()];
                    
                    procedure.modality = [[NSString alloc] initWithUTF8String:scheduledProcedureModality.c_str()];
                    procedure.referringPhysicianName = modality.referringPhysicianName;

                    // Create Referenced Study Sequence
                    NSMutableDictionary *referencedStudyDict = [[NSMutableDictionary alloc]init];
                    [referencedStudyDict setValue:[[NSString alloc] initWithUTF8String:referencedSOPClassUID.c_str()] forKey:@"ReferencedSOPClassUID"];
                     [referencedStudyDict setValue:[[NSString alloc] initWithUTF8String:referencedSOPInstanceUID.c_str()] forKey:@"ReferencedSOPInstanceUID"];
                    NSData  *referencedStudySequenceData = [NSJSONSerialization dataWithJSONObject:referencedStudyDict options:NSJSONWritingPrettyPrinted error:nil];
                    procedure.referencedStudySequence =  referencedStudySequenceData;
                    // end Referenced Study Sequence
                                        
                    //Create Request Attributes Sequence
                    NSMutableDictionary *requestAttributesDict = [[NSMutableDictionary alloc]init];
                    [requestAttributesDict setValue:[[NSString alloc] initWithUTF8String:requestedProcedureID.c_str()] forKey:@"RequestedProcedureID"];
                    if (requestedProcedureDescription != NULL) {
                    [requestAttributesDict setValue:[[NSString alloc] initWithUTF8String:requestedProcedureDescription] forKey:@"RequestedProcedureDescription"];
                    } else {
                        [requestAttributesDict setValue:@"" forKey:@"RequestedProcedureDescription"];
                    }
                    [requestAttributesDict setValue:[[NSString alloc] initWithUTF8String:requestedProcedureComments.c_str()] forKey:@"RequestedProcedureComments"];
                    [requestAttributesDict setValue:[[NSString alloc] initWithUTF8String:scheduledProcedureStepID.c_str()] forKey:@"ScheduledProcedureStepID"];
                    [requestAttributesDict setValue:[[NSString alloc] initWithUTF8String:scheduledProcedureStepDescription.c_str()] forKey:@"ScheduledProcedureStepDescription"];
                    
                    NSMutableDictionary *reqProcedureCodeDict = [[NSMutableDictionary alloc]init];
                    [reqProcedureCodeDict setValue:[[NSString alloc] initWithUTF8String:requestedProcedureCode.c_str()] forKey:@"CodeValue"];
                    [reqProcedureCodeDict setValue:[[NSString alloc] initWithUTF8String:requestedProcedureCodeMeaning.c_str()] forKey:@"CodeMeaning"];
                    [reqProcedureCodeDict setValue:[[NSString alloc] initWithUTF8String:requestedProcedureCodingSchemeDesignator.c_str()] forKey:@"CodingSchemeDesignator"];
                    [reqProcedureCodeDict setValue:[[NSString alloc] initWithUTF8String:requestedProcedureCodingSchemeVersion.c_str()] forKey:@"CodingSchemeVersion"];
                    [requestAttributesDict setValue: reqProcedureCodeDict forKey:@"RequestedProcedureCodeSequence"];
                    
                    NSMutableDictionary *scheduledProtocolCodeDict = [[NSMutableDictionary alloc]init];
                    [scheduledProtocolCodeDict setValue:[[NSString alloc] initWithUTF8String:scheduledProtocolCodeValue.c_str()] forKey:@"CodeValue"];
                    [scheduledProtocolCodeDict setValue:[[NSString alloc] initWithUTF8String:scheduledProtocolCodeMeaning.c_str()] forKey:@"CodeMeaning"];
                    [scheduledProtocolCodeDict setValue:[[NSString alloc] initWithUTF8String:scheduledProtocolCodingSchemeDesignator.c_str()] forKey:@"CodingSchemeDesignator"];
                    [scheduledProtocolCodeDict setValue:[[NSString alloc] initWithUTF8String:scheduledProtocolCodingSchemeVersion.c_str()] forKey:@"CodingSchemeVersion"];
                    [requestAttributesDict setValue: scheduledProtocolCodeDict forKey:@"ScheduledProtocolCodeSequence"];
                    
                    NSData  *requestAttributesSequenceData = [NSJSONSerialization dataWithJSONObject:requestAttributesDict options:NSJSONWritingPrettyPrinted error:nil];
                    procedure.requestAttributesSequence = requestAttributesSequenceData;
                    //end Request Attributes Sequence
                    
                    NSData  *procedureCodeSequenceData = [NSJSONSerialization dataWithJSONObject:reqProcedureCodeDict options:NSJSONWritingPrettyPrinted error:nil];
                    procedure.procedureCodeSequence = procedureCodeSequenceData;

                    [modality.procedures addObject:procedure];
                    
                    [patient.worklistOrders addObject:modality];
                }
                [patients addObject:patient];
            }
            //it++;
        }
        
        // clear memory
        findParams.clear();
        if (dset != NULL)
            dset->clear();
        if (cxID)
            cxID = NULL;
        
        //Success Response
        success(patients,successStatus);
    }
}

- (NSMutableDictionary*) getStudies:(NSString*)PatientId PACSConnection:(ServerConfigurationModule *)configureInfoObject {
    @autoreleasepool {
        [[DicomLogger sharedLogger] setupLogFiles];
        NSMutableArray *studyArray = [[NSMutableArray alloc] init];
        const char *ID = [PatientId UTF8String];
        NSMutableDictionary *inDict = [NSMutableDictionary new];
        DcmSCU * DicomSCU = [self createSCU:configureInfoObject];
        
        OFList<OFString> TransferSyntaxes;
        //TransferSyntaxes.push_back(UID_LittleEndianExplicitTransferSyntax);
        TransferSyntaxes.push_back(UID_LittleEndianImplicitTransferSyntax);
        
        DicomSCU->addPresentationContext(UID_FINDStudyRootQueryRetrieveInformationModel, TransferSyntaxes);
        
        OFCondition result = DicomSCU->initNetwork();
        result = DicomSCU->negotiateAssociation();
        
        T_ASC_PresentationContextID cxID = NULL;
        if (result == EC_Normal) {
            cxID = DicomSCU->findPresentationContextID(UID_FINDStudyRootQueryRetrieveInformationModel, "");
        }else{
            OFString temp_str;
            DCMNET_ERROR("Error: " << DimseCondition::dump(temp_str, result));
            [inDict setObject:@"false" forKey:@"status"];
            [inDict setObject:studyArray forKey:@"results"];
            DicomSCU->closeAssociation(DCMSCU_RELEASE_ASSOCIATION);
            return inDict;
        }
        
        DcmDataset findParams = DcmDataset();
        findParams.putAndInsertString(DCM_QueryRetrieveLevel, "STUDY");
        findParams.putAndInsertString(DCM_StudyDate, "");
        findParams.putAndInsertString(DCM_StudyTime, "");
        findParams.putAndInsertString(DCM_StudyDescription, "");
        findParams.putAndInsertString(DCM_AccessionNumber, "");
        findParams.putAndInsertString(DCM_PatientName, "");
        findParams.putAndInsertString(DCM_PatientID, ID);
        findParams.putAndInsertString(DCM_PatientSex, "");
        findParams.putAndInsertString(DCM_PatientAge, "");
        findParams.putAndInsertString(DCM_PatientBirthDate, "");
        findParams.putAndInsertString(DCM_StudyID, "");
        findParams.putAndInsertString(DCM_StudyInstanceUID, "");

        FINDResponses responses;
        result = DicomSCU->sendFINDRequest(cxID, &findParams, &responses);
        
        DicomSCU->closeAssociation(DCMSCU_RELEASE_ASSOCIATION);
        
        DcmDataset *dset = NULL;
        OFListIterator(FINDResponse*) it = responses.begin();
        while (it != responses.end())
        {
            FINDResponse* rsp = *it;
            dset =  rsp->m_dataset;
            
            if (dset != NULL)
            {
                OFString StudyID;
                result = dset->findAndGetOFString(DCM_StudyID, StudyID);
                NSLog(@"%s---- Study ID ", StudyID.c_str());
                
                OFString StudyDate;
                result = dset->findAndGetOFString(DCM_StudyDate, StudyDate);
                NSLog(@"%s---- Study Date ", StudyDate.c_str());
                
                OFString StudyTime;
                result = dset->findAndGetOFString(DCM_StudyTime, StudyTime);
                NSLog(@"%s---- Study Time ", StudyTime.c_str());
                
                OFString StudyDescription;
                result = dset->findAndGetOFString(DCM_StudyDescription, StudyDescription);
                NSLog(@"%s---- Study Description ", StudyDescription.c_str());
                
                OFString StudyInstanceUID;
                result = dset->findAndGetOFString(DCM_StudyInstanceUID, StudyInstanceUID);
                NSLog(@"%s---- Study StudyInstanceUID ", StudyInstanceUID.c_str());

                Study *study = [[Study alloc] init];
                study.Id = [[NSString alloc] initWithUTF8String:StudyID.c_str()];
                study.dateString = [[NSString alloc] initWithUTF8String:StudyDate.c_str()];
                study.studyDescription = [[NSString alloc] initWithUTF8String:StudyDescription.c_str()];
                study.timeString = [[NSString alloc] initWithUTF8String:StudyTime.c_str()];
                study.studyInstanceUid = [[NSString alloc] initWithUTF8String:StudyInstanceUID.c_str()];
                
                NSMutableDictionary *serieses = [self getSerieses:[[NSString alloc] initWithUTF8String:StudyInstanceUID.c_str()] PACSConnection:configureInfoObject];
                
                if ([[serieses objectForKey:@"status"] isEqualToString:@"false"]) {
                    [inDict setObject:@"false" forKey:@"status"];
                    [inDict setObject:studyArray forKey:@"results"];
                    return inDict;
                }else {
                    NSMutableArray *series = [serieses objectForKey:@"results"];
                    if (series.count == 0) {
                        studyArray = [[NSMutableArray alloc] init];
                        [inDict setObject:@"true" forKey:@"status"];
                        [inDict setObject:studyArray forKey:@"results"];
                        return inDict;
                    }else{
                        study.series = series;
                    }
                }
                [studyArray addObject:study];
            }
            it++;
        }
        
        // clear memory
        findParams.clear();
        if (dset != NULL)
            dset->clear();
        if (cxID)
            cxID = NULL;
        
        [inDict setObject:@"true" forKey:@"status"];
        [inDict setObject:studyArray forKey:@"results"];
        return inDict;
    }
}

- (NSMutableDictionary*) getSerieses:(NSString*)StudyUId PACSConnection:(ServerConfigurationModule *)configureInfoObject; {
    
    @autoreleasepool {
        
        NSMutableDictionary *inDict = [NSMutableDictionary new];
        NSMutableArray *seriesesArray = [[NSMutableArray alloc] init];
        const char *studyUId = [StudyUId UTF8String];
        
        DcmSCU * DicomSCU = [self createSCU:configureInfoObject];
        
        OFList<OFString> TransferSyntaxes;
        //TransferSyntaxes.push_back(UID_LittleEndianExplicitTransferSyntax);
        TransferSyntaxes.push_back(UID_LittleEndianImplicitTransferSyntax);
        
        DicomSCU->addPresentationContext(UID_FINDStudyRootQueryRetrieveInformationModel, TransferSyntaxes);
        
        OFCondition result = DicomSCU->initNetwork();
        result = DicomSCU->negotiateAssociation();
        
        T_ASC_PresentationContextID cxID = NULL;
        if (result == EC_Normal) {
            cxID = DicomSCU->findPresentationContextID(UID_FINDStudyRootQueryRetrieveInformationModel, "");
        }else{
            OFString temp_str;
            DCMNET_ERROR("Error: " << DimseCondition::dump(temp_str, result));
            [inDict setObject:@"false" forKey:@"status"];
            [inDict setObject:seriesesArray forKey:@"results"];
            return inDict;
            //            return seriesesArray;
        }
        
        DcmDataset findParams = DcmDataset();
        findParams.putAndInsertString(DCM_QueryRetrieveLevel, "SERIES");
        findParams.putAndInsertString(DCM_StudyID, "");
        findParams.putAndInsertString(DCM_SeriesTime, "");
        findParams.putAndInsertString(DCM_SeriesDate, "");
        findParams.putAndInsertString(DCM_StudyInstanceUID, studyUId);
        findParams.putAndInsertString(DCM_SeriesType, "");
        findParams.putAndInsertString(DCM_SeriesDescription, "");
        findParams.putAndInsertString(DCM_SeriesInstanceUID, "");
        findParams.putAndInsertString(DCM_SOPClassUID, "");
        
        FINDResponses responses;
        result = DicomSCU->sendFINDRequest(cxID, &findParams, &responses);
        DicomSCU->closeAssociation(DCMSCU_RELEASE_ASSOCIATION);
        
        DcmDataset *dset = NULL;
        OFListIterator(FINDResponse*) it = responses.begin();
        while (it != responses.end())
        {
            FINDResponse* rsp = *it;
            dset =  rsp->m_dataset;
            
            if (dset != NULL)
            {
                
                OFString seriesUID;
                result = dset->findAndGetOFString(DCM_SeriesInstanceUID, seriesUID);
                NSLog(@"%s---- Series UID ", seriesUID.c_str());
                
                OFString seriesTime;
                result = dset->findAndGetOFString(DCM_SeriesTime, seriesTime);
                NSLog(@"%s---- Series Time ", seriesTime.c_str());
                
                OFString seriesDate;
                result = dset->findAndGetOFString(DCM_SeriesDate, seriesDate);
                NSLog(@"%s---- Series Date ", seriesDate.c_str());
                
                OFString seriesType;
                result = dset->findAndGetOFString(DCM_SeriesType, seriesType);
                NSLog(@"%s---- Series Type ", seriesType.c_str());
                
                OFString seriesDesc;
                result = dset->findAndGetOFString(DCM_SeriesDescription, seriesDesc);
                NSLog(@"%s---- Series Desc ", seriesDesc.c_str());
                
                Series *series = [[Series alloc] init];
                series.Id = [[NSString alloc] initWithUTF8String:seriesUID.c_str()];
                series.seriesDescription = [[NSString alloc] initWithUTF8String:seriesDesc.c_str()];
                series.dateString = [[NSString alloc] initWithUTF8String:seriesDate.c_str()];
                series.timeString = [[NSString alloc] initWithUTF8String:seriesTime.c_str()];
                
                NSMutableDictionary *instances = [self getInstances:[[NSString alloc] initWithUTF8String:seriesUID.c_str()] StudyUId:[[NSString alloc] initWithUTF8String:studyUId] PACSConnection:configureInfoObject];
                if ([[instances objectForKey:@"status"] isEqualToString:@"false"]) {
                    [inDict setObject:@"false" forKey:@"status"];
                    [inDict setObject:[NSMutableArray new] forKey:@"results"];
                }
                if (instances.count == 0) {
                    seriesesArray = [[NSMutableArray alloc] init];
                    [inDict setObject:@"true" forKey:@"status"];
                    [inDict setObject:seriesesArray forKey:@"results"];
                    return inDict;
                } else {
                    series.medias = [instances objectForKey:@"results"];
                    if (series.medias.count > 0) {
                        series.seriesType = ((Media *)[series.medias objectAtIndex:0]).mediaType;
                    }
                }
                [seriesesArray addObject:series];
            }
            it++;
        }
        
        // clear memory
        findParams.clear();
        if (dset != NULL)
            dset->clear();
        if (cxID)
            cxID = NULL;
        
        [inDict setObject:@"true" forKey:@"status"];
        [inDict setObject:seriesesArray forKey:@"results"];
        return inDict;
        //        return seriesesArray;
    }
}

- (NSMutableDictionary*) getInstances:(NSString*)SeriesUId StudyUId:(NSString*)StudyUId PACSConnection:(ServerConfigurationModule *)configureInfoObject {
    @autoreleasepool {
        
        NSMutableArray *instencesArray = [[NSMutableArray alloc] init];
        NSMutableDictionary *inDict = [NSMutableDictionary new];
        const char *seriesUId = [SeriesUId UTF8String];
        const char *studyUId = [StudyUId UTF8String];

        DcmSCU * DicomSCU = [self createSCU:configureInfoObject];
        
        OFList<OFString> TransferSyntaxes;
        //TransferSyntaxes.push_back(UID_LittleEndianExplicitTransferSyntax);
        TransferSyntaxes.push_back(UID_LittleEndianImplicitTransferSyntax);
        
        DicomSCU->addPresentationContext(UID_FINDStudyRootQueryRetrieveInformationModel, TransferSyntaxes);
        
        OFCondition result = DicomSCU->initNetwork();
        result = DicomSCU->negotiateAssociation();
        T_ASC_PresentationContextID cxID = NULL;
        if (result == EC_Normal) {
            cxID = DicomSCU->findPresentationContextID(UID_FINDStudyRootQueryRetrieveInformationModel, "");
        }else{
            OFString temp_str;
            DCMNET_ERROR("Error: " << DimseCondition::dump(temp_str, result));
            [inDict setObject:@"false" forKey:@"status"];
            [inDict setObject:instencesArray forKey:@"results"];
            return inDict;
        }
        
        DcmDataset findParams = DcmDataset();
        findParams.putAndInsertString(DCM_QueryRetrieveLevel, "IMAGE");
        findParams.putAndInsertString(DCM_SeriesInstanceUID, seriesUId);
        findParams.putAndInsertString(DCM_StudyInstanceUID, studyUId);
        findParams.putAndInsertString(DCM_InstanceCreationDate, "");
        findParams.putAndInsertString(DCM_InstanceCreationTime, "");
        findParams.putAndInsertString(DCM_InstanceCreatorUID, "");
        findParams.putAndInsertString(DCM_SOPInstanceUID, "");
        findParams.putAndInsertString(DCM_SOPClassUID, "");
        findParams.putAndInsertString(DCM_AcquisitionTime, "");
        findParams.putAndInsertString(DCM_AcquisitionDate, "");
        findParams.putAndInsertString(DCM_ContentTime, "");
        findParams.putAndInsertString(DCM_ContentDate, "");
        
        FINDResponses responses;
        result = DicomSCU->sendFINDRequest(cxID, &findParams, &responses);
        DicomSCU->closeAssociation(DCMSCU_RELEASE_ASSOCIATION);
        
        DcmDataset *dset = NULL;
        OFListIterator(FINDResponse*) it = responses.begin();
        while (it != responses.end())
        {
            FINDResponse* rsp = *it;
            dset =  rsp->m_dataset;
            
            if (dset != NULL)
            {
                
                OFString instanceNumber;
                result = dset->findAndGetOFString(DCM_SOPInstanceUID, instanceNumber);
                NSLog(@"%s---- Instance Number ", instanceNumber.c_str());
                
                OFString instanceTime;
                result = dset->findAndGetOFString(DCM_InstanceCreationTime, instanceTime);
                NSLog(@"%s---- Instance Time ", instanceTime.c_str());
                
                //            OFString instanceDate;
                //            result = dset->findAndGetOFString(DCM_InstanceCreationDate, instanceDate);
                //            NSLog(@"%s---- Instance Date ", instanceDate.c_str());
                OFString AcquisitionDate;
                result = dset->findAndGetOFString(DCM_AcquisitionDate, AcquisitionDate);
                NSLog(@"%s---- Instance Date ", AcquisitionDate.c_str());
                
                OFString AcquisitionTime;
                result = dset->findAndGetOFString(DCM_AcquisitionTime, AcquisitionTime);
                NSLog(@"%s---- Instance Date ", AcquisitionTime.c_str());
                
                OFString instanceCreatorID;
                result = dset->findAndGetOFString(DCM_InstanceCreatorUID, instanceCreatorID);
                NSLog(@"%s---- Instance Creator ID ", instanceCreatorID.c_str());
                
                OFString sopClassUID;
                result = dset->findAndGetOFString(DCM_SOPClassUID, sopClassUID);
                NSLog(@"%s---- sopClassUID Instance Creator ID ", sopClassUID.c_str());
                
                Media *media = [[Media alloc] init];
                media.dateString = [[NSString alloc] initWithUTF8String:AcquisitionDate.c_str()];
                media.timeString = [[NSString alloc] initWithUTF8String:AcquisitionTime.c_str()];
                media.instanceNumber = [[NSString alloc] initWithUTF8String:instanceNumber.c_str()];
                media.creatorId = [[NSString alloc] initWithUTF8String:instanceCreatorID.c_str()];
                media.sopClassUID = [[NSString alloc] initWithUTF8String:sopClassUID.c_str()];
                
                if ([media.sopClassUID isEqualToString: @UID_VLMicroscopicImageStorage]){
                    media.mediaType = @"Image";
                    [instencesArray addObject:media];
                }else if ([media.sopClassUID isEqualToString: @UID_VideoMicroscopicImageStorage]){
                    media.mediaType = @"Video";
                    [instencesArray addObject:media];
                }else{
                    media.mediaType = @"Other";
                }
            }
            it++;
        }
        
        // clear the DcmDataset
        findParams.clear();
        if (dset != NULL)
            dset->clear();
        if (cxID)
            cxID = NULL;
        
        [inDict setObject:@"true" forKey:@"status"];
        [inDict setObject:instencesArray forKey:@"results"];
        return inDict;
    }
}
@end

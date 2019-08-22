//
//  StoreSCU.m
//  Dicom
//
//  Created by Sankar Dhekshit on 16/02/16.
//  Copyright © 2016 Carl Zeiss Meditec. All rights reserved.
//

#define WITH_OPENSSL 1

#import "StoreSCU.h"
#import "Constants.h"
#include "dcmtk/dcmnet/scu.h"
#include "dcmtk/dcmnet/diutil.h"
#include "dcmtk/dcmtls/tlsscu.h"

@interface StoreSCU ()
{
    DcmSCU *dicomSCU;
    DcmTLSSCU *dicomTLSSCU;
}
@end

@implementation StoreSCU

-(id)init
{
    dicomSCU = NULL;
    return self;
}

+ (DcmSCU *)createSCU:(ServerConfigurationModule*)configureInfoObject {
    NSString *callingAE = configureInfoObject.callingAE;
    NSString *calledAE = configureInfoObject.calledAE;
    NSString *calledIP = configureInfoObject.calledIP;
    NSString *port = configureInfoObject.port;
    
    DcmSCU * dicomSCU = new DcmSCU();
    dicomSCU->setAETitle([callingAE UTF8String]);
    dicomSCU->setPeerAETitle([calledAE UTF8String]);
    dicomSCU->setPeerHostName([calledIP UTF8String]);
    dicomSCU->setPeerPort([port intValue]);
    dicomSCU->setDIMSEBlockingMode(DIMSE_NONBLOCKING);
    dicomSCU->setDIMSETimeout(30);
    dicomSCU->setACSETimeout(30);
    dicomSCU->setMaxReceivePDULength(ASC_MAXIMUMPDUSIZE);
    
    return dicomSCU;
}

//+ (DcmTLSSCU *)createTLSSCU:(ServerConfigurationModule*)configureInfoObject {
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

- (void)storeDCM:(NSString *)dcmPath withMediaType:(NSString *)mediaType PACSConnection:(ServerConfigurationModule *)configureInfoObject success:(void(^)(NSString *result))success failure:(void(^)(NSError *error))failure;
{
    
    if (configureInfoObject == nil) {
        failure([NSError errorWithDomain:@"UNO3"
                                    code:EPERM
                                userInfo:@{
                                           NSLocalizedDescriptionKey:@"PACS needs to be configured correctly"
                                           }]);
        return;
    }
    dicomSCU = [StoreSCU createSCU:configureInfoObject];
    OFCondition result;
    T_ASC_PresentationContextID cxID = T_ASC_PresentationContextID();
    
    NSString *dcmFilename = dcmPath;
    __block DcmFileFormat fileFormat;
    __block DcmDataset dataset = DcmDataset();
    DcmDataset *dataset_res_command;
    DcmDataset *dataset_res_status;
    
    //---------------------------------------------------------------------------------------
    //Set up a cleanup block that'll release any handles before cancellation
    void (^cleanup)(void) = ^{
        //Release the background task handler, making the app eligible to be suspended now
        dataset.clear();
        fileFormat.clear();
        self->dicomSCU = NULL;
    };
    DCMNET_INFO("Dcm file Created Successfully, trying to send file to pacs");
    
    OFList<OFString> TransferSyntaxes;
    if ([mediaType isEqualToString:@"jpeg"])
    {
        TransferSyntaxes.push_back(UID_JPEGProcess1TransferSyntax);
        if (dicomSCU) {
            dicomSCU->addPresentationContext(UID_VLMicroscopicImageStorage, TransferSyntaxes);
            result = dicomSCU->initNetwork();
            result = dicomSCU->negotiateAssociation();
        }
        if (result == EC_Normal && dicomSCU) {
            cxID = dicomSCU->findPresentationContextID(UID_VLMicroscopicImageStorage, "");
        }
        else {
            OFString temp_str;
            DCMNET_ERROR("PACS connection details are not correct: " << DimseCondition::dump(temp_str, result));
            cleanup();
            failure([NSError errorWithDomain:@"UNO3"
                                        code:EPERM
                                    userInfo:@{
                                               NSLocalizedDescriptionKey:@"PACS connection details are not correct"
                                               }]);
            return;
        }
    }
    else {
        TransferSyntaxes.push_back(UID_MPEG2MainProfileAtHighLevelTransferSyntax);
        
        if (dicomSCU) {
            dicomSCU->addPresentationContext(UID_VideoMicroscopicImageStorage, TransferSyntaxes);
            result = dicomSCU->initNetwork();
            result = dicomSCU->negotiateAssociation();
        }
        if (result == EC_Normal && dicomSCU) {
            cxID = dicomSCU->findPresentationContextID(UID_VideoMicroscopicImageStorage, "");
        }
        else {
            OFString temp_str;
            DCMNET_ERROR("PACS connection details are not correct: " << DimseCondition::dump(temp_str, result));
            cleanup();
            failure([NSError errorWithDomain:@"UNO3"
                                        code:EPERM
                                    userInfo:@{
                                               NSLocalizedDescriptionKey:@"PACS connection details are not correct"
                                               }]);
            return;
        }
    }
    
    OFCondition loadStatus = fileFormat.loadFile([dcmFilename UTF8String]);
    if (loadStatus.good())
    {
        dataset = *fileFormat.getDataset();
    }
    else
    {
        OFString temp_str;
        DCMNET_ERROR("Faild to load object from a DICOM file: " << DimseCondition::dump(temp_str, loadStatus));
        cleanup();
        failure([NSError errorWithDomain:@"UNO3"
                                    code:EPERM
                                userInfo:@{
                                           NSLocalizedDescriptionKey:@"Faild to load object from a DICOM file"
                                           }]);
        
        return;
    }

    @try {
        
        Uint16 dd = 0;
        if (dicomSCU) {
            result = dicomSCU->sendSTORERequest(cxID, [dcmFilename UTF8String], &dataset, dataset_res_command, dataset_res_status, dd);
        }
        
        if (result == EC_Normal && dd == 0)
        {
            OFString instanceNumber;
            result = dataset.findAndGetOFString(DCM_SOPInstanceUID, instanceNumber);
            if (dicomSCU) {
                dicomSCU->closeAssociation(DCMSCU_RELEASE_ASSOCIATION);
            }
            cleanup();
            success([[NSString alloc] initWithUTF8String:instanceNumber.c_str()]);
            return;
        }
        else
        {
//            DCMNET_INFO("Failed sendSTORERequest ::: "<< result.text() << dd);
            OFString temp_str;
            DCMNET_ERROR("Failed to upload the Media file: " << DimseCondition::dump(temp_str, result));

            failure([NSError errorWithDomain:@"UNO3"
                                        code:EPERM
                                    userInfo:@{
                                               NSLocalizedDescriptionKey:@"Failed to upload the Media file"
                                               }]);
            if (dicomSCU) {
                dicomSCU->closeAssociation(DCMSCU_RELEASE_ASSOCIATION);
            }
            cleanup();
        }
        
    } @catch (NSException *exception) {
        printf("Exception occured %s",[exception.description UTF8String]);
    }
    
}

//- (void)storeDCMWithTLS:(NSString *)dcmPath withMediaType:(NSString *)mediaType PACSConnection:(ServerConfigurationModule *)configureInfoObject success:(void(^)(NSString *result))success failure:(void(^)(NSError *error))failure;
//{
//
//    if (!configureInfoObject.callingAE) {
//        failure([NSError errorWithDomain:@"UNO3"
//                                    code:EPERM
//                                userInfo:@{
//                                           NSLocalizedDescriptionKey:@"PACS connection deatils are not correct"
//                                           }]);
//        return;
//    }
//    dicomTLSSCU = [StoreSCU createTLSSCU:configureInfoObject];
//    OFCondition result;
//    T_ASC_PresentationContextID cxID = T_ASC_PresentationContextID();
//
//    NSString *dcmFilename = dcmPath;
//    __block DcmFileFormat fileFormat;
//    __block DcmDataset dataset = DcmDataset();
//    DcmDataset *dataset_res_command;
//    DcmDataset *dataset_res_status;
//
//    //---------------------------------------------------------------------------------------
//    //Set up a cleanup block that'll release any handles before cancellation
//    void (^cleanup)(void) = ^{
//        //Release the background task handler, making the app eligible to be suspended now
//        dataset.clear();
//        fileFormat.clear();
//        self->dicomTLSSCU = NULL;
//    };
//    DCMNET_INFO("Dcm file Created Successfully, trying to send file to pacs");
//
//    OFList<OFString> TransferSyntaxes;
//    if ([mediaType isEqualToString:@"jpeg"])
//    {
//        TransferSyntaxes.push_back(UID_JPEGProcess1TransferSyntax);
//        dicomTLSSCU->addPresentationContext(UID_VLMicroscopicImageStorage, TransferSyntaxes);
//        if (dicomTLSSCU)
//            result = dicomTLSSCU->initNetwork();
//        if (dicomTLSSCU)
//            result = dicomTLSSCU->negotiateAssociation();
//        if (result == EC_Normal && dicomTLSSCU)
//        {
//            cxID = dicomTLSSCU->findPresentationContextID(UID_VLMicroscopicImageStorage, "");
//        }
//        else
//        {
//            OFString temp_str;
//            DCMNET_ERROR("PACS connection details are not correct: " << DimseCondition::dump(temp_str, result));
//            cleanup();
//            failure([NSError errorWithDomain:@"UNO3"
//                                        code:EPERM
//                                    userInfo:@{
//                                               NSLocalizedDescriptionKey:@"PACS connection details are not correct"
//                                               }]);
//            return;
//        }
//    }
//    else
//    {
//        TransferSyntaxes.push_back(UID_MPEG2MainProfileAtHighLevelTransferSyntax);
//        TransferSyntaxes.push_back(UID_LittleEndianImplicitTransferSyntax);
//        TransferSyntaxes.push_back(UID_LittleEndianExplicitTransferSyntax);
//
//        dicomTLSSCU->addPresentationContext(UID_VideoMicroscopicImageStorage, TransferSyntaxes);
//        if (dicomTLSSCU)
//            result = dicomTLSSCU->initNetwork();
//        if (dicomTLSSCU)
//            result = dicomTLSSCU->negotiateAssociation();
//        if (result == EC_Normal && dicomTLSSCU)
//        {
//            cxID = dicomTLSSCU->findPresentationContextID(UID_VideoMicroscopicImageStorage, "");
//        }
//        else{
//            OFString temp_str;
//            DCMNET_ERROR("PACS connection details are not correct: " << DimseCondition::dump(temp_str, result));
//            cleanup();
//            failure([NSError errorWithDomain:@"UNO3"
//                                        code:EPERM
//                                    userInfo:@{
//                                               NSLocalizedDescriptionKey:@"PACS connection details are not correct"
//                                               }]);
//            return;
//        }
//    }
//
//    OFCondition loadStatus = fileFormat.loadFile([dcmFilename UTF8String]);
//    if (loadStatus.good())
//    {
//        dataset = *fileFormat.getDataset();
//    }
//    else
//    {
//        cleanup();
//        failure([NSError errorWithDomain:@"UNO3"
//                                    code:EPERM
//                                userInfo:@{
//                                           NSLocalizedDescriptionKey:@"Faild to load object from a DICOM file"
//                                           }]);
//
//        return;
//    }
//
//    @try {
//        Uint16 dd = 0;
//        result = dicomTLSSCU->sendSTORERequest(cxID, [dcmFilename UTF8String], &dataset, dataset_res_command, dataset_res_status, dd);
//
//        if (result == EC_Normal && dd == 0)
//        {
//            OFString instanceNumber;
//            result = dataset.findAndGetOFString(DCM_SOPInstanceUID, instanceNumber);
//            dicomTLSSCU->closeAssociation(DCMSCU_RELEASE_ASSOCIATION);
//            cleanup();
//            success([[NSString alloc] initWithUTF8String:instanceNumber.c_str()]);
//            return;
//        }
//        else
//        {
////            DCMNET_INFO("Failed sendSTORERequest ::: "<< result.text() << dd);
//            OFString temp_str;
//            DCMNET_ERROR("Failed to upload the Media file: " << DimseCondition::dump(temp_str, result));
//            failure([NSError errorWithDomain:@"UNO3"
//                                        code:EPERM
//                                    userInfo:@{
//                                               NSLocalizedDescriptionKey:@"Failed to upload the Media file"
//                                               }]);
//            dicomTLSSCU->closeAssociation(DCMSCU_RELEASE_ASSOCIATION);
//            cleanup();
//        }
//
//    } @catch (NSException *exception) {
//        printf("Exception occured %s",[exception.description UTF8String]);
//    }
//}

-(void)closeAssociation:(BOOL)isForTLS
{
    if (isForTLS) {
        @try {
            if (dicomTLSSCU != NULL)
            {
                if (dicomTLSSCU->isConnected() == OFTrue){
                    @try {
                        dicomTLSSCU->closeAssociation(DCMSCU_RELEASE_ASSOCIATION);
                        dicomTLSSCU = NULL;
                    }@catch (NSException *exception) {
                        printf("Exception occured %s",[exception.description UTF8String]);
                    }
                }
            }
        } @catch (NSException *exception) {
            printf("Exception occured %s",[exception.description UTF8String]);
        }
    }
    else {
        @try {
            if (dicomSCU != NULL)
            {
                if (dicomSCU->isConnected() == OFTrue){
                    @try {
                        dicomSCU->closeAssociation(DCMSCU_RELEASE_ASSOCIATION);
                        dicomSCU = NULL;
                    }@catch (NSException *exception) {
                        printf("Exception occured %s",[exception.description UTF8String]);
                    }
                }
            }
        } @catch (NSException *exception) {
            printf("Exception occured %s",[exception.description UTF8String]);
        }
    }
}

@end

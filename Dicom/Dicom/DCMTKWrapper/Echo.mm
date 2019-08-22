//
//  Echo.m
//  Dicom
//
//  Created by Sankar Dhekshit on 16/02/16.
//  Copyright © 2016 Carl Zeiss Meditec. All rights reserved.
//

#define WITH_OPENSSL 1

#import "Echo.h"
#import "Constants.h"
#import "DicomLogger.h"

#include "dcmtk/dcmnet/scu.h"
#include "dcmtk/config/osconfig.h"
#include "dcmtk/dcmnet/diutil.h"
#include "dcmtk/oflog/fileap.h"
#include "dcmtk/dcmtls/tlslayer.h"

@implementation Echo

-(void) PACSConnection:(ServerConfigurationModule *)configureInfo success:(void(^)(NSString *result))success failure:(void(^)(NSError *error))failure
{
    NSLog(@"PACSConnection entered");
    [[DicomLogger sharedLogger] setupLogFiles];
    /* ...*/
    
    @autoreleasepool
    {
        if (configureInfo == nil)
        {
            failure([NSError errorWithDomain:@"UNO3"
                                        code:EPERM
                                    userInfo:@{
                                               NSLocalizedDescriptionKey:@"PACS needs to be configured correctly"
                                               }]);
            return;
        }
        
        NSString *callingAE = configureInfo.callingAE;
        NSString *calledAE = configureInfo.calledAE;
        NSString *callingIP = configureInfo.callingIP;
        NSString *IP = configureInfo.serverIP;
        
        const char* callingAppTittle = [callingAE UTF8String];
        const char* calledAppTittle = [calledAE UTF8String];
        const char* callingPresentationAddress = [callingIP UTF8String];
        const char* calledPresentationAddress = [IP UTF8String];
        
        T_ASC_Network *net; // network struct, contains DICOM upper layer FSM etc.
        NSLog(@"PACSConnection: Before ASC_initializeNetwork");
        DCMNET_INFO("Before ASC_initializeNetwork");
        dcmConnectionTimeout.set(10);
        ASC_initializeNetwork(NET_REQUESTOR, 0, 10 /* timeout */, &net);
        NSLog(@"PACSConnection: After ASC_initializeNetwork");
        DCMNET_INFO("After ASC_initializeNetwork");
        T_ASC_Parameters *params; // parameters of association request
        ASC_createAssociationParameters(&params, ASC_MAXIMUMPDUSIZE);
        
        // set calling and called AE titles
        ASC_setAPTitles(params, callingAppTittle, calledAppTittle, NULL);
        
        // the DICOM server accepts connections at server.nowhere.com port 104
        ASC_setPresentationAddresses(params, callingPresentationAddress, calledPresentationAddress);
        
        if (isToSupportTLS) {
            // create TLS object that initializes the random generator through a file
            // "random.dat" containing random data (1 kByte is sufficient).
            DcmTLSTransportLayer *tLayer = new DcmTLSTransportLayer(
                                                                    DICOM_APPLICATION_REQUESTOR, "random.dat");
            if (TCS_ok != tLayer->setPrivateKeyFile(PrivatePEMKey, SSL_FILETYPE_PEM))
            {
                DCMNET_INFO("unable to load private key");
                return;
            }
            if (TCS_ok != tLayer->setCertificateFile(ClientCert, SSL_FILETYPE_PEM))
            {
                DCMNET_INFO("unable to load certificate");
                return;
            }
            // enable the TLS_RSA_WITH_3DES_EDE_CBC_SHA ciphersuite
            tLayer->setCipherSuites(SSL3_TXT_RSA_DES_192_CBC3_SHA);
            // accept any certificate from the remote site (not recommended)
            tLayer->setCertificateVerification(DCV_requireCertificate);//DCV_ignoreCertificate);
            // register and activate TLS layer
            ASC_setTransportLayer(net, tLayer, 1);
            ASC_setTransportLayerType(params, 1);
        }
        
        // list of transfer syntaxes, only a single entry here
        const char* ts[] = { UID_LittleEndianImplicitTransferSyntax };
        
        // add presentation context to association request
        ASC_addPresentationContext(params, 1, UID_VerificationSOPClass, ts, 1);
        
        // request DICOM association
        T_ASC_Association *assoc;
        NSLog(@"PACSConnection: Before ASC_requestAssociation");
        DCMNET_INFO("Before ASC_requestAssociation");
        OFCondition cond = ASC_requestAssociation(net, params, &assoc);
        NSLog(@"PACSConnection: After ASC_requestAssociation");
        DCMNET_INFO("After ASC_requestAssociation");
        if (cond.good())
        {
            if (ASC_countAcceptedPresentationContexts(params) == 1)
            {
                // the remote SCP has accepted the Verification Service Class
                DIC_US id = assoc->nextMsgID++; // generate next message ID
                DIC_US status; // DIMSE status of C-ECHO-RSP will be stored here
                DcmDataset *sd = NULL; // status detail will be stored here
                // send C-ECHO-RQ and handle response
                OFCondition con = DIMSE_echoUser(assoc, id, DIMSE_BLOCKING, 10, &status, &sd);
                delete sd; // we don't care about status detail
                ASC_releaseAssociation(assoc);

                NSLog(@"PACSConnection: successful");
                DCMNET_INFO("PACS Connection Successful");
                success(@"PACS Connection Successful");
                return;
            }
            else
            {
                DCMNET_INFO("Echo Failed :: " << cond.text());
                DCMNET_INFO("Echo Failed Connection Details :: " << configureInfo);
                failure([NSError errorWithDomain:@"UNO3"
                                            code:EPERM
                                        userInfo:@{
                                                   NSLocalizedDescriptionKey:@"PACS needs to be configured correctly"
                                                   }]);
                return;
            }
        }
        else
        {
            DCMNET_INFO("Echo Failed :: " << cond.text());
            DCMNET_INFO("Echo Failed Connection Details :: " << configureInfo);
            failure([NSError errorWithDomain:@"UNO3"
                                        code:EPERM
                                    userInfo:@{
                                               NSLocalizedDescriptionKey:@"PACS needs to be configured correctly"
                                               }]);
            return;
        }
    }
}
@end

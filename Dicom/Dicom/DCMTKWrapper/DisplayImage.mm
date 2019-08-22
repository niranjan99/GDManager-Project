//
//  DisplayImage.m
//  Dicom
//
//  Created by CARIn Lab on 06/05/16.
//  Copyright © 2016 Carl Zeiss Meditec. All rights reserved.
//

#import "DisplayImage.h"
#include "dcmtk/dcmnet/scu.h"
#include "dcmtk/dcmnet/dfindscu.h"

#include <zlib.h>         /* for zlibVersion() */
#include "dcmtk/config/osconfig.h"
#include "dcmtk/dcmdata/dctk.h"          /* for various dcmdata headers */
#include "dcmtk/dcmdata/cmdlnarg.h"      /* for prepareCmdLineArgs */
#include "dcmtk/dcmdata/dcuid.h"         /* for dcmtk version name */
#include "dcmtk/dcmdata/dcrledrg.h"      /* for DcmRLEDecoderRegistration */

#include "dcmtk/dcmimgle/dcmimage.h"      /* for DicomImage */
#include "dcmtk/dcmimgle/digsdfn.h"       /* for DiGSDFunction */
#include "dcmtk/dcmimgle/diciefn.h"       /* for DiCIELABFunction */

#include "dcmtk/ofstd/ofconapp.h"      /* for OFConsoleApplication */
#include "dcmtk/ofstd/ofcmdln.h"       /* for OFCommandLine */

#include "dcmtk/dcmimage/diregist.h"      /* include to support color images */
#include "dcmtk/ofstd/ofstd.h"         /* for OFStandard */
#include "dcmtk/dcmimage/dipitiff.h"     /* for dcmimage TIFF plugin */
#include "dcmtk/dcmimage/dipipng.h"      /* for dcmimage PNG plugin */

#include "dcmtk/ofstd/ofstream.h"
#include "dcmtk/dcmjpeg/djdecode.h"
#include "dcmtk/dcmjpeg/dipijpeg.h"
#include "dcmtk/dcmimage/dipipng.h"
#include "dcmtk/dcmdata/dcpxitem.h"

const unsigned int DCM_DumpMaxByteSize = 65535;
#define PRV_PrivateCreator  DcmTag(0x0029, 0x0010, EVR_LO)
#define PRV_PrivateElement DcmTag(0x0029, 0x1000, EVR_LO)


@implementation DisplayImage


+(void)displayImage:(NSString *)dcmPath :(NSString *)mediaPath :(NSString *)imageType success:(void(^)(NSMutableArray *result))success failure:(void(^)(NSError *error))failure;
{
    @autoreleasepool {
        
        NSMutableArray *outputFilesList = [[NSMutableArray alloc] init];
        if (!dcmPath) {
            failure([NSError errorWithDomain:@"UNO3" code:EPERM userInfo:@{
                                                                           NSLocalizedDescriptionKey:@"Imagepath can't be nill"
                                                                           }]);
            return;
        }
        
        DcmRLEDecoderRegistration::registerCodecs(OFFalse /*pCreateSOPInstanceUID*/, OFFalse);
        DJDecoderRegistration::registerCodecs(EDC_never, EUC_default, EPC_default, OFFalse);
        DJDecoderRegistration::registerCodecs(); // register JPEG codecs

        DcmFileFormat *dfile = new DcmFileFormat();
        OFCondition cond = dfile->loadFile([dcmPath cStringUsingEncoding:NSASCIIStringEncoding], EXS_Unknown, EGL_withoutGL, DCM_MaxReadLength, ERM_autoDetect);
        if (cond.bad()) {
            failure([NSError errorWithDomain:@"UNO3"
                                        code:EPERM
                                    userInfo:@{
                                               NSLocalizedDescriptionKey:@"Faild to create media file."
                                               }]);
            return;
        }
        
        DcmElement* element = NULL;
        DcmDataset *data = dfile->getDataset();
        OFCondition result1 = data->findAndGetElement(DCM_PixelData, element);
        if (result1.bad() || element == NULL)
        {
            failure([NSError errorWithDomain:@"UNO3"
                                        code:EPERM
                                    userInfo:@{
                                               NSLocalizedDescriptionKey:@"Faild to create media file."
                                               }]);
            dfile->clear();
            return;
        }
        
       __block DcmPixelData *dpix = NULL;
        dpix = OFstatic_cast(DcmPixelData*, element);
        
       __block DcmPixelSequence *dseq = NULL;
        E_TransferSyntax xferSyntax = EXS_Unknown;
        const DcmRepresentationParameter *rep = NULL;
       __block DcmPixelItem* pixitem = NULL;
        
        //---------------------------------------------------------------------------------------
        //Set up a cleanup block that'll release any handles before cancellation
        void (^cleanup)(void) = ^{
            
            //Release the background task handler, making the app eligible to be suspended now
            dfile->clear();
            if (data != NULL)
                data->clear();
            if (dpix != NULL)
                dpix = NULL;
            if (pixitem != NULL)
                pixitem = NULL;
            
        };

        // Find the key that is needed to access the right representation of the data within DCMTK
        dpix->getOriginalRepresentationKey(xferSyntax, rep);
        // Access original data representation and get result within pixel sequence
        OFCondition result2 = dpix->getEncapsulatedRepresentation(xferSyntax, rep, dseq);
        if ( result2 == EC_Normal )
        {
            // Access first frame (skipping offset table)
            dseq->getItem(pixitem, 1);
            if (pixitem == NULL)
            {
                dseq->getItem(pixitem, 0);
                if (pixitem == NULL)
                {
                    failure([NSError errorWithDomain:@"UNO3"
                                                code:EPERM
                                            userInfo:@{
                                                       NSLocalizedDescriptionKey:@"Faild to create media file."
                                                       }]);
                    cleanup();
                    return;
                }

            }
            // Get the length of this pixel item (i.e. fragment, i.e. most of the time, the lenght of the frame)
            Uint32 length = pixitem->getLength();
            if (length == 0)
            {
                failure([NSError errorWithDomain:@"UNO3"
                                            code:EPERM
                                        userInfo:@{
                                                   NSLocalizedDescriptionKey:@"Faild to create media file."
                                                   }]);
                cleanup();
                return;
            }
            
            // Finally, get the compressed data for this pixel item
            UInt32 offset = 0;
            void *buffer = malloc(DCM_DumpMaxByteSize);
            Uint32 bytes = DCM_DumpMaxByteSize;
            
            [[NSFileManager defaultManager] createFileAtPath:mediaPath contents:nil attributes:nil];
            NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:mediaPath];
            while (offset < length)
            {
                if ((length-offset) < bytes)
                {
                    bytes = (length-offset);
                }
                result2 = pixitem->getPartialValue(buffer, offset, bytes, NULL, EBO_unknown);
                offset += bytes;
                @autoreleasepool
                {
                    [fileHandle writeData:[NSData dataWithBytes:buffer length:bytes]];
                    [fileHandle synchronizeFile];
                }
            }
            
            [outputFilesList addObject:mediaPath];
            [fileHandle closeFile];
        }

        if (outputFilesList != NULL && outputFilesList.count > 0)
        {
            NSMutableDictionary *inDict = [NSMutableDictionary new];
            
            OFString privateCreator;
            OFCondition result = data->findAndGetOFString(PRV_PrivateCreator, privateCreator);
            if (result.good())
            {
                OFString element;
                result = data->findAndGetOFString(PRV_PrivateElement, element);
                if (result.good())
                {
                    NSString *tagString = [[NSString alloc] initWithUTF8String:element.c_str()];
                    if ([tagString length])
                    {
                        [inDict setValue:tagString forKey:@"tags"];
                    }
                }
            }
            [inDict setValue:[outputFilesList firstObject] forKey:@"image"];
            [outputFilesList removeAllObjects];
            [outputFilesList addObject:inDict];
            cleanup();
            success(outputFilesList);
        }
        else
        {
            cleanup();
            failure([NSError errorWithDomain:@"UNO3"
                                        code:EPERM
                                    userInfo:@{
                                               NSLocalizedDescriptionKey:@"Faild to create media file."
                                               }]);
        }
    }
}

@end

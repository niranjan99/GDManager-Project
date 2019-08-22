//
//  MoveSCU.m
//  DCMTKSample
//
//  Created by Sankar Dhekshit on 21/07/16.
//  Copyright © 2016 Carl Zeiss Meditec. All rights reserved.
//


#import "RetrieveFile.h"

#include "dcmtk/config/osconfig.h"

#include "dcmtk/ofstd/ofstd.h"
#include "dcmtk/ofstd/ofconapp.h"
#include "dcmtk/ofstd/ofdatime.h"
#include "dcmtk/dcmnet/dicom.h"         /* for DICOM_APPLICATION_ACCEPTOR */
#include "dcmtk/dcmnet/dimse.h"
#include "dcmtk/dcmnet/diutil.h"
#include "dcmtk/dcmnet/dcasccfg.h"      /* for class DcmAssociationConfiguration */
#include "dcmtk/dcmnet/dcasccff.h"      /* for class DcmAssociationConfigurationFile */
#include "dcmtk/dcmdata/dcfilefo.h"
#include "dcmtk/dcmdata/dcuid.h"
#include "dcmtk/dcmdata/dcdict.h"
#include "dcmtk/dcmdata/cmdlnarg.h"
#include "dcmtk/dcmdata/dcmetinf.h"
#include "dcmtk/dcmdata/dcuid.h"        /* for dcmtk version name */
#include "dcmtk/dcmdata/dcdeftag.h"
#include "dcmtk/dcmdata/dcostrmz.h"     /* for dcmZlibCompressionLevel */
#include "dcmtk/dcmnet/diutil.h"


#include <iostream>
using namespace std;


typedef struct {
    const char *findSyntax;
    const char *moveSyntax;
} QuerySyntax;

static QuerySyntax querySyntax[3] = {
    { UID_FINDPatientRootQueryRetrieveInformationModel,
        UID_MOVEPatientRootQueryRetrieveInformationModel },
    { UID_FINDStudyRootQueryRetrieveInformationModel,
        UID_MOVEStudyRootQueryRetrieveInformationModel },
    { UID_RETIRED_FINDPatientStudyOnlyQueryRetrieveInformationModel,
        UID_RETIRED_MOVEPatientStudyOnlyQueryRetrieveInformationModel }
};

typedef enum {
    QMPatientRoot = 0,
    QMStudyRoot = 1,
    QMPatientStudyOnly = 2
} QueryModel;

typedef struct {
    T_ASC_Association *assoc;
    T_ASC_PresentationContextID presId;
} MyCallbackInfo;

static DcmDataset *overrideKeys = NULL;

static int opt_acse_timeout = 20;
static OFCmdUnsignedInt  opt_maxPDU = ASC_MAXIMUMPDUSIZE;
static T_ASC_Network *net = NULL; /* the global DICOM network */

E_TransferSyntax  opt_out_networkTransferSyntax = EXS_Unknown;
QueryModel opt_queryModel = QMStudyRoot;

const char *opt_peerTitle = NULL;
const char *opt_ourTitle = NULL;
const char * opt_moveDestination = NULL;
const char* opt_peer = NULL;
int opt_port = 0;
int local_port = 0;


static T_DIMSE_BlockingMode opt_blockMode = DIMSE_NONBLOCKING;// DIMSE_BLOCKING;
static int opt_dimse_timeout = 30;
OFBool            opt_ignorePendingDatasets = OFTrue;
OFCmdSignedInt    opt_cancelAfterNResponses = -1;
E_TransferSyntax  opt_in_networkTransferSyntax = EXS_Unknown;

//SCP Properties
OFBool             opt_bitPreserving = OFTrue; //OFFalse : Changed to true to save bytes by bytes instead of loading entire file into memory
E_TransferSyntax   opt_writeTransferSyntax = EXS_Unknown;
E_GrpLenEncoding   opt_groupLength = EGL_recalcGL;
E_EncodingType     opt_sequenceType = EET_ExplicitLength;
E_PaddingEncoding  opt_paddingType = EPD_withoutPadding;
OFCmdUnsignedInt   opt_filepad = 0;
OFCmdUnsignedInt   opt_itempad = 0;
OFBool             opt_correctUIDPadding = OFFalse;
OFBool             opt_useMetaheader = OFTrue;
OFBool             opt_acceptAllXfers = OFTrue;

NSMutableArray *listofImages = [[NSMutableArray alloc] init];
NSString *filePath = [[NSString alloc] init];

T_ASC_Association *subAssociation = NULL;
NSOperationQueue *downloadQueue = nil;
NSBlockOperation *downloadOperation = nil;
NSString *errorString = @"";

@implementation RetrieveFile

static void
subOpCallback(void * /*subOpCallbackData*/,
              T_ASC_Network *aNet, T_ASC_Association **subAssoc)
{
    if (aNet == NULL) return;   /* help no net ! */
    
    if (*subAssoc == NULL) {
        /* negotiate association */
        acceptSubAssoc(aNet, subAssoc);
    } else {
        /* be a service class provider */
        subOpSCP(subAssoc);
    }
    return;
}

static OFCondition echoSCP(T_ASC_Association * assoc, T_DIMSE_Message * msg, T_ASC_PresentationContextID presID)
{
    OFString temp_str;
    DCMNET_INFO("Received Echo Request ");
    DCMNET_DEBUG(DIMSE_dumpMessage(temp_str, msg->msg.CEchoRQ, DIMSE_INCOMING, NULL, presID));

    
    /* the echo succeeded !! */
    OFCondition cond = DIMSE_sendEchoResponse(assoc, presID, &msg->msg.CEchoRQ, STATUS_Success, NULL);
    if (cond.bad())
    {
//        std::cout << "Echo SCP Failed: " << DimseCondition::dump(temp_str, cond) << OFendl;
        DCMNET_INFO("Echo SCP Failed: " << DimseCondition::dump(temp_str, cond));

    }
    return cond;
}

struct StoreCallbackData
{
    char* imageFileName;
    DcmFileFormat* dcmff;
    T_ASC_Association* assoc;
};

/*
 * This function.is used to indicate progress when storescp receives instance data over the
 * network. On the final call to this function (identified by progress->state == DIMSE_StoreEnd)
 * this function will store the data set which was received over the network to a file.
 * Earlier calls to this function will simply cause some information to be dumped to stdout.
 *
 * Parameters:
 *   callbackData  - [in] data for this callback function
 *   progress      - [in] The state of progress. (identifies if this is the initial or final call
 *                   to this function, or a call in between these two calls.
 *   req           - [in] The original store request message.
 *   imageFileName - [in] The path to and name of the file the information shall be written to.
 *   imageDataSet  - [in] The data set which shall be stored in the image file
 *   rsp           - [inout] the C-STORE-RSP message (will be sent after the call to this function)
 *   statusDetail  - [inout] This variable can be used to capture detailed information with regard to
 *                   the status information which is captured in the status element (0000,0900). Note
 *                   that this function does specify any such information, the pointer will be set to NULL.
 */

static void
storeSCPCallback(
                 void *callbackData,
                 T_DIMSE_StoreProgress *progress,
                 T_DIMSE_C_StoreRQ *req,
                 char * /*imageFileName*/, DcmDataset **imageDataSet,
                 T_DIMSE_C_StoreRSP *rsp,
                 DcmDataset **statusDetail)
{
    DIC_UI sopClass;
    DIC_UI sopInstance;
    
    // dump some information if required (depending on the progress state)
    // We can't use oflog for the pdu output, but we use a special logger for
    // generating this output. If it is set to level "INFO" we generate the
    // output, if it's set to "DEBUG" then we'll assume that there is debug output
    // generated for each PDU elsewhere.
    
    if (downloadOperation.cancelled) {
        
        // remember callback data
        StoreCallbackData *cbdata = OFstatic_cast(StoreCallbackData *, callbackData);
        ASC_dropSCPAssociation(cbdata->assoc, 0);
        return;
    }
    
    
    OFLogger progressLogger = OFLog::getLogger("dcmtk.apps. .progress");
    if (progressLogger.getChainedLogLevel() == OFLogger::INFO_LOG_LEVEL)
    {
        switch (progress->state)
        {
            case DIMSE_StoreBegin:
                COUT << "RECV: ";
                break;
            case DIMSE_StoreEnd:
                COUT << OFendl;
                break;
            default:
                COUT << '.';
                break;
        }
        COUT.flush();
    }
    
    // if this is the final call of this function, save the data which was received to a file
    // (note that we could also save the image somewhere else, put it in database, etc.)
    if (progress->state == DIMSE_StoreEnd)
    {
        OFString tmpStr;
        
        // do not send status detail information
        *statusDetail = NULL;
        
        // remember callback data
        StoreCallbackData *cbdata = OFstatic_cast(StoreCallbackData *, callbackData);
        
        // Concerning the following line: an appropriate status code is already set in the resp structure,
        // it need not be success. For example, if the caller has already detected an out of resources problem
        // then the status will reflect this.  The callback function is still called to allow cleanup.
        //rsp->DimseStatus = STATUS_Success;
        
        // we want to write the received information to a file only if this information
        // is present and the options opt_bitPreserving and opt_ignore are not set.
        if ((imageDataSet != NULL) && (*imageDataSet != NULL) && !opt_bitPreserving)// && !opt_ignore)
        {
            OFString fileName;
            {
                fileName = cbdata->imageFileName;
            }
            
            // determine the transfer syntax which shall be used to write the information to the file
            E_TransferSyntax xfer = opt_writeTransferSyntax;
            if (xfer == EXS_Unknown) xfer = (*imageDataSet)->getOriginalXfer();
            
            // store file either with meta header or as pure dataset
            std::cout << "storing DICOM file: " << fileName << OFendl;
            if (OFStandard::fileExists(fileName))
            {
                std::cout << "DICOM file already exists, overwriting: " << fileName << OFendl;
            }
            OFCondition cond = cbdata->dcmff->saveFile(fileName.c_str(), xfer, opt_sequenceType, opt_groupLength,
                                                       opt_paddingType, static_cast<Uint32>(opt_filepad), static_cast<Uint32>(opt_itempad),
                                                       (opt_useMetaheader) ? EWM_fileformat : EWM_dataset);
            if (cond.bad())
            {
                std::cout << "cannot write DICOM file: " << fileName << ": " << cond.text() << OFendl;
                rsp->DimseStatus = STATUS_STORE_Refused_OutOfResources;
            }
            
            // check the image to make sure it is consistent, i.e. that its sopClass and sopInstance correspond
            // to those mentioned in the request. If not, set the status in the response message variable.
            if ((rsp->DimseStatus = STATUS_Success) )//&& (!opt_ignore))
            {
                // which SOP class and SOP instance ?
                if (!DU_findSOPClassAndInstanceInDataSet(*imageDataSet, sopClass, sopInstance, opt_correctUIDPadding))
                {
                    std::cout << "bad DICOM file: " << fileName << OFendl;
                    rsp->DimseStatus = STATUS_STORE_Error_CannotUnderstand;
                }
                else if (strcmp(sopClass, req->AffectedSOPClassUID) != 0)
                {
                    rsp->DimseStatus = STATUS_STORE_Error_DataSetDoesNotMatchSOPClass;
                }
                else if (strcmp(sopInstance, req->AffectedSOPInstanceUID) != 0)
                {
                    rsp->DimseStatus = STATUS_STORE_Error_DataSetDoesNotMatchSOPClass;
                }
            }
        }
        
    }
}

/*
 * This function processes a DIMSE C-STORE-RQ commmand that was
 * received over the network connection.
 *
 * Parameters:
 *   assoc  - [in] The association (network connection to another DICOM application).
 *   msg    - [in] The DIMSE C-STORE-RQ message that was received.
 *   presID - [in] The ID of the presentation context which was specified in the PDV which contained
 *                 the DIMSE command.
 */

static OFCondition storeSCP(
                            T_ASC_Association *assoc,
                            T_DIMSE_Message *msg,
                            T_ASC_PresentationContextID presID)
{
    OFCondition cond = EC_Normal;
    T_DIMSE_C_StoreRQ *req;
    char imageFileName[2048];
    subAssociation = assoc;
    strcpy(imageFileName, [filePath UTF8String]);
    listofImages = [[NSMutableArray alloc] init];
    [listofImages addObject:filePath];
    
    // assign the actual information of the C-STORE-RQ command to a local variable
    req = &msg->msg.CStoreRQ;
    req->Priority = DIMSE_PRIORITY_LOW;
    
    // dump some information if required
    OFString str;
    DCMNET_INFO("Received Store Request: MsgID " << req->MessageID << ", ("
                << dcmSOPClassUIDToModality(req->AffectedSOPClassUID, "OT") << ")");
    DCMNET_DEBUG(DIMSE_dumpMessage(str, *req, DIMSE_INCOMING, NULL, presID));

    
    // intialize some variables
    StoreCallbackData callbackData;
    callbackData.assoc = assoc;
    callbackData.imageFileName = imageFileName;
    DcmFileFormat dcmff;
    callbackData.dcmff = &dcmff;
    
    // store SourceApplicationEntityTitle in metaheader
    if (assoc && assoc->params)
    {
        const char *aet = assoc->params->DULparams.callingAPTitle;
        if (aet) dcmff.getMetaInfo()->putAndInsertString(DCM_SourceApplicationEntityTitle, aet);
    }
    
    // define an address where the information which will be received over the network will be stored
    DcmDataset *dset = dcmff.getDataset();
    
    // if opt_bitPreserving is set, the user requires that the data shall be
    // written exactly as it was received. Depending on this option, function
    // DIMSE_storeProvider must be called with certain parameters.
    if (opt_bitPreserving)
    {
        cond = DIMSE_storeProvider(assoc, presID, req, imageFileName, opt_useMetaheader, NULL,
                                   storeSCPCallback, &callbackData, opt_blockMode, opt_dimse_timeout);
    }
    else
    {
        cond = DIMSE_storeProvider(assoc, presID, req, NULL, opt_useMetaheader, &dset,
                                   storeSCPCallback, &callbackData, opt_blockMode, opt_dimse_timeout);
    }
    // if some error occured, dump corresponding information and remove the outfile if necessary
    if (cond.bad())
    {
        OFString temp_str;
        DCMNET_INFO("Received Store Request: MsgID " << req->MessageID << ", ("
                    << dcmSOPClassUIDToModality(req->AffectedSOPClassUID, "OT") << ")");
        DCMNET_DEBUG("Store SCP Failed: " << cond.text());

    }
    return cond;
}

static OFCondition
subOpSCP(T_ASC_Association **subAssoc)
{
    T_DIMSE_Message msg;
    T_ASC_PresentationContextID presID;
    
    if (!ASC_dataWaiting(*subAssoc, 0)) /* just in case */
        return DIMSE_NODATAAVAILABLE;
    
    subAssociation = *subAssoc;
    OFCondition cond = DIMSE_receiveCommand(*subAssoc, opt_blockMode, opt_dimse_timeout, &presID, &msg, NULL);
    
    if (cond == EC_Normal) {
        switch (msg.CommandField)
        {
            case DIMSE_C_ECHO_RQ:
                // process C-ECHO-Request
                cond = echoSCP(*subAssoc, &msg, presID);
                break;
            case DIMSE_C_STORE_RQ:
                // process C-STORE-Request
                cond = storeSCP(*subAssoc, &msg, presID);
                break;
            default:
                OFString tempStr;
                // we cannot handle this kind of message
                cond = DIMSE_BADCOMMANDTYPE;
                
                DCMNET_INFO("Expected C-ECHO or C-STORE request but received DIMSE command 0x");
                DCMNET_DEBUG(STD_NAMESPACE hex << STD_NAMESPACE setfill('0') << STD_NAMESPACE setw(4)<< OFstatic_cast(unsigned, msg.CommandField));
                DCMNET_DEBUG(DIMSE_dumpMessage(tempStr, msg, DIMSE_INCOMING, NULL, presID));
                break;
        }
    }
    
    /* clean up on association termination */
    if (cond == DUL_PEERREQUESTEDRELEASE)
    {
        cond = ASC_acknowledgeRelease(*subAssoc);
        ASC_dropSCPAssociation(*subAssoc);
        ASC_destroyAssociation(subAssoc);
        return cond;
    }
    else if (cond != EC_Normal)
    {
        OFString temp_str;
        DCMNET_ERROR("DIMSE failure (aborting sub-association): " << DimseCondition::dump(temp_str, cond));
        /* some kind of error so abort the association */
        ASC_abortAssociation(*subAssoc);
    }
    if (cond != EC_Normal)
    {
        ASC_dropAssociation(*subAssoc);
        ASC_destroyAssociation(subAssoc);
    }
    return cond;
}

static OFCondition
acceptSubAssoc(T_ASC_Network *aNet, T_ASC_Association **assoc)
{
    const char *knownAbstractSyntaxes[] = {
        UID_VerificationSOPClass
    };
    const char *transferSyntaxes[] = { NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL };
    int numTransferSyntaxes;
    OFString temp_str;
    OFCondition cond = ASC_receiveAssociation(aNet, assoc, opt_maxPDU);
    if (cond.good())
    {
        DCMNET_INFO("Sub-Association Received");
        DCMNET_INFO("Parameters:" << OFendl << ASC_dumpParameters(temp_str, (*assoc)->params, ASC_ASSOC_RQ));
        
        switch (opt_in_networkTransferSyntax)
        {
            case EXS_LittleEndianImplicit:
                /* we only support Little Endian Implicit */
                transferSyntaxes[0] = UID_LittleEndianImplicitTransferSyntax;
                numTransferSyntaxes = 1;
                break;
            case EXS_LittleEndianExplicit:
                /* we prefer Little Endian Explicit */
                transferSyntaxes[0] = UID_LittleEndianExplicitTransferSyntax;
                transferSyntaxes[1] = UID_BigEndianExplicitTransferSyntax;
                transferSyntaxes[2] = UID_LittleEndianImplicitTransferSyntax;
                numTransferSyntaxes = 3;
                break;
            case EXS_BigEndianExplicit:
                /* we prefer Big Endian Explicit */
                transferSyntaxes[0] = UID_BigEndianExplicitTransferSyntax;
                transferSyntaxes[1] = UID_LittleEndianExplicitTransferSyntax;
                transferSyntaxes[2] = UID_LittleEndianImplicitTransferSyntax;
                numTransferSyntaxes = 3;
                break;
            case EXS_JPEGProcess14SV1TransferSyntax:
                /* we prefer JPEGLossless:Hierarchical-1stOrderPrediction (default lossless) */
                transferSyntaxes[0] = UID_JPEGProcess14SV1TransferSyntax;
                transferSyntaxes[1] = UID_LittleEndianExplicitTransferSyntax;
                transferSyntaxes[2] = UID_BigEndianExplicitTransferSyntax;
                transferSyntaxes[3] = UID_LittleEndianImplicitTransferSyntax;
                numTransferSyntaxes = 4;
                break;
            case EXS_JPEGProcess1TransferSyntax:
                /* we prefer JPEGBaseline (default lossy for 8 bit images) */
                transferSyntaxes[0] = UID_JPEGProcess1TransferSyntax;
                transferSyntaxes[1] = UID_LittleEndianExplicitTransferSyntax;
                transferSyntaxes[2] = UID_BigEndianExplicitTransferSyntax;
                transferSyntaxes[3] = UID_LittleEndianImplicitTransferSyntax;
                numTransferSyntaxes = 4;
                break;
            case EXS_JPEGProcess2_4TransferSyntax:
                /* we prefer JPEGExtended (default lossy for 12 bit images) */
                transferSyntaxes[0] = UID_JPEGProcess2_4TransferSyntax;
                transferSyntaxes[1] = UID_LittleEndianExplicitTransferSyntax;
                transferSyntaxes[2] = UID_BigEndianExplicitTransferSyntax;
                transferSyntaxes[3] = UID_LittleEndianImplicitTransferSyntax;
                numTransferSyntaxes = 4;
                break;
            case EXS_JPEG2000LosslessOnly:
                /* we prefer JPEG2000 Lossless */
                transferSyntaxes[0] = UID_JPEG2000LosslessOnlyTransferSyntax;
                transferSyntaxes[1] = UID_LittleEndianExplicitTransferSyntax;
                transferSyntaxes[2] = UID_BigEndianExplicitTransferSyntax;
                transferSyntaxes[3] = UID_LittleEndianImplicitTransferSyntax;
                numTransferSyntaxes = 4;
                break;
            case EXS_JPEG2000:
                /* we prefer JPEG2000 Lossy */
                transferSyntaxes[0] = UID_JPEG2000TransferSyntax;
                transferSyntaxes[1] = UID_LittleEndianExplicitTransferSyntax;
                transferSyntaxes[2] = UID_BigEndianExplicitTransferSyntax;
                transferSyntaxes[3] = UID_LittleEndianImplicitTransferSyntax;
                numTransferSyntaxes = 4;
                break;
            case EXS_JPEGLSLossless:
                /* we prefer JPEG-LS Lossless */
                transferSyntaxes[0] = UID_JPEGLSLosslessTransferSyntax;
                transferSyntaxes[1] = UID_LittleEndianExplicitTransferSyntax;
                transferSyntaxes[2] = UID_BigEndianExplicitTransferSyntax;
                transferSyntaxes[3] = UID_LittleEndianImplicitTransferSyntax;
                numTransferSyntaxes = 4;
                break;
            case EXS_JPEGLSLossy:
                /* we prefer JPEG-LS Lossy */
                transferSyntaxes[0] = UID_JPEGLSLossyTransferSyntax;
                transferSyntaxes[1] = UID_LittleEndianExplicitTransferSyntax;
                transferSyntaxes[2] = UID_BigEndianExplicitTransferSyntax;
                transferSyntaxes[3] = UID_LittleEndianImplicitTransferSyntax;
                numTransferSyntaxes = 4;
                break;
            case EXS_MPEG2MainProfileAtMainLevel:
                /* we prefer MPEG2 MP@ML */
                transferSyntaxes[0] = UID_MPEG2MainProfileAtMainLevelTransferSyntax;
                transferSyntaxes[1] = UID_LittleEndianExplicitTransferSyntax;
                transferSyntaxes[2] = UID_BigEndianExplicitTransferSyntax;
                transferSyntaxes[3] = UID_LittleEndianImplicitTransferSyntax;
                numTransferSyntaxes = 4;
                break;
            case EXS_MPEG2MainProfileAtHighLevel:
                /* we prefer MPEG2 MP@HL */
                transferSyntaxes[0] = UID_MPEG2MainProfileAtHighLevelTransferSyntax;
                transferSyntaxes[1] = UID_LittleEndianExplicitTransferSyntax;
                transferSyntaxes[2] = UID_BigEndianExplicitTransferSyntax;
                transferSyntaxes[3] = UID_LittleEndianImplicitTransferSyntax;
                numTransferSyntaxes = 4;
                break;
            case EXS_RLELossless:
                /* we prefer RLE Lossless */
                transferSyntaxes[0] = UID_RLELosslessTransferSyntax;
                transferSyntaxes[1] = UID_LittleEndianExplicitTransferSyntax;
                transferSyntaxes[2] = UID_BigEndianExplicitTransferSyntax;
                transferSyntaxes[3] = UID_LittleEndianImplicitTransferSyntax;
                numTransferSyntaxes = 4;
                break;
#ifdef WITH_ZLIB
            case EXS_DeflatedLittleEndianExplicit:
                /* we prefer Deflated Explicit VR Little Endian */
                transferSyntaxes[0] = UID_DeflatedExplicitVRLittleEndianTransferSyntax;
                transferSyntaxes[1] = UID_LittleEndianExplicitTransferSyntax;
                transferSyntaxes[2] = UID_BigEndianExplicitTransferSyntax;
                transferSyntaxes[3] = UID_LittleEndianImplicitTransferSyntax;
                numTransferSyntaxes = 4;
                break;
#endif
            default:
                if (opt_acceptAllXfers)
                {
                    /* we accept all supported transfer syntaxes
                     * (similar to "AnyTransferSyntax" in "storescp.cfg")
                     */
                    transferSyntaxes[0] = UID_JPEG2000TransferSyntax;
                    transferSyntaxes[1] = UID_JPEG2000LosslessOnlyTransferSyntax;
                    transferSyntaxes[2] = UID_JPEGProcess2_4TransferSyntax;
                    transferSyntaxes[3] = UID_JPEGProcess1TransferSyntax;
                    transferSyntaxes[4] = UID_JPEGProcess14SV1TransferSyntax;
                    transferSyntaxes[5] = UID_JPEGLSLossyTransferSyntax;
                    transferSyntaxes[6] = UID_JPEGLSLosslessTransferSyntax;
                    transferSyntaxes[7] = UID_RLELosslessTransferSyntax;
                    transferSyntaxes[8] = UID_MPEG2MainProfileAtMainLevelTransferSyntax;
                    transferSyntaxes[9] = UID_MPEG2MainProfileAtHighLevelTransferSyntax;
                    transferSyntaxes[10] = UID_DeflatedExplicitVRLittleEndianTransferSyntax;
                    if (gLocalByteOrder == EBO_LittleEndian)
                    {
                        transferSyntaxes[11] = UID_LittleEndianExplicitTransferSyntax;
                        transferSyntaxes[12] = UID_BigEndianExplicitTransferSyntax;
                    } else {
                        transferSyntaxes[11] = UID_BigEndianExplicitTransferSyntax;
                        transferSyntaxes[12] = UID_LittleEndianExplicitTransferSyntax;
                    }
                    transferSyntaxes[13] = UID_LittleEndianImplicitTransferSyntax;
                    numTransferSyntaxes = 14;
                } else {
                    /* We prefer explicit transfer syntaxes.
                     * If we are running on a Little Endian machine we prefer
                     * LittleEndianExplicitTransferSyntax to BigEndianTransferSyntax.
                     */
                    if (gLocalByteOrder == EBO_LittleEndian)  /* defined in dcxfer.h */
                    {
                        transferSyntaxes[0] = UID_LittleEndianExplicitTransferSyntax;
                        transferSyntaxes[1] = UID_BigEndianExplicitTransferSyntax;
                    } else {
                        transferSyntaxes[0] = UID_BigEndianExplicitTransferSyntax;
                        transferSyntaxes[1] = UID_LittleEndianExplicitTransferSyntax;
                    }
                    transferSyntaxes[2] = UID_LittleEndianImplicitTransferSyntax;
                    numTransferSyntaxes = 3;
                }
                break;
                
        }
        
        /* accept the Verification SOP Class if presented */
        cond = ASC_acceptContextsWithPreferredTransferSyntaxes(
                                                               (*assoc)->params,
                                                               knownAbstractSyntaxes, DIM_OF(knownAbstractSyntaxes),
                                                               transferSyntaxes, numTransferSyntaxes);
        
        if (cond.good())
        {
            /* the array of Storage SOP Class UIDs comes from dcuid.h */
            cond = ASC_acceptContextsWithPreferredTransferSyntaxes(
                                                                   (*assoc)->params,
                                                                   dcmAllStorageSOPClassUIDs, numberOfAllDcmStorageSOPClassUIDs,
                                                                   transferSyntaxes, numTransferSyntaxes);
        }
    }
    
    if (cond.good())
        cond = ASC_acknowledgeAssociation(*assoc);
    if (cond.good())
    {
        DCMNET_INFO("Sub-Association Acknowledged (Max Send PDV: " << OFendl << (*assoc)->sendPDVLength << ")");
        DCMNET_INFO("(but no valid presentation contexts)" << OFendl << ASC_dumpParameters(temp_str, (*assoc)->params, ASC_ASSOC_AC));
        
        if (ASC_countAcceptedPresentationContexts((*assoc)->params) == 0){
            DCMNET_INFO(ASC_dumpParameters(temp_str, (*assoc)->params, ASC_ASSOC_AC));
        }
    }
    else
    {
        std::cout << DimseCondition::dump(temp_str, cond) << OFendl;
        ASC_dropAssociation(*assoc);
        ASC_destroyAssociation(assoc);
    }

    return cond;
}



static void
moveCallback(void *callbackData, T_DIMSE_C_MoveRQ *request,
             int responseCount, T_DIMSE_C_MoveRSP *response)
{
    OFCondition cond = EC_Normal;
    MyCallbackInfo *myCallbackData;
    
    myCallbackData = OFstatic_cast(MyCallbackInfo*, callbackData);
    
    OFString temp_str;
    DCMNET_DEBUG("Move Response " << responseCount << ":" << OFendl << DIMSE_dumpMessage(temp_str, *response, DIMSE_INCOMING));
    
    /* should we send a cancel back ?? */
    if (opt_cancelAfterNResponses == responseCount) {
        std::cout << "Sending Cancel Request: MsgID " << request->MessageID
        << ", PresID " << myCallbackData->presId << OFendl;
        cond = DIMSE_sendCancelRequest(myCallbackData->assoc,
                                       myCallbackData->presId, request->MessageID);
        if (cond != EC_Normal) {
            std::cout << "Cancel Request Failed: " << DimseCondition::dump(temp_str, cond) << OFendl;
        }
    }
}


static void
substituteOverrideKeys(DcmDataset *dset)
{
    if (overrideKeys == NULL) {
        return; /* nothing to do */
    }
    
    /* copy the override keys */
    DcmDataset keys(*overrideKeys);
    
    /* put the override keys into dset replacing existing tags */
    unsigned long elemCount = keys.card();
    for (unsigned long i = 0; i < elemCount; i++) {
        DcmElement *elem = keys.remove(OFstatic_cast(unsigned long, 0));
        
        dset->insert(elem, OFTrue);
    }
}

static  OFCondition moveSCU(T_ASC_Association * associ)
{
    T_ASC_PresentationContextID presId;
    T_DIMSE_C_MoveRQ    req;
    T_DIMSE_C_MoveRSP   rsp;
    DIC_US              msgId = associ->nextMsgID++;
    DcmDataset          *rspIds = NULL;
    const char          *sopClass;
    DcmDataset          *statusDetail = NULL;
    MyCallbackInfo      callbackData;
    
    DcmFileFormat dcmff;
    
    /* replace specific keys by those in overrideKeys */
    substituteOverrideKeys(dcmff.getDataset());
    
    sopClass = querySyntax[opt_queryModel].moveSyntax;
    
    // which presentation context should be used
    presId = ASC_findAcceptedPresentationContextID(associ, sopClass);
    if (presId == 0) return DIMSE_NOVALIDPRESENTATIONCONTEXTID;
    
    DCMNET_INFO("Sending Move Request: MsgID " << msgId);
    
    callbackData.assoc = associ;
    callbackData.presId = presId;
    
    req.MessageID = msgId;
    strcpy(req.AffectedSOPClassUID, sopClass);
    req.Priority = DIMSE_PRIORITY_LOW;
    req.DataSetType = DIMSE_DATASET_PRESENT;
    if (opt_moveDestination == NULL) {
        // set the destination to be me
        ASC_getAPTitles(associ->params, req.MoveDestination,
                        NULL, NULL);
    }
    else {
        strcpy(req.MoveDestination, opt_moveDestination);
    }
    
    OFCondition cond = DIMSE_moveUser(associ, presId, &req, dcmff.getDataset(),
                                      moveCallback, &callbackData, opt_blockMode, opt_dimse_timeout, net, subOpCallback,
                                      NULL, &rsp, &statusDetail, &rspIds, opt_ignorePendingDatasets);
    
    if (cond == EC_Normal) {
        OFString temp_str;
        DCMNET_DEBUG("DIMSE_dumpMessage");
        std::cout << DIMSE_dumpMessage(temp_str, rsp, DIMSE_INCOMING) << OFendl;
        if (rspIds != NULL) {
            DCMNET_DEBUG("Response Identifiers:" << OFendl << DcmObject::PrintHelper(*rspIds) );
        }
    }else{
        OFString temp_str;
        DCMNET_ERROR("Move Request Failed: " << DimseCondition::dump(temp_str, cond));
    }
    if (statusDetail != NULL)
    {
        DCMNET_DEBUG("Status Detail:" << OFendl << DcmObject::PrintHelper(*statusDetail));
        delete statusDetail;
        errorString = @"Error connecting to Remote AE";
    }
    
    if (rspIds != NULL)
        delete rspIds;
    
    dcmff.clear();
    return cond;
}

/*
 ** We prefer to use Explicitly encoded transfer syntaxes.
 ** If we are running on a Little Endian machine we prefer
 ** LittleEndianExplicitTransferSyntax to BigEndianTransferSyntax.
 ** Some SCP implementations will just select the first transfer
 ** syntax they support (this is not part of the standard) so
 ** organise the proposed transfer syntaxes to take advantage
 ** of such behaviour.
 **
 ** The presentation contexts proposed here are only used for
 ** C-FIND and C-MOVE, so there is no need to support compressed
 ** transmission.
 */

static OFCondition
addPresentationContext(T_ASC_Parameters *params,
                       T_ASC_PresentationContextID pid,
                       const char* abstractSyntax)
{
    const char* transferSyntaxes[] = { NULL, NULL, NULL };
    int numTransferSyntaxes = 0;
    
    switch (opt_out_networkTransferSyntax) {
        case EXS_LittleEndianImplicit:
            /* we only support Little Endian Implicit */
            transferSyntaxes[0] = UID_LittleEndianImplicitTransferSyntax;
            numTransferSyntaxes = 1;
            break;
        case EXS_LittleEndianExplicit:
            /* we prefer Little Endian Explicit */
            transferSyntaxes[0] = UID_LittleEndianExplicitTransferSyntax;
            transferSyntaxes[1] = UID_BigEndianExplicitTransferSyntax;
            transferSyntaxes[2] = UID_LittleEndianImplicitTransferSyntax;
            numTransferSyntaxes = 3;
            break;
        case EXS_BigEndianExplicit:
            /* we prefer Big Endian Explicit */
            transferSyntaxes[0] = UID_BigEndianExplicitTransferSyntax;
            transferSyntaxes[1] = UID_LittleEndianExplicitTransferSyntax;
            transferSyntaxes[2] = UID_LittleEndianImplicitTransferSyntax;
            numTransferSyntaxes = 3;
            break;
        default:
            /* We prefer explicit transfer syntaxes.
             * If we are running on a Little Endian machine we prefer
             * LittleEndianExplicitTransferSyntax to BigEndianTransferSyntax.
             */
            if (gLocalByteOrder == EBO_LittleEndian)  /* defined in dcxfer.h */
            {
                transferSyntaxes[0] = UID_LittleEndianExplicitTransferSyntax;
                transferSyntaxes[1] = UID_BigEndianExplicitTransferSyntax;
            }
            else {
                transferSyntaxes[0] = UID_BigEndianExplicitTransferSyntax;
                transferSyntaxes[1] = UID_LittleEndianExplicitTransferSyntax;
            }
            transferSyntaxes[2] = UID_LittleEndianImplicitTransferSyntax;
            numTransferSyntaxes = 3;
            break;
    }
    
    return ASC_addPresentationContext(
                                      params, pid, abstractSyntax,
                                      transferSyntaxes, numTransferSyntaxes);
}

void addElement(Uint16 g, Uint16 e, string valStr)
{
    char msg[100];
    DcmTag tag(g, e);
    if (tag.error() != EC_Normal) {
        OFString temp_str;
        DCMNET_ERROR("unknown tag: " << DimseCondition::dump(temp_str, tag.error()));
        sprintf(msg, "unknown tag: (%04x,%04x)", g, e);
        std::cout << msg << OFendl;
    }
    
    DcmElement *elem = newDicomElement(tag);
    if (elem == NULL) {
        sprintf(msg, "cannot create element for tag: (%04x,%04x)", g, e);
        std::cout << msg << OFendl;
    }
    if (valStr.length() > 0) {
        if (elem->putString(valStr.c_str()).bad())
        {
            std::string msgString;
            sprintf(msg, "cannot put tag value: (%04x,%04x)=\"", g, e);
            msgString = msg;
            msgString += valStr;
            msgString += "\"";
            std::cout << msgString << OFendl;
        }
    }
    
    if (overrideKeys->insert(elem, OFTrue).bad()) {
        sprintf(msg, "cannot insert tag: (%04x,%04x)", g, e);
        std::cout << msg << OFendl;
    }
}

void fillParameters(const char *instanceId)
{
    if (overrideKeys != NULL){
        delete overrideKeys;
    }
    overrideKeys = new DcmDataset;
    
    addElement(0x0008, 0x0052, "IMAGE");
    addElement(0x0008, 0x0018, instanceId);
    
}

+(void)closeAssociation
{
    @autoreleasepool {
        id deleteBlock = ^{
            NSLog(@"Closing Operation");
        };
        if (downloadOperation != nil)
        {
            NSBlockOperation *deleteOperation = [[NSBlockOperation alloc] init];
            [deleteOperation addExecutionBlock:deleteBlock];
            [deleteOperation addDependency:downloadOperation];
            [downloadQueue addOperation:deleteOperation];
            [downloadOperation cancel];
        }
    }

}

+ (void) retrieveFile:(NSString*)instanceID filePath:(NSString*)path PACSConnection:(ServerConfigurationModule *)configureInfoObject success:(void(^)(NSMutableArray *result))success failure:(void(^)(NSError *error))failure
{
    if (downloadOperation)
    {
        NSError *error = [NSError errorWithDomain:@"UNO3" code:EPERM userInfo:@{                                                             NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Download in progress"]}];
        failure(error);
        return;
    }
    downloadQueue = [[NSOperationQueue alloc] init];
    downloadQueue.maxConcurrentOperationCount = 1;
    NSBlockOperation *operation = [[NSBlockOperation alloc] init];
    __weak typeof (self) weakSelf = self;
    __weak NSBlockOperation *weakOperation = operation;
    id semaphore = dispatch_semaphore_create(0);
    id executionBlock = ^{
        [weakSelf retrieveFile:instanceID filePath:path PACSConnection:configureInfoObject operation:weakOperation success:^(NSMutableArray *result) {
            //success block
             downloadOperation = nil;
            success(result);
            dispatch_semaphore_signal(semaphore);
        } failure:^(NSError *error) {
            //failure block
             downloadOperation = nil;
            failure(error);
            dispatch_semaphore_signal(semaphore);
        }];
    };
    
    [operation addExecutionBlock:executionBlock];
    operation.completionBlock = ^{
        downloadOperation = nil;
        dispatch_semaphore_signal(semaphore);
    };
    downloadOperation = operation;
    [downloadQueue addOperation:downloadOperation];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
}


+ (void) retrieveFile:(NSString*)instanceID filePath:(NSString*)path PACSConnection:(ServerConfigurationModule *)configureInfoObject operation:(__weak NSBlockOperation *)weakOperation success:(void(^)(NSMutableArray *result))success failure:(void(^)(NSError *error))failure;
{
    
    @autoreleasepool {
        
        if (configureInfoObject == nil) {
            failure([NSError errorWithDomain:@"UNO3" code:EPERM userInfo:@{
                                                                           NSLocalizedDescriptionKey:@"PACS needs to be configured correctly"
                                                                           }]);
            return;
        }

        
        NSError *operationError = [NSError errorWithDomain:@"UNO3"
                                               code:EPERM
                                           userInfo:@{
                                                      NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Download cancelled"]
                                                      }];
        
        if (weakOperation.cancelled) {
            failure(operationError);
            return;
        }
        //filling the AETittles
        opt_peer = [configureInfoObject.calledIP UTF8String];
        opt_port = [configureInfoObject.port intValue];
        opt_peerTitle = [configureInfoObject.calledAE UTF8String];
        opt_ourTitle = [configureInfoObject.callingAE UTF8String];
        opt_moveDestination = [configureInfoObject.callingAE UTF8String];
        local_port = [configureInfoObject.callingPort intValue];
        
        T_ASC_Parameters *params = NULL;
//        DIC_NODENAME localHost;
//        DIC_NODENAME peerHost;
        subAssociation = NULL;
        T_ASC_Association *assoc = NULL;
        
#ifdef HAVE_GUSI_H
        /* needed for Macintosh */
        GUSISetup(GUSIwithSIOUXSockets);
        GUSISetup(GUSIwithInternetSockets);
#endif
        
#ifdef HAVE_WINSOCK_H
        WSAData winSockData;
        /* we need at least version 1.1 */
        WORD winSockVersionNeeded = MAKEWORD(1, 1);
        WSAStartup(winSockVersionNeeded, &winSockData);
#endif
        /* network for move request and responses */
        T_ASC_NetworkRole role = NET_ACCEPTORREQUESTOR;
        dcmConnectionTimeout.set(opt_acse_timeout);
        OFCondition cond = ASC_initializeNetwork(role, static_cast<int>(local_port), opt_acse_timeout, &net);
        if (cond.bad())
        {
            std::cout << "cannot create network: " << cond.text() << OFendl;
            failure([NSError errorWithDomain:@"UNO3"
                                        code:EPERM
                                    userInfo:@{
                                               NSLocalizedDescriptionKey:[NSString stringWithFormat:@"cannot create network : %s", cond.text()]
                                               }]);
            return;
        }
        
        if (weakOperation.cancelled)
        {
            if (net)
                ASC_dropNetwork(&net);
            failure(operationError);
            return;
        }
        
        /* set up main association */
        cond = ASC_createAssociationParameters(&params, opt_maxPDU);
        if (cond.bad()) {
            std::cout << cond.text() << OFendl;
            
            failure([NSError errorWithDomain:@"UNO3"
                                        code:EPERM
                                    userInfo:@{
                                               NSLocalizedDescriptionKey:[NSString stringWithFormat:@"cannot associate with network : %s", cond.text()]
                                               }]);
            
            // exit(1);
            return;
        }
        
        ASC_setAPTitles(params, opt_ourTitle, opt_peerTitle, NULL);
        
        //gethostname(localHost, sizeof(localHost) - 1);
        //sprintf(peerHost, "%s:%d", opt_peer, OFstatic_cast(int, opt_port));
        ASC_setPresentationAddresses(params, [configureInfoObject.callingIP UTF8String], [configureInfoObject.serverIP UTF8String]);
        
        /*
         * We also add a presentation context for the corresponding
         * find sop class.
         */
        cond = addPresentationContext(params, 1,
                                      querySyntax[opt_queryModel].findSyntax);
        
        cond = addPresentationContext(params, 3,
                                      querySyntax[opt_queryModel].moveSyntax);
        if (cond.bad()) {
            std::cout << cond.text() << OFendl;
            ASC_dropNetwork(&net);
            failure([NSError errorWithDomain:@"UNO3"
                                        code:EPERM
                                    userInfo:@{
                                               NSLocalizedDescriptionKey:[NSString stringWithFormat:@"cannot create network : %s", cond.text()]
                                               }]);
            return;
        }
        
        if (weakOperation.cancelled) {
            ASC_dropNetwork(&net);
            failure(operationError);
            return;
        }
        
        DCMNET_INFO("Requesting Association");

        /* create association */
        cond = ASC_requestAssociation(net, params, &assoc);
        if (cond.bad()) {
            if (cond == DUL_ASSOCIATIONREJECTED) {
                T_ASC_RejectParameters rej;
                
                ASC_getRejectParameters(params, &rej);
                std::cout << "Association Rejected:" << OFendl;
                ASC_dropNetwork(&net);
                failure([NSError errorWithDomain:@"UNO3"
                                            code:EPERM
                                        userInfo:@{
                                                   NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Association rejected : %s", cond.text()]
                                                   }]);
                return;
            }
            else {
                std::cout << "Association Request Failed:" << OFendl;;
                std::cout << cond.text() << OFendl;
                ASC_dropNetwork(&net);
                failure([NSError errorWithDomain:@"UNO3"
                                            code:EPERM
                                        userInfo:@{
                                                   NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Association Request Failed : %s", cond.text()]
                                                   }]);
                return;
            }
        }
        
        /* what has been accepted/refused ? */
        DCMNET_INFO("Association Parameters Negotiated");
        
        if (ASC_countAcceptedPresentationContexts(params) == 0) {
            ASC_dropNetwork(&net);
            std::cout << "No Acceptable Presentation Contexts";
            failure([NSError errorWithDomain:@"UNO3"
                                        code:EPERM
                                    userInfo:@{
                                               NSLocalizedDescriptionKey:[NSString stringWithFormat:@"No Acceptable Presentation Contexts : %s", cond.text()]
                                               }]);
            return;
        }
        
        if (weakOperation.cancelled) {
            ASC_dropNetwork(&net);
            failure(operationError);
            return;
        }
        DCMNET_INFO("Association Accepted (Max Send PDV: " << assoc->sendPDVLength << ")");

        // Fill parameters
        fillParameters([instanceID UTF8String]);
        filePath = path;
        
        /* do the real work */
        cond = EC_Normal;
        cond = moveSCU(assoc);
        
        if (weakOperation.cancelled)
        {
            cond = ASC_dropNetwork(&net);
            failure(operationError);
            return;
        }
        
        /* tear down association */
        if (cond == EC_Normal)
        {
            /* release association */
            std::cout << "Releasing Association" << OFendl;
            cond = ASC_releaseAssociation(assoc);
            if (cond.bad())
            {
                std::cout << "Association Release Failed:" << OFendl;
                std::cout << cond.text() << OFendl;
            }
        }
        else if (cond == DUL_PEERREQUESTEDRELEASE)
        {
            std::cout << "Protocol Error: Peer requested release (Aborting)" << OFendl;
            std::cout << "Aborting Association" << OFendl;
            cond = ASC_abortAssociation(assoc);
            if (cond.bad()) {
                std::cout << "Association Abort Failed: " << cond.text() << OFendl;
                // exit(1);
            }
        }
        else if (cond == DUL_PEERABORTEDASSOCIATION)
        {
            std::cout << "Peer Aborted Association" << OFendl;
        }
        else
        {
            DCMNET_DEBUG("Move SCU Failed: " << cond.text());
            DCMNET_INFO("Aborting Association");
//           OFCondition condition = ASC_abortAssociation(assoc);
            if (cond.bad()) {
                OFString temp_str;
                DCMNET_ERROR("DIMSE failure (aborting association): " << DimseCondition::dump(temp_str, cond));
            }
        }
        
        ASC_destroyAssociation(&assoc);
        ASC_dropNetwork(&net);
        
#ifdef HAVE_WINSOCK_H
        WSACleanup();
#endif
        
        if (listofImages.count > 0)
        {
            success(listofImages);
        }
        else
        {
            failure([NSError errorWithDomain:@"UNO3"
                                        code:EPERM
                                    userInfo:@{
                                               NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Move request failed : %@",errorString]
                                               }]);
        }
        if (subAssociation)
        {
            subAssociation = NULL;
        }
    }
}

@end

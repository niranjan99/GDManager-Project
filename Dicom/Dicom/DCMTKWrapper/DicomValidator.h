//
//  DicomValidator.h
//  Dicom
//
//  Created by Aina on 24/10/18.
//  Copyright © 2018 Carl Zeiss Meditec. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kPatientNameMaxLimit 64

@interface DicomValidator : NSObject{
    
}

typedef enum  {
    VRKeyModality,
    VRKeyDate,
    VRKeyTime,
    VRKeyDescription,
    VRKeyCodeValue,
    VRKeyCodeMeaning,
    VRKeyCodingSchemeDesignator,
    VRKeyCodingSchemeVersion,
    VRKeyScheduledProcedureStepID,
    VRKeyRequestedProcedureID,
    VRKeyUniqueId,
    VRKeyUniqueIdNotEmpty,
    VRKeyAccessionNumber,
    VRKeyPersonName,
    VRKeyPatientID,
    VRKeyPatientsex,
    VRKeyNotEmpty,
    VRKeyComments,
    VRKeyIssuerOfPatientID,
    VRKeyOtherPatientIDs,
    VRKeyPatientEthnicGroup
} VRKey;

+(BOOL)validateVRFor:(NSString*)value forKey:(VRKey)keyName;
@end

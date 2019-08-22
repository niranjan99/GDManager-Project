//
//  DicomValidator.m
//  Dicom
//
//  Created by Aina on 24/10/18.
//  Copyright © 2018 Carl Zeiss Meditec. All rights reserved.
//

#import "DicomValidator.h"


@implementation DicomValidator

//VR(Value Representations)
NSString* const CS     = @"[A-Z0-9_ ]{0,16}";//@"[A-Z0-9_ \\*\\?]{0,16}"
NSString* const CSNE   = @"[A-Z0-9_ ]{1,16}";//@"[A-Z0-9_ \\*\\?]{1,16}"
NSString* const AE     = @"[ -\\[\\]-~]{1,16}";
NSString* const DA     = @"\\d{8}";//"\\d{4}\\d{2}\\d{2}";
NSString* const TM     = @"\\d{6}(\\.\\d{1,6})?";//"\\d{2}:\\d{2}:\\d{2}(\\.\\d{1,6})?";

NSString* const PN     = @"[ -~\\x1b]{0,64}";//@"[^\\n\\r\\t\\\\\\^=]{0,64}"
NSString* const PNNE   = @"[ -~\\x1b]{1,64}";//@"[^\\n\\r\\t\\\\\\^=]{1,64}"

NSString* const LO     = @"[ -\\[\\]-~\\x1b]{0,64}";//@"[^\\n\\r\\t\\\\]{0,64}"
NSString* const LONE   = @"[ -\\[\\]-~\\x1b]{1,64}";//@"[^\\n\\r\\t\\\\]{1,64}"
NSString* const SH     = @"[ -\\[\\]-~\\x1b]{0,16}";//@"[^\\n\\r\\t\\\\]{0,16}"
NSString* const SHNE   = @"[ -\\[\\]-~\\x1b]{1,16}";//@"[^\\n\\r\\t\\\\]{1,16}"
NSString* const UI     = @"[[0-9]+(\\.[0-9]+)+]{0,64}";
NSString* const UINE   = @"[[0-9]+(\\.[0-9]+)+]{1,64}";
NSString* const LT     = @"[ -~\\r\\n\\f\\x1b]{1,10240}";//@"[^\\n\\r\\t\\\\]{1,10240}"



+(BOOL)validateVRFor:(NSString*)value forKey:(VRKey)keyName {
    
    NSDictionary *vrDict = @{
                              [NSNumber numberWithInt:VRKeyModality]: CS,
                              [NSNumber numberWithInt:VRKeyDate]: DA,
                              [NSNumber numberWithInt:VRKeyTime]: TM,
                              [NSNumber numberWithInt:VRKeyDescription]: LO,
                              [NSNumber numberWithInt:VRKeyCodeValue]: SHNE,
                              [NSNumber numberWithInt:VRKeyCodeMeaning]: LO,
                              [NSNumber numberWithInt:VRKeyCodingSchemeDesignator]: SHNE,
                              [NSNumber numberWithInt:VRKeyCodingSchemeVersion]: SH,
                              [NSNumber numberWithInt:VRKeyScheduledProcedureStepID]: SHNE,
                              [NSNumber numberWithInt:VRKeyRequestedProcedureID]: SHNE,
                              [NSNumber numberWithInt:VRKeyUniqueId]: UI,
                              [NSNumber numberWithInt:VRKeyUniqueIdNotEmpty]: UINE,
                              [NSNumber numberWithInt:VRKeyAccessionNumber]: SHNE,
                              [NSNumber numberWithInt:VRKeyPersonName]: PN,
                              [NSNumber numberWithInt:VRKeyPatientID]: LONE,
                              [NSNumber numberWithInt:VRKeyPatientsex]: CS,
                              [NSNumber numberWithInt:VRKeyNotEmpty]: PNNE,
                              [NSNumber numberWithInt:VRKeyComments]: LT,
                              [NSNumber numberWithInt:VRKeyIssuerOfPatientID]: LO,
                              [NSNumber numberWithInt:VRKeyOtherPatientIDs]: LO,
                              [NSNumber numberWithInt:VRKeyPatientEthnicGroup]: SH
                              };
        
    //NSString *vr = vrDict[[NSNumber numberWithInt:keyName]];
    /*if ([vr containsString:@"\\n"] || [vr containsString:@"\\r"] || [vr containsString:@"\\t"] || [vr containsString:@"\\\\"]) {
        value = [self filterSpecificControlCharactersFrom:value];
    }*/
    
//    if (keyName == VRKeyComments) {
//        value = [self filterSpecificControlCharactersFrom:value];
//    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",vrDict[[NSNumber numberWithInt:keyName]]];
    Boolean status = true;
    if (keyName == VRKeyPersonName) {
        status = [self isValidPatientName: value];
    } else {
        status = [predicate evaluateWithObject:value];
    }
    return status;
}

+(BOOL)isValidPatientName:(NSString*)value {
    BOOL componentStatus = YES;
    BOOL subComponentStatus = YES;
    BOOL isFirstNLastNamesPresent = NO;
    NSArray *nameComponents = [value componentsSeparatedByString:@"="]; //3 component groups - alphabetical, ideographic, phonetic
    for (NSString* component in nameComponents) {        
        if (component.length > 0 && component.length <= kPatientNameMaxLimit) {
            NSArray<NSString*> *nameSubcomponents = [component componentsSeparatedByString:@"^"];
            if (nameSubcomponents.count > 1) {
                if (isFirstNLastNamesPresent != YES && nameSubcomponents[0].length > 0 && nameSubcomponents[1].length > 0) { //0 is last name, 1 is first name
                    isFirstNLastNamesPresent = YES;
                }
            }
            for (int i = 0; i<nameSubcomponents.count; i++) {
                NSPredicate *subPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",PN];
                subComponentStatus = subComponentStatus && [subPredicate evaluateWithObject:nameSubcomponents[i]];
            }
        }
        else {
            if (component.length > kPatientNameMaxLimit) {
                componentStatus = NO;
            }
        }
    }
    return componentStatus && subComponentStatus && isFirstNLastNamesPresent;
}

+ (NSString*)filterSpecificControlCharactersFrom:(NSString *)value {
    NSString *filteredValue = value;
    filteredValue = [filteredValue stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    filteredValue = [filteredValue stringByReplacingOccurrencesOfString:@"\\n" withString:@""];
    filteredValue = [filteredValue stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    filteredValue = [filteredValue stringByReplacingOccurrencesOfString:@"\\r" withString:@""];
    filteredValue = [filteredValue stringByReplacingOccurrencesOfString:@"\t" withString:@""];
    filteredValue = [filteredValue stringByReplacingOccurrencesOfString:@"\\t" withString:@""];
    filteredValue = [filteredValue stringByReplacingOccurrencesOfString:@"\\" withString:@""];
    filteredValue = [filteredValue stringByReplacingOccurrencesOfString:@"\\\\" withString:@""];
    return filteredValue;
}

@end

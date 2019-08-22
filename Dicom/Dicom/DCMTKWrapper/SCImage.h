//
//  SCStore.h
//  Dicom
//
//  Created by Sankar Dhekshit on 16/02/16.
//  Copyright © 2016 Carl Zeiss Meditec. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DicomObject.h"
#include <UIKit/UIKit.h>
#import "Patient.h"

@interface SCImage : DicomObject

/**
 Creates a dcm file with given information
 @param patientModule of type Patient
 @param Media dcmFilePath of type NSString
 @param success response during success
 @param failure response during failure
 */
+(void)createDicom:(Patient *)patientModule mediaPath:(FileDetails*)Media dcmFilePath:(NSString *)dcmFilePath mediaType:(NSString*)mediaType success:(void(^)(NSString *result))success failure:(void(^)(NSError *error))failure;

@end

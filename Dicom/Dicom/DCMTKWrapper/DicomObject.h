//
//  DicomObjects.h
//  Dicom
//
//  Created by Bankim Debnath on 29/02/16.
//  Copyright © 2016 Carl Zeiss Meditec. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <UIKit/UIKit.h>
#import "Patient.h"

@interface DicomObject : NSObject
/**
 @brief It creates dicom file with image or video and store it localy
 
 @param patientData captureing the all basic patient information data/value. mediaPath capturing the local media path. dcmFilePath capturing dcm file path and mediaType capturing the type of media file.
 
 @return String as success or error message.
 
 */
+(void)createDicom:(Patient *)patientModule mediaPath:(FileDetails*)media dcmFilePath:(NSString *)dcmFilePath mediaType:(NSString*)mediaType success:(void(^)(NSString *result))success failure:(void(^)(NSError *error))failure;

+(void)cancelDCMfileCreation;

@end

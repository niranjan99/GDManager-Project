//
//  VLVideo.h
//  Dicom
//
//  Created by Bankim Debnath on 23/02/16.
//  Copyright © 2016 Carl Zeiss Meditec. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DicomObject.h"
#include <UIKit/UIKit.h>

@interface VLVideo : DicomObject

/**
 Creates dcm file path for a video
 @param patientModule of type Patient
 @param media dcmFilePath of type FileDetails
 @param mediaType of type NSString
 @param success response during success
 @param failure response during failure
 */
+(void)createDicom:(Patient *)patientModule mediaPath:(FileDetails*)media dcmFilePath:(NSString *)dcmFilePath mediaType:(NSString*)mediaType success:(void(^)(NSString *result))success failure:(void(^)(NSError *error))failure;

@end

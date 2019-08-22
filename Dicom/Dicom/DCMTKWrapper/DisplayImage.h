//
//  DisplayImage.h
//  Dicom
//
//  Created by CARIn Lab on 06/05/16.
//  Copyright © 2016 Carl Zeiss Meditec. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <UIKit/UIKit.h>

@interface DisplayImage : NSObject

/**
 Displays image from dcm files
 @param dcmPath dcm file path   
 @param mediaPath image path
 @param imageType of type NSString
 @param success response
 @param failure response
 */
+(void)displayImage:(NSString *)dcmPath :(NSString *)mediaPath :(NSString *)imageType success:(void(^)(NSMutableArray *result))success failure:(void(^)(NSError *error))failure;

@end

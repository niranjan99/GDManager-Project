//
//  Utility.h
//  Dicom
//
//  Created by Narendra on 23/12/16.
//  Copyright © 2016 Carl Zeiss Meditec. All rights reserved.
//

#import <Foundation/Foundation.h>

 @interface Utility : NSObject
+(NSString *)getSOPInstanceUID;
+(NSString *)getStudyInstanceID;
+(NSString *)getSeriesInstanceID;
+(NSString *)getFormattedDateTime:(NSDate *)date;
+(NSString *)getValidStationName:(NSString *)station;
+(NSString *)getFormattedtimeStamp;
+(NSString *)getTimeStamp;

@end

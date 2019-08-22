//
//  Study.m
//  Dicom
//
//  Created by Sankar Dhekshit on 16/03/16.
//  Copyright © 2016 Carl Zeiss Meditec. All rights reserved.
//

#import "Study.h"
#import "Utility.h"

@implementation Study

- (id) init
{
    self = [super init];
    if (self!=nil) {
        self.Id = [Utility getTimeStamp];
//        self.instanceId = [Utility getStudyInstanceID];
        [self populateDateAndTimeWithDate:[NSDate date]];
        self.seriesNumber = 0;
        self.series = [[NSMutableArray alloc] init];
    }
    return self;
}

- (Study *)createStudyWithDescription:(NSString*)description :(NSDate*)date
{
    self.studyDescription = description;
    [self populateDateAndTimeWithDate:date];
    return self;
}

- (void)populateDateAndTimeWithDate:(NSDate*)date {
     NSDateFormatter *dateFormatter=[[NSDateFormatter alloc] init];
     NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
      dateFormatter.dateFormat = @"yyyyMMdd";
      NSTimeZone *timeZone = [NSTimeZone systemTimeZone];
      NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
      [dateFormatter setCalendar:gregorianCalendar];
      [dateFormatter setTimeZone:timeZone];
      [dateFormatter setLocale:locale];
      self.date = date;
      NSString *dateString = [dateFormatter stringFromDate:date];
      self.dateString = dateString;
      [dateFormatter setDateFormat:@"HHmmss"];
      self.timeString = [dateFormatter stringFromDate:date];
}

@end

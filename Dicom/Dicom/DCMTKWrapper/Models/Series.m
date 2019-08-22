//
//  Series.m
//  Dicom
//
//  Created by Sankar Dhekshit on 16/03/16.
//  Copyright © 2016 Carl Zeiss Meditec. All rights reserved.
//

#import "Series.h"
#import "Utility.h"

@implementation Series

- (id) init
{
    self = [super init];
    if (self!=nil) {
        
    }
    return self;
}

- (Series *)createSeriesWithDescription:(NSString*)description :(NSDate*)date
{
    self.seriesDescription = description;
    self.Id = [Utility getTimeStamp];
    
    NSDateFormatter *dateFormatter=[[NSDateFormatter alloc] init];
    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    dateFormatter.dateFormat = @"yyyyMMdd";
    NSTimeZone *timeZone = [NSTimeZone systemTimeZone];
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [dateFormatter setCalendar:gregorianCalendar];
    [dateFormatter setTimeZone:timeZone];
    [dateFormatter setLocale:locale];

    NSString *dateString = [dateFormatter stringFromDate:date];
    self.dateString = dateString;
    self.date = date;
    self.instanceId = [Utility getSeriesInstanceID];
    [dateFormatter setDateFormat:@"HHmmss"];
    self.timeString = [dateFormatter stringFromDate:date];
    self.medias = [[NSMutableArray alloc] init];
    return self;
}

@end

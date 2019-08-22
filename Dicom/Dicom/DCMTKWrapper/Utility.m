//
//  Utility.m
//  Dicom
//
//  Created by Narendra on 23/12/16.
//  Copyright © 2016 Carl Zeiss Meditec. All rights reserved.
//

#import "Utility.h"
#include <sys/socket.h>
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#import <NetworkExtension/NetworkExtension.h>

#define UID_ROOT            "1.2.276.0.75.2.7.40"
#define StudyLevel          "1"
#define SeriesLevel         "2"
#define SOPLevel            "3"
#define Algorithm_Version   "1"

#define Identifier  [NSString stringWithFormat:@"%d",arc4random_uniform(100000000)]

@implementation Utility

+(NSString *)getSOPInstanceUID;
{
    NSString *ident = [Utility getIdentifier];
    NSString *identifier =  ident ? ident : Identifier;
    identifier = [identifier stringByReplacingOccurrencesOfString:@"0" withString:@""];
    NSString *instanceId = [NSString stringWithFormat:@"%s.%s.%s.%@.%@.%d",UID_ROOT,Algorithm_Version,SOPLevel,[Utility getFormattedtimeStamp],identifier,arc4random_uniform(100000)];
    return instanceId;
}
+(NSString *)getStudyInstanceID;
{
    NSString *ident = [Utility getIdentifier];
    NSString *identifier =  ident ? ident : Identifier;
    identifier = [identifier stringByReplacingOccurrencesOfString:@"0" withString:@""];
    NSString *instanceId = [NSString stringWithFormat:@"%s.%s.%s.%@.%@.%d",UID_ROOT,Algorithm_Version,StudyLevel,[Utility getFormattedtimeStamp],identifier,arc4random_uniform(100000)];
    return instanceId;
}
+(NSString *)getSeriesInstanceID;
{
    NSString *ident = [Utility getIdentifier];
    NSString *identifier =  ident ? ident : Identifier;
    identifier = [identifier stringByReplacingOccurrencesOfString:@"0" withString:@""];
    NSString *instanceId = [NSString stringWithFormat:@"%s.%s.%s.%@.%@.%d",UID_ROOT,Algorithm_Version,SeriesLevel,[Utility getFormattedtimeStamp],identifier,arc4random_uniform(100000)];
    return instanceId;
}

+(NSString *)getFormattedtimeStamp
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.timeZone = [NSTimeZone systemTimeZone];
    dateFormatter.dateFormat = @"YYMMddHHMMSSmmm";
    NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
    return dateString;
}

+(NSString *)getFormattedDateTime:(NSDate *)date
{
    NSDateFormatter *dateFormatter=[[NSDateFormatter alloc] init];
    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    dateFormatter.dateFormat = @"YYYYMMddHHmmss";
    NSTimeZone *timeZone = [NSTimeZone systemTimeZone];
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [dateFormatter setCalendar:gregorianCalendar];
    [dateFormatter setTimeZone:timeZone];
    [dateFormatter setLocale:locale];

    NSString *dateString = [dateFormatter stringFromDate:date];
    return dateString;
}

    
+(NSString *) getTimeStamp
{
    return [NSString stringWithFormat:@"%.0f",[[NSDate date] timeIntervalSince1970] * 1000];
}

+(NSString *)getIdentifier
{
    if ([Utility getMacAddress])
    {
        NSString *identifier = nil;
        NSArray *components = [[Utility getMacAddress] componentsSeparatedByString:@":"];
        for (NSString *hex in components) {
            NSString *convertedValue = [Utility getDecimalFromHexa:hex];
            if (identifier) {
                identifier = [identifier stringByAppendingString:convertedValue];
            }else{
                identifier = [convertedValue stringByAppendingString:convertedValue];
            }
        }
        if (identifier.length > 15) {
            identifier = [identifier substringToIndex:15];
        }
        return identifier;
    }
    return nil;
}

/**
 Get decimal values from hexa
*/

+(NSString *)getDecimalFromHexa: (NSString *)hex
{
    return [NSString stringWithFormat:@"%d",(int)strtoull([hex UTF8String], NULL, 16)];
}

#pragma mark - getWifiStatus
/**
 *  Getting MACID
 *
 *  @return Returning String Value
 */

+ (NSString *)getMacAddress
{
    NSArray *interfaceNames = [self getAllWifiInterface];
    id info = nil;
    for (NSString *ifnam in interfaceNames) {
        info = [self getSSIDInfo:ifnam];
        NSString *wifilabName = [info objectForKey:@"BSSID"];
        if(wifilabName != nil){
            return wifilabName;
        }
        if (info && [info count]) { break; }
    }
    return nil;
}

+(NSDictionary *)getSSIDInfo:(NSString *)interfaceName {
    
    return CFBridgingRelease(CNCopyCurrentNetworkInfo((__bridge CFStringRef)interfaceName));
}
+(NSArray *)getAllWifiInterface
{
    return CFBridgingRelease(CNCopySupportedInterfaces());
}

+(NSString *)getValidStationName:(NSString *)station
{
    NSString * deviceName = station;
    deviceName = [deviceName stringByReplacingOccurrencesOfString:@"\\" withString:@" "];
    
    const char *deviceChar = [deviceName UTF8String];
    size_t charlength = strlen(deviceChar);
    if (charlength > 16)
    {
        char little[17] = "";
        strncpy(little,deviceChar, 16);
        little[sizeof(little)-1] = '\0';
        deviceName = [NSString stringWithFormat:@"%s",little];
    }
    return deviceName;
}

@end

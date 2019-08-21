//
//  LogCustomFormatter.m
//  UNO3_CommunicatorApp
//
//  Created by Mphasis on 19/08/17.
//  Copyright © 2017 Carl Zeiss Meditec. All rights reserved.
//

#import "LogCustomFormatter.h"
#import <libkern/OSAtomic.h>

@implementation LogCustomFormatter

- (NSString *)stringFromDate:(NSDate *)date {
    NSString *dateFormatString = @"dd-MM-yyyy-hh-mm-ss";
    int32_t loggerCount = [atomicLoggerCounter value];
    if (loggerCount <= 1) {
        // Single-threaded mode.
        
        if (threadUnsafeDateFormatter == nil) {
            threadUnsafeDateFormatter = [[NSDateFormatter alloc] init];
            [threadUnsafeDateFormatter setDateFormat:dateFormatString];
        }
        return [threadUnsafeDateFormatter stringFromDate:date];
    } else {
        // Multi-threaded mode.
        // NSDateFormatter is NOT thread-safe.
        
        NSString *key = @"MyCustomFormatter_NSDateFormatter";
        
        NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
        NSDateFormatter *dateFormatter = [threadDictionary objectForKey:key];
        
        if (dateFormatter == nil) {
            dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:dateFormatString];
            [threadDictionary setObject:dateFormatter forKey:key];
        }
        return [dateFormatter stringFromDate:date];
    }
}

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage {
    NSString *dateAndTime = [self stringFromDate:(logMessage.timestamp)];
    NSString *logMsg = logMessage->_message;
    
    for (NSNumber *context in self.whitelist) {
        if (context.integerValue == logMessage.context) {
            return [NSString stringWithFormat:@"%@ %@", dateAndTime, logMsg];
        }
    }
    return nil;
}

- (void)didAddToLogger:(id <DDLogger>)logger {
    [atomicLoggerCounter increment];
}

- (void)willRemoveFromLogger:(id <DDLogger>)logger {
     [atomicLoggerCounter decrement];
}

@end

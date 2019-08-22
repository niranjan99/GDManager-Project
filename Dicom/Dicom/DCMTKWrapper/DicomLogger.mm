//
//  ApplicationHelper.m
//  Dicom
//
//  Created by Malleswari on 10/22/18.
//  Copyright © 2018 Carl Zeiss Meditec. All rights reserved.
//

#import "DicomLogger.h"

#include "dcmtk/dcmnet/diutil.h"
#include "dcmtk/oflog/fileap.h"

#define MAX_LOGFILE_SIZE 30*1024*1024

@interface DicomLogger() {
    NSString *_logFilePath;
}
@end

@implementation DicomLogger

+ (DicomLogger*)sharedLogger
{
    //Singleton instance
    static DicomLogger *logger = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        logger = [[DicomLogger alloc] init];
    });
    
    return logger;
}

- (void)deleteOldLogFile {
    NSString *logsFilePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    logsFilePath = [logsFilePath stringByAppendingPathComponent:@"Logs/dcmtk.log"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:logsFilePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:logsFilePath error:nil];
    }
}

- (void)setupLogFiles {
    [self deleteOldLogFile];
    NSString *currentLogFilePath = [self getLatestLogFile];
    unsigned long long latestLogFileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:currentLogFilePath error:nil] fileSize];
    
    if (latestLogFileSize > MAX_LOGFILE_SIZE) {
        currentLogFilePath = [self getNewFilePathForLatestFilePath: currentLogFilePath];
    }
    if (![_logFilePath isEqualToString:currentLogFilePath]) {
        [self createLogFileAtPath: currentLogFilePath];
    }
}

- (void)createLogFileAtPath:(NSString*)logFilePath {
    /* specify log pattern */
    OFauto_ptr<log4cplus::Layout> layout(new log4cplus::PatternLayout("%D{%Y-%m-%d %H:%M:%S.%q} %5p: %m%n"));
    /* Denote that a log file should be used that is appended to. The file is re-created every */
    log4cplus::SharedAppenderPtr logfile(new log4cplus::FileAppender([logFilePath UTF8String], STD_NAMESPACE ios::app));
    
    logfile->setLayout(layout);
    /* make sure that only the file logger is used */
    log4cplus::Logger log = log4cplus::Logger::getRoot();
    log.removeAllAppenders();
    log.addAppender(logfile);
    
    log.setLogLevel([self getLogLevel:_logLevel]);
    _logFilePath = logFilePath;
    
    //log.setLogLevel(OFLogger::INFO_LOG_LEVEL);
    //log.setLogLevel(OFLogger::FATAL_LOG_LEVEL);
    //    log.setLogLevel(OFLogger::ERROR_LOG_LEVEL);
    //    log.setLogLevel(OFLogger::WARN_LOG_LEVEL);
    //    log.setLogLevel(OFLogger::DEBUG_LOG_LEVEL);
    //log.setLogLevel(OFLogger::TRACE_LOG_LEVEL);
    //}
}

- (NSString*)getLatestLogFile {
    NSString *logsPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    logsPath = [logsPath stringByAppendingPathComponent:@"Logs/dcmtk"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:logsPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:logsPath withIntermediateDirectories:true attributes:nil error:nil];
    }
    
    NSArray *docFileList = [[NSFileManager defaultManager] subpathsAtPath:logsPath];
    NSEnumerator *docEnumerator = [docFileList objectEnumerator];
    NSString *docFilePath;
    NSDate *lastModifiedDate = [NSDate dateWithTimeIntervalSince1970:0];
    NSString *lastModifiedFilePath = @"";
    int fileCount = 0;
    
    while ((docFilePath = [docEnumerator nextObject])) {
        NSString *fullPath = [logsPath stringByAppendingPathComponent:docFilePath];
        NSDictionary *fileAttributes = [[NSFileManager defaultManager]  attributesOfItemAtPath:fullPath error:nil];
        //NSDate *fileModificationDate = [fileAttributes fileModificationDate];
        NSDate *fileModificationDate = [fileAttributes fileCreationDate];
        
        if (fileCount == 0) {
            lastModifiedDate = fileModificationDate;
            lastModifiedFilePath = fullPath;
        }
        else {
            if ([fileModificationDate compare:lastModifiedDate] == NSOrderedDescending) {
                fileModificationDate = lastModifiedDate;
                lastModifiedFilePath = fullPath;
            }
        }
        fileCount++;
    }
    if ([lastModifiedFilePath isEqualToString:@""]) {
        lastModifiedFilePath = [logsPath stringByAppendingPathComponent:@"dcmtk1.log"];
    }
    return lastModifiedFilePath;
}

- (NSString*)getNewFilePathForLatestFilePath: (NSString*)latestFilePath {
    NSArray *fileComponents = [latestFilePath componentsSeparatedByString:@"/"];
    NSString *logsPath = [latestFilePath stringByReplacingOccurrencesOfString:[fileComponents objectAtIndex:fileComponents.count-1] withString:@""];
    NSString *latestFileName = [fileComponents objectAtIndex:fileComponents.count-1];
    
    NSString *numberString;
    NSScanner *scanner = [NSScanner scannerWithString:latestFileName];
    NSCharacterSet *numbers = [NSCharacterSet characterSetWithCharactersInString:@"123456789"];
    
    // Throw away characters before the first number.
    [scanner scanUpToCharactersFromSet:numbers intoString:NULL];
    
    // Collect numbers.
    [scanner scanCharactersFromSet:numbers intoString:&numberString];
    
    // Result.
    int number = [numberString intValue];
    
    if (number == 3) {
        number = 1;
    }
    else {
        number += 1;
    }
    
    NSString *newFileName = [NSString stringWithFormat:@"dcmtk%d.log",number];
    NSString *logsFilePath = [logsPath stringByAppendingPathComponent:newFileName];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:logsFilePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:logsFilePath error:nil];
    }
    return logsFilePath;
}

- (OFLogger::LogLevel)getLogLevel:(NSString*)logLevelName {
    if ([logLevelName isEqualToString: @"Exceptions"]) {
        return OFLogger::FATAL_LOG_LEVEL;
    }
    if ([logLevelName isEqualToString: @"Errors"]) {
        return OFLogger::ERROR_LOG_LEVEL;
    }
    if ([logLevelName isEqualToString: @"Warnings"]) {
        return OFLogger::WARN_LOG_LEVEL;
    }
    if ([logLevelName isEqualToString: @"Info"]) {
        return OFLogger::INFO_LOG_LEVEL;
    }
    return OFLogger::DEBUG_LOG_LEVEL;
}

- (void)logError:(NSString*)errorString {
    DCMNET_ERROR([errorString UTF8String]);
}
@end

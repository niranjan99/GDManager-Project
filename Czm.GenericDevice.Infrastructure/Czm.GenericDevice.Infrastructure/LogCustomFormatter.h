//
//  LogCustomFormatter.h
//  UNO3_CommunicatorApp
//
//  Created by Mphasis on 19/08/17.
//  Copyright © 2017 Carl Zeiss Meditec. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CocoaLumberjack/CocoaLumberjack.h>
#import <CocoaLumberjack/DDContextFilterLogFormatter.h>

@interface LogCustomFormatter : DDContextWhitelistFilterLogFormatter {
    int atomicLoggerCount;
    NSDateFormatter *threadUnsafeDateFormatter;
    DDAtomicCounter *atomicLoggerCounter;
   
}

@end

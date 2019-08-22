//
//  ApplicationHelper.h
//  Dicom
//
//  Created by Malleswari on 10/22/18.
//  Copyright © 2018 Carl Zeiss Meditec. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DicomLogger : NSObject {
}

@property(nonatomic, retain) NSString *logLevel;


+ (DicomLogger*)sharedLogger;
- (void)setupLogFiles;
- (void)logError:(NSString*)errorString;

@end


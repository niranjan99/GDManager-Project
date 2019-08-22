//
//  Study.h
//  Dicom
//
//  Created by Sankar Dhekshit on 16/03/16.
//  Copyright © 2016 Carl Zeiss Meditec. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Series.h"

@interface Study : NSObject

@property (nonatomic, strong) NSString *Id;
@property (nonatomic, strong) NSString *dateString;
@property (nonatomic, strong) NSString *timeString;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) NSString *modality;
//@property (nonatomic, strong) NSString *instanceId;
@property (nonatomic, assign) NSInteger seriesNumber;
@property (nonatomic, strong) NSString *studyDescription;
@property (nonatomic, strong) NSString *referringPhysicianName;
@property (nonatomic, strong) NSString *accessionNumber;
@property (nonatomic, strong) NSData *referencedStudySequence;
@property (nonatomic, strong) NSData *procedureCodeSequence;
@property (nonatomic, strong) NSString *studyInstanceUid;

@property (nonatomic, strong) NSMutableArray *series;

- (Study *)createStudyWithDescription:(NSString*)description :(NSDate*)date;

@end

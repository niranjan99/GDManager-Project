//
//  Medias.h
//  Dicom
//
//  Created by Sankar Dhekshit on 17/08/16.
//  Copyright © 2016 Carl Zeiss Meditec. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FileDetails : NSObject
@property (nonatomic, strong) NSString *mediaPath;
@property (nonatomic, strong) NSString *dateString;
@property (nonatomic, strong) NSString *timeString;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) NSString *tagStrings;
@property (nonatomic, strong) NSString *stationName;

@property (nonatomic, strong) NSString *rows;
@property (nonatomic, strong) NSString *colums;
@property (nonatomic, strong) NSString *frameTime;
@property (nonatomic, assign) NSInteger durationSeconds;

@end

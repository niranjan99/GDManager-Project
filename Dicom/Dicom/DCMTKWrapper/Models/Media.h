//
//  Media.h
//  Dicom
//
//  Created by Sankar Dhekshit on 16/03/16.
//  Copyright © 2016 Carl Zeiss Meditec. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Media : NSObject

@property (nonatomic, strong) NSString *mediaType;
@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSString *dateString;
@property (nonatomic, strong) NSString *timeString;
@property (nonatomic, strong) NSString *creatorId;
@property (nonatomic, strong) NSString *instanceNumber;
@property (nonatomic, strong) NSString *sopClassUID;

@end

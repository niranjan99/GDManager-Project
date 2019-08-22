//
//  Series.h
//  Dicom
//
//  Created by Sankar Dhekshit on 16/03/16.
//  Copyright © 2016 Carl Zeiss Meditec. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Media.h"

@interface Series : NSObject

@property (nonatomic, strong) NSString *Id;
@property (nonatomic, strong) NSString *seriesDescription;
@property (nonatomic, strong) NSString *seriesType;
@property (nonatomic, strong) NSString *dateString;
@property (nonatomic, strong) NSString *timeString;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) NSString *instanceId;
@property (nonatomic, strong) NSMutableArray *medias;
    
//Modality attributes
@property (nonatomic, strong) NSString *modality;
@property (nonatomic, strong) NSData *requestAttributesSequence;

- (Series *)createSeriesWithDescription:(NSString*)description :(NSDate*)date;

@end

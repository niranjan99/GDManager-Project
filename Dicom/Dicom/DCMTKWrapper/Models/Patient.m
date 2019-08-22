//
//  Patient.m
//  Dicom
//
//  Created by Sankar Dhekshit on 16/03/16.
//  Copyright © 2016 Carl Zeiss Meditec. All rights reserved.
//

#import "Patient.h"
@interface Patient ()

//@property (readwrite, nonatomic, strong) NSString *Id;

@end

@implementation Patient

- (id) init
{
    self = [super init];
    if (self!=nil) {
        self.Id = [NSString stringWithFormat:@"%d",(arc4random())];
        Study *study = [[Study alloc] init];
        self.studies = [[NSMutableArray alloc] init];
        [self.studies addObject:study];
        self.worklistOrders = [[NSMutableArray alloc] init];
    }
    return self;
}

@end

//
//  ModalityWorklistOrder.m
//  Dicom
//
//  Created by Aina on 08/05/18.
//  Copyright © 2018 Carl Zeiss Meditec. All rights reserved.
//

#import "ModalityWorklistOrder.h"
#import "Utility.h"
#import "ModalityProcedure.h"

@implementation ModalityWorklistOrder

- (id) init
{
    self = [super init];
    if (self!=nil) {
        self.procedures = [[NSMutableArray alloc] init];
    }
    return self;
}

- (ModalityWorklistOrder *)createModalityWithDescription:(NSString*)description :(NSDate*)date
{
    return self;
}

@end

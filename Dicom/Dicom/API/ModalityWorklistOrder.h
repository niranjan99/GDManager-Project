//
//  ModalityWorklistOrder.h
//  Dicom
//
//  Created by Aina on 08/05/18.
//  Copyright © 2018 Carl Zeiss Meditec. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Series.h"
#import "Study.h"
#import "FileDetails.h"
#import "ModalityProcedure.h"

@interface ModalityWorklistOrder : NSObject

@property (nonatomic, strong) NSString *orderID;
@property (nonatomic, strong) NSString *accessionNumber;
@property (nonatomic, strong) NSString *referringPhysicianName;
@property (nonatomic, strong) NSMutableArray<ModalityProcedure*> *procedures;

- (ModalityWorklistOrder *)createModalityWithDescription:(NSString*)description :(NSDate*)date;

@end


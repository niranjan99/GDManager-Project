//
//  Patient.h
//  Dicom
//
//  Created by Sankar Dhekshit on 16/03/16.
//  Copyright © 2016 Carl Zeiss Meditec. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Study.h"
#import "FileDetails.h"
#import "ModalityWorklistOrder.h"

@interface Patient : NSObject

@property (nonatomic, strong) NSString *Id;
@property (nonatomic, strong) NSString *firstName;
@property (nonatomic, strong) NSString *lastName;
@property (nonatomic, strong) NSDate *dateOfBirth;
@property (nonatomic, strong) NSString *gender;
@property (nonatomic, strong) NSString *ethnicity;
@property (nonatomic, strong) NSString *patientIssuer;
@property (nonatomic, strong) NSString *otherPatientIds;
@property (nonatomic, strong) NSString *comments;

@property (nonatomic, strong) NSMutableArray<ModalityWorklistOrder*> *worklistOrders;
@property (nonatomic, strong) NSMutableArray *studies;

//extra
@property (nonatomic, strong) NSString *institutionName;
@property (nonatomic, strong) NSString *stationName;

@end

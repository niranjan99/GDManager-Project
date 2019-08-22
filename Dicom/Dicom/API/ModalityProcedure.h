//
//  ModalityProcedure.h
//  Dicom
//
//  Created by Aina on 22/06/18.
//  Copyright © 2018 Carl Zeiss Meditec. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Series.h"
#import "Study.h"
#import "FileDetails.h"

@interface ModalityProcedure : NSObject<NSCoding>

//accessionNumber & referringPhysicianName are added to procedure to simplify the data retrieval
@property (nonatomic, strong) NSString *studyInstanceUID;
@property (nonatomic, strong) NSString *referringPhysicianName;
@property (nonatomic, strong) NSString *accessionNumber;
@property (nonatomic, strong) NSDate *scheduledProcedureDate;
@property (nonatomic, strong) NSString *scheduledProcedureTime;
@property (nonatomic, strong) NSDate *studyDate;
@property (nonatomic, strong) NSString *studyTime;
@property (nonatomic, strong) NSString *reqProcedureId;
@property (nonatomic, strong) NSString *reqProcedureDesc;
@property (nonatomic, strong) NSData *referencedStudySequence;
@property (nonatomic, strong) NSData *requestAttributesSequence;
@property (nonatomic, strong) NSData *procedureCodeSequence;
@property (nonatomic, strong) NSString *modality;

- (ModalityProcedure *)createModalityProcedureWithDescription:(NSString*)description :(NSDate*)date;
@end

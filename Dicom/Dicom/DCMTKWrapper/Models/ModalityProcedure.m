//
//  ModalityProcedure.m
//  Dicom
//
//  Created by Aina on 22/06/18.
//  Copyright © 2018 Carl Zeiss Meditec. All rights reserved.
//

#import "ModalityProcedure.h"

@implementation ModalityProcedure

- (id) init
{
    self = [super init];
    if (self!=nil) {
        
    }
    return self;
}

- (ModalityProcedure *)createModalityProcedureWithDescription:(NSString*)description :(NSDate*)date
{
    return self;
}
    
- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.studyInstanceUID forKey:@"studyInstanceUID"];
    [aCoder encodeObject:self.referringPhysicianName forKey:@"referringPhysicianName"];
    [aCoder encodeObject:self.accessionNumber forKey:@"accessionNumber"];
    [aCoder encodeObject:self.scheduledProcedureDate forKey:@"scheduledProcedureDate"];
    [aCoder encodeObject:self.scheduledProcedureTime forKey:@"scheduledProcedureTime"];
    [aCoder encodeObject:self.studyDate forKey:@"studyDate"];
    [aCoder encodeObject:self.studyTime forKey:@"studyTime"];
    [aCoder encodeObject:self.reqProcedureId forKey:@"reqProcedureId"];
    [aCoder encodeObject:self.reqProcedureDesc forKey:@"reqProcedureDesc"];
    [aCoder encodeObject:self.referencedStudySequence forKey:@"referencedStudySequence"];
    [aCoder encodeObject:self.requestAttributesSequence forKey:@"requestAttributesSequence"];
    [aCoder encodeObject:self.procedureCodeSequence forKey:@"procedureCodeSequence"];
    [aCoder encodeObject:self.modality forKey:@"modality"];
}
    
- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self.studyInstanceUID = [aDecoder decodeObjectForKey:@"studyInstanceUID"];
    self.referringPhysicianName = [aDecoder decodeObjectForKey:@"referringPhysicianName"];
    self.accessionNumber = [aDecoder decodeObjectForKey:@"accessionNumber"];
    self.scheduledProcedureDate = [aDecoder decodeObjectForKey:@"scheduledProcedureDate"];
    self.scheduledProcedureTime = [aDecoder decodeObjectForKey:@"scheduledProcedureTime"];
    self.studyDate = [aDecoder decodeObjectForKey:@"studyDate"];
    self.studyTime = [aDecoder decodeObjectForKey:@"studyTime"];
    self.reqProcedureId = [aDecoder decodeObjectForKey:@"reqProcedureId"];
    self.reqProcedureDesc = [aDecoder decodeObjectForKey:@"reqProcedureDesc"];
    self.referencedStudySequence = [aDecoder decodeObjectForKey:@"referencedStudySequence"];
    self.requestAttributesSequence = [aDecoder decodeObjectForKey:@"requestAttributesSequence"];
    self.procedureCodeSequence = [aDecoder decodeObjectForKey:@"procedureCodeSequence"];
    self.modality = [aDecoder decodeObjectForKey:@"modality"];
    return self;
}

@end

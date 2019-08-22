//
//  FindSCU.h
//  Dicom
//
//  Created by Bankim Debnath on 30/03/16.
//  Copyright © 2016 Carl Zeiss Meditec. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <UIKit/UIKit.h>
#import "ServerConfigurationModule.h"
#import "Study.h"
#import "Patient.h"
#import "ModalityWorklistOrder.h"
#import "ModalityProcedure.h"
#import "DicomLogger.h"
@interface FindSCU : NSObject

/**
 @brief It finds patients on pacs
 
 @param  PatientId of type NSString.
 @param  stringType of type NSString.
 @param  configureInfoObject of type ServerConfigurationModule.
 @param  success response.
 @param  failure response. 
 */
-(void)findScu:(NSString *)PatientId withStringType:(NSString *)stringType PACSConnection:(ServerConfigurationModule *)configureInfoObject success:(void(^)(NSMutableArray *result))success failure:(void(^)(NSError *error))failure;
- (NSMutableDictionary*) getStudies:(NSString*)PatientId PACSConnection:(ServerConfigurationModule *)configureInfoObject;
- (void)findScuWithSearchCriteria:(NSDictionary*)searchFieldValueDict PACSConnection:(ServerConfigurationModule *)configureInfoObject success:(void(^)(NSMutableArray *result, BOOL status))success failure:(void(^)(NSError *error))failure;

@end

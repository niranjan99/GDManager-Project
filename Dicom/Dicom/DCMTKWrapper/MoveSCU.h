//
//  MoveSCU.h
//  Dicom
//
//  Created by Carin on 5/24/16.
//  Copyright © 2016 Carl Zeiss Meditec. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <UIKit/UIKit.h>
#import "ServerConfigurationModule.h"
#import "Study.h"
#import "Patient.h"

@interface MoveSCU : NSObject

/**
 @brief Downloads patients and related study  pacs
 
 @param  PatientId of type NSString.
 @param  stringType of type NSString.
 @param  configureInfoObject of type ServerConfigurationModule.
 @param  success response.
 @param  failure response.
 */
- (void)moveScu:(NSMutableArray *)instanceList dcmPath:(NSString*)path PACSConnection:(ServerConfigurationModule *)configureInfoObject success:(void(^)(NSMutableArray *result))success failure:(void(^)(NSError *error))failure;

/**
 @brief Close Assosication/Current session
 
 */
-(void)closeAssociation;

@end

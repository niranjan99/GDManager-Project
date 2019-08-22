//
//  MoveSCU.h
//  DCMTKSample
//
//  Created by Sankar Dhekshit on 21/07/16.
//  Copyright © 2016 Carl Zeiss Meditec. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ServerConfigurationModule.h"

@interface RetrieveFile : NSObject
/**
 Retrieves files from a given path
 @param instanceID of type NSString
 @param path of type NSString
 @param configureInfoObject of type ServerConfigurationModule
 @param success response during success
 @param failure response during failure
 */
+ (void) retrieveFile:(NSString*)instanceID filePath:(NSString*)path PACSConnection:(ServerConfigurationModule *)configureInfoObject success:(void(^)(NSMutableArray *result))success failure:(void(^)(NSError *error))failure;
+(void)closeAssociation;

@end

//
//  ServerConfigurationModule.h
//  Dicom
//
//  Created by Sankar Dhekshit on 17/03/16.
//  Copyright © 2016 Carl Zeiss Meditec. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ServerConfigurationModule : NSObject

@property (nonatomic, strong) NSString *callingAE;
@property (nonatomic, strong) NSString *calledAE;
@property (nonatomic, strong) NSString *callingIP;
@property (nonatomic, strong) NSString *calledIP;
@property (nonatomic, strong) NSString *port;
@property (nonatomic, strong) NSString *serverIP;
@property (nonatomic, strong) NSString *callingPort;
@property (nonatomic, strong) NSNumber *isModality;

- (ServerConfigurationModule*) createServerConfigurationModule:(NSDictionary *)configureInfo;
    
@end

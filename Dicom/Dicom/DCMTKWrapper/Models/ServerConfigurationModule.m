//
//  ServerConfigurationModule.m
//  Dicom
//
//  Created by Sankar Dhekshit on 17/03/16.
//  Copyright © 2016 Carl Zeiss Meditec. All rights reserved.
//

#import "ServerConfigurationModule.h"

@implementation ServerConfigurationModule

#define CALLING_AE_TITLE @"callingAETitle"
#define CALLED_AE_TITLE @"calledAETitle"

#define CALLING_IP @"callingIP"

#define CALLED_IP @"calledIP"

#define PORT_NUMBER @"portNumber"
#define CALLING_PORT    @"callingPort"


- (ServerConfigurationModule*) createServerConfigurationModule:(NSDictionary *)configureInfo{
    if (configureInfo.count == 0) {
        return nil;
    }
    self.callingAE = [configureInfo objectForKey:CALLING_AE_TITLE];
    self.calledAE = [configureInfo objectForKey:CALLED_AE_TITLE];
    self.callingIP = [configureInfo objectForKey:CALLING_IP];
    self.calledIP = [configureInfo objectForKey:CALLED_IP];
    self.port = [configureInfo objectForKey:PORT_NUMBER];
    self.callingPort = [configureInfo objectForKey:CALLING_PORT];
    self.serverIP = [NSString stringWithFormat:@"%@:%@",self.calledIP,self.port];
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        self.callingAE = [decoder decodeObjectForKey:CALLING_AE_TITLE];
        self.calledAE = [decoder decodeObjectForKey:CALLED_AE_TITLE];
        self.callingIP = [decoder decodeObjectForKey:CALLING_IP];
        self.calledIP = [decoder decodeObjectForKey:CALLED_IP];
        self.port = [decoder decodeObjectForKey:PORT_NUMBER];
        self.callingPort = [decoder decodeObjectForKey:CALLING_PORT];
        self.serverIP = [decoder decodeObjectForKey:@"serverIP"];
        self.isModality = [decoder decodeObjectForKey:@"isModality"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.callingAE forKey:CALLING_AE_TITLE];
    [encoder encodeObject:self.calledAE forKey:CALLED_AE_TITLE];
    [encoder encodeObject:self.callingIP forKey:CALLING_IP];
    [encoder encodeObject:self.calledIP forKey:CALLED_IP];
    [encoder encodeObject:self.port forKey:PORT_NUMBER];
    [encoder encodeObject:self.callingPort forKey:CALLING_PORT];
    [encoder encodeObject:self.serverIP forKey:@"serverIP"];
    [encoder encodeObject:self.isModality forKey:@"isModality"];
}

@end

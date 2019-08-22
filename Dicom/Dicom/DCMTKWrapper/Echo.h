//
//  Echo.h
//  Dicom
//
//  Created by Sankar Dhekshit on 16/02/16.
//  Copyright © 2016 Carl Zeiss Meditec. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Patient.h"
#import "ServerConfigurationModule.h"

@interface Echo : NSObject
{
    //BOOL isToSupportTLS;
}
/**
 @brief It creates PacsConnection
 
 @param  configureInfo capture the value of configuration info. success returns the success response and failure returns the failure response.
 
 @return N/A
 
 */
-(void) PACSConnection:(ServerConfigurationModule *)configureInfo success:(void(^)(NSString *result))success failure:(void(^)(NSError *error))failure;

@end

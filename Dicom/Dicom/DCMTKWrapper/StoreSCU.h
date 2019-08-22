//
//  StoreSCU.h
//  Dicom
//
//  Created by Sankar Dhekshit on 16/02/16.
//  Copyright © 2016 Carl Zeiss Meditec. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <UIKit/UIKit.h>
#import "ServerConfigurationModule.h"

@interface StoreSCU : NSObject
{
    //BOOL isToSupportTLS;
}

/*!
 @brief It stores the dicom file with required tags into PACS server.
 
 @param dcmPath captureing the local dcm file path. Param mediaType capturing the type of media file. Param configureInfoObject capturing the PACS configuration credientials. success returns the success response and failure returns the failure response.
 
 @return N/A
 
 */

-(void)storeDCM:(NSString *)dcmPath withMediaType:(NSString *)mediaType PACSConnection:(ServerConfigurationModule *)configureInfoObject success:(void(^)(NSString *result))success failure:(void(^)(NSError *error))failure;

-(void)closeAssociation: (BOOL)isForTLS;

@end

//
//  MoveSCU.m
//  Dicom
//
//  Created by Carin on 5/24/16.
//  Copyright © 2016 Carl Zeiss Meditec. All rights reserved.
//

#import "MoveSCU.h"
#include "dcmtk/dcmnet/scu.h"
#include "dcmtk/dcmnet/scp.h"
#include "dcmtk/dcmnet/dfindscu.h"
#include "dcmtk/dcmqrdb/dcmqrdba.h"
#include "RetrieveFile.h"

@implementation MoveSCU

- (void)moveScu:(NSMutableArray *)instanceList dcmPath:(NSString*)path PACSConnection:(ServerConfigurationModule *)configureInfoObject success:(void(^)(NSMutableArray *result))success failure:(void(^)(NSError *error))failure {
    
    [RetrieveFile retrieveFile:[instanceList firstObject] filePath:path PACSConnection:
     configureInfoObject success:^(NSMutableArray *response){
         success(response);
     } failure:^(NSError *error){
         failure(error);
     }];
}

-(void)closeAssociation
{
    [RetrieveFile closeAssociation];
}



@end

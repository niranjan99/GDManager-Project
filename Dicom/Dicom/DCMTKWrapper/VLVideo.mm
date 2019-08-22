//
//  VLVideo.m
//  Dicom
//
//  Created by Bankim Debnath on 23/02/16.
//  Copyright © 2016 Carl Zeiss Meditec. All rights reserved.
//

#import "VLVideo.h"


@implementation VLVideo

+(void)createDicom:(Patient *)patientModule mediaPath:(FileDetails*)media dcmFilePath:(NSString *)dcmFilePath mediaType:(NSString*)mediaType success:(void(^)(NSString *result))success failure:(void(^)(NSError *error))failure{
    [DicomObject createDicom:patientModule mediaPath:media dcmFilePath:dcmFilePath mediaType:mediaType success:^(NSString *response){
        success(response);
    } failure:^(NSError *error){
        failure(error);
    }];
}

@end

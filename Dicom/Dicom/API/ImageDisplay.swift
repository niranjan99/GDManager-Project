//
//  ImageDisplay.swift
//  Dicom
//
//  Created by Bankim Debnath on 06/05/16.
//  Copyright © 2016 Carl Zeiss Meditec. All rights reserved.
//

import Foundation

public class ImageDisplay: NSObject, ImageDisplayProtocol {
    public /**
     :brief: It display the instances from PACS server.
     
     :param: imagepath the input values representing the instance path.
     
     :returns:  String as success or error message
     */
    func showImages(_ dcmPath: String, mediaPath: String, imageType: Mediatype, success: @escaping (NSMutableArray) -> Void, failure: @escaping (NSError?) -> Void) {
        var type : String
        if (imageType ==  Mediatype.JPEG){
            type = "Image"
        }else{
            type = "Video"
        }
        
        DisplayImage.displayImage(dcmPath, mediaPath , type,
                                  success:{(response : NSMutableArray!) in
                                    success(response)
                                    return
        }, failure:{ (error) in
            failure(error as NSError?)
            return
            })
    }
}

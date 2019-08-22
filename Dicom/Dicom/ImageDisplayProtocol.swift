//
//  ImageDisplayProtocol.swift
//  Dicom
//
//  Created by Sankar Dhekshit on 19/07/16.
//  Copyright © 2016 Carl Zeiss Meditec. All rights reserved.
//

import Foundation

public protocol ImageDisplayProtocol {
    /**
     :brief: It display the instances from PACS server.
     
     :param: imagepath the input values representing the instance path.
     
     :returns:  String as success or error message
     */
    func showImages(_ dcmPath: String, mediaPath: String, imageType: Mediatype, success: @escaping  (_ response: NSMutableArray) -> Void, failure: @escaping  (_ error: NSError?) -> Void)
}

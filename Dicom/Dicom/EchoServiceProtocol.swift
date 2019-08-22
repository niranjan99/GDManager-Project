//
//  EchoProtocol.swift
//  Dicom
//
//  Created by Sankar Dhekshit on 19/07/16.
//  Copyright © 2016 Carl Zeiss Meditec. All rights reserved.
//
import Foundation

public protocol EchoServiceProtocol {
    /**
     :brief: It checks the pacs server connections.
     
     :param: N/A.
     
     :returns:  String as success or error message
     */
    func pingPacsServer(_ infoObject: ServerConfigurationModule, success: @escaping (_ response: AnyObject?) -> Void, failure: @escaping (_ error: NSError?) -> Void)
    
    /**
     :brief: It create the server configuration modual with required information .
     
     :param: configureInfo capturing the dictionary with all the server information.
     
     :returns:  it return the serverconfiguration modual.
     */
    func createServerConfiguration(_ configureInfo:NSDictionary) -> ServerConfigurationModule!
}

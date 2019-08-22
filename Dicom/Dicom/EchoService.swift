//
//  Echo.swift
//  Dicom
//
//  Created by Sankar Dhekshit on 19/07/16.
//  Copyright © 2016 Carl Zeiss Meditec. All rights reserved.
//

import Foundation

public class EchoService:NSObject, EchoServiceProtocol {
    
    var echo : Echo!
    
    public init(echo: Echo) {
        self.echo = echo
    }
    /**
     Configures pacs server
     
     - parameter configureInfo:NSDictionary
     
     - returns: ServerConfigurationModule
     */
    public func createServerConfiguration(_ configureInfo:NSDictionary) -> ServerConfigurationModule!{
        let serverConfig : ServerConfigurationModule = ServerConfigurationModule().createServerConfigurationModule(configureInfo as [NSObject : AnyObject])
        if (serverConfig.callingAE == nil || serverConfig.calledAE == nil || serverConfig.callingIP == nil || serverConfig.calledIP == nil)  {
            return nil
        }
        
        if (serverConfig.callingAE == "" || serverConfig.calledAE == "" || serverConfig.callingIP == "" || serverConfig.calledIP == "")  {
            return nil
        }
        return serverConfig
    }
    
    /**
     pingPacsServer
     
     - parameter infoObject: ServerConfigurationModule
     - parameter success:    success response
     - parameter failure:    failure response
     */
    public func pingPacsServer(_ infoObject: ServerConfigurationModule, success: @escaping (_ response: AnyObject?) -> Void, failure: @escaping (_ error: NSError?) -> Void) {
        self.echo.pacsConnection(infoObject,
                                 success:{(response : String!) in
                                    print(response)
                                    success(response as AnyObject)
        }, failure:{ (error) in
            failure(error as NSError?)
            })
    }
}

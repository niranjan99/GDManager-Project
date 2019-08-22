//
//  RetriveService.swift
//  Dicom
//
//  Created by Sankar Dhekshit on 02/08/16.
//  Copyright © 2016 Carl Zeiss Meditec. All rights reserved.
//

import Foundation

open class RetriveService: RetriveServiceProtocol {
    var moveSCU : MoveSCU!
    
    public init(moveSCU: MoveSCU) {
        self.moveSCU = moveSCU
    }
    
    /**
     Find By Instance Number
     
     - parameter instanceNumbers: NSMutableArray
     - parameter dcmPath:         String
     - parameter pacsconnection:  ServerConfigurationModule
     - parameter success:         success response
     - parameter failure:         failure response
     */
    open func findByInstanceNumber(_ instanceNumbers: NSMutableArray!, dcmPath:String, pacsconnection: ServerConfigurationModule, success: @escaping (_ response: NSMutableArray) -> Void, failure: @escaping (_ error: NSError?) -> Void) {
        var instanceArray: NSMutableArray!
        
        self.moveSCU.moveScu(instanceNumbers, dcmPath:dcmPath, pacsConnection: pacsconnection,
                             success:{(response : NSMutableArray!) in
                                instanceArray = response;
                                success(instanceArray)
                                return
        }, failure:{ (error) in
            failure(error as NSError?)
            return
        })
    }
    
    open func closeSession()
    {
        self.moveSCU.closeAssociation()
    }
}

//
//  RetriveServiceProtocol.swift
//  Dicom
//
//  Created by Sankar Dhekshit on 02/08/16.
//  Copyright © 2016 Carl Zeiss Meditec. All rights reserved.
//

import Foundation

public protocol RetriveServiceProtocol {
    
    /**
     :brief: It finds the patient information based on patient ID.
     
     :param: patientid the input values representing the patient ID.
     
     :returns:  String as success or error message
     */
    
    func findByInstanceNumber(_ instanceNumbers: NSMutableArray!, dcmPath:String, pacsconnection: ServerConfigurationModule, success: @escaping (_ response: NSMutableArray) -> Void, failure: @escaping (_ error: NSError?) -> Void)
    
    /**
     :brief: It will Close the current session
     
     :param: N/A
     
     :returns:  It return true/false
     */
    func closeSession()
}

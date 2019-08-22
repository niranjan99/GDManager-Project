//
//  FindService.swift
//  Dicom
//
//  Created by Sankar Dhekshit on 19/07/16.
//  Copyright © 2016 Carl Zeiss Meditec. All rights reserved.
//

import Foundation

open class FindService:NSObject, FindServiceProtocol {
    
    
    var findSCU : FindSCU!
    
    public init(findSCU: FindSCU) {
        self.findSCU = findSCU
    }
    /**
     Searches by id for patients in dicom
     
     - parameter patientid:      String
     - parameter pacsconnection: ServerConfigurationModule
     - parameter success:        success response
     - parameter failure:        failure response
     */
    public func findByID(_ patientid: String!, pacsconnection: ServerConfigurationModule, success: @escaping ([Patient]) -> Void, failure: @escaping (NSError?) -> Void) {
        
        self.findSCU.findScu(patientid, withStringType: "ID", pacsConnection: pacsconnection,
                             success:{(response : NSMutableArray!) in
                                if response.count > 0
                                {
                                    success(NSArray(array:response) as! [Patient])
                                    return
                                }else{
                                    self.findByPatientName(patientid, pacsconnection: pacsconnection, success: { (response) in
                                        success(response)
                                    }, failure: { (error) in
                                        failure(error)
                                        return
                                    })
                                }
        }, failure:{ (error) in
            failure(error as NSError?)
        })
    }
    
    /**
     Searches by patient name for patients in dicom
     
     - parameter patientname:    String
     - parameter pacsconnection: ServerConfigurationModule
     - parameter success:        success response
     - parameter failure:        failure response
     */
    open func findByPatientName(_ patientname: String!, pacsconnection: ServerConfigurationModule, success: @escaping (_ response: [Patient]) -> Void, failure: @escaping (_ error: NSError?) -> Void) {
        
        self.findSCU.findScu(patientname, withStringType: "name", pacsConnection: pacsconnection,
                             success:{(response : NSMutableArray!) in
                                success(NSArray(array:response) as! [Patient])
        }, failure:{ (error) in
            failure(error as NSError?)
            })
    }
    
    /**
     Searches by patient dob for patients in dicom
     
     - parameter patientname:    String
     - parameter pacsconnection: ServerConfigurationModule
     - parameter success:        success response
     - parameter failure:        failure response
     */
    open func findByDOB(_ patientdob: String!, pacsconnection: ServerConfigurationModule, success: @escaping (_ response: [Patient]) -> Void, failure: @escaping (_ error: NSError?) -> Void) {
        
        self.findSCU.findScu(patientdob, withStringType: "dob", pacsConnection: pacsconnection,
                             success:{(response : NSMutableArray!) in
                                success(NSArray(array:response) as! [Patient])
        }, failure:{ (error) in
            failure(error as NSError?)
        })
    }
    
    open func findBy(searchCriteria searchFieldValueDict: Dictionary<NSNumber, String>, pacsconnection: ServerConfigurationModule, success: @escaping (_ response: [Patient]?, _ status: Bool) -> Void, failure: @escaping (_ error: NSError?) -> Void) {
        self.findSCU.findScu(withSearchCriteria: searchFieldValueDict, pacsConnection: pacsconnection, success:{(response : NSMutableArray!,successStatus) in
            success(NSArray(array:response) as? [Patient], successStatus)
        }, failure:{ (error) in
            failure(error as NSError?)
        })
    }

    open func getStudies(_ patientID: String!, pacsconnection: ServerConfigurationModule) -> NSMutableDictionary?
    {
        return self.findSCU.getStudies(patientID, pacsConnection: pacsconnection)
    }
    
}

//
//  FindServiceProtocol.swift
//  Dicom
//
//  Created by Sankar Dhekshit on 19/07/16.
//  Copyright © 2016 Carl Zeiss Meditec. All rights reserved.
//

import Foundation

public protocol FindServiceProtocol {
    /**
     :brief: It finds the patient information based on patient ID.
     
     :param: patientid the input values representing the patient ID.
     
     :returns:  String as success or error message
     */
    func findByID(_ patientid: String!, pacsconnection: ServerConfigurationModule, success: @escaping (_ response: [Patient]) -> Void, failure: @escaping (_ error: NSError?) -> Void)
    
    /**
     :brief: It finds the patient information based on patient Name.
     
     :param: patientname the input values representing the patient Name.
     
     :returns:  String as success or error message
     */
    func findByPatientName(_ patientname: String!, pacsconnection: ServerConfigurationModule, success: @escaping (_ response: [Patient]) -> Void, failure: @escaping (_ error: NSError?) -> Void)
    
    /**
     :brief: It finds the patient information based on patient's Date of birth.
     
     :param: patientdob the input values representing the patient's Date of birth.
     
     :returns:  String as success or error message
     */
    func findByDOB(_ patientdob: String!, pacsconnection: ServerConfigurationModule, success: @escaping (_ response: [Patient]) -> Void, failure: @escaping (_ error: NSError?) -> Void)
    
    
    /**
     :brief: It finds the patient information based on the mutliple search criteria.
     
     :param: It takes a dictionary of key value pairs
     
     :returns:  String as success or error message
     */
    func findBy(searchCriteria searchFieldValueDict: Dictionary<NSNumber, String>, pacsconnection: ServerConfigurationModule, success: @escaping (_ response: [Patient]?, _ status: Bool) -> Void, failure: @escaping (_ error: NSError?) -> Void)
    
    func getStudies(_ patientdob: String!, pacsconnection: ServerConfigurationModule) -> NSMutableDictionary?
}

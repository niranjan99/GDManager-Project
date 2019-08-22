//
//  StoreServiceProtocol.swift
//  Dicom
//
//  Created by Sankar Dhekshit on 19/07/16.
//  Copyright © 2016 Carl Zeiss Meditec. All rights reserved.
//

// Enum methods

import Foundation

public enum Mediatype: String{
    case JPEG
    case MPEG
    case OTHER
}

public protocol StoreServiceProtocol {
    /**
     :brief: It store the image file to pacs server.
     
     :param: PatientInfromation the input values representing the dictionary along with mediaPath param and mediaType param.
     
     :returns:  String as success or error message
     */
    func storeImagesToPacs( _ patientInfromation: Patient, mediaPaths: [FileDetails], mediaType: Mediatype, pacsconnection: ServerConfigurationModule, success: @escaping (_
        response: [StoreResponse]) -> Void, failure: @escaping (_ error: NSError?) -> Void)
    
    /**
     :brief: It store the video file to pacs server.
     
     :param: PatientInfromation the input values representing the dictionary along with mediaPath param and mediaType param.
     
     :returns:  String as success or error message
     */
    func storeVideosToPacs( _ patientInfromation: Patient, mediaPaths: [FileDetails], mediaType: Mediatype, pacsconnection: ServerConfigurationModule, success: @escaping (_ response: [StoreResponse]) -> Void, failure: @escaping (_ error: NSError?) -> Void)
    
    /**
     :brief: It creats patient module with study details.
     
     :param: studyDescription capture the study info.
     
     :returns:  it return the patient module with study info.
     */
    func createPatientModule(_ studyDescription:String, date:Date) -> Patient
    
    /**
     :brief: It will delete all old file from DicomFiles directory
     
     :param: N/A
     
     :returns:  It return true/false
     */
    func clearAllFilesFromDicomFilesDirectory() -> Bool
    
    /**
     :brief: It will Close the current session
     
     :param: N/A
     
     :returns:  It return true/false
     */
    func closeSession()
    
    
}

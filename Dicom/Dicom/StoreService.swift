//
//  StoreService.swift
//  Dicom
//
//  Created by Sankar Dhekshit on 19/07/16.
//  Copyright © 2016 Carl Zeiss Meditec. All rights reserved.
//

import Foundation

public class StoreService: NSObject, StoreServiceProtocol {
     var isForTLS = false
     /**
     :brief: It creats patient module with study details.
     
     :param: studyDescription capture the study info.
     
     :returns:  it return the patient module with study info.
     */
    
    
    public func createPatientModule(_ studyDescription: String, date: Date) -> Patient {
        let patient: Patient = Patient()
        var study: Study = patient.studies[0] as! Study
        study = study.createStudy(withDescription: studyDescription, date as Date?)
        return patient
    }
    
    var storeSCU : StoreSCU!
    
    public init(storeSCU: StoreSCU) {
        self.storeSCU = storeSCU
    }
    
    /**
     Stores images to pacs
     
     - parameter patientInfromation: Patient
     - parameter mediaPaths:         Array of type FileDetails
     - parameter mediaType:          Mediatype
     - parameter pacsconnection:     ServerConfigurationModule
     - parameter seriesDescription:  String
     - parameter success:            success response
     - parameter failure:            failure response
     */
    public func storeImagesToPacs( _ patientInfromation: Patient, mediaPaths: [FileDetails], mediaType: Mediatype, pacsconnection: ServerConfigurationModule, success: @escaping (_ response: [StoreResponse]) -> Void, failure: @escaping (_ error: NSError?) -> Void) {
        var dcmPath: String!
        var dcmPaths: [StoreResponse]! = []
        
//        let patientInfromation = self.createSeries(patient: patientInfromation, series: series)
        
        let mediaTypeString : String = mediaType.rawValue.lowercased()
        
        if mediaPaths.count == 0 {
            failure(NSError(domain: "UNO3", code: Int(EPERM), userInfo: [NSLocalizedDescriptionKey:"No Images found"]));
            return
        }
        
        for media in mediaPaths {
            
            let storeResponseObj : StoreResponse = StoreResponse()
            storeResponseObj.mediaPath = media.mediaPath
            
            let extensionString  = media.mediaPath.components(separatedBy: ".").last
            if let compareString = extensionString
            {
                if compareString.caseInsensitiveCompare("png") == .orderedSame
                {
                    if let image = UIImage(contentsOfFile: media.mediaPath) {
                        let jpegData = image.jpegData(compressionQuality: 1.0)
                        let jpegPath = dcmpath(fileName: (media.mediaPath as NSString).lastPathComponent)
                        do {
                            try jpegData?.write(to: URL(fileURLWithPath: jpegPath), options: .atomic)
                        } catch let error {
                            print(error)
                        }
                        media.mediaPath = jpegPath
                    }
                }
            }
            
            //Creating the DCMfile
            SCImage.createDicom(patientInfromation, mediaPath: media, dcmFilePath: dcmpath(fileName: NSUUID().uuidString + ".dcm"), mediaType: mediaTypeString,
                                success:{(response : String!) in
                                    dcmPath = response
                                    //print("Image DCM path : \(String(describing: response))")
                                    //Store the DCM file in Pacs server
                                    self.storeSCU.storeDCM(dcmPath, withMediaType: mediaTypeString, pacsConnection: pacsconnection,
                                                           success:{(response : String!) in
                                                            storeResponseObj.instanceNumber = response
                                    }, failure:{ (error ) in
                                        storeResponseObj.instanceNumber = nil
                                        })
                                    
            }, failure:{ (error) in
                storeResponseObj.instanceNumber = nil
                })
            
            dcmPaths.append(storeResponseObj)
        }
        self.clearAllFilesFromDicomFilesDirectory()
        //Returning Storeresponses
        success(dcmPaths)
    }
    
    /**
     Stores videos to pacs
     
     - parameter patientInfromation: Patient
     - parameter mediaPaths:         Array of type FileDetails
     - parameter mediaType:          Mediatype
     - parameter pacsconnection:     ServerConfigurationModule
     - parameter seriesDescription:  String
     - parameter success:            success response
     - parameter failure:            failure response
     */
    public func storeVideosToPacs( _ patientInfromation: Patient, mediaPaths: [FileDetails], mediaType: Mediatype, pacsconnection: ServerConfigurationModule, success: @escaping (_ response: [StoreResponse]) -> Void, failure: @escaping (_ error: NSError?) -> Void) {
        var dcmPath: String!
        var dcmPaths: [StoreResponse]! = []
        
//        let patientInfromation = self.createSeries(patient: patientInfromation, series: series)

        let mediaTypeString : String = mediaType.rawValue.lowercased()
        
        if mediaPaths.count == 0 {
            failure(NSError(domain: "UNO3", code: Int(EPERM), userInfo: [NSLocalizedDescriptionKey:"No Videos found"]));
            return
        }
        
        for media in mediaPaths {
            
            let storeResponseObj : StoreResponse = StoreResponse()
            storeResponseObj.mediaPath = media.mediaPath
            
            //Creatig the DCMfile
            VLVideo.createDicom(patientInfromation, mediaPath: media, dcmFilePath: dcmpath(fileName: NSUUID().uuidString + ".dcm"), mediaType: mediaTypeString,
                                success:{(response : String!) in
                                    dcmPath = response
                                    //print("Video DCM path : \(String(describing: response))")
                                    //Store the DCM file in Pacs server
                                    self.storeSCU.storeDCM(dcmPath, withMediaType: mediaTypeString, pacsConnection: pacsconnection,
                                                           success:{(response : String!) in
                                                            storeResponseObj.instanceNumber = response
                                    }, failure:{ (error) in
                                        storeResponseObj.instanceNumber = nil
                                        })
            }, failure:{ (error) in
                storeResponseObj.instanceNumber = nil
                })
            
            dcmPaths.append(storeResponseObj)
        }
        
        //Returning Storeresponses
        success(dcmPaths)
        self.clearAllFilesFromDicomFilesDirectory()
    }
    
    /**
     Clears all files from dicom files directory
     
     - returns: Bool
     */
    @discardableResult public func clearAllFilesFromDicomFilesDirectory() -> Bool{
        var result : Bool = false
        let fileManager = FileManager.default
        let dcmPath = self.getDocumentsDirectory().appendingPathComponent("DicomFiles")
        do {
            let filePaths = try fileManager.contentsOfDirectory(atPath: dcmPath)
            if filePaths.count == 0
            {
                result = true
            }
            for filePath in filePaths {
                do {
                    let path = NSString(format:"%@/%@", dcmPath, filePath) as String
                    try FileManager.default.removeItem(atPath: path)
                    result = true
                } catch {
                    print("an error during a removing")
                    result = false
                }
            }
        } catch {
            print("Could not clear temp folder: \(error)")
            result = false
        }
        
        return result
    }
    
    
    //MARK: private methods
    /**
     Creates series
     
     - parameter patient:           Patient
     - parameter seriesDescription: String
     
     - returns: Patient
     */
//    func createSeries(patient: Patient, series: Series) -> Patient {
//        let study: Study = patient.studies[0] as! Study
//        let newSeries: Series = Series().createSeries(withDescription: series.seriesDescription, study.date)
//        newSeries.modality = series.modality
//        newSeries.requestAttributesSequence = series.requestAttributesSequence
//        study.series.removeAllObjects()
//        study.series.add(newSeries);
//        return patient
//    }
    
    /**
     Returns documents directory path
     
     - returns: String
     */
    func getDocumentsDirectory() -> NSString {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory as NSString
    }
    /**
     Returns dcm file path
     
     - returns: String
     */
    func dcmpath(fileName : String) -> String{
        var dcmPath = getDocumentsDirectory().appendingPathComponent("DicomFiles")
        
        do {
            try FileManager.default.createDirectory(atPath: dcmPath, withIntermediateDirectories: true, attributes: nil)
        } catch {
            NSLog("Unable to create directory")
        }
        
        dcmPath = dcmPath.appendingFormat("/\(fileName)")
        
        return dcmPath
    }
    
    public func closeSession()
    {
        DicomObject.cancelDCMfileCreation()
        if self.storeSCU != nil
        {
            self.storeSCU.closeAssociation(isForTLS)
        }
    }
}

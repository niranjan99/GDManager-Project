//
//  DicomApi.swift
//  Dicom
//
//  Created by Sankar Dhekshit on 19/07/16.
//  Copyright © 2016 Carl Zeiss Meditec. All rights reserved.
//

import Foundation

open class DicomApi: NSObject {
    open var logLevel: String = "Verbose" {
        didSet {
            if oldValue != logLevel {
                DicomLogger.shared()?.logLevel = logLevel
            }
        }
    }
    
    fileprivate var findService :FindServiceProtocol?
    fileprivate var echoService :EchoServiceProtocol?
    fileprivate var storeService :StoreServiceProtocol?
    fileprivate var imageDisplay :ImageDisplayProtocol?
    fileprivate var retriveService :RetriveServiceProtocol?
    
    public override init(){
        self.findService = FindService(findSCU: FindSCU())
        self.echoService = EchoService(echo: Echo())
        self.storeService = StoreService(storeSCU: StoreSCU())
        self.imageDisplay = ImageDisplay()
        self.retriveService = RetriveService(moveSCU: MoveSCU())
    }
    
    //MARK: Find Patient Methods
    open func findByID(_ patientid: String!, pacsconnection: ServerConfigurationModule, success: @escaping (_ response: [Patient]?) -> Void, failure: @escaping (_ error: NSError?) -> Void) {
        self.findService?.findByID(patientid, pacsconnection: pacsconnection, success:{(response : [Patient]!) in
            success(response)
            return
        }, failure:{ (error) -> Void in
            failure(error)
            return
        })
    }
    
    open func findByPatientName(_ patientname: String!, pacsconnection: ServerConfigurationModule, success: @escaping (_ response: [Patient]?) -> Void, failure: @escaping(_ error: NSError?) -> Void) {
        self.findService?.findByPatientName(patientname, pacsconnection: pacsconnection, success:{(response : [Patient]!) in
            success(response)
            return
        }, failure:{ (error) -> Void in
            failure(error)
            return
        })
    }
    
    open func findByDOB(_ patientdob: String!, pacsconnection: ServerConfigurationModule, success: @escaping (_ response: [Patient]?) -> Void, failure: @escaping (_ error: NSError?) -> Void) {
        self.findService?.findByDOB(patientdob, pacsconnection: pacsconnection, success:{(response : [Patient]!) in
            success(response)
            return
        }, failure:{ (error) -> Void in
            failure(error)
            return
        })
    }
    
    open func findBy(searchCriteria searchFieldValueDict: NSDictionary, pacsconnection: ServerConfigurationModule, success: @escaping (_ response: [Patient]?,_ status : Bool) -> Void, failure: @escaping (_ error: NSError?) -> Void) {
        self.findService?.findBy(searchCriteria: searchFieldValueDict as! Dictionary<NSNumber, String>, pacsconnection: pacsconnection, success:{(response : [Patient]!,successStatus)  in
            success(response,successStatus)
            return
        }, failure:{ (error) -> Void in
            failure(error)
            return
        })
    }

    open func getStudies(_ patientID: String!, pacsconnection: ServerConfigurationModule) -> (NSMutableArray,Bool) {
        //DicomLogger.shared()?.setupLogFiles() //Check for log files
        let inDict = self.findService?.getStudies(patientID, pacsconnection: pacsconnection)!
        let status = inDict?.object(forKey: "status") as! String
        let results = inDict?.object(forKey: "results")
        return (results as! NSMutableArray,NSString(string: status).boolValue)
    }
    
    //MARK: EchoService Methods
    open func pingPacsServer(_ infoObject: ServerConfigurationModule, success: @escaping (_ response: AnyObject?) -> Void, failure: @escaping (_ error: NSError?) -> Void) {
        self.echoService!.pingPacsServer(infoObject,success: { (response) -> Void in
            success(response)
        }, failure:{ (error) -> Void in
            print(error!.userInfo[NSLocalizedDescriptionKey]!)
            failure(error)
        })
    }
    
    open func createServerConfiguration(_ configureInfo:NSDictionary) -> ServerConfigurationModule {
        return self.echoService!.createServerConfiguration(configureInfo as! [AnyHashable : Any] as [AnyHashable: Any] as NSDictionary)
    }
    
    //MARK: StoreService Methods
    //    Add Visit date
    open func createPatientModule(_ studyDescription:String) -> Patient {
        return self.storeService!.createPatientModule(studyDescription, date:Date())
    }
    
    open func storeImagesToPacs( _ patientInfromation: Patient, mediaPaths: [FileDetails], mediaType: Mediatype, pacsconnection: ServerConfigurationModule, success: @escaping (_ response: [StoreResponse]) -> Void, failure: @escaping(_ error: NSError?) -> Void) {
        self.storeService!.storeImagesToPacs(patientInfromation, mediaPaths: mediaPaths, mediaType: Mediatype.JPEG, pacsconnection: pacsconnection, success: { (response) -> Void in
            print("image storeService response : \(response)")
            success(response)
        }, failure:{ (error) -> Void in
            print(error!.userInfo[NSLocalizedDescriptionKey]!)
            failure(error)
        })
    }
    
    open func storeVideosToPacs( _ patientInfromation: Patient, mediaPaths: [FileDetails], mediaType: Mediatype, pacsconnection: ServerConfigurationModule, success: @escaping (_ response: [StoreResponse]) -> Void, failure: @escaping (_ error: NSError?) -> Void, modalityProcedure: ModalityProcedure? = nil) {
        self.storeService!.storeVideosToPacs(patientInfromation, mediaPaths: mediaPaths, mediaType: Mediatype.MPEG, pacsconnection: pacsconnection, success: { (response) -> Void in
            print("video storeService response : \(response)")
            success(response)
            
        }, failure:{ (error) -> Void in
            print(error!.userInfo[NSLocalizedDescriptionKey]!)
            failure(error)
        })
    }
    
    open func clearAllFilesFromDicomFilesDirectory() -> Bool {
        return self.storeService!.clearAllFilesFromDicomFilesDirectory()
    }
    
    //MARK: DisplayImage methods
    open func showImages(_ dcmpath: String, mediapath: String, imageType: Mediatype, success: @escaping (_ response: NSMutableArray) -> Void, failure: @escaping (_ error: NSError?) -> Void) {
        self.imageDisplay!.showImages(dcmpath, mediaPath: mediapath, imageType: imageType, success:{(response : NSMutableArray!) in
            print(response)
            success(response)
        }, failure:{ (error) -> Void in
            print(error!.userInfo[NSLocalizedDescriptionKey]!)
            failure(error)
        })
    }
    
    //MARK: Retrive files methods
    open func findByInstanceNumber(_ instanceNumbers: NSMutableArray!, dcmPath:String, pacsconnection: ServerConfigurationModule, success: @escaping (_ response: NSMutableArray) -> Void, failure: @escaping (_ error: NSError?) -> Void) {
        self.retriveService!.findByInstanceNumber(instanceNumbers, dcmPath: dcmPath, pacsconnection: pacsconnection, success:{(response : NSMutableArray!) in
            success(response)
        }, failure:{ (error) -> Void in
            failure(error)
        })
    }
    
    open func closeCurrentSession() {
        self.storeService!.closeSession()
        self.retriveService!.closeSession()
    }
    
    //MARK: Log error methods
    open func logError(_ errorString: String) {
        DicomLogger.shared().logError(errorString)
    }
}

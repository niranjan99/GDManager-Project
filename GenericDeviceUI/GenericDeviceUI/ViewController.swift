//
//  ViewController.swift
//  GenericDeviceUI
//
//  Created by Carin on 3/22/19.
//  Copyright © 2019 Carin. All rights reserved.
//

import UIKit

//import Czm_GenericDevice_DataManagement
//import Czm_GenericDevice_DataManagement_Interfaces
//import Czm_GenericDevice_DeviceDataManagement_Interfaces
//import Czm_GenericDevice_DeviceDataManagement
//import Czm_GenericDevice_Infrastructure_Interfaces
//import Czm_GenericDevice_Infrastructure
////import Czm_GenericDevice_SettingsManagement
//import Czm_GenericDevice_SettingsManagement_Interfaces
//import Czm_GenericDevice_EventBroker
import Czm_GenericDevice_CryptoServices
import Czm_GenericDevice_CryptoServices_Interfaces
//import Swinject

import Czm_GenericDevice_InfrastructureServices
import Czm_GenericDevice_InfrastructureServices_Interfaces
import Czm_GenericDevice_SettingsManagement

import Czm_GenericDevice_SettingsManagement
import Czm_GenericDevice_SettingsManagement_Interfaces
import Czm_GenericDevice_Infrastructure_Interfaces
import Czm_GenericDevice_Infrastructure
import Czm_GenericDevice_EventBroker_Interfaces
import Czm_GenericDevice_EventBroker
import Czm_GenericDevice_DependencyInjector
class ViewController: UIViewController {
    
    @IBOutlet var buttonCreate:UIButton!
    @IBOutlet var buttonCreateExam:UIButton!
    var savedPatientKey:String!
    var infrstucture = InfrastructureServices()

    override func viewDidLoad() {
        super.viewDidLoad()
        buttonCreateExam.isHidden = true
//        let infra = iInfrastructureServices.self
//       infrast.initialize()
//        let settingscontainer = infrstucture.container.resolve(ISettingsContainer.self)
  
        
     //   dep.container = infrstucture.dependency.container
        
        
//        print(settingscontainer?.SetSettingValue(originSetting: "hello", sourceType: "aap", value: "sss"))
//        print(infrstucture.settingsManager.applicationSettingsContainer)
//        let infrstucture =  InfrastructureServices(Logger: ILogger.self as! ILogger, SettingsManager: ISettingsManager.self as! ISettingsManager, EventBroker: IEventBroker.self as! IEventBroker, Dependency: ISwinjectContainer.self as! ISwinjectContainer)
        
        let crypto = infrstucture.container.resolve(ICryptoServices.self)
//        var infrstucture2 = dependencyInjector2.container.resolve(iInfrastructureServices.self)
//
//        
//       print(infrstucture.SettingsManager)
//     
//     
        infrstucture.eventBroker.publish(name: NSNotification.Name(rawValue: "nsm"), object: "sd")
//        let dictionary = infrstucture.settingsManager.applicationSettingsContainer.categories

//      componentManager.componentManager.ci
  
//        let patientRepo = DependencyInjector.container.resolve(iPatientRepository.self)
//      let cryptoService = dependencyInjector.container.resolve(ICryptoServices.self)

     let encryp:String =   crypto?.encrypt(plainText: "niranjan", password: "12345") ?? "23"
     let decrp =   crypto?.decrypt(encryptedText: encryp, password: "12345")

     print("cypto",encryp)
     print("cypto",decrp)
        
        
        
        
//        self.settingsManager()
        
    }
   /*
    func setDataToPatient(){
        let exPatientRepo = dependencyInjector.container.resolve(iPatientRepository.self)
        let patient = exPatientRepo!.getInstance(entity:"ExtendedPatient")
        addExtendedPatientData(exPatient: patient as! ExtendedPatient)
    }
    
    func addExtendedPatientData(exPatient:ExtendedPatient){
        
        let patientRepo = dependencyInjector.container.resolve(iPatientRepository.self)
        exPatient.devicePatientKey = UUID().uuidString
        exPatient.eyeColor = "Red"
        exPatient.height = "6.0"
        patientRepo!.Save(entity: exPatient)
        let patient = patientRepo!.getInstance(entity:"Patient")
        addPatientData(patient: patient as! Patient, key: exPatient.devicePatientKey!)
        
    }
    func addPatientData(patient:Patient, key:String){
        let patientRepo = dependencyInjector.container.resolve(iPatientRepository.self)
        patient.patientKey = key
        patient.key = key
        patient.id = "1001"
        patient.issuerOfPatientId = "zeiss"
        patient.issuerOfPatientId = "zeiss_conflict1"
        patient.issuerOfPatientId = "zeiss_conflict2"
        patient.birthDate = "22/12/2019 22:21:58 PM"
        patient.sex = "M"
        patient.ethnicGroup = "sd"
        patient.isInArchive = true
        patient.comments = "sdsdfdsfsd fds f dsf dsf sd"
        patient.creationDate = "22/12/2019 22:21:58 PM"
        patient.otherPatientIds = ""
        patient.owner = UUID().uuidString
        patient.familyName = "dsfdsf"
        patient.givenName = "23esdsd"
        patient.middleName = "sdafsdf"
        patient.prefix = "prdsf"
        patient.suffix = "sdfd"
        patient.familyName_Ideographic = "familyName_Ideographic"
        patient.givenName_Ideographic = "givenName_Ideographic"
        patient.middleName_Ideographic = "middleName_Ideographic"
        patient.prefix_Ideographic = "prefix_Ideographic"
        patient.suffix_Ideographic = "suffix_Ideographic"
        patient.familyName_Phonetic = "suffix_Ideographic"
        patient.givenName_Phonetic = "givenName_Phonetic"
        patient.middleName_Phonetic = "middleName_Phonetic"
        patient.prefix_Phonetic = "prefix_Phonetic"
        patient.suffix_Phonetic = "suffix_Phonetic"
        patientRepo!.Save(entity: patient)
        savedPatientKey = patient.patientKey
        
    }
    @IBAction func createPatientClick(sender: UIButton)
    {
         self.Log()
        //Create patient
//        self .setDataToPatient()
//        buttonCreateExam.isHidden = false
    }
    @IBAction func createExamClick(sender: UIButton)
    {
        //Create exam
        self .setDataToExam()
    }
    
    func setDataToExam(){
        let exTExamRepo = dependencyInjector.container.resolve(IExtendedExamRepository.self)
        let exam = exTExamRepo!.getInstance(entity:"ExtendedExam")
        addExtendedExamData(exExam: exam as! ExtendedExam)
    }
    func addExtendedExamData(exExam:ExtendedExam)
    {
        let rawExam = dependencyInjector.container.resolve(iRawExamRepository.self)
        let enPdf = dependencyInjector.container.resolve(iEncapsulatedPdfRepository.self)
        let measurement = dependencyInjector.container.resolve(iEncapsulatedPdfRepository.self)
        let examRepo = dependencyInjector.container.resolve(iExamRepository.self)
        
        
        let rawExamRepo = rawExam!.getInstance(entity:"RawExam")
        let enPdfRepo = enPdf!.getInstance(entity:"EncapsulatedPdf")
        let mesureRepo = measurement!.getInstance(entity:"ExamMeasurement")
        
        
        let  rawExamRepos:RawExam = rawExamRepo as! RawExam
        rawExamRepos.fileName = "new raw exam"
        rawExamRepos.exExamKey = UUID().uuidString
        
        
        let  enPdfRepos:EncapsulatedPdf = enPdfRepo as! EncapsulatedPdf
        enPdfRepos.conversionType = ""
        enPdfRepos.key = rawExamRepos.exExamKey
        
        let  mesureRepos:ExamMeasurement = mesureRepo as! ExamMeasurement
        mesureRepos.key = rawExamRepos.exExamKey
        
        // ADDING TO EXAM
        exExam.deviceExamKey = rawExamRepos.exExamKey
        exExam.duration = "23.32"
        exExam.examType = "Retina scan"
        exExam.image = "No Data"
        exExam.key = savedPatientKey
        exExam.rawExam = rawExamRepos
        exExam.enPdf = enPdfRepos
        exExam.measurement = mesureRepos
        
        let exam = examRepo!.getInstance(entity:"Exam")
        addExamData(exam: exam as! Exam, key: exExam.deviceExamKey!)
        
    }
    
    func addExamData(exam:Exam, key:String){
        let examRepo = dependencyInjector.container.resolve(iExamRepository.self)
        
        exam.acquisitionDate = "22/12/2019 22:21:58 PM"
        exam.acquisitionNumber = "3223"
        exam.comments = "No Com"
        exam.deleteOnShutdown = ""
        exam.examKey = key
        exam.instanceNumber = "23233"
        exam.isArchived = "No"
        exam.isMetadata = "YES"
        exam.isPrivateData = "YES"
        exam.laterality = "sdf"
        exam.seriesKey = ""
        exam.sopClassUid = ""
        exam.sopInstanceUid = ""
        exam.storageCommitmentErrorCount = ""
        exam.storageCommitted = ""
        exam.xmlRetrieveData_XmlBlob = ""
        examRepo!.Save(entity: exam)
    }
    
    
    func Log() {
        
        let logger = dependencyInjector.container.resolve(ILogger.self)
        
        
        
        logger!.SetLogLevel(LogLevel: .Debug)
    
        logger!.Log(theme: "ViewController", logMessage: "log Message")
        logger!.ServiceLog(theme: "ViewController", logMessage: "ServiceLog Message")
        logger!.BackupRestoreLog(theme: "ViewController", logMessage: "BackupRestoreLog Message")
        logger!.AuditLog(theme: "ViewController", logMessage: "AuditLog Message")
   
       }

    func settingsManager() {
        
//        let settingsManager = dependencyInjector.container.resolve(ISettingsManager.self)
//
//        let settingsFileReader =  dependencyInjector.container.resolve(ISettingsFileReader.self)
//
//        let applicationSettingsContainer = dependencyInjector.container.resolve(ISettingsContainer.self)
//        let deviceSettingsContainer = dependencyInjector.container.resolve(ISettingsContainer.self)
//        let userSettingsContainer = dependencyInjector.container.resolve(ISettingsContainer.self)
//
//
//        settingsFileReader?.LoadSettingsFile(fileName: "default.settings", container: deviceSettingsContainer!)
//
//        settingsFileReader?.LoadSettingsFile(fileName: "application.settings", container: applicationSettingsContainer!)
//
//        settingsFileReader?.LoadSettingsFile(fileName: "user.settings", container: userSettingsContainer!)
//
//        let setting:Setting =  settingsManager!.GetSetting(categoryName: "default", name: "SwVersion")
//
//        let eventBroker = EventBroker()
//        eventBroker.publish(name: NSNotification.Name(rawValue: "settingsChanged"), object: setting)
//
        
    }
    */
}


//
//  InfrastructureServices.swift
//  GenericDeviceUI
//
//  Created by Carin on 6/11/19.
//  Copyright © 2019 Carin. All rights reserved.
//

import Foundation

import Czm_GenericDevice_SettingsManagement_Interfaces
import Czm_GenericDevice_EventBroker_Interfaces
import Czm_GenericDevice_Infrastructure_Interfaces
import Czm_GenericDevice_InfrastructureServices_Interfaces
import Czm_GenericDevice_DataManagement_Interfaces
import Czm_GenericDevice_CryptoServices_Interfaces
import Czm_GenericDevice_DataBaseManagement_Interfaces
import Czm_GenericDevice_SettingsManagement
import Czm_GenericDevice_Infrastructure
import Czm_GenericDevice_EventBroker
import Czm_GenericDevice_DataManagement
import Czm_GenericDevice_CryptoServices
import Czm_GenericDevice_DataBaseManagement
import Czm_GenericDevice_DependencyInjector_Interfaces
import Czm_GenericDevice_DependencyInjector
import Swinject
//import SwinjectAutoregistration
//import SwinjectStoryboard

public class InfrastructureServices:iInfrastructureServices {
   
     public var  logger:ILogger
     public var  settingsManager:ISettingsManager
     public var  eventBroker:IEventBroker
     public var  dependency:IDependencyInjector
     public var  container:Container
    
    public convenience init(){
        self.init(Logger: Logger.sharedInstance , SettingsManager: SettingsManager.sharedInstance, EventBroker: EventBroker.sharedInstance, Dependency: DependencyInjector.sharedInstance)
    }
    
     init(Logger: Logger , SettingsManager: SettingsManager, EventBroker: EventBroker, Dependency: DependencyInjector){
        self.logger = Logger
        self.settingsManager = SettingsManager
        self.dependency = Dependency
        self.eventBroker = EventBroker
        self.container = self.dependency.container
        self.initialize()
    }

    public func initialize(){
        
        self.dependency.container.register(ISettingsManager.self) { r in
            let settingManager = self.settingsManager
            return settingManager
            }.inObjectScope(ObjectScope.container)
        
        self.dependency.container.register(ILogger.self) { r in
            let logger = self.logger
            return logger
            }.inObjectScope(ObjectScope.container)
        
        self.dependency.container.register(IEventBroker.self) { r in
            let logger = self.eventBroker
            return logger
            }.inObjectScope(ObjectScope.container)
        
       self.dependency.container.register(iPatientRepository.self) { r in
           let patientRepo = PatientRepository()
           return patientRepo
       }
       self.dependency.container.register(ICryptoServices.self) { r in
           let logger = CryptoServices()
           return logger
           }.inObjectScope(ObjectScope.container)

       self.dependency.container.register(iExamRepository.self) { r in
           let exam = ExamRepository()
           return exam
           }.inObjectScope(ObjectScope.container)

       self.dependency.container.register(iSeriesRepository.self) { r in
           let series = SeriesRepository()
           return series
           }.inObjectScope(ObjectScope.container)

       self.dependency.container.register(iStudyRepository.self) { r in
           let Study = StudyRepository()
           return Study
           }.inObjectScope(ObjectScope.container)

       self.dependency.container.register(ISettingsContainer.self) { r in
           let settingsContainer = SettingsContainer()
           return settingsContainer
       }
       self.dependency.container.register(ISetting.self) { r in
           let setting = Setting()
           return setting
       }
       self.dependency.container.register(ISettingsFileReader.self) { r in
           let fileReader = SettingsFileReader()
           return fileReader
           }.inObjectScope(ObjectScope.container)

       self.dependency.container.register(ISettingsFileWriter.self) { r in
           let fileWriter = SettingsFileWriter()
           return fileWriter
           }.inObjectScope(ObjectScope.container)

       self.dependency.container.register(IRepository.self) { r in
           let repo = RepositoryBase()
           return repo
           }.inObjectScope(ObjectScope.container)

       self.dependency.container.register(ICoreDataManager.self) { r in
           let coreManager = CoreDataManager()
           return coreManager
           }.inObjectScope(ObjectScope.container)
        /*
         container.register(iVisitRepository.self) { r in
         let visit = VisitRepository()
         return visit
         }// not needed
         container.register(iRequestedAttributeRepository.self) { r in
         let reqAttribute = RequestedAttributeRepository()
         return reqAttribute
         }// not needed
         container.register(iSopUidRepository.self) { r in
         let sop = SopUidRepository()
         return sop
         }// not needed
         container.register(iCodeItemRepository.self) { r in
         let codeitem = CodeItemRepository()
         return codeitem
         }// not needed
         
         container.register(iExtendedPatientRepository.self) { r in
         let extendPatient = ExtendedPatientRepository()
         return extendPatient
         } // not needed
         container.register(IExtendedExamRepository.self) { r in
         let extendExam = ExtendedExamRepository()
         return extendExam
         }// not needed
         container.register(iRawExamRepository.self) { r in
         let RawExam = RawExamRepository()
         return RawExam
         }// not needed
         container.register(iEncapsulatedPdfRepository.self) { r in
         let pdfRepo = EncapsulatedPdfRepository()
         return pdfRepo
         }// not needed
         container.register(iMeasurementRepository.self) { r in
         let measurement = MeasurementRepository()
         return measurement
         }// not needed
         */
        
    }
  
    
    
}
//
//extension SwinjectStoryboard {
//
//
//    @objc class func setup() {
//
//        defaultContainer.autoregister(ISettingsManager.self, initializer: SettingsManager.init).inObjectScope(ObjectScope.container)
//        defaultContainer.autoregister(ILogger.self, initializer: Logger.init)
//        defaultContainer.autoregister(IEventBroker.self, initializer: EventBroker.init)
//
//       }
//
//}

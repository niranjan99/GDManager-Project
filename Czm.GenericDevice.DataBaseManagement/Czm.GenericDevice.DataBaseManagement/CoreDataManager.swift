//
//  CoreDataManager.swift
//  GD_FrameWork
//
//  Created by Carin on 12/14/18.
//  Copyright © 2018 Carin. All rights reserved.
//

import Foundation
import CoreData
import Czm_GenericDevice_DataBaseManagement_Interfaces

public class CoreDataManager:ICoreDataManager {

   
  //  public typealias T = NSManagedObject
   // public static let manager = CoreDataManager()
    public init() {
    }
   
   public func deleteAllRecords<T>(entity: T) where T : NSManagedObject {
       let managedContext =
           self.persistentContainer.viewContext
    
       let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Patient")
       let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
    
       do {
           try managedContext.execute(deleteRequest)
           try managedContext.save()
       } catch {
           print ("There was an error")
       }
   }
   
   public func delete<T>(entity: T) where T : NSManagedObject {
    
       let moc = persistentContainer.viewContext
       let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity.entity.name!)
       fetchRequest.predicate = NSPredicate(format: "key = %@", self.getKey(object: entity))
       fetchRequest.returnsObjectsAsFaults = false
    
       do {
           let results = try moc.fetch(fetchRequest)
        
           if results.count > 0 {
            
               for result in results as! [NSManagedObject] {
                
                   print ("Note:")
                   if let creationDate = result.value(forKey: "creationDate") {
                       print("creationDate: \(creationDate)")
                   }
                
                   moc.delete(result)
                
                   do {
                       try moc.save()
                   } catch {
                       print("failed to delete note")
                   }
               }
           }
       } catch {
           print ("Error in do")
       }
   }
   public func saveContext() {
       CoreDataManager.saveDB(persistantStore: persistentContainer)
   }

   
    public func getObjByID<T>(patientKey: String, entity: T) -> T where T : NSManagedObject {
       let moc = persistentContainer.viewContext
       let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity.entity.name!)
       fetchRequest.predicate = NSPredicate(format: "key = %@", "\(self.getKey(object: entity))")
       fetchRequest.returnsObjectsAsFaults = false
       var reqObjct:NSManagedObject? = nil
       do {
           let results = try moc.fetch(fetchRequest)
           if results.count > 0 {
            
               for result in results as! [NSManagedObject] {
                   reqObjct = result
               }
           }
       } catch {
           print ("Error in do")
       }
       return reqObjct! as! T
   }
   
   func getKey(object: NSManagedObject ) -> String {
   let value = object.value(forKey: "key")
       return  value as! String
   }

   public func save<T>(name: String, entity: T) where T : NSManagedObject {
    
    
       // 1
       let managedContext =
           self.persistentContainer.viewContext
    
       // 2
       let entity =
           NSEntityDescription.entity(forEntityName: entity.entity.name!,
                                      in: managedContext)!
    
       let patient = NSManagedObject(entity: entity,
                                     insertInto: managedContext)
    
       // 3
        patient.setValue(name, forKeyPath: "name")
    
        // 4
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    
    }


    public static func saveDB(persistantStore: NSPersistentContainer) {
        let context = persistantStore.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }


    lazy var managedObjectModel: NSManagedObjectModel = {
        return managedObjectModelD
    }()

//   var managedObjectModelD: NSManagedObjectModel  {
//           let modelIdentifier = "in.co.czm.carin.Czm-GenericDevice-DataManagement-Interfaces"
//           let frameWorkBundle = Bundle(identifier: modelIdentifier)!
//           let modelURL = frameWorkBundle.url(forResource: "GenericDevice", withExtension: "momd")!
//           return NSManagedObjectModel(contentsOf: modelURL)!
//       }
  var managedObjectModelD: NSManagedObjectModel = {
    
        var managedObjectBaseModel: NSManagedObjectModel = {
            let modelIdentifier = "in.co.czm.carin.Czm-GenericDevice-DataManagement-Interfaces"
            let frameWorkBundle = Bundle(identifier: modelIdentifier)!
            
            let modelURL = frameWorkBundle.url(forResource: "GenericDevice", withExtension: "momd")!
            return NSManagedObjectModel(contentsOf: modelURL)!
        }()
    
    
        var managedObjectExtendedModel: NSManagedObjectModel = {
            let modelIdentifier = "in.co.czm.carin.Czm-GenericDevice-DeviceDataManagement-Interfaces" //in.co.czm.carin.BaseProject
            let applicationBundle = Bundle(identifier: modelIdentifier)!
            let modelURL = applicationBundle.url(forResource: "ExtendedModel", withExtension: "momd")!
            return NSManagedObjectModel(contentsOf: modelURL)!
        }()
    
    
    
        let managedObjectModel = [managedObjectExtendedModel,managedObjectBaseModel]
    
        let combinedModel = NSManagedObjectModel(byMerging: managedObjectModel)
    
//        let patient = combinedModel?.entities.first(where: { (item) -> Bool in
//            item.name == "Patient"
//        })
//
//        let extpatient = combinedModel?.entities.first(where: { (item) -> Bool in
//            item.name == "ExtendedPatient"
//        })
//
//        let entriesRelation = NSRelationshipDescription()
//        entriesRelation.name = "Patient"
//        entriesRelation.destinationEntity = patient
//        entriesRelation.minCount = 0
//        entriesRelation.maxCount = 1 // max = 0 for to-many relationship
//        entriesRelation.deleteRule = .cascadeDeleteRule
//        extpatient?.properties.append(entriesRelation)
//
//        let extendedPatientRelation = NSRelationshipDescription()
//        extendedPatientRelation.name = "ExtendedPatient"
//        extendedPatientRelation.destinationEntity = patient
//        extendedPatientRelation.minCount = 0
//        extendedPatientRelation.maxCount = 1 // max = 0 for to-many relationship
//        extendedPatientRelation.deleteRule = .cascadeDeleteRule
//        patient?.properties.append(extendedPatientRelation)
//
//   let exam = combinedModel?.entities.first(where: { (item) -> Bool in
//       item.name == "Exam"
//   })
//
//   let extExam = combinedModel?.entities.first(where: { (item) -> Bool in
//       item.name == "ExtendedExam"
//   })


        return combinedModel!
    
    }()
    public lazy var persistentContainer: NSPersistentContainer = {
        
        let container = NSPersistentContainer(name: "Czm.GenericDevice.DataBaseManagement.Interfaces", managedObjectModel:managedObjectModel)
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()


    public func insertNewObject(entity:String) ->NSManagedObject  {
        
        let testEntity =  NSEntityDescription.entity(forEntityName: entity, in: persistentContainer.viewContext)
        let NSMobj = NSManagedObject(entity: testEntity!, insertInto: persistentContainer.viewContext)
        return NSMobj
        
    }

    public func bundleInit(bundles: [String]) {
        
    }

}


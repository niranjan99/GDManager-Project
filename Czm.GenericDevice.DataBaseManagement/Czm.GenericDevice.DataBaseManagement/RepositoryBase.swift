//
//  RepositoryBase.swift
//  Czm.GenericDevice.DataBaseManagement
//
//  Created by Carin on 3/19/19.
//  Copyright © 2019 Carin. All rights reserved.
//

import Foundation
import CoreData
import Czm_GenericDevice_DataBaseManagement_Interfaces

open class RepositoryBase : IRepository
{
    public init() {
        
    }
    
    public func Save<T>(entity: T) {
        let coredatamanager = CoreDataManager()
        coredatamanager.saveContext()
    }
    
    public func Delete<T>(entity: T) {
         let coredatamanager = CoreDataManager()
        coredatamanager.delete(entity: entity as! NSManagedObject)
    }
    
    public func DeleteById<T>(entity: T, id: String) {
         let coredatamanager = CoreDataManager()
        coredatamanager.delete(entity: entity as! NSManagedObject)
    }
    
    public func GetById<T>(entity: T, id: String) {
        let coredatamanager = CoreDataManager()
       coredatamanager.delete(entity: entity as! NSManagedObject)
    }
    
    public func Refresh<T>(entity: T) {
        
    }
    
    public func Evict<T>(entity: T) {
        
    }
    
    public func getInstance(entity: String) -> NSManagedObject {
         let coredatamanager = CoreDataManager()
         return  coredatamanager.insertNewObject(entity: entity)
    }

  
}




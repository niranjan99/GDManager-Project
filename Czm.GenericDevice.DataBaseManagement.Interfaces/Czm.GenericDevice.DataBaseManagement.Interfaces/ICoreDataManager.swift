//
//  i_CoreDataManager.swift
//  Czm.GenericDevice.DataBaseManagement.Interfaces
//
//  Created by Carin on 3/19/19.
//  Copyright © 2019 Carin. All rights reserved.
//

import Foundation
import CoreData
public protocol ICoreDataManager
{
   // associatedtype T
    func bundleInit(bundles: [String])
    func delete<T:NSManagedObject>(entity:T)
    func saveContext()
    func getObjByID<T:NSManagedObject>(patientKey: String, entity:T) -> T
    static func saveDB(persistantStore:NSPersistentContainer)
    func deleteAllRecords<T:NSManagedObject>(entity:T)
    func save<T:NSManagedObject>(name: String, entity:T)
}

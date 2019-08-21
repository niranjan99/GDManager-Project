
//
//  IRepository.swift
//  Czm.GenericDevice.DataBaseManagement.Interfaces
//
//  Created by Carin on 12/14/18.
//  Copyright © 2018 Carin. All rights reserved.
//
//https://medium.com/swift2go/mastering-generics-with-protocols-the-specification-pattern-5e2e303af4ca

import Foundation
import CoreData

public protocol IRepository {
   // associatedtype T
    func Save<T>(entity:T)
    func Delete<T>(entity:T)
    func DeleteById<T>(entity:T, id:String)
    func GetById<T>(entity:T, id:String)
    func Refresh<T>(entity:T)
    func Evict<T>(entity:T)
    func getInstance(entity:String) ->NSManagedObject
}

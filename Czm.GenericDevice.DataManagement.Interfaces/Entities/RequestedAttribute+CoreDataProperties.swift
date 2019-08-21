//
//  RequestedAttribute+CoreDataProperties.swift
//  Czm.GenericDevice.DataManagement.Interfaces
//
//  Created by Carin on 3/19/19.
//  Copyright © 2019 Carin. All rights reserved.
//
//

import Foundation
import CoreData


extension RequestedAttribute {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<RequestedAttribute> {
        return NSFetchRequest<RequestedAttribute>(entityName: "RequestedAttribute")
    }

    @NSManaged public var key: String?
    @NSManaged public var requestedAttributeKey: String?
    @NSManaged public var requestedProcedureCodeKey: String?
    @NSManaged public var requestedProcedureComments: String?
    @NSManaged public var requestedProcedureDescription: String?
    @NSManaged public var requestedProcedureId: String?
    @NSManaged public var scheduledProcedureStepDescription: String?
    @NSManaged public var scheduledProcedureStepId: String?
    @NSManaged public var codeItem: NSSet?

}

// MARK: Generated accessors for codeItem
extension RequestedAttribute {

    @objc(addCodeItemObject:)
    @NSManaged public func addToCodeItem(_ value: CodeItem)

    @objc(removeCodeItemObject:)
    @NSManaged public func removeFromCodeItem(_ value: CodeItem)

    @objc(addCodeItem:)
    @NSManaged public func addToCodeItem(_ values: NSSet)

    @objc(removeCodeItem:)
    @NSManaged public func removeFromCodeItem(_ values: NSSet)

}

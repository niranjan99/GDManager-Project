//
//  CodeItem+CoreDataProperties.swift
//  Czm.GenericDevice.DataManagement.Interfaces
//
//  Created by Carin on 3/19/19.
//  Copyright © 2019 Carin. All rights reserved.
//
//

import Foundation
import CoreData

extension CodeItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CodeItem> {
        return NSFetchRequest<CodeItem>(entityName: "CodeItem")
    }

    @NSManaged public var key: String?
    @NSManaged public var meaning: String?
    @NSManaged public var schemeDesignator: String?
    @NSManaged public var schemeVersion: String?
    @NSManaged public var value: String?

}

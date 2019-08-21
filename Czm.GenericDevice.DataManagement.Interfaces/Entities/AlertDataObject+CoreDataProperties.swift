//
//  AlertDataObject+CoreDataProperties.swift
//  Czm.GenericDevice.DataManagement.Interfaces
//
//  Created by Carin on 3/19/19.
//  Copyright © 2019 Carin. All rights reserved.
//
//

import Foundation
import CoreData


extension AlertDataObject {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AlertDataObject> {
        return NSFetchRequest<AlertDataObject>(entityName: "AlertDataObject")
    }

    @NSManaged public var alertCode: String?
    @NSManaged public var descriptionParameters: String?
    @NSManaged public var id: String?
    @NSManaged public var occurrenceTime: String?
    @NSManaged public var userName: String?

}

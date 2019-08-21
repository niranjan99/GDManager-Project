//
//  Visit+CoreDataProperties.swift
//  Czm.GenericDevice.DataManagement.Interfaces
//
//  Created by Carin on 3/19/19.
//  Copyright © 2019 Carin. All rights reserved.
//
//

import Foundation
import CoreData


extension Visit {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Visit> {
        return NSFetchRequest<Visit>(entityName: "Visit")
    }

    @NSManaged public var patientKey: String?
    @NSManaged public var visitDate: String?

}

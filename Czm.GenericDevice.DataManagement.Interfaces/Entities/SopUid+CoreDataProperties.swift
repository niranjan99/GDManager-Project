//
//  SopUid+CoreDataProperties.swift
//  Czm.GenericDevice.DataManagement.Interfaces
//
//  Created by Carin on 3/19/19.
//  Copyright © 2019 Carin. All rights reserved.
//
//

import Foundation
import CoreData


extension SopUid {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SopUid> {
        return NSFetchRequest<SopUid>(entityName: "SopUid")
    }

    @NSManaged public var key: String?
    @NSManaged public var referencedSopClassUid: String?
    @NSManaged public var referencedSopInstanceUid: String?

}

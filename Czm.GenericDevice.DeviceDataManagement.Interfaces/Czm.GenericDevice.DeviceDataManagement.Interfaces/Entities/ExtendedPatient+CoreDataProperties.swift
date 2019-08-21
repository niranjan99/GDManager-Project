//
//  ExtendedPatient+CoreDataProperties.swift
//  DeviceDataManagement.Interfaces
//
//  Created by Carin on 4/9/19.
//  Copyright © 2019 Carin. All rights reserved.
//
//

import Foundation
import CoreData


extension ExtendedPatient {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ExtendedPatient> {
        return NSFetchRequest<ExtendedPatient>(entityName: "ExtendedPatient")
    }

    @NSManaged public var devicePatientKey: String?
    @NSManaged public var eyeColor: String?
    @NSManaged public var height: String?

}

//
//  ExamMeasurement+CoreDataProperties.swift
//  DeviceDataManagement.Interfaces
//
//  Created by Carin on 4/9/19.
//  Copyright © 2019 Carin. All rights reserved.
//
//

import Foundation
import CoreData


extension ExamMeasurement {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ExamMeasurement> {
        return NSFetchRequest<ExamMeasurement>(entityName: "ExamMeasurement")
    }

    @NSManaged public var key: String?
    @NSManaged public var measurementKey: String?
    @NSManaged public var name: String?

}

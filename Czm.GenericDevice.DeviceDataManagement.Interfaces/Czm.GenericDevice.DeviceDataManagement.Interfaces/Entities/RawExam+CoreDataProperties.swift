//
//  RawExam+CoreDataProperties.swift
//  DeviceDataManagement.Interfaces
//
//  Created by Carin on 4/9/19.
//  Copyright © 2019 Carin. All rights reserved.
//
//

import Foundation
import CoreData


extension RawExam {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<RawExam> {
        return NSFetchRequest<RawExam>(entityName: "RawExam")
    }

    @NSManaged public var fileName: String?
    @NSManaged public var exExamKey: String?

}

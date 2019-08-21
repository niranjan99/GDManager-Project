//
//  ExtendedExam+CoreDataProperties.swift
//  DeviceDataManagement.Interfaces
//
//  Created by Carin on 4/9/19.
//  Copyright © 2019 Carin. All rights reserved.
//
//

import Foundation
import CoreData


extension ExtendedExam {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ExtendedExam> {
        return NSFetchRequest<ExtendedExam>(entityName: "ExtendedExam")
    }

    @NSManaged public var deviceExamKey: String?
    @NSManaged public var duration: String?
    @NSManaged public var examType: String?
    @NSManaged public var image: String?
    @NSManaged public var key: String?
    @NSManaged public var rawExam: RawExam?
    @NSManaged public var measurement: ExamMeasurement?
    @NSManaged public var enPdf: EncapsulatedPdf?

}

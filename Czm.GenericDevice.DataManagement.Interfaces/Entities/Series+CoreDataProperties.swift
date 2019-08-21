//
//  Series+CoreDataProperties.swift
//  Czm.GenericDevice.DataManagement.Interfaces
//
//  Created by Carin on 3/19/19.
//  Copyright © 2019 Carin. All rights reserved.
//
//

import Foundation
import CoreData


extension Series {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Series> {
        return NSFetchRequest<Series>(entityName: "Series")
    }

    @NSManaged public var departmentName: String?
    @NSManaged public var deviceSerialNumber: String?
    @NSManaged public var institutionAddress: String?
    @NSManaged public var institutionName: String?
    @NSManaged public var isMetadata: String?
    @NSManaged public var lastCalibration: String?
    @NSManaged public var manufacturer: String?
    @NSManaged public var manufacturersModelName: String?
    @NSManaged public var number: String?
    @NSManaged public var performedProcedureStepStartDate: String?
    @NSManaged public var performingPhysician_FamilyName_Ideographic: String?
    @NSManaged public var performingPhysician_FamilyName_Phonetic: String?
    @NSManaged public var performingPhysician_GivenName: String?
    @NSManaged public var performingPhysician_GivenName_Ideographic: String?
    @NSManaged public var performingPhysician_GivenName_Phonetic: String?
    @NSManaged public var performingPhysician_MiddleName: String?
    @NSManaged public var performingPhysician_MiddleName_Ideographic: String?
    @NSManaged public var performingPhysician_MiddleName_Phonetic: String?
    @NSManaged public var performingPhysician_Prefix: String?
    @NSManaged public var performingPhysician_Prefix_Ideographic: String?
    @NSManaged public var performingPhysician_Prefix_Phonetic: String?
    @NSManaged public var performingPhysician_Suffix: String?
    @NSManaged public var performingPhysician_Suffix_Ideographic: String?
    @NSManaged public var performingPhysician_Suffix_Phonetic: String?
    @NSManaged public var seriesDate: String?
    @NSManaged public var seriesid: String?
    @NSManaged public var snstanceUid: String?
    @NSManaged public var softwareVersion: String?
    @NSManaged public var stationName: String?
    @NSManaged public var studyKey: String?
    @NSManaged public var synchronizationFrameofReferenceUid: String?
    @NSManaged public var exam: NSSet?
    @NSManaged public var study: Study?

}

// MARK: Generated accessors for exam
extension Series {

    @objc(addExamObject:)
    @NSManaged public func addToExam(_ value: Exam)

    @objc(removeExamObject:)
    @NSManaged public func removeFromExam(_ value: Exam)

    @objc(addExam:)
    @NSManaged public func addToExam(_ values: NSSet)

    @objc(removeExam:)
    @NSManaged public func removeFromExam(_ values: NSSet)

}

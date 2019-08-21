//
//  Patient+CoreDataProperties.swift
//  Czm.GenericDevice.DataManagement.Interfaces
//
//  Created by Carin on 3/19/19.
//  Copyright © 2019 Carin. All rights reserved.
//
//

import Foundation
import CoreData


extension Patient {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Patient> {
        return NSFetchRequest<Patient>(entityName: "Patient")
    }

    @NSManaged public var birthDate: String?
    @NSManaged public var comments: String?
    @NSManaged public var creationDate: String?
    @NSManaged public var ethnicGroup: String?
    @NSManaged public var familyName: String?
    @NSManaged public var familyName_Ideographic: String?
    @NSManaged public var familyName_Phonetic: String?
    @NSManaged public var givenName: String?
    @NSManaged public var givenName_Ideographic: String?
    @NSManaged public var givenName_Phonetic: String?
    @NSManaged public var id: String?
    @NSManaged public var isInArchive: Bool
    @NSManaged public var issuerOfPatientId: String?
    @NSManaged public var key: String?
    @NSManaged public var middleName: String?
    @NSManaged public var middleName_Ideographic: String?
    @NSManaged public var middleName_Phonetic: String?
    @NSManaged public var otherPatientIds: String?
    @NSManaged public var owner: String?
    @NSManaged public var patientKey: String?
    @NSManaged public var prefix: String?
    @NSManaged public var prefix_Ideographic: String?
    @NSManaged public var prefix_Phonetic: String?
    @NSManaged public var sex: String?
    @NSManaged public var suffix: String?
    @NSManaged public var suffix_Ideographic: String?
    @NSManaged public var suffix_Phonetic: String?
    @NSManaged public var study: NSSet?

}

// MARK: Generated accessors for study
extension Patient {

    @objc(addStudyObject:)
    @NSManaged public func addToStudy(_ value: Study)

    @objc(removeStudyObject:)
    @NSManaged public func removeFromStudy(_ value: Study)

    @objc(addStudy:)
    @NSManaged public func addToStudy(_ values: NSSet)

    @objc(removeStudy:)
    @NSManaged public func removeFromStudy(_ values: NSSet)

}

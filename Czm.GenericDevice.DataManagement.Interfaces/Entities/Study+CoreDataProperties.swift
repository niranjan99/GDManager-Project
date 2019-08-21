//
//  Study+CoreDataProperties.swift
//  Czm.GenericDevice.DataManagement.Interfaces
//
//  Created by Carin on 3/19/19.
//  Copyright © 2019 Carin. All rights reserved.
//
//

import Foundation
import CoreData


extension Study {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Study> {
        return NSFetchRequest<Study>(entityName: "Study")
    }

    @NSManaged public var accessionNumber: String?
    @NSManaged public var date: String?
    @NSManaged public var descriptiOn: String?
    @NSManaged public var id: String?
    @NSManaged public var isMetadata: Bool
    @NSManaged public var patientKey: String?
    @NSManaged public var referringPhysician_FamilyName: String?
    @NSManaged public var referringPhysician_FamilyName_Ideographic: String?
    @NSManaged public var referringPhysician_FamilyName_Phonetic: String?
    @NSManaged public var referringPhysician_GivenName: String?
    @NSManaged public var referringPhysician_GivenName_Ideographic: String?
    @NSManaged public var referringPhysician_GivenName_Phonetic: String?
    @NSManaged public var referringPhysician_MiddleName: String?
    @NSManaged public var referringPhysician_MiddleName_Ideographic: String?
    @NSManaged public var referringPhysician_MiddleName_Phonetic: String?
    @NSManaged public var referringPhysician_Prefix: String?
    @NSManaged public var referringPhysician_Prefix_Ideographic: String?
    @NSManaged public var referringPhysician_Prefix_Phonetic: String?
    @NSManaged public var referringPhysician_Suffix: String?
    @NSManaged public var referringPhysician_Suffix_Ideographic: String?
    @NSManaged public var referringPhysician_Suffix_Phonetic: String?
    @NSManaged public var studyInstanceUid: String?
    @NSManaged public var studyKey: String?
    @NSManaged public var key: String?
    @NSManaged public var patient: Patient?
    @NSManaged public var series: NSSet?

}

// MARK: Generated accessors for series
extension Study {

    @objc(addSeriesObject:)
    @NSManaged public func addToSeries(_ value: Series)

    @objc(removeSeriesObject:)
    @NSManaged public func removeFromSeries(_ value: Series)

    @objc(addSeries:)
    @NSManaged public func addToSeries(_ values: NSSet)

    @objc(removeSeries:)
    @NSManaged public func removeFromSeries(_ values: NSSet)

}

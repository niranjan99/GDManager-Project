//
//  Exam+CoreDataProperties.swift
//  Czm.GenericDevice.DataManagement.Interfaces
//
//  Created by Carin on 3/19/19.
//  Copyright © 2019 Carin. All rights reserved.
//
//

import Foundation
import CoreData


extension Exam {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Exam> {
        return NSFetchRequest<Exam>(entityName: "Exam")
    }

    @NSManaged public var acquisitionDate: String?
    @NSManaged public var acquisitionNumber: String?
    @NSManaged public var comments: String?
    @NSManaged public var contentDate: String?
    @NSManaged public var deleteOnShutdown: String?
    @NSManaged public var examKey: String?
    @NSManaged public var instanceNumber: String?
    @NSManaged public var isArchived: String?
    @NSManaged public var isMetadata: String?
    @NSManaged public var isPrivateData: String?
    @NSManaged public var laterality: String?
    @NSManaged public var seriesKey: String?
    @NSManaged public var sopClassUid: String?
    @NSManaged public var sopInstanceUid: String?
    @NSManaged public var storageCommitmentErrorCount: String?
    @NSManaged public var storageCommitted: String?
    @NSManaged public var xmlRetrieveData_XmlBlob: String?
    @NSManaged public var series: Series?

}

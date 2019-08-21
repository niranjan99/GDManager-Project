//
//  EncapsulatedPdf+CoreDataProperties.swift
//  DeviceDataManagement.Interfaces
//
//  Created by Carin on 4/9/19.
//  Copyright © 2019 Carin. All rights reserved.
//
//

import Foundation
import CoreData


extension EncapsulatedPdf {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<EncapsulatedPdf> {
        return NSFetchRequest<EncapsulatedPdf>(entityName: "EncapsulatedPdf")
    }

    @NSManaged public var conversionType: String?
    @NSManaged public var documentTitle: String?
    @NSManaged public var encapsulatedPdfKey: String?
    @NSManaged public var key: String?
    @NSManaged public var mimeType: String?
    @NSManaged public var pdfDicomFile: String?
    @NSManaged public var pdfFile: String?
    @NSManaged public var pdfType: String?

}

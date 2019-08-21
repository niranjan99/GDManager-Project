//
//  ISettingsFileWriter.swift
//  XMLSample
//
//  Created by Carin on 4/29/19.
//  Copyright © 2019 Carin. All rights reserved.
//

import Foundation

public protocol ISettingsFileWriter {
   
    func Save(fileName:String, container: ISettingsContainer)
}

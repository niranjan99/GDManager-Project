//
//  SettingsCategory.swift
//  XMLSample
//
//  Created by Carin on 4/29/19.
//  Copyright © 2019 Carin. All rights reserved.
//

import Foundation
import Czm_GenericDevice_SettingsManagement_Interfaces
public class SettingsCategory {
    
    var settings: Dictionary<String, Setting> = [:]
    var name = String()
    var sourceType =  String()
    
    public static let manager = SettingsCategory()
    private init() {
        settings = NSMutableDictionary() as! Dictionary<String, Setting>
        name = String()
        sourceType =  String()
    }
    func Name() -> String{

        return name
    }
    func Settings() -> Dictionary<String, Setting> {
        
        return settings
    }
    func SourceType() -> String{
        
        return sourceType
    }
    
}


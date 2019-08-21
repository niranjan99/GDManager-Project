//
//  ISettingsManager.swift
//  XMLSample
//
//  Created by Carin on 5/5/19.
//  Copyright © 2019 Carin. All rights reserved.
//

import Foundation
public protocol ISettingsManager{
    
    func DeleteAllUserSettings()
    func DeleteAllApplicationSettings()
    func DeleteUserSetting(categoryName:String,name:String)
    func DeleteApplicationSetting(categoryName:String,name:String)
    func DeleteUserSettingCategory(categoryName:String)
    func DeleteApplicationSettingCategory(categoryName:String)
    func GetSetting<T>(categoryName:String,name:String) -> T
    func TryGetSetting<T>(categoryName:String,name:String, value:T) -> Bool
    func GetCategory<T>(categoryName:String) -> Dictionary<String,[T]>
    func LoadSettingsFile(categoryName:String)
    func ResetCategory(categoryName:String)
    func ResetSetting(categoryName:String,settingName:String)
    func Save()
    func SetSetting<T>(categoryName:String,name:String, value:T )
    func Detach()
    func ExportSettingsToFile(targetFile:String, params:[String])
    
    var applicationSettingsContainer:ISettingsContainer { get set}
    var deviceSettingsContainer:ISettingsContainer { get set}
    var userSettingsContainer:ISettingsContainer { get set}
    var setting:ISetting { get set}
    var isDetached:Bool { get set}

}

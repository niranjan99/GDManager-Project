//
//  SettingsManager.swift
//  XMLSample
//
//  Created by Carin on 5/5/19.
//  Copyright © 2019 Carin. All rights reserved.
//

import Foundation
import Czm_GenericDevice_SettingsManagement_Interfaces
import Czm_GenericDevice_CryptoServices

public class SettingsManager:ISettingsManager{
    public var applicationSettingsContainer: ISettingsContainer
    public var deviceSettingsContainer: ISettingsContainer
    public var userSettingsContainer: ISettingsContainer
    public var setting: ISetting
    public var isDetached:Bool
    
    public static let sharedInstance = SettingsManager()
    
    public init() {
        
        applicationSettingsContainer = SettingsContainer()
        deviceSettingsContainer = SettingsContainer()
        userSettingsContainer = SettingsContainer()
        setting = Setting()
        isDetached = Bool()
    }
    
    public func GetCategory<T>(categoryName: String) -> Dictionary<String, [T]> {
       
        let deviceDict:Dictionary<String, [Setting]> = userSettingsContainer.Categories()
        let applicationDict:Dictionary<String, [Setting]> = applicationSettingsContainer.Categories()
        
        var arrSettings = NSArray()
        if let _ = deviceDict[categoryName]
            
        {
            arrSettings = deviceDict[categoryName]! as NSArray
        }
        else if let _ = applicationDict[categoryName] {
            arrSettings = deviceDict[categoryName]! as NSArray
        }
        var catDict:Dictionary<String, [Setting]> = NSMutableDictionary() as! Dictionary<String, [Setting]>
        
        var settings = [setting]
        
        for i in 0..<arrSettings.count {
            let setting:Setting = arrSettings.object(at: i) as! Setting
            settings.append(setting)
        }
        catDict =  [categoryName : settings] as! Dictionary<String, [Setting]>
        
        
        return catDict as! Dictionary<String, [T]>
    }
    
    

    public func DeleteAllUserSettings() {
        userSettingsContainer.categories.removeAll()
        deleteFilePath(filename: "user.settings")
    }
    
    public func DeleteAllApplicationSettings() {
        applicationSettingsContainer.categories.removeAll()
        deleteFilePath(filename: "application.settings")
        
    }
    
    public func DeleteUserSetting(categoryName: String, name: String) {
        
        userSettingsContainer.DeleteSetting(categoryName: categoryName, settingName: name, filename: "user.settings")
        
    }
    
    public func DeleteApplicationSetting(categoryName: String, name: String) {
        
        applicationSettingsContainer.DeleteSetting(categoryName: categoryName, settingName: name, filename: "application.settings")
    }
    
    public func DeleteUserSettingCategory(categoryName: String) {
        userSettingsContainer.DeleteCategory(categoryName: categoryName, filename: "user.settings")
    }
    
    public func DeleteApplicationSettingCategory(categoryName: String) {
        applicationSettingsContainer.DeleteCategory(categoryName: categoryName, filename: "application.settings")
    }
    
    public func GetSetting<T>(categoryName: String, name: String) -> T {
        
        let userDict:Dictionary<String, [Setting]> = userSettingsContainer.Categories()
        let userContains =  self.TryGetSetting(categoryName: categoryName, name: name, value: userDict)
        
        if userContains
        {
            return setting as! T
        }
        
        let appDict:Dictionary<String, [Setting]> = applicationSettingsContainer.Categories()
        let appContains =  self.TryGetSetting(categoryName: categoryName, name: name, value: appDict)
        
        if appContains
        {
            return setting as! T
        }
        
        let deviceDict:Dictionary<String, [Setting]> = deviceSettingsContainer.Categories()
        let devContains =  self.TryGetSetting(categoryName: categoryName, name: name, value: deviceDict)
        
        if devContains
        {
            return setting as! T
        }
        
        return setting as! T
        
        
    }
    
    public func TryGetSetting<T>(categoryName: String, name: String, value: T) -> Bool {
        
        var dict = value as! Dictionary<String,[Setting]>
        if let _ = dict[categoryName] {
            let arrSettings:NSArray = dict[categoryName]! as NSArray
            for i in 0..<arrSettings.count {
                
                let setting:Setting = arrSettings.object(at: i) as! Setting
                
                if (setting.name == name){
                    if setting.isEncrypted{
                      setting.valueString = self.decrypt(encryptedText: setting.valueString, password: "6898ecc%$#@")
                    }
                    self.SaveSetting(categoryName: categoryName, name: name, value: setting)
                    return true
                }
            }
        }
        return false
    }
    
    public func LoadSettingsFile(categoryName: String) {
        
        self.LoadSettingsFile(categoryName: categoryName, container: userSettingsContainer)
    }
    
    func LoadSettingsFile(categoryName: String, container:ISettingsContainer) {
        
        
        
        
    }
    
    public func ResetCategory(categoryName: String) {
        
    }
    
    public func ResetSetting(categoryName: String, settingName: String) {
        
    }
    
    public func Save()
    {
        
        if !isDetached{
            
            
            if userSettingsContainer.categories.count == 0 {
                 userSettingsContainer.Save()
            }
            if applicationSettingsContainer.categories.count == 0 {
                 applicationSettingsContainer.Save()
            }

        }
    }
    
    public func SetSetting<T>(categoryName: String, name: String, value: T) {
        
        let valueString:String = value as! String
        
        let deviceDict:Dictionary<String, [Setting]> = deviceSettingsContainer.Categories()
        
        let devContainsSetting:Bool =  self.TryGetSetting(categoryName: categoryName, name: name, value: deviceDict)
        
        if devContainsSetting == false
        {
            print("The category\(setting.categoryName) cannot be found.")
        }
        else if setting.valueString == value as! String{
            print("Its duplicate value")
            
        }
        else{
            
            if setting.isReadOnly{
                
                print("The setting\(setting.valueString) category \(setting.categoryName),is readonly and cannot be changed." )
            }
            else{
                
                let settingcontainer = SettingsContainer()
                if setting.scope == .application
                {
                    
                    settingcontainer.SetSettingValue(originSetting: setting, sourceType: "application", value: valueString)
                    print("application")
                }
                else
                {
                    settingcontainer.SetSettingValue(originSetting: setting, sourceType: "user", value: valueString)
                    print("User")
                }
            }
            
            
        }
        
    }
    public func Detach() {
        
        isDetached = true
    }
    
    public func ExportSettingsToFile(targetFile: String, params: [String]) {
        
    }
    
    public func SaveSetting<T>(categoryName: String, name: String, value: T) {
        
        setting = value as! Setting
        
    }
    
    
    func deleteFilePath(filename:String) {
        let fileManager = FileManager.default
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        let path = documentsPath.appendingPathComponent(String(format: "%@.xml",filename))
        
        do {
            let filePaths = try fileManager.contentsOfDirectory(atPath: path)
            for filePath in filePaths {
                try fileManager.removeItem(atPath: path + filePath)
            }
        } catch {
            print("Could not clear temp folder: \(error)")
        }
    }
    func decrypt(encryptedText : String, password: String) -> String {
        do  {
            let data: Data = Data(base64Encoded: encryptedText)! // Just get data from encrypted base64Encoded string.
            let decryptedData = try RNCryptor.decrypt(data: data, withPassword: password)
            let decryptedString = String(data: decryptedData, encoding: .utf8) // Getting original string, using same .utf8 encoding option,which we used for encryption.
            return decryptedString ?? ""
        }
        catch {
            return "FAILED"
        }
    }
}


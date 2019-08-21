//
//  SettingsdependencyInjector.container.swift
//  XMLSample
//
//  Created by Carin on 4/29/19.
//  Copyright © 2019 Carin. All rights reserved.
//

import Foundation
import Czm_GenericDevice_SettingsManagement_Interfaces
import Czm_GenericDevice_CryptoServices
import Czm_GenericDevice_DependencyInjector
import Czm_GenericDevice_InfrastructureServices_Interfaces
import Swinject
public class SettingsContainer:ISettingsContainer {
    public var fileName: String
    public var categories: Dictionary<String, [ISetting]>
    public var name: String
    var dependencyInjector = DependencyInjector.sharedInstance
    public  init(){
   
        fileName = String()
        categories = Dictionary<String, [Setting]>()
        name =  String()
        dependencyInjector = DependencyInjector.sharedInstance
    }
    
    public func SetSettingValue<T>(originSetting: T, sourceType: String, value: String) {
//
       var infrstucture = dependencyInjector.container.resolve(iInfrastructureServices.self)

        let setting:Setting = originSetting as! Setting
        let categoryName:String = setting.CategoryName();
        let valueString:String = value
        var patientDetailsArray = [Setting]()
        if sourceType == "application"{

            if setting.valueString == valueString{
                // duplicate value
            }
            else{
                setting.valueString = valueString
                patientDetailsArray.append(setting)
                let dictionary = infrstucture!.settingsManager.applicationSettingsContainer.categories
                if dictionary.count > 0{
                    let category = dictionary[categoryName]
                    if category != nil {
                        for sett in category! {
                            if sett.valueString != setting.valueString{

                                if !setting.isReadOnly{

                                    if  setting.isEncrypted{

                                        let encryptedstring =  self.encrypt(plainText: setting.valueString, password: "6898ecc%$#@")

                                        setting.valueString = encryptedstring
                                    }
                                    patientDetailsArray.append(setting )
                                }
                                else{
                                    print("The setting {0}, category {1}, is readonly and cannot be changed.")

                                }


                            }
                        }
                    }
                }
                infrstucture?.settingsManager.applicationSettingsContainer.categories.updateValue(patientDetailsArray, forKey: categoryName)

                categories = infrstucture!.settingsManager.applicationSettingsContainer.categories
                fileName = "application.settings"
                self.Save()

            }
        }
        else{

            if setting.valueString == valueString{
                // duplicate value
            }
            else{
                setting.valueString = valueString
                patientDetailsArray.append(setting)
                let dictionary = infrstucture!.settingsManager.userSettingsContainer.categories

                if dictionary.count > 0{

                    let category = dictionary[categoryName]
                    if category != nil {
                        for ss in category! {
                            if ss.valueString != setting.valueString{

                                if !setting.isReadOnly{

                                    if  setting.isEncrypted{

                                        let encryptedstring =  self.encrypt(plainText: setting.valueString, password: "6898ecc%$#@")
                                        setting.valueString = encryptedstring
                                    }
                                    patientDetailsArray.append(setting)
                                }
                                else{


                                    print("The setting {0}, category {1}, is readonly and cannot be changed.")

                                }


                            }
                        }
                    }
                }
                infrstucture!.settingsManager.userSettingsContainer.categories.updateValue(patientDetailsArray, forKey: categoryName)
                categories = infrstucture!.settingsManager.userSettingsContainer.categories
                fileName = "user.settings"
                self.Save()
            }

        }
 }
  
  public func Categories<T>() -> Dictionary<String, [T]> {
      return categories as! Dictionary<String, [T]>
  }
  
  
  public func DeleteAllSettings() {
    
  }
  public func DeleteCategory(categoryName: String, filename: String) {
        var infrstucture = dependencyInjector.container.resolve(iInfrastructureServices.self)

        if filename == "user.settings"{
            categories = infrstucture!.settingsManager.userSettingsContainer.Categories()
            print("categories",categories)
            if categories.count != 0{
                categories.removeValue(forKey: categoryName)
                infrstucture!.settingsManager.userSettingsContainer.categories = categories

            }
            else{
                print("usersettings has no data")
            }
        }
        else{
            categories = infrstucture!.settingsManager.applicationSettingsContainer.Categories()
            print("categories",categories)
            if categories.count != 0{
                categories.removeValue(forKey: categoryName)
                infrstucture!.settingsManager.applicationSettingsContainer.categories = categories
            }
            else{
                print("usersettings has no data")
            }
        }
  }
  public func DeleteSetting(categoryName: String, settingName: String, filename: String) {
   
        var infrstucture = dependencyInjector.container.resolve(iInfrastructureServices.self)

        if filename == "user.settings"{
            categories = infrstucture!.settingsManager.userSettingsContainer.Categories()


            print("categories",categories)
            if categories.count != 0{
                let setting:Setting = self.TryGetSetting(categoryName: categoryName, name: settingName, value: categories)

                var settings:[Setting] = categories[categoryName] as! [Setting]

                if let idx = settings.firstIndex(where: { $0 === setting }) {
                    settings.remove(at: idx)
                }
                categories.updateValue(settings, forKey: categoryName)
                infrstucture!.settingsManager.userSettingsContainer.categories = categories
            }
            else{
                print("usersettings has no data")
            }

        }
        else{
            categories = infrstucture!.settingsManager.applicationSettingsContainer.Categories()
            print("categories",categories)

            var infrstucture = dependencyInjector.container.resolve(iInfrastructureServices.self)

            if categories.count != 0{
                let setting:Setting = self.TryGetSetting(categoryName: categoryName, name: settingName, value: categories)
                var settings:[Setting] = categories[categoryName] as! [Setting]

                if let idx = settings.firstIndex(where: { $0 === setting }) {
                    settings.remove(at: idx)
                }
                categories.updateValue(settings, forKey: categoryName)
                infrstucture!.settingsManager.applicationSettingsContainer.categories = categories

            }
            else{
                print("usersettings has no data")
            }
        }




    }


    public func TryGetSetting<T>(categoryName: String, name: String, value: T) -> Setting {

        let seting = Setting()
        var dict = value as! Dictionary<String,[Setting]>
        if let _ = dict[categoryName] {
            let arrSettings:NSArray = dict[categoryName]! as NSArray
            for i in 0..<arrSettings.count {

                let setting:Setting = arrSettings.object(at: i) as! Setting

                if (setting.name == name){

                    return setting
                }
            }
        }
        return seting
  }
  
  
  
  public func Save()
  {
        let writer = SettingsFileWriter()

        var infrstucture = dependencyInjector.container.resolve(iInfrastructureServices.self)

        if fileName == "user.settings"{
            writer.Save(fileName: "user.settings", container: infrstucture!.settingsManager.userSettingsContainer)

        }else{
            writer.Save(fileName: "application.settings", container: infrstucture!.settingsManager.applicationSettingsContainer)

        }
    
    
  }
  
  public func TryGetSettingValue<T>(category: String, name: String, value: T) -> Bool {
      return false
  }
  
  public func FileName() -> String {
      return fileName
  }
  public func Categories(name:String, category:SettingsCategory) -> Dictionary<String, [Setting]> {
    
      return categories as! Dictionary<String, [Setting]>
  }
  public func Categories() -> Dictionary<String, [Setting]> {
    
      return categories as! Dictionary<String, [Setting]>
  }
  
  func encrypt(plainText : String, password: String) -> String {
      let data: Data = plainText.data(using: .utf8)!
      let encryptedData = RNCryptor.encrypt(data: data, withPassword: password)
      let encryptedString : String = encryptedData.base64EncodedString() // getting base64encoded string of encrypted data.
      return encryptedString
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







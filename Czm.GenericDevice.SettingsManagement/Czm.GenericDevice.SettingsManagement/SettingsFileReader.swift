//
//  SettingsFileReader.swift
//  XMLSample
//
//  Created by Carin on 4/29/19.
//  Copyright © 2019 Carin. All rights reserved.
//

import Foundation
import Czm_GenericDevice_SettingsManagement_Interfaces
import Czm_GenericDevice_CryptoServices
import Czm_GenericDevice_CryptoServices_Interfaces

public class SettingsFileReader:NSObject,ISettingsFileReader,XMLParserDelegate
{
    public var posts: [Dictionary<String, Any>]
    
    public var parser: XMLParser
    
    public var catName: String
    
    public var catSource: String
    
    public var elements: NSMutableDictionary
    
    public var dataElements: NSMutableDictionary
    
    public var ApplicationSettingsFileName: String
    
    public var UserSettingsFileName: String
    
    public var DefaultSettingsFileName: String
    
    public var element: String
    
    public var name: String
    
    public var type: String
    
    public var encrypted: Bool
    
    public var readonly: Bool
    
    public var scope: String
    
    public var valueString: String
    
    public var foundCharacters: String
    
    public var xmlfilename: String
    
    public var container: ISettingsContainer
    
    public var setting: ISetting
    
    public var patientDetailsArray: [ISetting]
    
    public var xmlFilename: String
    
    public var settingsManager: ISettingsManager
    
    let settingsCategory = SettingsCategory.manager
    
    
//    var posts = [Dictionary<String, Any>]()
//    var parser = XMLParser()
//    var catName = String()
//    var catSource = String()
//    var elements = NSMutableDictionary()
//    var dataElements = NSMutableDictionary()
//    
//    
//    let ApplicationSettingsFileName:String = "application.settings"
//    let UserSettingsFileName:String = "user.settings"
//    let DefaultSettingsFileName:String = "default.settings"
//    var element:String = ""
//    var name:String = ""
//    var type:String = ""
//    var encrypted = Bool()
//    var readonly = Bool()
//    var scope:String = ""
//    var valueString:String = ""
//    var foundCharacters = String()
//    
//    let settingsCategory = SettingsCategory.manager
//    var xmlfilename = String()
//    var Container:SettingsContainer
//    let setting = Setting()
//    var patientDetailsArray = [Setting]()
//    var xmlFilename = String()
//    let settingsManager = SettingsManager()
//    
    public override init() {
     container = SettingsContainer()
       posts = [Dictionary<String, Any>]()
       parser = XMLParser()
       catName = String()
       catSource = String()
       elements = NSMutableDictionary()
       dataElements = NSMutableDictionary()
     
     
       ApplicationSettingsFileName = "application.settings"
       UserSettingsFileName = "user.settings"
       DefaultSettingsFileName = "default.settings"
       element = ""
       name = ""
       type = ""
       encrypted = Bool()
       readonly = Bool()
       scope = ""
       valueString = ""
       foundCharacters = String()
       xmlfilename = String()
       setting = Setting()
       patientDetailsArray = [Setting]()
       xmlFilename = String()
       settingsManager = SettingsManager()
    }
    
    public func LoadSettingsFile(fileName: String, container: ISettingsContainer) {
        xmlFilename = fileName
        posts = []
        xmlfilename = fileName
        self.container = container as! SettingsContainer
        let xmlPath = Bundle.main.path(forResource:fileName, ofType: "xml")
        
        if xmlPath == nil{
            
            print("Settings file not found")
            
        }
        else{
            let xmlData = NSData(contentsOfFile: xmlPath!)
            parser = XMLParser(data: xmlData! as Data)
            parser.delegate = self
            parser.parse()
            let writer = SettingsFileWriter()
            writer.Save(fileName: fileName, container: self.container)
        }
    }
    
    
    
    //XMLParser Methods
    public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String])
    {
        
        element = (elementName as NSString) as String
        
        if (elementName == "category"){
            self.catName = attributeDict ["name"] ?? ""
            self.catSource = attributeDict ["source"] ?? ""
            
        }
        if (elementName == "setting"){
            self.name = attributeDict ["name"] ?? ""
            self.type = attributeDict ["type"] ?? ""
            self.encrypted = NSString(string: attributeDict ["encrypted"] ?? "False").boolValue
            self.readonly = NSString(string: attributeDict ["readonly"] ?? "False").boolValue
            self.scope = attributeDict ["scope"] ?? ""
            self.valueString = attributeDict ["SwVersion"] ?? ""
        }
    }
    public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?)
    {
        
        
        
        if elementName == "category" {
            
            // dataElements.setValue(posts, forKey: catName)
            
            if xmlFilename == DefaultSettingsFileName{
                settingsManager.deviceSettingsContainer.categories.updateValue(patientDetailsArray, forKey: catName)
                container = settingsManager.deviceSettingsContainer
                print("print", settingsManager.deviceSettingsContainer.categories)
            }
            else if xmlFilename == ApplicationSettingsFileName{
            settingsManager.applicationSettingsContainer.categories.updateValue(patientDetailsArray, forKey: catName)
                container = settingsManager.deviceSettingsContainer
            }
            else if xmlFilename == UserSettingsFileName{
                settingsManager.userSettingsContainer.categories.updateValue(patientDetailsArray, forKey: catName)
                container = settingsManager.deviceSettingsContainer
            }
            else{
                
                print("default.settings")
            }
            
            print("container",container.categories)
            patientDetailsArray .removeAll()
            posts .removeAll()
            
        }
        if elementName == "setting" {
            
            let setting = Setting()
            setting.categoryName = catName
            setting.name = name
            setting.typeName = type
            setting.isEncrypted = encrypted
            setting.isReadOnly = readonly
            setting.valueString = foundCharacters
            
            if encrypted{
                if foundCharacters.count != 0 {
                    let cryptoservices = CryptoServices()
                     setting.valueString = cryptoservices.encrypt(plainText: foundCharacters, password: "6898ecc%$#@")
                }
            }
            if scope == "application"{setting.scope = .application}else if scope == "user"{setting.scope = .user}else{setting.scope = .device}
            patientDetailsArray.append(setting)
            posts.append(elements as! Dictionary<String, Any>)
        }
    }
    
    
    public func parser(_ parser: XMLParser, foundCharacters string: String) {
        let version = String(string.filter { !"\n\t\r".contains($0) })
        let triimmedval = version.trimmingCharacters(in: .whitespacesAndNewlines)
        self.foundCharacters = triimmedval;
        
        
    }
    
}




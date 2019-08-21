//
//  SettingsFileWriter.swift
//  XMLSample
//
//  Created by Carin on 5/2/19.
//  Copyright © 2019 Carin. All rights reserved.
//

import Foundation
import Czm_GenericDevice_SettingsManagement_Interfaces
import Czm_GenericDevice_CryptoServices
public class SettingsFileWriter:ISettingsFileWriter
{
    
    
    public init(){
        
    }
    
    public func Save(fileName: String, container: ISettingsContainer){}
//    {
//        let dictionary:Dictionary<String, [Setting]> = container.Categories()
//        print("dict", dictionary)
//        let xmlRequest = AEXMLDocument()
//        let arr:Array = Array(dictionary.keys)
//        let attributes = ["xmlns:xsi" : "http://www.w3.org/2001/XMLSchema-instance", "xsi:noNamespaceSchemaLocation" : "SettingsConfig.xsd"]
//        let settingsConfiguration = xmlRequest.addChild(name: "settingsConfiguration", attributes: attributes)
//        let categories = settingsConfiguration.addChild(name: "categories")
//
//        for key in arr {
//
//            let arrSettings:NSArray = dictionary[key]! as NSArray
//            let category = categories.addChild(name: "category",attributes:["name":key , "source":"xml"] )
//            let settings = category.addChild(name: "settings")
//
//            for i in 0..<arrSettings.count {
//
//                let setting:Setting = arrSettings.object(at: i) as! Setting
//                var response = Dictionary<String, String>()
//
//                let name = setting.name
//                let type = setting.typeName
//                let valueString = setting.valueString
//                let scope:String = setting.scope.rawValue
//                var encrypted = "False"
//                var readonly = "False"
//
//                if setting.isEncrypted  {
//                    encrypted = "True"
//                }
//                if setting.isReadOnly {
//                    readonly = "True"
//                }
//
//                response = ["name" : name , "type" : type,"encrypted": encrypted ,"readonly": readonly,"scope": scope]
//                settings.addChild(name: "setting", value: valueString , attributes: response )
//
//            }
//        }
//        self.writeToDocumentsFile(fileName: fileName, value: xmlRequest)
//    }
    
    func writeToDocumentsFile(fileName:String,value:AEXMLDocument) {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        let path = documentsPath.appendingPathComponent(String(format: "%@.xml",fileName))
        print("filename",fileName,  path)
        do{
            try value.xml.write(toFile: path, atomically: true, encoding: String.Encoding.utf8)
        }catch{
        }
    }
    
    func readFromDocumentsFile(fileName:String) -> String {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        let path = documentsPath.appendingPathComponent(fileName)
        let checkValidation = FileManager.default
        var file:String
        
        if checkValidation.fileExists(atPath: path) {
            do{
                try file = NSString(contentsOfFile: path, encoding: String.Encoding.utf8.rawValue) as String
            }catch{
                file = ""
            }
        } else {
            file = ""
        }
        
        return file
    }
    
    
}


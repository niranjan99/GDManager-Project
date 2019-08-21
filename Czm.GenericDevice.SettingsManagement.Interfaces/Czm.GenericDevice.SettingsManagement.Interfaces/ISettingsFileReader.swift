//
//  ISettingsFileReader.swift
//  XMLSample
//
//  Created by Carin on 4/29/19.
//  Copyright © 2019 Carin. All rights reserved.
//

import Foundation
public protocol ISettingsFileReader {

    func LoadSettingsFile(fileName:String, container : ISettingsContainer)
    
    
    
    var posts:[Dictionary<String, Any>] {get set}
    var parser:XMLParser{get set}
    var catName:String{get set}
    var catSource:String{get set}
    var elements:NSMutableDictionary{get set}
    var dataElements:NSMutableDictionary{get set}
    
    
    var ApplicationSettingsFileName:String {get set}
    var UserSettingsFileName:String {get set}
    var DefaultSettingsFileName:String {get set}
    var element:String {get set}
    var name:String {get set}
    var type:String {get set}
    var encrypted:Bool {get set}
    var readonly:Bool{get set}
    var scope:String {get set}
    var valueString:String {get set}
    var foundCharacters:String {get set}
    

    var xmlfilename:String {get set}
    var container:ISettingsContainer {get set}
    var setting:ISetting {get set}
    var patientDetailsArray:[ISetting] {get set}
    var xmlFilename:String {get set}
    var settingsManager:ISettingsManager {get set}
    
    
    
    
}

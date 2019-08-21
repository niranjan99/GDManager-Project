//
//  Setting.swift
//  XMLSample
//
//  Created by Carin on 4/29/19.
//  Copyright © 2019 Carin. All rights reserved.
//

import Foundation
import Czm_GenericDevice_SettingsManagement_Interfaces
public class Setting:ISetting
{
   
  public  var typeName = String()
  public  var categoryName = String()
  public  var name =  String()
  public  var isEncrypted =  Bool()
  public  var isReadOnly =  Bool()
  public  var scope:Scope = .user
  public  var valueString =  String()


    public init(){
        
    }
    
    
    public func CategoryName() -> String {
        
        return self.categoryName
    }
    
    public func IsEncrypted() -> Bool {
        
        return self.isEncrypted
    }
    
    public func IsReadOnly() -> Bool {
        
        return self.isReadOnly
    }
    
    public func Name() -> String {
        
        return self.name
    }
    
    public func Scope() -> Scope {
        return    self.scope
    }
    
    public func TypeName() -> String {
        return self.typeName
    }
    
    public func ValueString() -> String {
        return self.valueString
    }
    
    public func GetValue<T>() -> T {
        
        if(object_getClass(self.valueString)?.description() == "NSNull"){
             print("The value string in a setting cannot be null ({0}, {1})")
        }
        else
        {
            print("getype::", getType())

            if self.isReadOnly{
                 print("its readonly)")
            }
            else{
                if self.isEncrypted{
                    // emcrypt
                }
                else{
                    // decript
                }
            }
            
        }
        return self.valueString as! T
        
    }
    
    func getType<T>() -> T {
        
        if self.typeName == "System.String"{
            return self.valueString as! T
        }
        else if self.typeName == "System.Boolean"{
            let aString = NSString(string:self.valueString)
            let b = aString.boolValue
            return b as! T
        }
        else {
            let aString = NSString(string:self.valueString)
            let b = aString.intValue
            return b as! T
        }
        
    }
   
    
}


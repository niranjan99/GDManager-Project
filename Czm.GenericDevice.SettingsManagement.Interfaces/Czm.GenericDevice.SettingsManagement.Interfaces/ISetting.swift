//
//  ISetting.swift
//  XMLSample
//
//  Created by Carin on 4/29/19.
//  Copyright © 2019 Carin. All rights reserved.
//

import Foundation
public protocol ISetting {

    func CategoryName() -> String
    func IsEncrypted() -> Bool
    func IsReadOnly() -> Bool
    func Name() -> String
    func Scope() -> Scope
    func TypeName() -> String
    func ValueString() -> String
    func GetValue<T>() -> T
    
    var typeName:String {get set}
    var categoryName:String {get set}
    var name:String {get set}
    var isEncrypted:Bool {get set}
    var isReadOnly:Bool {get set}
    var scope:Scope {get set}
    var valueString:String {get set}

    
    
}

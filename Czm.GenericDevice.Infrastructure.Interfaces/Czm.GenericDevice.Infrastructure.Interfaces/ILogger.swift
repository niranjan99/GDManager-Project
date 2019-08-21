//
//  ILogger.swift
//  Czm.GenericDevice.Infrastructure.Interfaces
//
//  Created by Carin on 4/15/19.
//  Copyright © 2019 Carin. All rights reserved.
//

import Foundation

public enum LogLevel:Int {
 
    case Debug = 0

    case Info = 1
   
    case Warning = 2
    
    case Error = 3
    
    case FatealError = 4
    
}
public protocol ILogger
{
    
    func Log(theme : String , logMessage : String)
    
    func ServiceLog(theme : String , logMessage : String)
    
    func BackupRestoreLog(theme : String , logMessage : String)
    
    func AuditLog(theme : String , logMessage : String)
 
    func SetLogLevel(LogLevel : LogLevel)

    func ConfigureDefault()
    
}



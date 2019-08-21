//
//  Logger.swift
//  Czm.GenericDevice.Infrastructure
//
//  Created by Carin on 4/15/19.
//  Copyright © 2019 Carin. All rights reserved.
//

import Foundation
import Czm_GenericDevice_Infrastructure_Interfaces
public class Logger: ILogger
{
    
    public static let sharedInstance = Logger()
    
    public init() {
    }
    
    var log_Level:LogLevel = .Debug
    
    
    public func Log(theme: String, logMessage: String) {
         self.CreateLogFile(LogLevel: log_Level, logMessage: logMessage, context: 0)
    }
    
    public func ServiceLog(theme: String, logMessage: String) {
        self.CreateLogFile(LogLevel: log_Level, logMessage: logMessage, context: 1)
    }
    
    public func BackupRestoreLog(theme: String, logMessage: String) {
        self.CreateLogFile(LogLevel: log_Level, logMessage: logMessage, context: 2)
    }
    
    public func AuditLog(theme: String, logMessage: String) {
        self.CreateLogFile(LogLevel: log_Level, logMessage: logMessage, context: 3)
    }

    public func SetLogLevel(LogLevel: LogLevel) {
        log_Level = LogLevel
    }
    
    public func ConfigureDefault() {
        self.createLogFolder(forType:.Log)
        
        let delay = 5.0 * Double(NSEC_PER_MSEC)
        let time = DispatchTime.now() + Double(Int64(delay)) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: time) {
            self.createLogFolder(forType: .ServiceLog)
        }
        let time2 = DispatchTime.now() + Double(Int64(delay)) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: time2) {
            self.createLogFolder(forType: .BackupRestoreLog)
        }
        let time3 = DispatchTime.now() + Double(Int64(delay)) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: time3) {
            self.createLogFolder(forType: .AuditLog)
        }
    }
    
    
    
    
    public func CreateLogFile(LogLevel: LogLevel, logMessage: String, context: Int)
    {
        switch LogLevel {
        case .Debug:
            DDLogDebug(logMessage, context: context)
            break
        case .Error:
            DDLogError(logMessage, context: context)
            break
        case .Info:
            DDLogInfo(logMessage, context: context)
            break
        case .Warning:
            DDLogWarn(logMessage, context: context)
            break
        case .FatealError:
            DDLogDebug(logMessage, context: context)
            break
            
        }
    }
    
   
    public func createLogFolder(forType logFileType:LogFileType) {
        
        let cacheDirectory : String = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
        let logsFolder : String = String(format: "%@/Logs/\(logFileType.name)",cacheDirectory)
        print("cacheDirectory is \(cacheDirectory)")
        let filemanagerApplication: DDLogFileManagerDefault = DDLogFileManagerDefault(logsDirectory: logsFolder)
        let applicationLogger: DDFileLogger = DDFileLogger(logFileManager:filemanagerApplication)
        let applicationFormatter = LogCustomFormatter()
        print("context",logFileType.context)
        applicationFormatter?.add(toWhitelist: logFileType.context)
        applicationLogger.logFormatter = applicationFormatter
        applicationLogger.maximumFileSize = (2 * 1024 * 1024)//Max file size is 2MB
        applicationLogger.rollingFrequency = 0
        applicationLogger.logFileManager.maximumNumberOfLogFiles = 5
        applicationLogger.doNotReuseLogFiles = false
        
        
        DDLog.add(applicationLogger)
    }
    }

public enum LogFileType: UInt {
    case Log
    case ServiceLog
    case BackupRestoreLog
    case AuditLog
    
    var name: String {
        switch(self) {
        case .Log: return "Log"
        case .ServiceLog: return "ServiceLog"
        case .BackupRestoreLog: return "BackupRestoreLog"
        case .AuditLog: return "AuditLog"
        }
    }
    var context: Int {
        switch(self) {
        case .Log: return 0
        case .ServiceLog: return 1
        case .BackupRestoreLog: return 2
        case .AuditLog: return 3
        }
        
    }
    
}

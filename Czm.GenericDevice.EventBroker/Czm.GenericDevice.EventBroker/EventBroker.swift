//
//  EventBroker.swift
//  XMLSample
//
//  Created by Carin on 5/27/19.
//  Copyright © 2019 Carin. All rights reserved.
//

import Foundation
import UserNotifications
import Czm_GenericDevice_EventBroker_Interfaces

enum MyNotification: String {
    case settingsChanged
    case somethingElseHappened
    case anotherNotification
    case oneMore
}


public class EventBroker:NSObject, UNUserNotificationCenterDelegate,IEventBroker {
    
    public static let sharedInstance = EventBroker()

    public override init() {
        
    }

   public func subscribe(notification: Notification) {
        
    }
    
    
    
    //    func addObserver(observer: String, selector: Selector,
    //             notification: MyNotification, object: Any? = nil)
    //    {
    //        NotificationCenter.default.addObserver(observer, selector: selector,
    //                    name: Notification.Name(notification.rawValue),
    //                    object: object)
    //    }
    
   public func publish<T>(name: NSNotification.Name, object: T) {
        
        NotificationCenter.default.post(name: name, object: object)
        
    }
    
    //    func subscribe(name:String, completion: @escaping(String)->()) {
    //
    //        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: name), object: nil, queue: nil) { note in
    //            // implementation
    //
    //            completion("finshed")
    //        }
    //        }
    //
    
    
    //https://github.com/TakeScoop/Kugel
    private static let notificationCenter = NotificationCenter.default
    
    // Publish
    
    public class func publish(_ notification: Notification) {
        notificationCenter.post(notification)
    }
    
    public class func publish(_ name: NSNotification.Name, object: Any? = nil, userInfo: [AnyHashable: Any]? = nil) {
        notificationCenter.post(name: name, object: object, userInfo: userInfo)
    }
    
    // Subscribe
    
    public class func subscribe(_ name: NSNotification.Name, block: @escaping ((Notification) -> Void)) -> NSObjectProtocol {
        return notificationCenter.addObserver(forName: name, object: nil, queue: nil) { notification in
            block(notification)
        }
    }
    
    public class func subscribe(_ observer: Any, name: NSNotification.Name, selector: Selector, object: Any? = nil) {
        return notificationCenter.addObserver(observer, selector: selector, name: name, object: object)
    }
    
    public class func subscribe(_ observer: Any, _ notifications: [NSNotification.Name: Selector], object: Any? = nil) {
        for (name, selector) in notifications {
            subscribe(observer, name: name, selector: selector, object: object)
        }
    }
    
    // Unsubscribe
    
    public class func unsubscribe(_ observer: Any, name: NSNotification.Name? = nil, object: Any? = nil) {
        return notificationCenter.removeObserver(observer, name: name, object: nil)
    }
    
    public class func unsubscribe(_ observer: Any, _ names: [NSNotification.Name], object: Any? = nil) {
        for name in names {
            unsubscribe(observer, name: name, object: object)
        }
    }
    
    
}



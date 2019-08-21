//
//  IEventBroker.swift
//  XMLSample
//
//  Created by Carin on 5/27/19.
//  Copyright © 2019 Carin. All rights reserved.
//

import Foundation
public protocol IEventBroker {
    
    func publish<T>(name: NSNotification.Name, object: T)
    func subscribe(notification: Notification)
    
}

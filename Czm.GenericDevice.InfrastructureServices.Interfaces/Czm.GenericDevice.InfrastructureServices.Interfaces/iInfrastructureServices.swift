//
//  iInfrastructureServices.swift
//  GenericDeviceUI
//
//  Created by Carin on 6/11/19.
//  Copyright © 2019 Carin. All rights reserved.
//

import Foundation


import Czm_GenericDevice_SettingsManagement_Interfaces
import Czm_GenericDevice_EventBroker_Interfaces
import Czm_GenericDevice_Infrastructure_Interfaces
import Czm_GenericDevice_DependencyInjector_Interfaces
import Swinject

public protocol iInfrastructureServices{

    var logger:ILogger { get set }
    var settingsManager:ISettingsManager { get set }
    var eventBroker:IEventBroker { get set }
    var dependency:IDependencyInjector { get set }
    var container:Container { get set }
    func initialize()
}


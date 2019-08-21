//
//  ISwinjectContainer.swift
//  Czm.GenericDevice.InfrastructureServices.Interfaces
//
//  Created by Carin on 6/12/19.
//  Copyright © 2019 Carin. All rights reserved.
//

import Foundation
import Swinject

public protocol IDependencyInjector{

    var container: Container {get set}
    
}

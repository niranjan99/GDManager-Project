
//  DependencyInjector.swift
//  XMLSample
//
//  Created by Carin on 4/29/19.
//  Copyright © 2019 Carin. All rights reserved.
//
import Swinject
import Czm_GenericDevice_DependencyInjector_Interfaces
public class DependencyInjector:IDependencyInjector {
 
   public var container: Container

   public static let sharedInstance = DependencyInjector()

   public init()
   {
       container = Container()
   }
   
  
    
    
}



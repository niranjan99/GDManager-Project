//
//  ICryptoServices.swift
//  XMLSample
//
//  Created by Carin on 5/27/19.
//  Copyright © 2019 Carin. All rights reserved.
//

import Foundation

public protocol ICryptoServices {
    func encrypt(plainText : String, password: String) -> String
    func decrypt(encryptedText : String, password: String) -> String
}

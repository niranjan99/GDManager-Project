//
//  CryptoServices.swift
//  XMLSample
//
//  Created by Carin on 5/27/19.
//  Copyright © 2019 Carin. All rights reserved.
//

import Foundation
import Czm_GenericDevice_CryptoServices_Interfaces

public class CryptoServices:ICryptoServices
{
//    let icrypto:ICryptoServices
//    
//    public init(icryptoservice:ICryptoServices){
//        icrypto = icryptoservice
//    }
//
     public init(){
     }
    
   public func encrypt(plainText : String, password: String) -> String {
        let data: Data = plainText.data(using: .utf8)!
        let encryptedData = RNCryptor.encrypt(data: data, withPassword: password)
        let encryptedString : String = encryptedData.base64EncodedString() // getting base64encoded string of encrypted data.
        return encryptedString
    }
    
  public  func decrypt(encryptedText : String, password: String) -> String {
        do  {
            let data: Data = Data(base64Encoded: encryptedText)! // Just get data from encrypted base64Encoded string.
            let decryptedData = try RNCryptor.decrypt(data: data, withPassword: password)
            let decryptedString = String(data: decryptedData, encoding: .utf8) // Getting original string, using same .utf8 encoding option,which we used for encryption.
            return decryptedString ?? ""
        }
        catch {
            return "FAILED"
        }
    }
    
    
}

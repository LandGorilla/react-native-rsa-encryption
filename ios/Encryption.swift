//
//  Encryption.swift
//  RsaEncryption
//
//  Created by Carlos Duclos on 26/11/23.
//  Copyright © 2023 Facebook. All rights reserved.
//

import Foundation
import SwiftyRSA

struct Encryption {
    
    private let pemEncoded: String
    
    init(pemEncoded: String) {
        self.pemEncoded = pemEncoded
    }
    
    func encrypt(message: String) -> String? {
        do {
            let publicKey = try PublicKey(pemEncoded: pemEncoded)
            let clear = try ClearMessage(string: message, using: .utf8)
            let encrypted = try clear.encrypted(with: publicKey, padding: .PKCS1)
            return encrypted.base64String
        } catch {
            print(error)
            return nil
        }
    }
}

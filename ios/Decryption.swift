//
//  Decryption.swift
//  RsaEncryption
//
//  Created by Carlos Duclos on 27/11/23.
//  Copyright © 2023 Facebook. All rights reserved.
//

import Foundation
import SwiftyRSA

struct Decryption {
    
    private let pemEncoded: String
    
    init(pemEncoded: String) {
        self.pemEncoded = pemEncoded
    }
    
    func decrypt(encryptedMessage: String) -> String? {
        do {
            let privateKey = try PrivateKey(pemEncoded: pemEncoded)
            let encrypted = try EncryptedMessage(base64Encoded: encryptedMessage)
            let clear = try encrypted.decrypted(with: privateKey, padding: .PKCS1)
            return try clear.string(encoding: .utf8)
        } catch {
            print(error)
            return nil
        }
    }
}

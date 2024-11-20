//
//  Generation.swift
//  RsaEncryption
//
//  Created by Carlos Duclos on 3/11/24.
//  Copyright © 2024 Facebook. All rights reserved.
//

import CryptoKit
import Foundation
import SwiftyRSA
import os

enum Generation {
    
    static func generateKeyPair() -> (privateKey: String, publicKey: String)? {
        do {
            // Generate a 4096-bit RSA key pair
            let keyPair = try SwiftyRSA.generateRSAKeyPair(sizeInBits: 4096)
            let privateKey = keyPair.privateKey
            let publicKey = keyPair.publicKey
            
            // Export keys as PEM strings
            let privateKeyPEM = try privateKey.pemString()
            let publicKeyPEM = try publicKey.pemString()
            
            return (privateKeyPEM, publicKeyPEM)
        } catch {
            print("Key pair generation failed: \(error)")
            return nil
        }
    }
    
    static func generateImageSignature(path: String, pemPrivateKey: String) throws -> String {
        guard let imageData = getRawBytes(from: path) else {
            throw GenerationError.unableToFindImage
        }
        do {
            let privateKey = try PrivateKey(pemEncoded: pemPrivateKey)
            let clearMessage = ClearMessage(data: imageData)
            if #available(iOS 13.0, *) {
                let signature = try clearMessage.signed(with: privateKey, digestType: .sha256)
                return signature.base64String
            } else {
                throw GenerationError.errorSigning
            }
        } catch {
            throw GenerationError.errorSigning
        }
    }
    
    static func getRawBytes(from filePath: String) -> Data? {
        return try? Data(contentsOf: URL(fileURLWithPath: filePath))
    }
}

enum GenerationError: Error {
    case unableToFindImage
    case errorSigning
    case invalidPrivateKey
    case failedToGeneratePrivateKey
    
    var code: String {
        switch self {
        case .unableToFindImage: return "unable_to_find_image"
        case .errorSigning: return "error_signing_image"
        case .invalidPrivateKey: return "invalid_private_key"
        case .failedToGeneratePrivateKey: return "failed_to_generate_private_and_public_key"
        }
    }
    
    var message: String {
        switch self {
        case .unableToFindImage: return "Unable to find image."
        case .errorSigning: return "Error signing image."
        case .invalidPrivateKey: return "Invalid private key."
        case .failedToGeneratePrivateKey: return "Failed to generate private and public key."
        }
    }
}

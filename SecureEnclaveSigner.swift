//
//  SecureEnclaveSigner.swift
//  Pods
//
//  Created by Carlos Duclos on 15/05/25.
//

import CommonCrypto
import Foundation
import Security
import CryptoKit

final class SecureEnclaveSigner {

    // MARK: - Public API

    /// Returns the PEM-encoded public key for the given tag,
    /// creating a new Secure Enclave key if needed.
    func getPublicKeyPEM(tag: String) throws -> String {
        let privKey = try fetchOrCreatePrivateKey(tag: tag)
        let publicKey = try exportPublicKeyPEM(from: privKey)
        return publicKey
    }

    /// Signs the image at the given file path using the Secure Enclave key
    /// identified by `tag`, returning a base64-encoded ECDSA signature.
    func generateImageSignature(path: String, tag: String) throws -> String {
        let privKey = try fetchOrCreatePrivateKey(tag: tag)
        return try signImage(atPath: path, with: privKey)
    }

    // MARK: - Private Helpers

    private func fetchOrCreatePrivateKey(tag: String) throws -> SecKey {
        // 1) Turn the tag into NSData (CFDataRef)
        let tagData = (tag as NSString).data(using: String.Encoding.utf8.rawValue)! as NSData

        // 2) Try to fetch an existing private key
        let query: [CFString: Any] = [
          kSecClass:               kSecClassKey,
          kSecAttrKeyClass:        kSecAttrKeyClassPrivate,
          kSecAttrKeyType:         kSecAttrKeyTypeECSECPrimeRandom,
          kSecAttrApplicationTag:  tagData,
          kSecReturnRef:           kCFBooleanTrue!    // CFBoolean, not Swift Bool
        ]

        var itemRef: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &itemRef)
        print("🔑 fetch key status: \(status)")
        if status == errSecSuccess {
            let key = itemRef as! SecKey
            return key
        }

        // If it wasn’t found, or something else happened, create a new one
        if status != errSecItemNotFound {
          print("⚠️ unexpected fetch error \(status), will try creating anyway")
        }
        return try createEnclaveKey(tagData: tagData)
    }

    private func createEnclaveKey(tagData: CFData) throws -> SecKey {
        let attributes: [CFString: Any] = [
            kSecAttrKeyType:           kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits:     256,
            kSecAttrTokenID:           kSecAttrTokenIDSecureEnclave,
            kSecPrivateKeyAttrs: [
                kSecAttrIsPermanent:    true,
                kSecAttrApplicationTag: tagData,
                kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            ]
        ]

        var error: Unmanaged<CFError>?
        guard let privKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            throw GenerationError.failedToGeneratePrivateKey
        }
        return privKey
    }

    private func exportPublicKeyPEM(from privateKey: SecKey) throws -> String {
        guard let pubKey = SecKeyCopyPublicKey(privateKey) else {
            throw GenerationError.invalidPrivateKey
        }
        var error: Unmanaged<CFError>?
        guard let rawPub = SecKeyCopyExternalRepresentation(pubKey, &error) as Data? else {
            throw GenerationError.invalidPrivateKey
        }

        let b64 = rawPub.base64EncodedString(options: [.lineLength64Characters])
        return """
        -----BEGIN PUBLIC KEY-----
        \(b64)
        -----END PUBLIC KEY-----
        """
    }

    private func signImage(atPath path: String, with privateKey: SecKey) throws -> String {
        guard let data = rawImageData(from: path) else {
            throw GenerationError.unableToFindImage
        }
        
        var error: Unmanaged<CFError>?
        guard let signature = SecKeyCreateSignature(
            privateKey,
            .ecdsaSignatureMessageX962SHA256,
            data as CFData,
            &error
        ) as Data? else {
            throw error!.takeRetainedValue() as Error
        }
        return signature.base64EncodedString()
    }

    private func rawImageData(from path: String) -> Data? {
        return try? Data(contentsOf: URL(fileURLWithPath: path))
    }
}

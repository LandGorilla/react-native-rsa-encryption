import SwiftyRSA

@objc(RsaEncryption)
class RsaEncryption: NSObject {
    
    private let signer = SecureEnclaveSigner()
    
    @objc(encrypt:withData:withResolver:withRejecter:)
    func encrypt(
        pemEncoded: String,
        data: [String: String],
        resolve: RCTPromiseResolveBlock,
        reject: RCTPromiseRejectBlock
    ) -> Void {
        guard let message = data.stringRepresentation else {
            let error = EncryptionError.cannotConvertToString
            reject(error.code, error.message, error)
            return
        }
        
        let encryption = Encryption(pemEncoded: pemEncoded)
        guard let encrypted = encryption.encrypt(message: message) else {
            let error = EncryptionError.failedEncryption
            reject(error.code, error.message, error)
            return
        }
        
        resolve(encrypted)
    }
    
    @objc(decrypt:withEncryptedMessage:withResolver:withRejecter:)
    func decrypt(
        pemEncoded: String,
        encryptedMessage: String,
        resolve: RCTPromiseResolveBlock,
        reject: RCTPromiseRejectBlock
    ) {
        let decryption = Decryption(pemEncoded: pemEncoded)
        guard let decrypted = decryption.decrypt(encryptedMessage: encryptedMessage) else {
            let error = EncryptionError.failedDecryption
            reject(error.code, error.message, error)
            return
        }
        
        resolve(decrypted)
    }

    @objc(getPublicKeyPEM:withResolver:withRejecter:)
    func getPublicKeyPEM(tag: String, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        do {
            let pem = try signer.getPublicKeyPEM(tag: tag)
            resolve(pem)
        } catch let err as GenerationError {
            reject(err.code, err.localizedDescription, err)
        } catch {
            reject("unknown_error", error.localizedDescription, error)
        }
    }

    @objc(generateImageSignature:withTag:withResolver:withRejecter:)
    func generateImageSignature(path: String, tag: String, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        do {
            let signature = try signer.generateImageSignature(path: path, tag: tag)
            resolve(signature)
        } catch let err as GenerationError {
            reject(err.code, err.localizedDescription, err)
        } catch {
            reject("unknown_error", error.localizedDescription, error)
        }
    }
}

enum EncryptionError: Error {
    case cannotConvertToString
    case invalidCertificate
    case failedEncryption
    case failedDecryption
    
    var code: String {
        switch self {
        case .invalidCertificate: return "invalid_certificate"
        case .cannotConvertToString: return "cannot_convert_to_string"
        case .failedEncryption: return "failed_encryption"
        case .failedDecryption: return "failed_decryption"
        }
    }
    
    var message: String {
        switch self {
        case .invalidCertificate: return "Invalid certificate"
        case .cannotConvertToString: return "Cannot convert dictionary to string"
        case .failedEncryption: return "Encryption failed"
        case .failedDecryption: return "Decryption failed"
        }
    }
}

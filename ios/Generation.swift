//
//  Generation.swift
//  RsaEncryption
//
//  Created by Carlos Duclos on 3/11/24.
//  Copyright © 2024 Facebook. All rights reserved.
//

import CryptoKit
import Foundation
import UIKit
import SwiftyRSA
import MobileCoreServices
import UniformTypeIdentifiers

enum Generation {
    
    static func generateKeyPair() -> (privateKey: String, publicKey: String)? {
        do {
            // Generate a 2048-bit RSA key pair
            let keyPair = try SwiftyRSA.generateRSAKeyPair(sizeInBits: 4096)
            let privateKey = keyPair.privateKey
            let publicKey = keyPair.publicKey
            
            // Export keys as PEM strings if needed
            let privateKeyPEM = try privateKey.pemString()
            let publicKeyPEM = try publicKey.pemString()
            
            return (privateKeyPEM, publicKeyPEM)
        } catch {
            return nil
        }
    }
    
    static func generateImageSignature(path: String, pemPrivateKey: String) throws -> String {
        guard let imageData = getRawBytes(from: path) else {
            throw GenerationError.unableToGetImageWithoutMetadata
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
        guard let imageData = loadImageData(from: filePath) else {
            print("Failed to load image data.")
            return nil
        }
        
        guard let cgImage = createCGImage(from: imageData) else {
            print("Failed to create CGImage.")
            return nil
        }
        
        guard let rawBytes = extractRawBytes(from: cgImage) else {
            print("Failed to extract raw bytes.")
            return nil
        }
        
        return rawBytes
    }
    
    static func loadImageData(from filePath: String) -> Data? {
        let url = URL(fileURLWithPath: filePath)
        return try? Data(contentsOf: url)
    }
    
    static func createCGImage(from imageData: Data) -> CGImage? {
        guard let dataProvider = CGDataProvider(data: imageData as CFData) else {
            return nil
        }
        
        guard let source = CGImageSourceCreateWithDataProvider(dataProvider, nil) else {
            return nil
        }
        
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }
    
    static func extractRawBytes(from cgImage: CGImage) -> Data? {
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        // Allocate memory for raw data
        var rawData = [UInt8](repeating: 0, count: height * bytesPerRow)
        
        // Define color space (sRGB is commonly used)
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
            return nil
        }
        
        // Define bitmap info (RGBA)
        let bitmapInfo = CGImageAlphaInfo.noneSkipLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        
        // Create a bitmap context
        guard let context = CGContext(data: &rawData,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: bitsPerComponent,
                                      bytesPerRow: bytesPerRow,
                                      space: colorSpace,
                                      bitmapInfo: bitmapInfo)
        else {
            return nil
        }
        
        // Draw the image into the context
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        context.draw(cgImage, in: rect)
        
        // Convert the raw byte array to Data
        return Data(rawData)
    }
}

enum GenerationError: Error {
    case unableToGetImageWithoutMetadata
    case unableToFindImage
    case errorSigning
    case invalidPrivateKey
    case failedToGeneratePrivateKey
    
    var code: String {
        switch self {
        case .unableToGetImageWithoutMetadata: return "unable_to_get_image_without_metadata"
        case .unableToFindImage: return "unable_to_find_image"
        case .errorSigning: return "error signing image"
        case .invalidPrivateKey: return "invalid_private_key"
        case .failedToGeneratePrivateKey: return "failed_to_generate_private_and_public_key"
        }
    }
    
    var message: String {
        switch self {
        case .unableToGetImageWithoutMetadata: return "Unable to get bits map"
        case .unableToFindImage: return "Unable to find image"
        case .errorSigning: return "error signing image"
        case .invalidPrivateKey: return "Invalid private key"
        case .failedToGeneratePrivateKey: return "Failed to generate private and public key"
        }
    }
}

extension Data {
    func hexEncodedString(separator: String = " ") -> String {
        return self.map { String(format: "%02x", $0) }.joined(separator: separator)
    }
}

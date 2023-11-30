//
//  Dictionary+.swift
//  react-native-rsa-encryption
//
//  Created by Carlos Duclos on 26/11/23.
//

import Foundation

extension Dictionary where Key == String, Value == String {
    
    var stringRepresentation: String? {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
            guard let jsonString = String(data: jsonData, encoding: .utf8) else { return nil }
            return jsonString
        } catch {
            print("Error converting dictionary to string: \(error.localizedDescription)")
            return nil
        }
    }
}

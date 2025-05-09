//
//  PasswordService.swift
//  iLaps
//
//  Created by Somesh Pathak on 28/04/2025.
//

import Foundation

/// Generates a strong random password, stores it in Key Vault,
/// and retrieves it later for display.
class PasswordService {
    static let shared = PasswordService()
    private init() {}

    /// Generates & stores a new random password for the given device ID.
    /// - Parameters:
    ///   - deviceId: The Intune managedDevice ID.
    ///   - completion: Returns the clear-text password on success.
    func generateAndStorePassword(
        for deviceId: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        print("Generating password for device: \(deviceId)")
        let newPwd = generateStrongPassword()
        
        print("Storing password in Key Vault...")
        KeyVaultService.shared.storePassword(newPwd, for: deviceId) { result in
            switch result {
            case .success:
                print("Password stored successfully")
                completion(.success(newPwd))
            case .failure(let error):
                print("Failed to store password: \(error)")
                completion(.failure(error))
            }
        }
    }

    /// Retrieves the stored password from Key Vault for the given device ID.
    /// - Parameters:
    ///   - deviceId: The Intune managedDevice ID.
    ///   - completion: Returns the clear-text password on success.
    func retrievePassword(
        for deviceId: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        print("Retrieving password for device: \(deviceId)")
        KeyVaultService.shared.retrievePassword(for: deviceId) { result in
            switch result {
            case .success(let password):
                print("Password retrieved successfully")
                completion(.success(password))
            case .failure(let error):
                print("Failed to retrieve password: \(error)")
                completion(.failure(error))
            }
        }
    }

    /// Generates a strong password that meets common requirements:
    /// - At least 16 characters
    /// - Mix of uppercase, lowercase, numbers, and symbols
    private func generateStrongPassword() -> String {
        let length = 16
        let uppercaseLetters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let lowercaseLetters = "abcdefghijklmnopqrstuvwxyz"
        let numbers = "0123456789"
        let symbols = "!@#$%^&*()_+-=[]{}|;:,.<>?"
        let allChars = uppercaseLetters + lowercaseLetters + numbers + symbols
        
        var password = ""
        
        // Ensure at least one of each type
        password += String(uppercaseLetters.randomElement()!)
        password += String(lowercaseLetters.randomElement()!)
        password += String(numbers.randomElement()!)
        password += String(symbols.randomElement()!)
        
        // Fill the rest randomly
        while password.count < length {
            password += String(allChars.randomElement()!)
        }
        
        // Shuffle the password to make it more random
        return String(password.shuffled())
    }
}

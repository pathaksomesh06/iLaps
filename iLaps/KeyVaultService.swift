//
//  KeyVaultService.swift
//  iLaps
//
//  Created by Somesh Pathak on 28/04/2025.
//

import Foundation

enum KeyVaultError: Error {
    case invalidURL
    case noData
    case httpError(Int)
    case invalidResponse
    case encodingError
}

class KeyVaultService {
    static let shared = KeyVaultService()
    private let baseURL: String
    
    private init() {
        // Initialize with your Key Vault URL from configuration
        self.baseURL = ConfigService.shared.keyVaultURL
    }
    
    /// Stores the LAPS password in Azure Key Vault for a specific device
    /// - Parameters:
    ///   - password: The LAPS password to store
    ///   - deviceId: The Intune device ID
    ///   - completion: Completion handler with success/failure
    func storePassword(_ password: String, for deviceId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        AuthService.shared.acquireToken(scopes: [ConfigService.shared.keyVaultScope]) { result in
            switch result {
            case .success(let token):
                // Create the secret name using device ID
                let secretName = "\(deviceId)-localAdminPassword"
                
                // Construct the Key Vault secret URL
                guard let encodedSecret = secretName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
                      let url = URL(string: "\(self.baseURL)/secrets/\(encodedSecret)?api-version=7.4") else {
                    completion(.failure(KeyVaultError.invalidURL))
                    return
                }
                
                // Prepare the request
                var request = URLRequest(url: url)
                request.httpMethod = "PUT"
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                // Prepare the payload
                let payload = [
                    "value": password,
                    "attributes": [
                        "enabled": true,
                        "exp": Int(Date().addingTimeInterval(90 * 24 * 3600).timeIntervalSince1970) // 90 days expiry
                    ]
                ] as [String : Any]
                
                do {
                    request.httpBody = try JSONSerialization.data(withJSONObject: payload)
                } catch {
                    completion(.failure(KeyVaultError.encodingError))
                    return
                }
                
                // Make the request
                URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        completion(.failure(KeyVaultError.invalidResponse))
                        return
                    }
                    
                    guard (200...299).contains(httpResponse.statusCode) else {
                        completion(.failure(KeyVaultError.httpError(httpResponse.statusCode)))
                        return
                    }
                    
                    completion(.success(()))
                }.resume()
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Retrieves the LAPS password from Azure Key Vault for a specific device
    /// - Parameters:
    ///   - deviceId: The Intune device ID
    ///   - completion: Completion handler with the password or error
    func retrievePassword(for serialNumber: String, completion: @escaping (Result<String, Error>) -> Void) {
        AuthService.shared.acquireToken(scopes: [ConfigService.shared.keyVaultScope]) { result in
            switch result {
            case .success(let token):
                let secretName = "\(serialNumber)-localAdminPassword"
                let encodedSecret = secretName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
                let urlString = "\(self.baseURL)/secrets/\(encodedSecret ?? "")?api-version=7.4"
                print("[KeyVaultService] baseURL: \(self.baseURL)")
                print("[KeyVaultService] serialNumber: \(serialNumber)")
                print("[KeyVaultService] urlString: \(urlString)")
                guard let encodedSecret = encodedSecret,
                      let url = URL(string: urlString) else {
                    print("[KeyVaultService] Invalid URL for Key Vault password retrieval!")
                    completion(.failure(KeyVaultError.invalidURL))
                    return
                }
                
                var request = URLRequest(url: url)
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                
                URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                        print("Key Vault network error: \(error)")
                        completion(.failure(error))
                        return
                    }
                    guard let httpResponse = response as? HTTPURLResponse else {
                        print("Key Vault: Invalid response")
                        completion(.failure(KeyVaultError.invalidResponse))
                        return
                    }
                    guard (200...299).contains(httpResponse.statusCode) else {
                        if let data = data, let body = String(data: data, encoding: .utf8) {
                            print("Key Vault error response: \(body)")
                        }
                        print("Key Vault HTTP status: \(httpResponse.statusCode)")
                        completion(.failure(KeyVaultError.httpError(httpResponse.statusCode)))
                        return
                    }
                    guard let data = data else {
                        print("Key Vault: No data")
                        completion(.failure(KeyVaultError.noData))
                        return
                    }
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let password = json["value"] as? String {
                            completion(.success(password))
                        } else {
                            print("Key Vault: Invalid JSON structure")
                            completion(.failure(KeyVaultError.invalidResponse))
                        }
                    } catch {
                        print("Key Vault: JSON decode error: \(error)")
                        completion(.failure(error))
                    }
                }.resume()
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
} 
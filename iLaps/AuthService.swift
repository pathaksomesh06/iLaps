//
//  AuthService.swift
//  iLaps
//
//  Created by Somesh Pathak on 28/04/2025.
//

import Foundation
import MSAL
import AppKit

enum AuthError: Error {
    case noAccount
    case msalError(Error)
    case noToken
}

/// Manages MSAL authentication: silent & interactive token acquisition, plus sign-out.
public class AuthService {
    public static let shared = AuthService()
    private var application: MSALPublicClientApplication?
    private var currentAccount: MSALAccount?
    
    private init() {
        print("Initializing AuthService...")
        
        // Build authority URL with tenant ID from MDM config
        let authorityURLString = "https://login.microsoftonline.com/\(ConfigService.shared.tenantID)"
        print("Authority URL: \(authorityURLString)")
        
        guard let authorityURL = URL(string: authorityURLString) else {
            print("Failed to create authority URL")
            return
        }
        
        do {
            let authority = try MSALAADAuthority(url: authorityURL)
            
            // Configure MSAL with MDM-delivered values
            var config = MSALPublicClientApplicationConfig(
                clientId: ConfigService.shared.clientID,
                redirectUri: ConfigService.shared.redirectURI,
                authority: authority
            )
            
            // Configure keychain access for MSAL 2.0
            let teamId = "LJ3W53UDG4"
            config.cacheConfig.keychainSharingGroup = "\(teamId).com.microsoft.adalcache"
            
            print("MSAL configuration:")
            print("- Client ID: \(config.clientId)")
            print("- Redirect URI: \(config.redirectUri ?? "nil")")
            print("- Authority: \(authorityURLString)")
            print("- Keychain Group: \(config.cacheConfig.keychainSharingGroup ?? "nil")")
            
            do {
                self.application = try MSALPublicClientApplication(configuration: config)
                
                // Try to get cached account if available
                if let accounts = try? application?.allAccounts(),
                   let firstAccount = accounts.first {
                    print("Found cached account: \(firstAccount.username ?? "unknown")")
                    currentAccount = firstAccount
                } else {
                    print("No cached account found")
                }
            } catch {
                print("Failed to initialize MSAL: \(error)")
                if let nsError = error as NSError? {
                    print("Error domain: \(nsError.domain)")
                    print("Error code: \(nsError.code)")
                    print("User info: \(nsError.userInfo)")
                }
            }
        } catch {
            print("Failed to initialize MSAL: \(error)")
        }
    }
    
    /// Acquires a token for the specified scopes
    /// - Parameters:
    ///   - scopes: The scopes to request access for
    ///   - completion: Completion handler with the access token or error
    func acquireToken(scopes: [String], completion: @escaping (Result<String, Error>) -> Void) {
        guard let application = application else {
            completion(.failure(AuthError.msalError(NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "MSAL application not initialized"]))))
            return
        }
        
        // Try to get an account
        var account: MSALAccount?
        do {
            if let currentAccount = currentAccount {
                account = currentAccount
            } else {
                let accounts = try application.allAccounts()
                if let firstAccount = accounts.first {
                    account = firstAccount
                    currentAccount = firstAccount // Cache the account
                }
            }
        } catch {
            print("Failed to get accounts: \(error)")
            completion(.failure(AuthError.msalError(error)))
            return
        }
        
        // try silent token acquisition
        if let account = account {
            print("Attempting silent token acquisition for scopes: \(scopes)")
            let silentParameters = MSALSilentTokenParameters(scopes: scopes, account: account)
            application.acquireTokenSilent(with: silentParameters) { result, error in
                if let error = error {
                    print("Silent token acquisition failed: \(error)")
                    // Silent token acquisition failed, try interactive
                    self.acquireTokenInteractive(scopes: scopes, completion: completion)
                    return
                }
                
                if let result = result, let token = result.accessToken as String? {
                    print("Silent token acquisition succeeded")
                    completion(.success(token))
                } else {
                    print("Silent token acquisition failed: no token")
                    completion(.failure(AuthError.noToken))
                }
            }
        } else {
            print("No account found, starting interactive auth")
            // No account, try interactive token acquisition
            acquireTokenInteractive(scopes: scopes, completion: completion)
        }
    }
    
    private func acquireTokenInteractive(scopes: [String], completion: @escaping (Result<String, Error>) -> Void) {
        guard let application = application else {
            completion(.failure(AuthError.msalError(NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "MSAL application not initialized"]))))
            return
        }
        
        // Wait for the window to be ready
        DispatchQueue.main.async {
            guard let window = NSApplication.shared.keyWindow else {
                // Retry after a short delay if window isn't ready
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.acquireTokenInteractive(scopes: scopes, completion: completion)
                }
                return
            }
            
            guard let viewController = window.contentViewController else {
                completion(.failure(AuthError.msalError(NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No view controller found for auth webview"]))))
                return
            }
            
            print("Starting interactive token acquisition for scopes: \(scopes)")
            let webviewParameters = MSALWebviewParameters(authPresentationViewController: viewController)
            let parameters = MSALInteractiveTokenParameters(scopes: scopes, webviewParameters: webviewParameters)
            parameters.promptType = .selectAccount
            
            application.acquireToken(with: parameters) { [weak self] result, error in
                if let error = error {
                    print("Interactive token acquisition failed: \(error)")
                    completion(.failure(AuthError.msalError(error)))
                    return
                }
                
                if let result = result, let token = result.accessToken as String? {
                    print("Interactive token acquisition succeeded")
                    self?.currentAccount = result.account // Cache the account
                    completion(.success(token))
                } else {
                    print("Interactive token acquisition failed: no token")
                    completion(.failure(AuthError.noToken))
                }
            }
        }
    }
    
    /// Signs out the current user and clears the token cache
    func signOut() {
        guard let application = application else {
            print("Cannot sign out: MSAL application not initialized")
            return
        }
        
        do {
            let accounts = try application.allAccounts()
            print("Signing out \(accounts.count) accounts")
            try accounts.forEach { account in
                try application.remove(account)
            }
            currentAccount = nil
            print("Sign out successful")
        } catch {
            print("Failed to sign out: \(error)")
        }
    }
}

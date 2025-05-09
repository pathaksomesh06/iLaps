//
//  AuthViewModel.swift
//  iLaps
//
//  Created by Somesh Pathak on 28/04/2025.
//

import Foundation
import SwiftUI
import MSAL

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let authService = AuthService.shared
    
    init() {
        
        checkAuthStatus()
    }
    
    func login() {
        isLoading = true
        errorMessage = nil
        
        print("Starting login process...")
        authService.acquireToken(scopes: [ConfigService.shared.graphScope]) { [weak self] (result: Result<String, Error>) in
            Task { @MainActor in
                switch result {
                case .success:
                    print("Login successful")
                    self?.isAuthenticated = true
                case .failure(let error):
                    print("Login failed: \(error)")
                    self?.errorMessage = error.localizedDescription
                }
                self?.isLoading = false
            }
        }
    }
    
    func logout() {
        print("Logging out...")
        authService.signOut()
        isAuthenticated = false
    }
    
    private func checkAuthStatus() {
        isLoading = true
        
        print("Checking auth status...")
        authService.acquireToken(scopes: [ConfigService.shared.graphScope]) { [weak self] (result: Result<String, Error>) in
            Task { @MainActor in
                switch result {
                case .success:
                    print("Valid token found")
                    self?.isAuthenticated = true
                case .failure(let error):
                    print("No valid token: \(error)")
                    self?.isAuthenticated = false
                }
                self?.isLoading = false
            }
        }
    }
} 

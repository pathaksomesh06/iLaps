//
//  DeviceListViewModel.swift
//  iLaps
//
//  Created by Somesh Pathak on 28/04/2025.
//

import Foundation
import SwiftUI
import AppKit

@MainActor
class DeviceListViewModel: ObservableObject {
    @Published var devices: [Device] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var passwords: [String: String] = [:] // device.id : password
    @Published var successMessage: String? = nil
    
    private let graphService = GraphService.shared
    private let keyVaultService = KeyVaultService.shared
    
    func fetchDevices() {
        Task {
            isLoading = true
            errorMessage = nil
            
            graphService.listMacDevices { [weak self] (result: Result<[Device], Error>) in
                Task { @MainActor in
                    self?.isLoading = false
                    
                    switch result {
                    case .success(let devices):
                        print("Fetched \(devices.count) devices")
                        self?.devices = devices.sorted { ($0.deviceName ?? "") < ($1.deviceName ?? "") }
                    case .failure(let error):
                        print("Failed to fetch devices: \(error)")
                        self?.errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }
    
    func fetchPassword(for device: Device) {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        if let serial = device.serialNumber {
            keyVaultService.retrievePassword(for: serial) { [weak self] (result: Result<String, Error>) in
                Task { @MainActor in
                    self?.isLoading = false
                    
                    switch result {
                    case .success(let password):
                        // Store password for this device
                        self?.passwords[device.id] = password
                        // Copy password to clipboard
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(password, forType: .string)
                        self?.successMessage = "Password copied to clipboard."
                    case .failure(let error):
                        self?.errorMessage = "Failed to retrieve password: \(error.localizedDescription)"
                    }
                }
            }
        } else {
            // Handle missing serial number (show error to user)
        }
    }
}

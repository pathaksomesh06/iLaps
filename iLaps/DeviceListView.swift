//
//  DeviceListView.swift
//  iLaps
//
//  Created by Somesh Pathak on 28/04/2025.
//

import SwiftUI
import Foundation

struct DeviceListView: View {
    @EnvironmentObject private var viewModel: DeviceListViewModel
    @State private var selectedDeviceID: String? = nil
    @State private var showRotateConfirmation = false
    @State private var deviceToRotate: Device? = nil
    @State private var isPasswordVisible = false
    
    private var deviceList: some View {
        List(selection: $selectedDeviceID) {
            ForEach(viewModel.devices) { device in
                DeviceRow(device: device)
                    .tag(device.id)
            }
        }
        .navigationTitle("Managed Macs")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { viewModel.fetchDevices() }) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
            }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.2))
            }
        }
        .alert("Error",
               isPresented: Binding<Bool>(
                   get: { viewModel.errorMessage != nil },
                   set: { if !$0 { viewModel.errorMessage = nil } }
               ),
               actions: {
                   Button("OK") { viewModel.errorMessage = nil }
               },
               message: {
                   Text(viewModel.errorMessage ?? "")
               }
        )
        .onAppear {
            viewModel.fetchDevices()
        }
    }
    
    private var detailPane: some View {
        let device = viewModel.devices.first { $0.id == selectedDeviceID }
        return DeviceDetailPane(device: device, viewModel: viewModel)
    }
    
    var body: some View {
        NavigationView {
            deviceList
            detailPane
        }
    }
}

struct DeviceRow: View {
    let device: Device
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Device icon based on type (fallback to laptop)
            Image(systemName: device.deviceType == "mac" || device.deviceType == "macMDM" ? "laptopcomputer" : "desktopcomputer")
                .font(.system(size: 28))
                .foregroundColor(.accentColor)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 4) {
                Text(device.deviceName ?? "Unnamed Device")
                    .font(.headline)
                if let os = device.operatingSystem, let version = device.osVersion {
                    Text("\(os) \(version)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                if let compliance = device.complianceState {
                    Label {
                        Text(compliance.capitalized)
                    } icon: {
                        Circle()
                            .fill(compliance == "compliant" ? Color.green : Color.orange)
                            .frame(width: 10, height: 10)
                    }
                    .font(.caption)
                    .foregroundColor(compliance == "compliant" ? .green : .orange)
                    .padding(.vertical, 1)
                    .padding(.horizontal, 6)
                    .background((compliance == "compliant" ? Color.green.opacity(0.1) : Color.orange.opacity(0.1)).cornerRadius(8))
                }
                if let lastSync = device.lastSyncDateTime,
                   let date = ISO8601DateFormatter().date(from: lastSync) {
                    Label("Last Sync: \(date.formatted())", systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

struct DeviceDetailPane: View {
    let device: Device?
    @ObservedObject var viewModel: DeviceListViewModel
    @State private var isPasswordVisible = false
    @State private var showSuccess = false
    
    var body: some View {
        if let device = device {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: device.deviceType == "mac" || device.deviceType == "macMDM" ? "laptopcomputer" : "desktopcomputer")
                        .font(.system(size: 36))
                        .foregroundColor(.accentColor)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(device.deviceName ?? "Unnamed Device")
                            .font(.title2)
                            .bold()
                        if let os = device.operatingSystem, let version = device.osVersion {
                            Text("OS: \(os) \(version)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                if let compliance = device.complianceState {
                    HStack(spacing: 8) {
                        Text("Compliance:")
                            .font(.subheadline)
                        Text(compliance.capitalized)
                            .font(.subheadline)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 2)
                            .background((compliance == "compliant" ? Color.green.opacity(0.15) : Color.orange.opacity(0.15)).cornerRadius(8))
                            .foregroundColor(compliance == "compliant" ? .green : .orange)
                    }
                }
                if let lastSync = device.lastSyncDateTime,
                   let date = ISO8601DateFormatter().date(from: lastSync) {
                    Label("Last Sync: \(date.formatted())", systemImage: "clock")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                if let message = viewModel.successMessage {
                    Text(message)
                        .foregroundColor(.green)
                        .font(.subheadline)
                        .transition(.opacity)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                showSuccess = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    showSuccess = false
                                }
                            }
                        }
                        .opacity(showSuccess ? 1 : 0)
                }
                Divider()
                VStack(alignment: .leading, spacing: 8) {
                    Text("Device Password")
                        .font(.headline)
                    if let password = viewModel.passwords[device.id] {
                        HStack {
                            if isPasswordVisible {
                                TextField("Password", text: .constant(password))
                                    .textFieldStyle(.roundedBorder)
                                    .disabled(true)
                            } else {
                                SecureField("Password", text: .constant(password))
                                    .textFieldStyle(.roundedBorder)
                                    .disabled(true)
                            }
                            Button(action: { isPasswordVisible.toggle() }) {
                                Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                            }
                            .help(isPasswordVisible ? "Hide Password" : "Show Password")
                            Button(action: {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(password, forType: .string)
                            }) {
                                Image(systemName: "doc.on.doc")
                            }
                            .help("Copy Password")
                        }
                    } else {
                        Button("Fetch Password") {
                            viewModel.fetchPassword(for: device)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 18).fill(Color(.windowBackgroundColor)).shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        } else {
            VStack {
                Spacer()
                Image(systemName: "rectangle.on.rectangle.slash")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
                Text("Select a device to view details")
                    .font(.title3)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

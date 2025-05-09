//
//  MainView.swift
//  iLaps
//
//  Created by Somesh Pathak on 28/04/2025.
//

import SwiftUI

struct MainView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var deviceListViewModel = DeviceListViewModel()
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                DeviceListView()
                    .environmentObject(deviceListViewModel)
            } else {
                LoginView()
            }
        }
        .environmentObject(authViewModel)
    }
} 
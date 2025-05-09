//
//  iLapsApp.swift
//  iLaps
//
//  Created by Somesh Pathak on 28/04/2025.
//

import SwiftUI
import AppKit

@main
struct iLapsApp: App {
    // Initialize services early
    private let configService = ConfigService.shared
    private let authService = AuthService.shared
    
    init() {
        // Set up any global app configuration here
        print("Initializing iLaps Admin Console...")
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About iLaps") {
                    NSApplication.shared.orderFrontStandardAboutPanel()
                }
            }
            
            CommandGroup(replacing: .newItem) { }
            
            CommandGroup(after: .windowList) {
                Button("Sign Out") {
                    // The view model will be available through the environment
                    NotificationCenter.default.post(name: NSNotification.Name("SignOutRequested"), object: nil)
                }
                .keyboardShortcut("L", modifiers: [.command, .shift])
            }
        }
    }
} 
//
//  TakeABreakApp.swift
//  Take a Break
//
//  Created by Prakash Joshi on 22/04/2025.
//

import SwiftUI
import SwiftData

@main
struct TakeABreakApp: App {
    // Use the app delegate
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // No longer need to initialize managers here
    
    var body: some Scene {
        // The Settings scene provides the standard macOS settings window
        // accessible via Cmd+,
        Settings {
            // Ensure appDelegate.takeABreakSettings is not nil before creating the view
            if let settings = appDelegate.takeABreakSettings {
                SettingsView(settings: settings)
            } else {
                // Provide a fallback view or handle the nil case appropriately
                Text("Settings not available.")
                    .frame(width: 300, height: 200)
            }
        }
    }
}

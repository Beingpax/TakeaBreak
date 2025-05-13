import SwiftUI
import SwiftData
import AppKit

@main
struct TakeABreakApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        // Ensure we're on the main thread and NSApp is available
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(.accessory)
        }
    }
    
    var body: some Scene {
        Settings {
            // Use direct access to settings to avoid optional unwrapping
            SettingsView(settings: appDelegate.takeABreakSettings ?? TakeABreakSettings())
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}

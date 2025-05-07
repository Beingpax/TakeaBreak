import AppKit
import SwiftUI
import Combine // Add Combine for cancellables

class AppDelegate: NSObject, NSApplicationDelegate {
    
    // Hold references to the core components
    private var timerManager: TimerManager?
    private var windowManager: WindowManager?
    // BreatherSettings is now standalone, loaded from storage
    private var settings = BreatherSettings()
    private var menuBarManager: MenuBarManager?
    private var menuRefreshTimer: Timer?
    private var cancellables = Set<AnyCancellable>() // To hold subscriptions

    // Keep a reference to the settings object to pass to the SwiftUI App
    var breatherSettings: BreatherSettings? {
        return settings
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide the dock icon *first*
        NSApp.setActivationPolicy(.accessory)
        
        // Now initialize the components
        // Settings are loaded automatically by its init
        let settingsInstance = self.settings
        
        // Initialize TimerManager *with* settings
        let timerManagerInstance = TimerManager(settings: settingsInstance)
        
        // Pass both settings and timerManager to WindowManager
        let windowManagerInstance = WindowManager(
            settings: settingsInstance,
            timerManager: timerManagerInstance
        )
        
        // Initialize menu bar manager
        let menuBarManagerInstance = MenuBarManager(
            timerManager: timerManagerInstance,
            settings: settingsInstance
        )
        
        // Store instances
        self.timerManager = timerManagerInstance
        self.windowManager = windowManagerInstance
        // self.settings is already set
        self.menuBarManager = menuBarManagerInstance

        // Setup timer manager callbacks to WindowManager
        timerManagerInstance.onBreakTime = { [weak windowManagerInstance] in
            windowManagerInstance?.showReminderWindow()
        }
        
        timerManagerInstance.onPreBreakNotification = { [weak windowManagerInstance] in
            windowManagerInstance?.showPreBreakNotification()
        }
        
        // NEW: Setup callback for TimerManager to tell WindowManager to hide all notifications
        // This is used during system events (sleep/screensaver) or when Breather is disabled.
        timerManagerInstance.onHideNotifications = { [weak windowManagerInstance] in
            windowManagerInstance?.hideAllNotificationsForSystemEvent()
        }
        
        // Only start the timer if the setting is enabled
        if settingsInstance.isEnabled {
            timerManagerInstance.startTimer()
        }
        
        // Start periodic menu refresh timer
        self.menuRefreshTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak menuBarManagerInstance] _ in
            menuBarManagerInstance?.refreshMenu()
        }
        
        // LaunchAtLogin state is now handled by the LaunchAtLogin library
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Clean up timer if needed
        menuRefreshTimer?.invalidate()
        menuRefreshTimer = nil
        cancellables.forEach { $0.cancel() } // Cancel subscriptions
    }
} 
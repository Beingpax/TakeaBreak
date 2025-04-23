import AppKit
import SwiftUI
import Combine // Add Combine for cancellables

class AppDelegate: NSObject, NSApplicationDelegate {
    
    // Hold references to the core components
    private var timerManager: TimerManager?
    private var windowManager: WindowManager?
    private var settings: BreatherSettings?
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
        let timerManagerInstance = TimerManager()
        let settingsInstance = BreatherSettings(timerManager: timerManagerInstance)
        
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
        self.settings = settingsInstance
        self.menuBarManager = menuBarManagerInstance

        // Setup timer manager to show reminder window
        timerManagerInstance.onBreakTime = { [weak windowManagerInstance] in
            windowManagerInstance?.showReminderWindow()
        }
        
        // Setup timer manager to show pre-break notification
        timerManagerInstance.onPreBreakNotification = { [weak windowManagerInstance] in
            windowManagerInstance?.showPreBreakNotification()
        }
        
        // Configure timer interval based on initial settings
        timerManagerInstance.setBreakInterval(settingsInstance.breakInterval)
        timerManagerInstance.setPreBreakNotificationTime(settingsInstance.preBreakNotificationTime)
        
        // Start the timer if enabled in settings
        if settingsInstance.isEnabled {
            timerManagerInstance.startTimer()
        }
        
        // Start periodic menu refresh timer
        self.menuRefreshTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak menuBarManagerInstance] _ in
            menuBarManagerInstance?.refreshMenu()
        }
        
        // Observe settings changes (moved from BreatherSettings init)
        // We do this here to ensure timerManagerInstance is fully initialized
        settingsInstance.$breakInterval
            .dropFirst() // Ignore initial value
            .sink { [weak timerManagerInstance] interval in
                UserDefaults.standard.set(interval, forKey: "breakInterval") // Use key directly or enum
                timerManagerInstance?.setBreakInterval(interval)
            }
            .store(in: &cancellables)
            
        settingsInstance.$isEnabled
            .dropFirst() // Ignore initial value
            .sink { [weak timerManagerInstance] enabled in
                UserDefaults.standard.set(enabled, forKey: "isEnabled") // Use key directly or enum
                if enabled {
                    timerManagerInstance?.startTimer()
                } else {
                    timerManagerInstance?.stopTimer()
                }
            }
            .store(in: &cancellables)
            
        // Observer for autoDismissDuration
        settingsInstance.$autoDismissDuration
            .dropFirst()
            .sink { duration in
                UserDefaults.standard.set(duration, forKey: "autoDismissDuration")
            }
            .store(in: &cancellables)
            
        // Observer for preBreakNotificationTime
        settingsInstance.$preBreakNotificationTime
            .dropFirst()
            .sink { [weak timerManagerInstance] time in
                UserDefaults.standard.set(time, forKey: "preBreakNotificationTime")
                timerManagerInstance?.setPreBreakNotificationTime(time)
            }
            .store(in: &cancellables)
            
        // Observer for preBreakNotificationDuration
        settingsInstance.$preBreakNotificationDuration
            .dropFirst()
            .sink { duration in
                UserDefaults.standard.set(duration, forKey: "preBreakNotificationDuration")
            }
            .store(in: &cancellables)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Clean up timer if needed
        menuRefreshTimer?.invalidate()
        menuRefreshTimer = nil
        cancellables.forEach { $0.cancel() } // Cancel subscriptions
    }
} 
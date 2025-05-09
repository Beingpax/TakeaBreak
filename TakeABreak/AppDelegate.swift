import AppKit
import SwiftUI
import Combine // Add Combine for cancellables

class AppDelegate: NSObject, NSApplicationDelegate {
    
    // Hold references to the core components
    private var timerManager: TimerManager?
    private var windowManager: WindowManager?
    // BreatherSettings is now standalone, loaded from storage
    private var settings = TakeABreakSettings()
    private var menuBarManager: MenuBarManager?
    private var menuRefreshTimer: Timer?
    private var cancellables = Set<AnyCancellable>() // To hold subscriptions
    private var onboardingWindowManager: OnboardingWindowManager?

    // Expose settings for use in the app
    var takeABreakSettings: TakeABreakSettings? {
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
        
        // Check if onboarding needs to be shown
        if !settingsInstance.hasCompletedOnboarding {
            showOnboarding()
        } else {
            // Only start the timer if the setting is enabled and onboarding is completed
            if settingsInstance.isEnabled {
                timerManagerInstance.startTimer()
            }
        }
        
        // Start periodic menu refresh timer
        self.menuRefreshTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak menuBarManagerInstance] _ in
            menuBarManagerInstance?.refreshMenu()
        }
        
        // LaunchAtLogin state is now handled by the LaunchAtLogin library
    }
    
    private func showOnboarding() {
        onboardingWindowManager = OnboardingWindowManager(settings: settings) { [weak self] in
            // Onboarding completed, start the timer if enabled
            guard let self = self else { return }
            if self.settings.isEnabled, let timerManager = self.timerManager {
                timerManager.startTimer()
            }
        }
        onboardingWindowManager?.showOnboardingWindow()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Clean up timer if needed
        menuRefreshTimer?.invalidate()
        menuRefreshTimer = nil
        cancellables.forEach { $0.cancel() } // Cancel subscriptions
    }
} 
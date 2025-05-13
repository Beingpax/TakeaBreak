import AppKit
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    
    private var timerManager: TimerManager?
    private var windowManager: WindowManager?
    private var settings = TakeABreakSettings()
    private var menuBarManager: MenuBarManager?
    private var menuRefreshTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var onboardingWindowManager: OnboardingWindowManager?

    var takeABreakSettings: TakeABreakSettings? {
        return settings
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        
        let settingsInstance = self.settings
        
        let timerManagerInstance = TimerManager(settings: settingsInstance)
        
        let windowManagerInstance = WindowManager(
            settings: settingsInstance,
            timerManager: timerManagerInstance
        )
        
        let menuBarManagerInstance = MenuBarManager(
            timerManager: timerManagerInstance,
            settings: settingsInstance
        )
        
        self.timerManager = timerManagerInstance
        self.windowManager = windowManagerInstance
        self.menuBarManager = menuBarManagerInstance

        timerManagerInstance.onBreakTime = { [weak windowManagerInstance] in
            windowManagerInstance?.showReminderWindow()
        }
        
        timerManagerInstance.onPreBreakNotification = { [weak windowManagerInstance] in
            windowManagerInstance?.showPreBreakNotification()
        }
        
        timerManagerInstance.onHideNotifications = { [weak windowManagerInstance] in
            windowManagerInstance?.hideAllNotificationsForSystemEvent()
        }
        
        if !settingsInstance.hasCompletedOnboarding {
            showOnboarding()
        } else {
            if settingsInstance.isEnabled {
                timerManagerInstance.startTimer()
            }
        }
        
        self.menuRefreshTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak menuBarManagerInstance] _ in
            menuBarManagerInstance?.refreshMenu()
        }
        
        NSApp.setActivationPolicy(.accessory)
    }
    
    private func showOnboarding() {
        onboardingWindowManager = OnboardingWindowManager(settings: settings) { [weak self] in
            guard let self = self else { return }
            if self.settings.isEnabled, let timerManager = self.timerManager {
                timerManager.startTimer()
            }
            
            NSApp.setActivationPolicy(.accessory)
        }
        onboardingWindowManager?.showOnboardingWindow()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            NSApp.setActivationPolicy(.accessory)
        }
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        menuRefreshTimer?.invalidate()
        menuRefreshTimer = nil
        cancellables.forEach { $0.cancel() }
    }
} 
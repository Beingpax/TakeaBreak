import SwiftUI
import AppKit

class MenuBarManager: ObservableObject {
    private var statusItem: NSStatusItem?
    private var timerManager: TimerManager
    private var settings: TakeABreakSettings
    private var settingsWindow: NSWindow?
    private var settingsWindowDelegate: SettingsWindowDelegate?
    
    init(timerManager: TimerManager, settings: TakeABreakSettings) {
        self.timerManager = timerManager
        self.settings = settings
        
        setupStatusBar()
    }
    
    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.title = timerManager.formattedTimeRemainingInMinutes() 
            button.action = #selector(toggleMenu)
            button.target = self
        }
        
        updateMenu()
    }
    
    private func updateMenu() {
        let menu = NSMenu()
        
        statusItem?.button?.title = timerManager.formattedTimeRemainingInMinutes()

        let timeRemainingItem = NSMenuItem(title: "Next break: \(timerManager.formattedTimeRemaining())", action: nil, keyEquivalent: "")
        timeRemainingItem.isEnabled = false
        menu.addItem(timeRemainingItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let toggleItem = NSMenuItem(title: settings.isEnabled ? "Disable Breaks" : "Enable Breaks", action: #selector(toggleBreaks), keyEquivalent: "")
        toggleItem.target = self
        menu.addItem(toggleItem)
        
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        #if DEBUG
        menu.addItem(NSMenuItem.separator())
        
        let debugMenu = NSMenu()
        let debugItem = NSMenuItem(title: "Debug", action: nil, keyEquivalent: "")
        debugItem.submenu = debugMenu
        
        let triggerBreakItem = NSMenuItem(title: "Trigger Break Now", action: #selector(debugTriggerBreak), keyEquivalent: "")
        triggerBreakItem.target = self
        debugMenu.addItem(triggerBreakItem)
        
        let resetOnboardingItem = NSMenuItem(title: "Reset Onboarding", action: #selector(debugResetOnboarding), keyEquivalent: "")
        resetOnboardingItem.target = self
        debugMenu.addItem(resetOnboardingItem)
        
        menu.addItem(debugItem)
        #endif
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    func refreshMenu() {
        updateMenu()
    }
    
    @objc private func toggleMenu() {
        updateMenu()
    }
    
    @objc private func toggleBreaks() {
        settings.isEnabled.toggle()
        updateMenu()
    }
    
    @objc private func openSettings() {
        if let existingWindow = settingsWindow {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let contentView = SettingsView(settings: settings)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 350, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        let windowDelegate = SettingsWindowDelegate { [weak self] in
            self?.settingsWindow = nil
            self?.settingsWindowDelegate = nil
        }
        self.settingsWindowDelegate = windowDelegate
        window.delegate = windowDelegate
        
        window.title = "Take a Break Settings"
        window.center()
        window.contentView = NSHostingView(rootView: contentView)
        window.isReleasedWhenClosed = false
        
        self.settingsWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func quitApp() {
        settingsWindow?.close()
        settingsWindow = nil
        settingsWindowDelegate = nil
        NSApp.terminate(nil)
    }
    
    #if DEBUG
    @objc private func debugTriggerBreak() {
        timerManager.stopTimer()
        timerManager.stopBreakCountdown()
        
        timerManager.onBreakTime?()
    }
    
    @objc private func debugResetOnboarding() {
        settings.hasCompletedOnboarding = false
        let alert = NSAlert()
        alert.messageText = "Onboarding Reset"
        alert.informativeText = "The onboarding will be shown next time you restart the app."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    #endif
    
    deinit {
        settingsWindow?.close()
        settingsWindow = nil
        settingsWindowDelegate = nil
    }
}

class SettingsWindowDelegate: NSObject, NSWindowDelegate {
    private let onClose: () -> Void
    
    init(onClose: @escaping () -> Void) {
        self.onClose = onClose
        super.init()
    }
    
    func windowWillClose(_ notification: Notification) {
        onClose()
    }
} 
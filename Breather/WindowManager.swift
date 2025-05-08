import SwiftUI
import AppKit

class WindowManager: ObservableObject {
    private var reminderPanels: [KeyablePanel] = []
    private var panelHostingViews: [KeyablePanel: NSHostingView<ReminderView>] = [:]
    private var settings: BreatherSettings
    private var timerManager: TimerManager
    private var preBreakPanel: NSPanel?
    private var preBreakHostingView: NSHostingView<PreBreakNotificationView>?

    init(settings: BreatherSettings, timerManager: TimerManager) {
        self.settings = settings
        self.timerManager = timerManager
    }
    
    func showPreBreakNotification() {
        hidePreBreakNotification()
        
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 140),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        let contentView = PreBreakNotificationView(
            duration: settings.preBreakNotificationDuration,
            skipAction: { [weak self] in
                self?.timerManager.resetTimer()
                self?.hidePreBreakNotification(isUserAction: true)
            },
            takeBreakNowAction: { [weak self] in
                self?.hidePreBreakNotification(isUserAction: true)
                self?.showReminderWindow()
            },
            postponeAction: { [weak self] in
                guard let self = self else { return }
                self.timerManager.extendTimer(by: 5 * 60)
                self.hidePreBreakNotification(isUserAction: true)
            }
        )
        
        let hostingView = NSHostingView(rootView: contentView)
        panel.contentView = hostingView
        
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.level = .floating
        
        let activeScreen = getActiveScreen()
        let screenFrame = activeScreen.visibleFrame
        let panelFrame = panel.frame
        let xPosition = screenFrame.maxX - panelFrame.width - 20
        let yPosition = screenFrame.minY + 20
        
        panel.setFrameOrigin(NSPoint(x: xPosition, y: yPosition))
        
        preBreakPanel = panel
        preBreakHostingView = hostingView
        
        panel.orderFront(nil)
    }
    
    func hidePreBreakNotification(isUserAction: Bool = false) {
        preBreakPanel?.close()
        preBreakPanel = nil
        preBreakHostingView = nil
    }
    
    func showReminderWindow() {
        if !reminderPanels.isEmpty {
            hideReminderWindow(isSystemEventOrDisabled: true)
        }
        hidePreBreakNotification()
        
        timerManager.startBreakCountdown(duration: settings.autoDismissDuration)
        
        // Select a single motivational quote for all screens
        let selectedQuote = !settings.motivationalQuotes.isEmpty 
            ? settings.motivationalQuotes.randomElement()! 
            : "Enjoy your break!"
        
        let screens = NSScreen.screens
        
        for screen in screens {
            let panel = KeyablePanel(
                contentRect: screen.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false,
                screen: screen
            )
            
            reminderPanels.append(panel)
            
            let contentView = ReminderView(
                autoDismissDuration: settings.autoDismissDuration,
                dismissAction: { [weak self] in
                    self?.hideReminderWindow()
                },
                settings: settings,
                timerManager: timerManager,
                motivationalQuote: selectedQuote  // Pass the selected quote
            )
            
            let hostingView = NSHostingView(rootView: contentView)
            panelHostingViews[panel] = hostingView
            
            panel.contentView = hostingView
            panel.backgroundColor = .clear
            panel.isOpaque = false
            panel.hasShadow = false
            panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.screenSaverWindow)))
            panel.hidesOnDeactivate = false
            panel.ignoresMouseEvents = false
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenPrimary, .stationary]
            
            panel.setFrame(screen.frame, display: true)
            panel.orderFront(nil)
            panel.makeKeyAndOrderFront(nil)
        }
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func hideReminderWindow(isSystemEventOrDisabled: Bool = false) {
        if reminderPanels.isEmpty && !isSystemEventOrDisabled {
            if isSystemEventOrDisabled {
                timerManager.stopBreakCountdown()
            }
            return
        }
        
        let panelsToClose = reminderPanels
        reminderPanels.removeAll()
        
        for panel in panelsToClose {
            panelHostingViews.removeValue(forKey: panel)
            panel.close()
        }
        panelHostingViews.removeAll()
        
        if !isSystemEventOrDisabled && settings.isEnabled {
            timerManager.stopBreakCountdown()
            timerManager.resumeTimer()
        } else {
            timerManager.stopBreakCountdown()
        }
    }
    
    func hideAllNotificationsForSystemEvent() {
        hidePreBreakNotification()
        if !timerManager.isBreakActive {
            hideReminderWindow(isSystemEventOrDisabled: true)
        }
    }
    
    deinit {
        hideAllNotificationsForSystemEvent()
    }
    
    private func getActiveScreen() -> NSScreen {
        let mouseLocation = NSEvent.mouseLocation
        
        if let screenWithMouse = NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) }) {
            return screenWithMouse
        }
        
        if let keyWindow = NSApp.keyWindow, let windowScreen = keyWindow.screen {
            return windowScreen
        }
        
        return NSScreen.main ?? NSScreen.screens.first!
    }
} 
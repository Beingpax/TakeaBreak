import SwiftUI
import AppKit

class WindowManager: ObservableObject {
    private var reminderPanels: [KeyablePanel] = []
    private var panelHostingViews: [KeyablePanel: NSHostingView<ReminderView>] = [:]
    private var settings: BreatherSettings
    private var timerManager: TimerManager
    
    // For pre-break notification
    private var preBreakPanel: NSPanel?
    private var preBreakHostingView: NSHostingView<PreBreakNotificationView>?

    init(settings: BreatherSettings, timerManager: TimerManager) {
        self.settings = settings
        self.timerManager = timerManager
    }
    
    func showPreBreakNotification() {
        hidePreBreakNotification()
        
        // Create the notification panel
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 95),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        let contentView = PreBreakNotificationView(
            duration: settings.preBreakNotificationDuration,
            skipAction: { [weak self] in
                self?.hidePreBreakNotification()
                self?.timerManager.resetTimer() // Skip this break and restart full timer
                print("DEBUG: Break skipped, timer reset to full interval: \(self?.timerManager.formattedTimeRemaining() ?? "unknown")")
            },
            takeBreakNowAction: { [weak self] in
                self?.hidePreBreakNotification()
                self?.showReminderWindow()
                print("DEBUG: Taking break now")
            },
            postponeAction: { [weak self] in
                guard let self = self else { return }
                self.hidePreBreakNotification()
                self.timerManager.extendTimer(by: 5 * 60) // Add 5 minutes to current time
                print("DEBUG: Added 5 minutes to timer, new time: \(self.timerManager.formattedTimeRemaining())")
            }
        )
        
        let hostingView = NSHostingView(rootView: contentView)
        panel.contentView = hostingView
        
        // Configure the panel
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.level = .floating
        
        // Position in bottom right of main screen
        if let mainScreen = NSScreen.main {
            let screenFrame = mainScreen.visibleFrame
            let panelFrame = panel.frame
            let xPosition = screenFrame.maxX - panelFrame.width - 20
            let yPosition = screenFrame.minY + 20
            
            panel.setFrameOrigin(NSPoint(x: xPosition, y: yPosition))
        }
        
        // Store references
        preBreakPanel = panel
        preBreakHostingView = hostingView
        
        // Show the panel
        panel.orderFront(nil)
    }
    
    func hidePreBreakNotification() {
        preBreakPanel?.close()
        preBreakPanel = nil
        preBreakHostingView = nil
    }
    
    func showReminderWindow() {
        // Only hide reminder window if there are existing panels
        if !reminderPanels.isEmpty {
            hideReminderWindow()
        }
        hidePreBreakNotification()
        
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
                autoDismissDuration: settings.autoDismissDuration
            ) { [weak self] in
                guard let self = self else { return }
                if let index = self.reminderPanels.firstIndex(of: panel) {
                    let panelToClose = self.reminderPanels.remove(at: index)
                    self.panelHostingViews.removeValue(forKey: panelToClose)
                    panelToClose.close()
                    
                    // If this was the last panel, resume the timer
                    if self.reminderPanels.isEmpty {
                        self.timerManager.resumeTimer()
                    }
                }
            }
            
            let hostingView = NSHostingView(rootView: contentView)
            panelHostingViews[panel] = hostingView
            
            panel.contentView = hostingView
            panel.backgroundColor = .clear
            panel.isOpaque = false
            panel.hasShadow = false
            panel.level = .screenSaver
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenPrimary]
            
            panel.setFrame(screen.frame, display: true)
            panel.orderFront(nil)
            panel.makeKeyAndOrderFront(nil)
        }
        
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func hideReminderWindow() {
        let panelsToClose = reminderPanels
        reminderPanels.removeAll()
        
        for panel in panelsToClose {
            panelHostingViews.removeValue(forKey: panel)
            panel.close()
        }
        
        panelHostingViews.removeAll()
        
        // Resume timer when all panels are closed
        if !panelsToClose.isEmpty {
            timerManager.resumeTimer()
        }
    }
    
    deinit {
        hideReminderWindow()
        hidePreBreakNotification()
    }
} 
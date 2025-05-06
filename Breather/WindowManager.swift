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
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 95),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        let contentView = PreBreakNotificationView(
            duration: settings.preBreakNotificationDuration,
            skipAction: { [weak self] in
                self?.hidePreBreakNotification()
                self?.timerManager.resetTimer()
            },
            takeBreakNowAction: { [weak self] in
                self?.hidePreBreakNotification()
                self?.showReminderWindow()
            },
            postponeAction: { [weak self] in
                guard let self = self else { return }
                self.hidePreBreakNotification()
                self.timerManager.extendTimer(by: 5 * 60)
            }
        )
        
        let hostingView = NSHostingView(rootView: contentView)
        panel.contentView = hostingView
        
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.level = .floating
        
        if let mainScreen = NSScreen.main {
            let screenFrame = mainScreen.visibleFrame
            let panelFrame = panel.frame
            let xPosition = screenFrame.maxX - panelFrame.width - 20
            let yPosition = screenFrame.minY + 20
            
            panel.setFrameOrigin(NSPoint(x: xPosition, y: yPosition))
        }
        
        preBreakPanel = panel
        preBreakHostingView = hostingView
        
        panel.orderFront(nil)
    }
    
    func hidePreBreakNotification() {
        preBreakPanel?.close()
        preBreakPanel = nil
        preBreakHostingView = nil
    }
    
    func showReminderWindow() {
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
                autoDismissDuration: settings.autoDismissDuration,
                dismissAction: { [weak self] in
                    guard let self = self else { return }
                    if let index = self.reminderPanels.firstIndex(of: panel) {
                        let panelToClose = self.reminderPanels.remove(at: index)
                        self.panelHostingViews.removeValue(forKey: panelToClose)
                        panelToClose.close()
                        
                        if self.reminderPanels.isEmpty {
                            self.timerManager.resumeTimer()
                        }
                    }
                },
                settings: settings
            )
            
            let hostingView = NSHostingView(rootView: contentView)
            panelHostingViews[panel] = hostingView
            
            panel.contentView = hostingView
            panel.backgroundColor = .clear
            panel.isOpaque = false
            panel.hasShadow = false
            
            // Use a custom level higher than any predefined level
            // CGWindowLevelForKey(.screenSaver) is 1000, so we'll use something higher
            panel.level = NSWindow.Level(rawValue: 2000)
            
            panel.hidesOnDeactivate = false
            panel.ignoresMouseEvents = false // Allow mouse events for buttons in the reminder
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenPrimary, .stationary]
            
            panel.setFrame(screen.frame, display: true)
            panel.orderFront(nil)
            panel.makeKeyAndOrderFront(nil)
        }
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func hideReminderWindow() {
        if reminderPanels.isEmpty {
            return
        }
        
        let panelsToClose = reminderPanels
        reminderPanels.removeAll()
        
        for panel in panelsToClose {
            panelHostingViews.removeValue(forKey: panel)
            panel.close()
        }
        
        panelHostingViews.removeAll()
        
        if !panelsToClose.isEmpty {
            timerManager.resumeTimer()
        }
    }
    
    deinit {
        hideReminderWindow()
        hidePreBreakNotification()
    }
} 
import Foundation
import AppKit
import os.log

// Define delegate methods for system event notifications
protocol SystemEventsDelegate: AnyObject {
    func systemWillSleep()
    func systemDidWake()
    func screenSaverDidStart()
    func screenSaverDidStop()
    func displayDidSleep()
    func displayDidWake()
}

class SystemEventsManager {
    // Delegate to receive event notifications
    weak var delegate: SystemEventsDelegate?
    
    // Track current system state
    private var isScreenSaverActive = false
    private var isDisplaySleeping = false
    
    // Logger for debugging screen saver issues
    private let logger = Logger(subsystem: "com.yourapp.breather", category: "timerbreak")
    
    // Initialize and register for system notifications
    init() {
        setupNotifications()
        logger.notice("SystemEventsManager initialized")
    }
    
    private func setupNotifications() {
        let workspaceNC = NSWorkspace.shared.notificationCenter
        let distNC = DistributedNotificationCenter.default()
        
        // System sleep/wake
        workspaceNC.addObserver(self, selector: #selector(handleSystemWillSleep), 
                                name: NSWorkspace.willSleepNotification, object: nil)
        workspaceNC.addObserver(self, selector: #selector(handleSystemDidWake), 
                                name: NSWorkspace.didWakeNotification, object: nil)
        
        // Screen saver
        distNC.addObserver(self, selector: #selector(handleScreenSaverDidStart),
                          name: NSNotification.Name("com.apple.screensaver.didstart"), object: nil)
        distNC.addObserver(self, selector: #selector(handleScreenSaverDidStop),
                          name: NSNotification.Name("com.apple.screensaver.didstop"), object: nil)
        
        // Display sleep/wake
        distNC.addObserver(self, selector: #selector(handleDisplaySleep),
                          name: NSNotification.Name("com.apple.screenIsLocked"), object: nil)
        distNC.addObserver(self, selector: #selector(handleDisplayWake),
                          name: NSNotification.Name("com.apple.screenIsUnlocked"), object: nil)
        
        logger.notice("Registered for screen saver notifications: didstart, didstop")
    }
    
    // Handle system sleep notification
    @objc private func handleSystemWillSleep() {
        delegate?.systemWillSleep()
    }
    
    // Handle system wake notification
    @objc private func handleSystemDidWake() {
        delegate?.systemDidWake()
    }
    
    // Handle screen saver start notification
    @objc private func handleScreenSaverDidStart() {
        logger.notice("Screen saver START notification received")
        if !isScreenSaverActive {
            isScreenSaverActive = true
            logger.notice("Screen saver started - pausing timer")
            delegate?.screenSaverDidStart()
        }
    }
    
    // Handle screen saver stop notification
    @objc private func handleScreenSaverDidStop() {
        logger.notice("Screen saver STOP notification received")
        if isScreenSaverActive {
            isScreenSaverActive = false
            logger.notice("Screen saver stopped - resuming timer")
            delegate?.screenSaverDidStop()
        }
    }
    
    @objc private func handleDisplaySleep() {
        if !isDisplaySleeping {
            isDisplaySleeping = true
            delegate?.displayDidSleep()
        }
    }
    
    @objc private func handleDisplayWake() {
        if isDisplaySleeping {
            isDisplaySleeping = false
            delegate?.displayDidWake()
        }
    }
    
    // Clean up observers
    deinit {
        NotificationCenter.default.removeObserver(self)
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        DistributedNotificationCenter.default().removeObserver(self)
    }
} 
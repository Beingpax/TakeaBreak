import Foundation
import AppKit

// Define delegate methods for system event notifications
protocol SystemEventsDelegate: AnyObject {
    func systemWillSleep()
    func systemDidWake()
    func displayDidSleep()
    func displayDidWake()
}

class SystemEventsManager {
    // Delegate to receive event notifications
    weak var delegate: SystemEventsDelegate?
    
    // Track current system state
    private var isDisplaySleeping = false
    
    // Initialize and register for system notifications
    init() {
        setupNotifications()
    }
    
    private func setupNotifications() {
        let workspaceNC = NSWorkspace.shared.notificationCenter
        let distNC = DistributedNotificationCenter.default()
        
        // System sleep/wake
        workspaceNC.addObserver(self, selector: #selector(handleSystemWillSleep), 
                                name: NSWorkspace.willSleepNotification, object: nil)
        workspaceNC.addObserver(self, selector: #selector(handleSystemDidWake), 
                                name: NSWorkspace.didWakeNotification, object: nil)
        
        // Display sleep/wake (lock/unlock)
        distNC.addObserver(self, selector: #selector(handleDisplaySleep),
                          name: NSNotification.Name("com.apple.screenIsLocked"), object: nil)
        distNC.addObserver(self, selector: #selector(handleDisplayWake),
                          name: NSNotification.Name("com.apple.screenIsUnlocked"), object: nil)
    }
    
    // Handle system sleep notification
    @objc private func handleSystemWillSleep() {
        delegate?.systemWillSleep()
    }
    
    // Handle system wake notification
    @objc private func handleSystemDidWake() {
        delegate?.systemDidWake()
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
import Foundation
import CoreGraphics
import Combine
import os.log

/// Protocol defining delegate methods for idle state changes
protocol IdleDetectorDelegate: AnyObject {
    /// Called when the user becomes idle for longer than the threshold
    func userDidBecomeIdle()
    
    /// Called when the user resumes activity after being idle
    func userDidBecomeActive()
}

/// A class that monitors user input activity to detect when the system becomes idle
class IdleDetector: ObservableObject {
    // MARK: - Published Properties
    
    /// Current idle state of the user
    @Published private(set) var isUserIdle = false
    
    /// Time elapsed since the last user activity in seconds
    @Published private(set) var idleTimeSeconds: TimeInterval = 0
    
    // MARK: - Properties
    
    /// The delegate that will receive idle state change notifications
    weak var delegate: IdleDetectorDelegate?
    
    /// The time threshold in seconds after which the system is considered idle
    private var idleThreshold: TimeInterval
    
    /// Timer used for polling the idle state
    private var timer: Timer?
    
    /// Polling interval for checking idle state (in seconds)
    private let pollingInterval: TimeInterval
    
    /// Logger instance for debugging and diagnostics
    private let logger = Logger(subsystem: "com.yourapp.breather", category: "idleDetection")
    
    // MARK: - Initialization
    
    /// Initializes a new idle detector with the specified threshold
    /// - Parameters:
    ///   - idleThreshold: Time in seconds after which the user is considered idle (default: 60 seconds)
    ///   - pollingInterval: How frequently to check for idle state in seconds (default: 5 seconds)
    init(idleThreshold: TimeInterval = 60, pollingInterval: TimeInterval = 5) {
        self.idleThreshold = idleThreshold
        self.pollingInterval = pollingInterval
        
        logger.notice("IdleDetector initialized with threshold: \(idleThreshold) seconds, polling interval: \(pollingInterval) seconds")
        startMonitoring()
    }
    
    // MARK: - Monitoring Methods
    
    /// Updates the idle threshold value
    /// - Parameter newThreshold: The new threshold in seconds
    func updateIdleThreshold(_ newThreshold: TimeInterval) {
        if idleThreshold != newThreshold {
            logger.notice("Updating idle threshold from \(self.idleThreshold) to \(newThreshold) seconds")
            idleThreshold = newThreshold
            
            // Check if the state should change with the new threshold
            let shouldBeIdle = idleTimeSeconds > idleThreshold
            if shouldBeIdle != isUserIdle {
                isUserIdle = shouldBeIdle
                
                if shouldBeIdle {
                    logger.notice("User is now considered idle with new threshold")
                    delegate?.userDidBecomeIdle()
                } else {
                    logger.notice("User is now considered active with new threshold")
                    delegate?.userDidBecomeActive()
                }
            }
        }
    }
    
    /// Starts monitoring for user idle state
    func startMonitoring() {
        stopMonitoring()
        
        logger.notice("Starting idle detection monitoring")
        timer = Timer.scheduledTimer(withTimeInterval: pollingInterval, repeats: true) { [weak self] _ in
            self?.checkIdleState()
        }
        
        if let timer = timer {
            RunLoop.current.add(timer, forMode: .common)
        }
        
        // Initial check
        checkIdleState()
    }
    
    /// Stops monitoring for user idle state
    func stopMonitoring() {
        if timer != nil {
            logger.notice("Stopping idle detection monitoring")
            timer?.invalidate()
            timer = nil
        }
    }
    
    /// Manually resets the idle state
    func resetIdleState() {
        if isUserIdle {
            logger.notice("Manually resetting idle state to active")
            isUserIdle = false
            idleTimeSeconds = 0
            delegate?.userDidBecomeActive()
        }
    }
    
    // MARK: - Private Methods
    
    /// Checks the current idle state of the system
    private func checkIdleState() {
        // Get time since last event for different input types
        let keyboardIdleTime = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .keyDown)
        let mouseClickIdleTime = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .leftMouseDown)
        let mouseMovedIdleTime = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .mouseMoved)
        
        // Find the minimum idle time (most recent activity)
        idleTimeSeconds = min(keyboardIdleTime, min(mouseClickIdleTime, mouseMovedIdleTime))
        
        // Detect state change
        let wasIdle = isUserIdle
        let isIdle = idleTimeSeconds > idleThreshold
        
        if isIdle != wasIdle {
            // State has changed
            isUserIdle = isIdle
            
            if isIdle {
                logger.notice("User became idle after \(self.idleTimeSeconds) seconds of inactivity")
                delegate?.userDidBecomeIdle()
            } else {
                logger.notice("User became active after \(String(format: "%.1f", self.idleTimeSeconds)) seconds of idle time")
                delegate?.userDidBecomeActive()
            }
        } else if isUserIdle {
            // Log extended idle time at longer intervals to avoid log spam
            if Int(idleTimeSeconds) % 60 == 0 {
                logger.notice("User still idle for \(Int(self.idleTimeSeconds)) seconds")
            }
        }
    }
    
    // MARK: - Cleanup
    
    deinit {
        logger.notice("IdleDetector being deallocated, stopping monitoring")
        stopMonitoring()
    }
}

// MARK: - Notification Support

/// Notification names for idle state changes
extension Notification.Name {
    /// Posted when the user becomes idle
    static let userBecameIdle = Notification.Name("userBecameIdle")
    
    /// Posted when the user becomes active again
    static let userBecameActive = Notification.Name("userBecameActive")
}

/// Helper methods to post notifications
extension IdleDetector {
    /// Posts a notification when the user becomes idle
    private func postIdleNotification() {
        NotificationCenter.default.post(name: .userBecameIdle, object: self)
    }
    
    /// Posts a notification when the user becomes active
    private func postActiveNotification() {
        NotificationCenter.default.post(name: .userBecameActive, object: self)
    }
} 

import Foundation
import CoreGraphics
import Combine
import os.log

protocol IdleDetectorDelegate: AnyObject {
    func userDidBecomeIdle()
    func userDidBecomeActive()
}

class IdleDetector: ObservableObject {
    @Published private(set) var isUserIdle = false
    @Published private(set) var idleTimeSeconds: TimeInterval = 0
    
    weak var delegate: IdleDetectorDelegate?
    private var idleThreshold: TimeInterval
    private var timer: Timer?
    private let pollingInterval: TimeInterval
    private let logger = Logger(subsystem: "com.yourapp.breather", category: "idleDetection")
    
    init(idleThreshold: TimeInterval = 60, pollingInterval: TimeInterval = 5) {
        self.idleThreshold = idleThreshold
        self.pollingInterval = pollingInterval
        
        logger.notice("IdleDetector initialized with threshold: \(idleThreshold) seconds, polling interval: \(pollingInterval) seconds")
        startMonitoring()
    }
    
    func updateIdleThreshold(_ newThreshold: TimeInterval) {
        if idleThreshold != newThreshold {
            logger.notice("Updating idle threshold from \(self.idleThreshold) to \(newThreshold) seconds")
            idleThreshold = newThreshold
            
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
    
    func startMonitoring() {
        stopMonitoring()
        
        logger.notice("Starting idle detection monitoring")
        timer = Timer.scheduledTimer(withTimeInterval: pollingInterval, repeats: true) { [weak self] _ in
            self?.checkIdleState()
        }
        
        if let timer = timer {
            RunLoop.current.add(timer, forMode: .common)
        }
        
        checkIdleState()
    }
    
    func stopMonitoring() {
        if timer != nil {
            logger.notice("Stopping idle detection monitoring")
            timer?.invalidate()
            timer = nil
        }
    }
    
    func resetIdleState() {
        if isUserIdle {
            logger.notice("Manually resetting idle state to active")
            isUserIdle = false
            idleTimeSeconds = 0
            delegate?.userDidBecomeActive()
        }
    }
    
    private func checkIdleState() {
        let keyboardIdleTime = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .keyDown)
        let mouseClickIdleTime = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .leftMouseDown)
        let mouseMovedIdleTime = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .mouseMoved)
        
        idleTimeSeconds = min(keyboardIdleTime, min(mouseClickIdleTime, mouseMovedIdleTime))
        
        let wasIdle = isUserIdle
        let isIdle = idleTimeSeconds > idleThreshold
        
        if isIdle != wasIdle {
            isUserIdle = isIdle
            
            if isIdle {
                logger.notice("User became idle after \(self.idleTimeSeconds) seconds of inactivity")
                delegate?.userDidBecomeIdle()
            } else {
                logger.notice("User became active after \(String(format: "%.1f", self.idleTimeSeconds)) seconds of idle time")
                delegate?.userDidBecomeActive()
            }
        } else if isUserIdle {
            if Int(idleTimeSeconds) % 60 == 0 {
                logger.notice("User still idle for \(Int(self.idleTimeSeconds)) seconds")
            }
        }
    }
    
    deinit {
        logger.notice("IdleDetector being deallocated, stopping monitoring")
        stopMonitoring()
    }
}

extension Notification.Name {
    static let userBecameIdle = Notification.Name("userBecameIdle")
    static let userBecameActive = Notification.Name("userBecameActive")
}

extension IdleDetector {
    private func postIdleNotification() {
        NotificationCenter.default.post(name: .userBecameIdle, object: self)
    }
    
    private func postActiveNotification() {
        NotificationCenter.default.post(name: .userBecameActive, object: self)
    }
}

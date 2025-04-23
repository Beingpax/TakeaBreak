import Foundation
import Combine

class TimerManager: ObservableObject {
    // The timer that counts down to the next break
    private var timer: Timer?
    
    // Published property to track time until next break
    @Published var timeUntilBreak: TimeInterval = 0
    
    // Called when it's time to show the break reminder
    var onBreakTime: (() -> Void)?
    
    // Called when it's time to show the pre-break notification
    var onPreBreakNotification: (() -> Void)?
    
    // Current break interval (in seconds)
    private var breakInterval: TimeInterval = 20 * 60 // Default 20 minutes
    
    // Flag to track if timer is paused due to reminder
    private var isReminderShowing = false
    
    // Time for pre-break notification
    private var preBreakNotificationTime: TimeInterval = 30 // Default 30 seconds
    
    // Flag to track if pre-break notification is showing
    private var isPreBreakNotificationShowing = false
    
    init() {}
    
    // Update the break interval
    func setBreakInterval(_ interval: TimeInterval) {
        self.breakInterval = interval
        if timer != nil && !isReminderShowing && !isPreBreakNotificationShowing {
            // Restart timer with new interval if it's running and not showing notifications
            stopTimer()
            startTimer(resetTime: true)
        }
    }
    
    // Set pre-break notification time
    func setPreBreakNotificationTime(_ time: TimeInterval) {
        self.preBreakNotificationTime = time
    }
    
    // Start the timer
    func startTimer(resetTime: Bool = true) {
        stopTimer() // Ensure any existing timer is invalidated
        
        if isReminderShowing || isPreBreakNotificationShowing {
            return // Don't start timer if notifications are showing
        }
        
        // Only reset the time if specifically requested
        if resetTime {
            timeUntilBreak = breakInterval
        }
        
        // Create a new timer that fires every second
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.timeUntilBreak > 0 {
                self.timeUntilBreak -= 1
                
                // Check if it's time for pre-break notification
                if !self.isPreBreakNotificationShowing && self.timeUntilBreak <= self.preBreakNotificationTime && self.timeUntilBreak > 0 {
                    self.showPreBreakNotification()
                }
            } else {
                // Time for a break!
                self.pauseTimer() // Pause the timer before showing reminder
                self.onBreakTime?()
            }
        }
        
        // Make sure timer works even during scrolling
        RunLoop.current.add(timer!, forMode: .common)
    }
    
    // Stop the timer
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // Pause timer when showing reminder
    func pauseTimer() {
        isReminderShowing = true
        stopTimer()
    }
    
    // Resume timer after reminder is dismissed
    func resumeTimer() {
        isReminderShowing = false
        isPreBreakNotificationShowing = false
        timeUntilBreak = breakInterval // Reset the interval
        startTimer(resetTime: true)
    }
    
    // Show pre-break notification
    func showPreBreakNotification() {
        isPreBreakNotificationShowing = true
        onPreBreakNotification?()
    }
    
    // Reset timer for next break (called when skipping a break)
    func resetTimer() {
        isReminderShowing = false
        isPreBreakNotificationShowing = false
        timeUntilBreak = breakInterval // Reset to full interval
        startTimer(resetTime: false) // Don't reset time again
    }
    
    // Extend timer by specified amount (for postponing)
    func extendTimer(by seconds: TimeInterval) {
        isPreBreakNotificationShowing = false
        timeUntilBreak += seconds
        startTimer(resetTime: false) // Don't reset the time we just extended
    }
    
    // Calculate time remaining in human-readable format
    func formattedTimeRemaining() -> String {
        let minutes = Int(timeUntilBreak) / 60
        let seconds = Int(timeUntilBreak) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    deinit {
        stopTimer()
    }
} 
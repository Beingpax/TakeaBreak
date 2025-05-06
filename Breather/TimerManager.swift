import Foundation
import Combine

class TimerManager: ObservableObject, SystemEventsDelegate {
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
    
    // Reference to settings
    private let settings: BreatherSettings
    
    // Combine subscription cancellable
    private var settingsCancellable: AnyCancellable?
    
    // System events manager
    private var systemEventsManager: SystemEventsManager?
    
    // Initialize with settings
    init(settings: BreatherSettings) {
        self.settings = settings
        self.breakInterval = settings.breakIntervalMinutes * 60
        self.preBreakNotificationTime = settings.preBreakNotificationMinutes * 60
        self.timeUntilBreak = self.breakInterval
        
        // Initialize and set up system events manager
        self.systemEventsManager = SystemEventsManager()
        self.systemEventsManager?.delegate = self
        
        setupSettingsSubscription()
        // Initial check is handled by AppDelegate before calling startTimer the first time
    }
    
    // Update the break interval (now driven by settings subscription)
    private func updateBreakInterval(_ minutes: Double) {
        let newInterval = minutes * 60
        if newInterval != self.breakInterval {
            self.breakInterval = newInterval
            // Only restart if the main timer should be active
            if settings.isEnabled && timer != nil && !isReminderShowing && !isPreBreakNotificationShowing {
                stopTimer()
                startTimer(resetTime: true)
            }
        }
    }
    
    // Update pre-break notification time (now driven by settings subscription)
    private func updatePreBreakNotificationTime(_ minutes: Double) {
        self.preBreakNotificationTime = minutes * 60
        // No need to restart timer, this is checked during ticks
    }
    
    private func handleIsEnabledChange(newValue: Bool) {
        if newValue {
            // If enabling, and no reminder/notification is showing, start the timer.
            // Resetting time to full interval is appropriate here.
            if !isReminderShowing && !isPreBreakNotificationShowing {
                startTimer(resetTime: true)
            }
        } else {
            // If disabling, stop the timer regardless of other states.
            stopTimer()
        }
    }
    
    // Setup Combine subscription to settings changes
    private func setupSettingsSubscription() {
        settingsCancellable = settings.objectWillChange
            .receive(on: DispatchQueue.main) // Ensure updates are on main thread
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                // Store the old isEnabled state before settings object updates
                let oldIsEnabled = self.settings.isEnabled
                
                // Allow the settings object to update its properties internally first
                // Then, compare old and new to react to specific changes.
                // This requires a slight delay or a more robust Combine pipeline if settings updates are complex.
                // For simple @Published properties, the update should be fairly immediate.
                
                // React to isEnabled change
                if oldIsEnabled != self.settings.isEnabled {
                    self.handleIsEnabledChange(newValue: self.settings.isEnabled)
                }
                
                // React to other setting changes that might affect a running timer
                // We check isEnabled here too, as these should only apply if the timer is meant to be on.
                if self.settings.isEnabled {
                    // It's important to get the updated values from self.settings here
                    self.updateBreakInterval(self.settings.breakIntervalMinutes)
                    self.updatePreBreakNotificationTime(self.settings.preBreakNotificationMinutes)
                } else if !oldIsEnabled && self.settings.isEnabled { 
                    // This case handles if isEnabled was just turned on, ensure other settings are applied.
                     self.updateBreakInterval(self.settings.breakIntervalMinutes)
                    self.updatePreBreakNotificationTime(self.settings.preBreakNotificationMinutes)
                }
            }
    }
    
    // Start the timer
    func startTimer(resetTime: Bool = true) {
        // Guard: Only start if the main 'isEnabled' setting is true
        guard settings.isEnabled else {
            // If isEnabled is false, ensure timer is stopped
            stopTimer()
            return
        }
        
        stopTimer() // Invalidate any existing timer first
        
        if isReminderShowing || isPreBreakNotificationShowing {
            return // Don't start if a reminder or pre-break notification is active
        }
        
        if resetTime {
            timeUntilBreak = breakInterval
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.timeUntilBreak > 0 {
                self.timeUntilBreak -= 1
                
                if !self.isPreBreakNotificationShowing && self.timeUntilBreak <= self.preBreakNotificationTime && self.timeUntilBreak > 0 {
                    self.showPreBreakNotification()
                }
            } else {
                if !self.isPreBreakNotificationShowing {
                    self.pauseTimer() // This also calls stopTimer()
                    self.onBreakTime?()
                } else {
                    // Pre-break was showing, break initiated by user action probably.
                    self.isReminderShowing = true
                    self.stopTimer()
                }
            }
        }
        
        if let strongTimer = timer {
            RunLoop.current.add(strongTimer, forMode: .common)
        }
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
        isPreBreakNotificationShowing = false // Ensure pre-break is also cleared
        // Only resume if reminders are generally enabled
        if settings.isEnabled {
            startTimer(resetTime: true) // Reset to full interval
        }
    }
    
    // Show pre-break notification
    func showPreBreakNotification() {
        isPreBreakNotificationShowing = true
        stopTimer() // Stop main timer, pre-break UI takes over
        onPreBreakNotification?()
    }
    
    // Reset timer for next break (called when skipping a break)
    func resetTimer() { // Typically called by skip, or system wake/screen saver stop
        isReminderShowing = false
        isPreBreakNotificationShowing = false
        // Only reset and start if reminders are generally enabled
        if settings.isEnabled {
            // Using startTimer(resetTime: true) is more robust here
            // as it correctly resets timeUntilBreak to breakInterval
            startTimer(resetTime: true) 
        }
    }
    
    // Extend timer by specified amount (for postponing)
    func extendTimer(by seconds: TimeInterval) {
        isPreBreakNotificationShowing = false // Clear this flag
        // Only extend if reminders are generally enabled
        if settings.isEnabled {
            timeUntilBreak += seconds
            startTimer(resetTime: false) // Don't reset the time we just extended
        }
    }
    
    // Calculate time remaining in human-readable format
    func formattedTimeRemaining() -> String {
        let minutes = Int(timeUntilBreak) / 60
        let seconds = Int(timeUntilBreak) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // Calculate time remaining in minutes for menu bar
    func formattedTimeRemainingInMinutes() -> String {
        let minutes = Int(ceil(timeUntilBreak / 60.0))
        return String(format: "%dm", minutes)
    }
    
    // SystemEventsDelegate methods
    func systemWillSleep() { 
        isReminderShowing = false
        isPreBreakNotificationShowing = false
        stopTimer() 
    }
    
    func systemDidWake() { 
        // Only reset if settings.isEnabled is true
        if settings.isEnabled {
            resetTimer() 
        }
    }
    
    func screenSaverDidStart() { 
        isReminderShowing = false
        isPreBreakNotificationShowing = false
        stopTimer() 
    }
    
    func screenSaverDidStop() { 
        if settings.isEnabled {
            resetTimer() 
        }
    }
    
    func displayDidSleep() { 
        isReminderShowing = false
        isPreBreakNotificationShowing = false
        stopTimer() 
    }
    
    func displayDidWake() { 
        if settings.isEnabled {
            resetTimer() 
        }
    }
    
    deinit {
        stopTimer()
        settingsCancellable?.cancel()
    }
} 
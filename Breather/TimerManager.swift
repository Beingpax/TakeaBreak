import Foundation
import Combine
import os.log

class TimerManager: ObservableObject, SystemEventsDelegate {
    // The timer that counts down to the next break
    private var timer: Timer?
    
    // Published property to track time until next break
    @Published var timeUntilBreak: TimeInterval = 0
    
    // Called when it's time to show the break reminder
    var onBreakTime: (() -> Void)?
    
    // Called when it's time to show the pre-break notification
    var onPreBreakNotification: (() -> Void)?
    
    // To tell WindowManager to hide notifications
    var onHideNotifications: (() -> Void)?
    
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
    
    // ADDED: Timer for break countdown across all screens
    private var breakCountdownTimer: Timer?
    
    // ADDED: Published property to track remaining break time (shared across all screens)
    @Published var remainingBreakTime: Int = 0
    
    // Logger for debugging screen saver issues
    private let logger = Logger(subsystem: "com.yourapp.breather", category: "timerbreak")
    
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
        
        logger.notice("TimerManager initialized with break interval: \(self.breakInterval) seconds")
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
        logger.notice("Handling isEnabled change to: \(newValue)")
        
        if newValue {
            // When enabling, first ensure all states are clean
            onHideNotifications?()
            isReminderShowing = false
            isPreBreakNotificationShowing = false
            stopBreakCountdown()
            stopTimer()
            
            // Then start fresh timer
            startTimer(resetTime: true)
            logger.notice("Enabled: Started fresh timer")
        } else {
            // When disabling, clean up all states and stop everything
            onHideNotifications?()
            isReminderShowing = false
            isPreBreakNotificationShowing = false
            stopBreakCountdown()
            stopTimer()
            logger.notice("Disabled: Stopped all timers and cleaned up states")
        }
    }
    
    // Setup Combine subscription to settings changes
    private func setupSettingsSubscription() {
        settingsCancellable = settings.objectWillChange
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    
                    if self.breakInterval != self.settings.breakIntervalMinutes * 60 {
                        self.updateBreakInterval(self.settings.breakIntervalMinutes)
                    }
                    
                    if self.preBreakNotificationTime != self.settings.preBreakNotificationMinutes * 60 {
                        self.updatePreBreakNotificationTime(self.settings.preBreakNotificationMinutes)
                    }
                    
                    // Directly handle isEnabled changes by comparing with settings
                    self.handleIsEnabledChange(newValue: self.settings.isEnabled)
                }
            }
    }
    
    var isEnabled: Bool {
        // Reflects if the timer logic should be active, not just the setting.
        // For example, if a reminder is showing, isEnabled might be true, but the main timer is paused.
        return settings.isEnabled
    }
    
    // Check to see whether the display is asleep, screensaver active, etc.
    private func shouldTimerRun() -> Bool {
        // Just check the settings.isEnabled flag as a simple check
        return settings.isEnabled && !isReminderShowing && !isPreBreakNotificationShowing
    }
    
    // Start the timer
    func startTimer(resetTime: Bool = true) {
        // Guard: Only start if the main 'isEnabled' setting is true
        guard settings.isEnabled else {
            logger.notice("Timer not started - isEnabled is false")
            stopTimer()
            return
        }
        
        stopTimer() // Invalidate any existing timer first
        
        if isReminderShowing || isPreBreakNotificationShowing {
            logger.notice("Timer not started - reminder or pre-break notification is active")
            return // Don't start if a reminder or pre-break notification is active
        }
        
        if resetTime {
            timeUntilBreak = breakInterval
            logger.notice("Timer reset to full interval: \(self.breakInterval) seconds")
        }
        
        logger.notice("Starting timer with \(self.timeUntilBreak) seconds remaining")
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.timeUntilBreak > 0 {
                self.timeUntilBreak -= 1
                
                if !self.isPreBreakNotificationShowing && self.timeUntilBreak <= self.preBreakNotificationTime && self.timeUntilBreak > 0 && self.preBreakNotificationTime > 0 {
                    self.showPreBreakNotification()
                }
            } else {
                 // timeUntilBreak is 0 or less
                if !self.isPreBreakNotificationShowing { // Ensure pre-break isn't already showing (e.g. if preBreakNotificationTime is 0)
                    self.pauseTimer() // This also calls stopTimer()
                    self.onBreakTime?()
                } else {
                    // This case should ideally not be hit if preBreakNotificationTime > 0,
                    // as showPreBreakNotification would have stopped the main timer.
                    // If preBreakNotificationTime is 0, this might be hit directly.
                    logger.notice("Main timer reached zero while pre-break was (notionally) active. Transitioning to break.")
                    self.isReminderShowing = true // Transition to break state
                    self.isPreBreakNotificationShowing = false
                    self.stopTimer()
                    self.onBreakTime?() // Trigger break time
                }
            }
        }
        
        if let strongTimer = timer {
            RunLoop.current.add(strongTimer, forMode: .common)
        }
    }
    
    // Stop the timer
    func stopTimer() {
        if timer != nil {
            logger.notice("Stopping main timer")
        timer?.invalidate()
        timer = nil
        }
    }
    
    // Pause timer when showing reminder (called when main timer reaches zero)
    func pauseTimer() {
        logger.notice("PauseTimer called (main timer reached zero, break starting)")
        isReminderShowing = true
        isPreBreakNotificationShowing = false // Pre-break is done
        stopTimer() // Stop the main work timer
    }
    
    // Resume timer after reminder is dismissed by user action (skip, or break ends)
    func resumeTimer() {
        logger.notice("ResumeTimer called (break ended or skipped by user)")
        isReminderShowing = false
        isPreBreakNotificationShowing = false // Ensure pre-break is also cleared
        if settings.isEnabled {
            startTimer(resetTime: true) // Reset to full interval for next work period
        }
    }
    
    // Show pre-break notification
    func showPreBreakNotification() {
        logger.notice("Showing pre-break notification")
        isPreBreakNotificationShowing = true
        // isReminderShowing should be false here
        stopTimer() // Stop main timer, pre-break UI takes over
        onPreBreakNotification?()
    }
    
    // Reset timer for next break (typically called by skip, or system wake/screen saver stop)
    func resetTimer() {
        logger.notice("ResetTimer called (e.g. skip, system wake/unlock)")
        isReminderShowing = false
        isPreBreakNotificationShowing = false
        stopBreakCountdown() // Ensure any break countdown is also stopped

        if settings.isEnabled {
            startTimer(resetTime: true) 
        } else {
            stopTimer() // Ensure main timer is also stopped if disabled
        }
    }
    
    // Extend timer by specified amount (for postponing pre-break)
    func extendTimer(by seconds: TimeInterval) {
        logger.notice("Extending timer by \(seconds) seconds")
        isPreBreakNotificationShowing = false // Clear this flag as pre-break is dismissed
        // isReminderShowing should be false
        if settings.isEnabled {
            timeUntilBreak += seconds
            startTimer(resetTime: false) // Don't reset the time we just extended
        }
    }
    
    // ADDED: Start break countdown timer (shared across all screens)
    func startBreakCountdown(duration: TimeInterval) {
        logger.notice("Starting break countdown: \(duration)s. Main timer should be stopped.")
        isReminderShowing = true // This is the break state
        isPreBreakNotificationShowing = false
        stopTimer() // Ensure main work timer is stopped
        stopBreakCountdown() // Stop any existing break countdown
        
        remainingBreakTime = Int(ceil(duration))
        
        breakCountdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.remainingBreakTime > 0 {
                self.remainingBreakTime -= 1
            } else {
                self.stopBreakCountdown() // Countdown finished
                // Notification that break time is over, this will trigger hideReminderWindow -> resumeTimer
                // This is typically handled by the ReminderView observing remainingBreakTime and calling its dismissAction
                // which in turn calls timerManager.resumeTimer() via WindowManager.
                // If not, we might need an explicit callback here. For now, assume UI handles it.
                logger.notice("Break countdown finished. Expecting UI to trigger resume.")
            }
        }
        
        if let countdownTimer = breakCountdownTimer {
            RunLoop.current.add(countdownTimer, forMode: .common)
        }
    }
    
    // ADDED: Stop break countdown timer
    func stopBreakCountdown() {
        if breakCountdownTimer != nil {
            logger.notice("Stopping break countdown timer. Remaining: \(self.remainingBreakTime)s")
        breakCountdownTimer?.invalidate()
        breakCountdownTimer = nil
        }
    }
    
    // ADDED: Adjust break time for all screens
    func adjustBreakTime(by seconds: Int) {
        let newTime = max(0, remainingBreakTime + seconds)
        logger.notice("Adjusting break time by \(seconds)s. New remaining: \(newTime)s")
        remainingBreakTime = newTime
        // If timer was running and time is added, it continues. If it was 0 and time is added, it needs restart.
        // This is complex. For now, assume this is called while breakCountdownTimer is active.
        // If remainingBreakTime becomes >0 from 0, the timer needs to be re-established if not running.
        // This method is typically called by UI buttons, so the breakCountdownTimer should be active.
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
    
    // ADDED: Format break countdown time
    func formattedBreakCountdown() -> String {
        let minutes = remainingBreakTime / 60
        let seconds = remainingBreakTime % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // --- SystemEventsDelegate methods ---
    private func handleSystemEventStart() {
        logger.notice("System event started (sleep/screensaver/lock). Hiding notifications and stopping timers.")
        onHideNotifications?() // Tell WindowManager to hide UIs without triggering resume
        isReminderShowing = false
        isPreBreakNotificationShowing = false
        stopTimer() 
        stopBreakCountdown()
    }
    
    private func handleSystemEventEnd() {
        logger.notice("System event ended (wake/screensaver-stop/unlock).")
        if settings.isEnabled {
            logger.notice("Settings are enabled, resetting timer.")
            resetTimer() 
        } else {
            logger.notice("Settings are disabled, ensuring timers remain stopped.")
            // Ensure all timers are indeed stopped if settings got disabled during the event.
            stopTimer()
            stopBreakCountdown()
        }
    }

    func systemWillSleep() { 
        logger.notice("Delegate: systemWillSleep")
        handleSystemEventStart()
    }
    
    func systemDidWake() { 
        logger.notice("Delegate: systemDidWake")
        handleSystemEventEnd()
    }
    
    func screenSaverDidStart() { 
        logger.notice("Delegate: screenSaverDidStart")
        handleSystemEventStart()
    }
    
    func screenSaverDidStop() { 
        logger.notice("Delegate: screenSaverDidStop")
        handleSystemEventEnd()
    }
    
    func displayDidSleep() { 
        logger.notice("Delegate: displayDidSleep (screen locked)")
        handleSystemEventStart()
    }
    
    func displayDidWake() { 
        logger.notice("Delegate: displayDidWake (screen unlocked)")
        handleSystemEventEnd()
    }
    
    deinit {
        logger.notice("TimerManager deinit")
        stopTimer()
        stopBreakCountdown()
        settingsCancellable?.cancel()
    }
} 

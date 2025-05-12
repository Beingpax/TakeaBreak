import Foundation
import Combine
import os.log

class TimerManager: ObservableObject, SystemEventsDelegate, IdleDetectorDelegate {
    // MARK: - Published Properties
    @Published private(set) var timeUntilBreak: TimeInterval = 0
    @Published private(set) var remainingBreakTime: Int = 0
    @Published private(set) var isUserIdle: Bool = false
    
    // MARK: - Callbacks
    var onBreakTime: (() -> Void)?
    var onPreBreakNotification: (() -> Void)?
    var onHideNotifications: (() -> Void)?
    
    // MARK: - Private Properties
    private var timer: Timer?
    private var breakCountdownTimer: Timer?
    private let settings: TakeABreakSettings
    private var settingsCancellable: AnyCancellable?
    private var systemEventsManager: SystemEventsManager?
    private var idleDetector: IdleDetector?
    private let logger = Logger(subsystem: "com.yourapp.breather", category: "timerbreak")
    
    // Timer intervals
    private var breakInterval: TimeInterval
    private var preBreakNotificationTime: TimeInterval
    
    // State tracking
    private var isReminderShowing = false
    private var isPreBreakNotificationShowing = false
    private var systemIsCurrentlyInactive = false
    private var pendingWorkTimerStartAfterWakeUp = false
    private var timerWasActiveBeforeIdle = false
    private var timeAtIdle: TimeInterval = 0
    
    // MARK: - Public Properties
    var isBreakActive: Bool { isReminderShowing }
    var isEnabled: Bool { settings.isEnabled }
    
    // MARK: - Initialization
    init(settings: TakeABreakSettings) {
        self.settings = settings
        self.breakInterval = settings.breakIntervalMinutes * 60
        self.preBreakNotificationTime = settings.preBreakNotificationMinutes * 60
        self.timeUntilBreak = self.breakInterval
        
        self.systemEventsManager = SystemEventsManager()
        self.systemEventsManager?.delegate = self
        
        setupSettingsSubscription()
        setupIdleDetection()
    }
    
    // Setup the idle detector
    private func setupIdleDetection() {
        // Create idle detector with threshold from settings
        idleDetector = IdleDetector(
            idleThreshold: settings.idleThresholdSeconds,
            pollingInterval: 5
        )
        idleDetector?.delegate = self
        
        // Enable or disable based on settings
        if !settings.idleDetectionEnabled {
            idleDetector?.stopMonitoring()
            logger.notice("Idle detection disabled by user settings")
        } else {
            logger.notice("Idle detection initialized with \(self.settings.idleThresholdSeconds) second threshold")
        }
        
    }
    
    private func updateIdleDetectionFromSettings() {
        // Always update detector with current settings
        if let detector = idleDetector {
            // Update threshold regardless of enabled state
            detector.updateIdleThreshold(settings.idleThresholdSeconds)
            
            if settings.idleDetectionEnabled {
                detector.startMonitoring()
                logger.notice("Idle detection enabled with \(self.settings.idleThresholdSeconds) second threshold")
            } else {
                detector.stopMonitoring()
                logger.notice("Idle detection disabled")
            }
        }
    }
    
    // MARK: - Timer Control
    func startTimer(resetTime: Bool = true) {
        guard settings.isEnabled else {
            stopTimer()
            return
        }
        
        stopTimer()
        
        if isReminderShowing || isPreBreakNotificationShowing { return }
        
        // Always ensure we're using the current settings value
        breakInterval = settings.breakIntervalMinutes * 60
        preBreakNotificationTime = settings.preBreakNotificationMinutes * 60
        
        if resetTime {
            timeUntilBreak = breakInterval
            logger.notice("Timer started with duration: \(Int(self.breakInterval)) seconds")
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.timeUntilBreak > 0 {
                self.timeUntilBreak -= 1
                
                // Check for pre-break notification
                if !self.isPreBreakNotificationShowing && 
                   self.timeUntilBreak <= self.preBreakNotificationTime && 
                   self.timeUntilBreak > 0 && 
                   self.preBreakNotificationTime > 0 {
                    self.showPreBreakNotification()
                }
            } else {
                self.handleTimerExpiration()
            }
        }
        
        if let strongTimer = timer {
            RunLoop.current.add(strongTimer, forMode: .common)
        }
    }
    
    private func handleTimerExpiration() {
        if !isPreBreakNotificationShowing {
            isReminderShowing = true
            isPreBreakNotificationShowing = false
            stopTimer()
            onBreakTime?()
        } else {
            isReminderShowing = true
            isPreBreakNotificationShowing = false
            stopTimer()
            onBreakTime?()
        }
    }
    
    func startBreakCountdown(duration: TimeInterval) {
        isReminderShowing = true
        isPreBreakNotificationShowing = false
        stopTimer()
        stopBreakCountdown()
        
        remainingBreakTime = Int(ceil(duration))
        
        breakCountdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.remainingBreakTime = max(0, self.remainingBreakTime - 1)
            
            if self.remainingBreakTime <= 0 {
                self.stopBreakCountdown()
            }
        }
        
        if let countdownTimer = breakCountdownTimer {
            RunLoop.current.add(countdownTimer, forMode: .common)
        }
    }
    
    // MARK: - Timer State Management
    func resumeTimer() {
        resetBreakRelatedStates()
        if settings.isEnabled {
            if systemIsCurrentlyInactive {
                pendingWorkTimerStartAfterWakeUp = true
            } else {
                startTimer(resetTime: true)
            }
        }
    }
    
    func resetTimer() {
        resetBreakRelatedStates()
        
        // Ensure we're using updated values from settings
        breakInterval = settings.breakIntervalMinutes * 60
        preBreakNotificationTime = settings.preBreakNotificationMinutes * 60
        
        if settings.isEnabled {
            startTimer(resetTime: true)
        } else {
            stopTimer()
        }
    }
    
    func extendTimer(by seconds: TimeInterval) {
        isPreBreakNotificationShowing = false
        if settings.isEnabled {
            timeUntilBreak += seconds
            startTimer(resetTime: false)
        }
    }
    
    // MARK: - Timer Cleanup
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func stopBreakCountdown() {
        breakCountdownTimer?.invalidate()
        breakCountdownTimer = nil
    }
    
    private func resetBreakRelatedStates() {
        isReminderShowing = false
        isPreBreakNotificationShowing = false
        stopBreakCountdown()
    }
    
    // MARK: - Break Management
    func showPreBreakNotification() {
        isPreBreakNotificationShowing = true
        stopTimer()
        onPreBreakNotification?()
    }
    
    func adjustBreakTime(by seconds: Int) {
        remainingBreakTime = max(0, remainingBreakTime + seconds)
    }
    
    // MARK: - Time Formatting
    func formattedTimeRemaining() -> String {
        formatTime(Int(timeUntilBreak))
    }
    
    func formattedTimeRemainingInMinutes() -> String {
        String(format: "%dm", Int(ceil(timeUntilBreak / 60.0)))
    }
    
    func formattedBreakCountdown() -> String {
        formatTime(remainingBreakTime)
    }
    
    private func formatTime(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Settings Management
    private func setupSettingsSubscription() {
        // Cancel any existing subscription
        settingsCancellable?.cancel()
        
        // Create a new subscription to settings changes
        settingsCancellable = settings.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                // Apply all settings changes immediately
                self.handleSettingsChange()
                self.updateIdleDetectionFromSettings()
                
                self.logger.notice("Settings changes were applied")
            }
        
        // Apply current settings immediately during setup
        handleSettingsChange()
        updateIdleDetectionFromSettings()
        
        logger.notice("Settings subscription initialized")
    }
    
    private func handleSettingsChange() {
        logger.notice("handleSettingsChange called.") // Log entry
        
        // Update internal values from settings
        breakInterval = settings.breakIntervalMinutes * 60
        preBreakNotificationTime = settings.preBreakNotificationMinutes * 60
        
        logger.notice("Settings updated - Work duration: \(Int(self.breakInterval)) seconds, Pre-break notice: \(Int(self.preBreakNotificationTime)) seconds")
        logger.notice("Current state: isReminderShowing=\(self.isReminderShowing), isPreBreakNotificationShowing=\(self.isPreBreakNotificationShowing)") // Log state

        // If breaks are disabled, stop everything
        if !settings.isEnabled {
            logger.notice("Breaks are disabled, stopping timer.") // Log disable path
            onHideNotifications?()
            resetBreakRelatedStates()
            stopTimer()
            return 
        }
        
        // If no active break or notification, restart timer with new values
        if !isReminderShowing && !isPreBreakNotificationShowing { 
            logger.notice("No active break/notification, attempting to restart timer immediately.") // Log restart path
            stopTimer()
            // Always reset time when settings change
            timeUntilBreak = breakInterval 
            startTimer(resetTime: true) // This will use the updated breakInterval
            logger.notice("Timer restart initiated with new settings.") // Log restart confirmation
        } else {
            logger.notice("Active break or notification present, timer will update after completion.") // Log deferred path
        }
    }
    
    // MARK: - System Events Handling
    private func handleSystemEventStart() {
        systemIsCurrentlyInactive = true
        if !isReminderShowing {
            onHideNotifications?()
            isPreBreakNotificationShowing = false
            stopTimer()
            stopBreakCountdown()
        }
    }
    
    private func handleSystemEventEnd() {
        systemIsCurrentlyInactive = false
        if !isReminderShowing {
            if settings.isEnabled {
                if pendingWorkTimerStartAfterWakeUp {
                    pendingWorkTimerStartAfterWakeUp = false
                    startTimer(resetTime: true)
                } else {
                    resetTimer()
                }
            } else {
                stopTimer()
                stopBreakCountdown()
            }
        }
    }
    
    // MARK: - SystemEventsDelegate Implementation
    func systemWillSleep() { handleSystemEventStart() }
    func systemDidWake() { handleSystemEventEnd() }
    func displayDidSleep() { handleSystemEventStart() }
    func displayDidWake() { handleSystemEventEnd() }
    
    // MARK: - IdleDetectorDelegate Implementation
    func userDidBecomeIdle() {
        logger.notice("User became idle, pausing timer")
        isUserIdle = true
        
        // Save current timer state
        timerWasActiveBeforeIdle = timer != nil && settings.isEnabled && !isReminderShowing && !isPreBreakNotificationShowing
        timeAtIdle = timeUntilBreak
        
        // Pause any active timer while user is idle
        if !isReminderShowing {
            onHideNotifications?()
            isPreBreakNotificationShowing = false
            stopTimer()
            stopBreakCountdown()
        }
    }
    
    func userDidBecomeActive() {
        logger.notice("User became active, resetting break timer")
        isUserIdle = false
        
        // Update intervals from current settings first
        breakInterval = settings.breakIntervalMinutes * 60
        preBreakNotificationTime = settings.preBreakNotificationMinutes * 60
        
        // Reset timer instead of resuming from previous state
        if timerWasActiveBeforeIdle && !isReminderShowing {
            if settings.isEnabled {
                if systemIsCurrentlyInactive {
                    pendingWorkTimerStartAfterWakeUp = true
                } else {
                    // Reset timer to full interval
                    timeUntilBreak = breakInterval
                    startTimer(resetTime: true)
                    logger.notice("Reset timer to full interval: \(Int(self.breakInterval)) seconds")
                }
            }
        }
    }
    
    // MARK: - Cleanup
    deinit {
        stopTimer()
        stopBreakCountdown()
        settingsCancellable?.cancel()
        idleDetector?.stopMonitoring()
    }
}

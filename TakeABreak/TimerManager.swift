import Foundation
import Combine
import os.log

class TimerManager: ObservableObject, SystemEventsDelegate, IdleDetectorDelegate {
    @Published private(set) var timeUntilBreak: TimeInterval = 0
    @Published private(set) var remainingBreakTime: Int = 0
    @Published private(set) var isUserIdle: Bool = false
    
    var onBreakTime: (() -> Void)?
    var onPreBreakNotification: (() -> Void)?
    var onHideNotifications: (() -> Void)?
    
    private var timer: Timer?
    private var breakCountdownTimer: Timer?
    private let settings: TakeABreakSettings
    private var settingsCancellable: AnyCancellable?
    private var systemEventsManager: SystemEventsManager?
    private var idleDetector: IdleDetector?
    private let logger = Logger(subsystem: "com.yourapp.breather", category: "timerbreak")
    
    private var breakInterval: TimeInterval
    private var preBreakNotificationTime: TimeInterval
    
    private var isReminderShowing = false
    private var isPreBreakNotificationShowing = false
    private var systemIsCurrentlyInactive = false
    private var pendingWorkTimerStartAfterWakeUp = false
    private var timerWasActiveBeforeIdle = false
    private var timeAtIdle: TimeInterval = 0
    
    var isBreakActive: Bool { isReminderShowing }
    var isEnabled: Bool { settings.isEnabled }
    
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
    
    private func setupIdleDetection() {
        idleDetector = IdleDetector(
            idleThreshold: settings.idleThresholdSeconds,
            pollingInterval: 5
        )
        idleDetector?.delegate = self
        
        if !settings.idleDetectionEnabled {
            idleDetector?.stopMonitoring()
            logger.notice("Idle detection disabled by user settings")
        } else {
            logger.notice("Idle detection initialized with \(self.settings.idleThresholdSeconds) second threshold")
        }
    }
    
    private func updateIdleDetectionFromSettings() {
        if let detector = idleDetector {
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
    
    func startTimer(resetTime: Bool = true) {
        guard settings.isEnabled else {
            stopTimer()
            return
        }
        
        stopTimer()
        
        if isReminderShowing || isPreBreakNotificationShowing { return }
        
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
    
    func showPreBreakNotification() {
        isPreBreakNotificationShowing = true
        stopTimer()
        onPreBreakNotification?()
    }
    
    func adjustBreakTime(by seconds: Int) {
        remainingBreakTime = max(0, remainingBreakTime + seconds)
    }
    
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
    
    private func setupSettingsSubscription() {
        settingsCancellable?.cancel()
        
        settingsCancellable = settings.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                self.handleSettingsChange()
                self.updateIdleDetectionFromSettings()
                
                self.logger.notice("Settings changes were applied")
            }
        
        handleSettingsChange()
        updateIdleDetectionFromSettings()
        
        logger.notice("Settings subscription initialized")
    }
    
    private func handleSettingsChange() {
        logger.notice("handleSettingsChange called.")
        
        breakInterval = settings.breakIntervalMinutes * 60
        preBreakNotificationTime = settings.preBreakNotificationMinutes * 60
        
        logger.notice("Settings updated - Work duration: \(Int(self.breakInterval)) seconds, Pre-break notice: \(Int(self.preBreakNotificationTime)) seconds")
        logger.notice("Current state: isReminderShowing=\(self.isReminderShowing), isPreBreakNotificationShowing=\(self.isPreBreakNotificationShowing)")

        if !settings.isEnabled {
            logger.notice("Breaks are disabled, stopping timer.")
            onHideNotifications?()
            resetBreakRelatedStates()
            stopTimer()
            return 
        }
        
        if !isReminderShowing && !isPreBreakNotificationShowing { 
            logger.notice("No active break/notification, attempting to restart timer immediately.")
            stopTimer()
            timeUntilBreak = breakInterval 
            startTimer(resetTime: true)
            logger.notice("Timer restart initiated with new settings.")
        } else {
            logger.notice("Active break or notification present, timer will update after completion.")
        }
    }
    
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
    
    func systemWillSleep() { handleSystemEventStart() }
    func systemDidWake() { handleSystemEventEnd() }
    func displayDidSleep() { handleSystemEventStart() }
    func displayDidWake() { handleSystemEventEnd() }
    
    func userDidBecomeIdle() {
        logger.notice("User became idle, pausing timer")
        isUserIdle = true
        
        timerWasActiveBeforeIdle = timer != nil && settings.isEnabled && !isReminderShowing && !isPreBreakNotificationShowing
        timeAtIdle = timeUntilBreak
        
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
        
        breakInterval = settings.breakIntervalMinutes * 60
        preBreakNotificationTime = settings.preBreakNotificationMinutes * 60
        
        if timerWasActiveBeforeIdle && !isReminderShowing {
            if settings.isEnabled {
                if systemIsCurrentlyInactive {
                    pendingWorkTimerStartAfterWakeUp = true
                } else {
                    timeUntilBreak = breakInterval
                    startTimer(resetTime: true)
                    logger.notice("Reset timer to full interval: \(Int(self.breakInterval)) seconds")
                }
            }
        }
    }
    
    deinit {
        stopTimer()
        stopBreakCountdown()
        settingsCancellable?.cancel()
        idleDetector?.stopMonitoring()
    }
}

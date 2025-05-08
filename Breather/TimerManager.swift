import Foundation
import Combine
import os.log

class TimerManager: ObservableObject, SystemEventsDelegate {
    // MARK: - Published Properties
    @Published private(set) var timeUntilBreak: TimeInterval = 0
    @Published private(set) var remainingBreakTime: Int = 0
    
    // MARK: - Callbacks
    var onBreakTime: (() -> Void)?
    var onPreBreakNotification: (() -> Void)?
    var onHideNotifications: (() -> Void)?
    
    // MARK: - Private Properties
    private var timer: Timer?
    private var breakCountdownTimer: Timer?
    private let settings: BreatherSettings
    private var settingsCancellable: AnyCancellable?
    private var systemEventsManager: SystemEventsManager?
    private let logger = Logger(subsystem: "com.yourapp.breather", category: "timerbreak")
    
    // Timer intervals
    private var breakInterval: TimeInterval
    private var preBreakNotificationTime: TimeInterval
    
    // State tracking
    private var isReminderShowing = false
    private var isPreBreakNotificationShowing = false
    private var systemIsCurrentlyInactive = false
    private var pendingWorkTimerStartAfterWakeUp = false
    
    // MARK: - Public Properties
    var isBreakActive: Bool { isReminderShowing }
    var isEnabled: Bool { settings.isEnabled }
    
    // MARK: - Initialization
    init(settings: BreatherSettings) {
        self.settings = settings
        self.breakInterval = settings.breakIntervalMinutes * 60
        self.preBreakNotificationTime = settings.preBreakNotificationMinutes * 60
        self.timeUntilBreak = self.breakInterval
        
        self.systemEventsManager = SystemEventsManager()
        self.systemEventsManager?.delegate = self
        
        setupSettingsSubscription()
    }
    
    // MARK: - Timer Control
    func startTimer(resetTime: Bool = true) {
        guard settings.isEnabled else {
            stopTimer()
            return
        }
        
        stopTimer()
        
        if isReminderShowing || isPreBreakNotificationShowing { return }
        
        if resetTime {
            timeUntilBreak = breakInterval
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
        settingsCancellable = settings.objectWillChange
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.handleSettingsChange()
                }
            }
    }
    
    private func handleSettingsChange() {
        let newBreakInterval = settings.breakIntervalMinutes * 60
        let newPreBreakTime = settings.preBreakNotificationMinutes * 60
        
        if breakInterval != newBreakInterval {
            breakInterval = newBreakInterval
            if shouldRestartTimer {
                stopTimer()
                startTimer(resetTime: true)
            }
        }
        
        if preBreakNotificationTime != newPreBreakTime {
            preBreakNotificationTime = newPreBreakTime
        }
        
        if !settings.isEnabled {
            onHideNotifications?()
            resetBreakRelatedStates()
            stopTimer()
        } else {
            // When breaks are enabled, always start the timer if there's no active break
            if !isReminderShowing && !isPreBreakNotificationShowing {
                startTimer(resetTime: true)
            }
        }
    }
    
    private var shouldRestartTimer: Bool {
        settings.isEnabled && timer != nil && !isReminderShowing && !isPreBreakNotificationShowing
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
    func screenSaverDidStart() { handleSystemEventStart() }
    func screenSaverDidStop() { handleSystemEventEnd() }
    func displayDidSleep() { handleSystemEventStart() }
    func displayDidWake() { handleSystemEventEnd() }
    
    // MARK: - Cleanup
    deinit {
        stopTimer()
        stopBreakCountdown()
        settingsCancellable?.cancel()
    }
}

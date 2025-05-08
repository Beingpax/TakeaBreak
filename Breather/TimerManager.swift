import Foundation
import Combine
import os.log

class TimerManager: ObservableObject, SystemEventsDelegate {
    private var timer: Timer?
    
    @Published var timeUntilBreak: TimeInterval = 0
    
    var onBreakTime: (() -> Void)?
    
    var onPreBreakNotification: (() -> Void)?
    
    var onHideNotifications: (() -> Void)?
    
    var isBreakActive: Bool {
        return isReminderShowing
    }
    
    private var breakInterval: TimeInterval = 20 * 60
    
    private var isReminderShowing = false
    
    private var preBreakNotificationTime: TimeInterval = 30
    
    private var isPreBreakNotificationShowing = false
    
    private let settings: BreatherSettings
    
    private var settingsCancellable: AnyCancellable?
    
    private var systemEventsManager: SystemEventsManager?
    
    private var breakCountdownTimer: Timer?
    
    @Published var remainingBreakTime: Int = 0
    
    private let logger = Logger(subsystem: "com.yourapp.breather", category: "timerbreak")
    
    private func resetBreakRelatedStatesAndTimers() {
        isReminderShowing = false
        isPreBreakNotificationShowing = false
        stopBreakCountdown()
    }
    
    init(settings: BreatherSettings) {
        self.settings = settings
        self.breakInterval = settings.breakIntervalMinutes * 60
        self.preBreakNotificationTime = settings.preBreakNotificationMinutes * 60
        self.timeUntilBreak = self.breakInterval
        
        self.systemEventsManager = SystemEventsManager()
        self.systemEventsManager?.delegate = self
        
        setupSettingsSubscription()
    }
    
    private func updateBreakInterval(_ minutes: Double) {
        let newInterval = minutes * 60
        if newInterval != self.breakInterval {
            self.breakInterval = newInterval
            if settings.isEnabled && timer != nil && !isReminderShowing && !isPreBreakNotificationShowing {
                stopTimer()
                startTimer(resetTime: true)
            }
        }
    }
    
    private func updatePreBreakNotificationTime(_ minutes: Double) {
        self.preBreakNotificationTime = minutes * 60
    }
    
    private func handleIsEnabledChange(newValue: Bool) {
        onHideNotifications?()
        resetBreakRelatedStatesAndTimers()
        stopTimer()

        if newValue {
            startTimer(resetTime: true)
        }
    }
    
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
                    
                    self.handleIsEnabledChange(newValue: self.settings.isEnabled)
                }
            }
    }
    
    var isEnabled: Bool {
        return settings.isEnabled
    }
    
    private func shouldTimerRun() -> Bool {
        return settings.isEnabled && !isReminderShowing && !isPreBreakNotificationShowing
    }
    
    func startTimer(resetTime: Bool = true) {
        guard settings.isEnabled else {
            stopTimer()
            return
        }
        
        stopTimer()
        
        if isReminderShowing || isPreBreakNotificationShowing {
            return
        }
        
        if resetTime {
            timeUntilBreak = breakInterval
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.timeUntilBreak > 0 {
                self.timeUntilBreak -= 1
                
                if !self.isPreBreakNotificationShowing && self.timeUntilBreak <= self.preBreakNotificationTime && self.timeUntilBreak > 0 && self.preBreakNotificationTime > 0 {
                    self.showPreBreakNotification()
                }
            } else {
                if !self.isPreBreakNotificationShowing {
                    self.pauseTimer()
                    self.onBreakTime?()
                } else {
                    self.isReminderShowing = true
                    self.isPreBreakNotificationShowing = false
                    self.stopTimer()
                    self.onBreakTime?()
                }
            }
        }
        
        if let strongTimer = timer {
            RunLoop.current.add(strongTimer, forMode: .common)
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func pauseTimer() {
        isReminderShowing = true
        isPreBreakNotificationShowing = false
        stopTimer()
    }
    
    func resumeTimer() {
        resetBreakRelatedStatesAndTimers()
        if settings.isEnabled {
            startTimer(resetTime: true)
        }
    }
    
    func showPreBreakNotification() {
        isPreBreakNotificationShowing = true
        stopTimer()
        onPreBreakNotification?()
    }
    
    func resetTimer() {
        resetBreakRelatedStatesAndTimers()

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
    
    func startBreakCountdown(duration: TimeInterval) {
        isReminderShowing = true
        isPreBreakNotificationShowing = false
        stopTimer()
        stopBreakCountdown()
        
        remainingBreakTime = Int(ceil(duration))
        
        breakCountdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.remainingBreakTime > 0 {
                self.remainingBreakTime -= 1
            } else {
                self.stopBreakCountdown()
            }
        }
        
        if let countdownTimer = breakCountdownTimer {
            RunLoop.current.add(countdownTimer, forMode: .common)
        }
    }
    
    func stopBreakCountdown() {
        breakCountdownTimer?.invalidate()
        breakCountdownTimer = nil
    }
    
    func adjustBreakTime(by seconds: Int) {
        let newTime = max(0, remainingBreakTime + seconds)
        remainingBreakTime = newTime
    }
    
    func formattedTimeRemaining() -> String {
        let minutes = Int(timeUntilBreak) / 60
        let seconds = Int(timeUntilBreak) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func formattedTimeRemainingInMinutes() -> String {
        let minutes = Int(ceil(timeUntilBreak / 60.0))
        return String(format: "%dm", minutes)
    }
    
    func formattedBreakCountdown() -> String {
        let minutes = remainingBreakTime / 60
        let seconds = remainingBreakTime % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func handleSystemEventStart() {
        if isReminderShowing {
            return
        }
        
        onHideNotifications?()
        isPreBreakNotificationShowing = false
        stopTimer()
        stopBreakCountdown()
    }
    
    private func handleSystemEventEnd() {
        if isReminderShowing {
            return
        }
        
        if settings.isEnabled {
            resetTimer()
        } else {
            stopTimer()
            stopBreakCountdown()
        }
    }

    func systemWillSleep() { 
        handleSystemEventStart()
    }
    
    func systemDidWake() { 
        handleSystemEventEnd()
    }
    
    func screenSaverDidStart() { 
        handleSystemEventStart()
    }
    
    func screenSaverDidStop() { 
        handleSystemEventEnd()
    }
    
    func displayDidSleep() { 
        handleSystemEventStart()
    }
    
    func displayDidWake() { 
        handleSystemEventEnd()
    }
    
    deinit {
        stopTimer()
        stopBreakCountdown()
        settingsCancellable?.cancel()
    }
}

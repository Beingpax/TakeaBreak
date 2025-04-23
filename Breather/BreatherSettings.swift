import Foundation
import Combine

class BreatherSettings: ObservableObject {
    // Keys for UserDefaults
    private enum Keys {
        static let breakInterval = "breakInterval"
        static let isEnabled = "isEnabled"
        static let autoDismissDuration = "autoDismissDuration"
        static let preBreakNotificationTime = "preBreakNotificationTime"
        static let preBreakNotificationDuration = "preBreakNotificationDuration"
    }
    
    // Published properties that will update the UI when changed
    @Published var breakInterval: TimeInterval
    @Published var isEnabled: Bool
    @Published var autoDismissDuration: TimeInterval
    @Published var preBreakNotificationTime: TimeInterval
    @Published var preBreakNotificationDuration: TimeInterval
    
    // Reference to timer manager (still needed for initialization)
    private var timerManager: TimerManager
    
    // No longer need cancellables here
    // private var cancellables = Set<AnyCancellable>()

    init(timerManager: TimerManager) {
        self.timerManager = timerManager
        
        // Initialize properties with default/placeholder values first
        let savedInterval = UserDefaults.standard.double(forKey: Keys.breakInterval)
        self.breakInterval = (savedInterval > 0) ? savedInterval : 20 * 60 // Default 20 mins
        
        let savedEnabled = UserDefaults.standard.object(forKey: Keys.isEnabled)
        self.isEnabled = (savedEnabled as? Bool) ?? true // Default true
        
        let savedDismissDuration = UserDefaults.standard.double(forKey: Keys.autoDismissDuration)
        self.autoDismissDuration = (savedDismissDuration > 0) ? savedDismissDuration : 20 // Default 20 seconds
        
        let savedPreNotificationTime = UserDefaults.standard.double(forKey: Keys.preBreakNotificationTime)
        self.preBreakNotificationTime = (savedPreNotificationTime > 0) ? savedPreNotificationTime : 30 // Default 30 seconds
        
        let savedPreNotificationDuration = UserDefaults.standard.double(forKey: Keys.preBreakNotificationDuration)
        self.preBreakNotificationDuration = (savedPreNotificationDuration > 0) ? savedPreNotificationDuration : 10 // Default 10 seconds
        
        // Now that all properties are initialized, save defaults if necessary
        // Note: Reading/writing happens here, but side effects (timer/observers) are handled in AppDelegate
        if savedInterval == 0 {
            UserDefaults.standard.set(self.breakInterval, forKey: Keys.breakInterval)
        }
        if savedEnabled == nil {
            UserDefaults.standard.set(self.isEnabled, forKey: Keys.isEnabled)
        }
        if savedDismissDuration == 0 {
             UserDefaults.standard.set(self.autoDismissDuration, forKey: Keys.autoDismissDuration)
        }
        if savedPreNotificationTime == 0 {
            UserDefaults.standard.set(self.preBreakNotificationTime, forKey: Keys.preBreakNotificationTime)
        }
        if savedPreNotificationDuration == 0 {
            UserDefaults.standard.set(self.preBreakNotificationDuration, forKey: Keys.preBreakNotificationDuration)
        }
        
        // Observers are now set up in AppDelegate
        // setupObservers()
    }
    
    // setupObservers() method removed
} 
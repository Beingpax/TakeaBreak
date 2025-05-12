import Foundation

struct UserDefaultsManager {
    private static let settingsKey = "breatherSettingsData"
    
    // Default values for all settings
    struct DefaultSettings {
        // Break settings
        static let breakIntervalMinutes: Double = 25.0
        static let isEnabled: Bool = true
        
        // Notification settings
        static let preBreakNotificationMinutes: Double = 0.25
        static let autoDismissDuration: TimeInterval = 30
        static let preBreakNotificationDuration: TimeInterval = 10
        
        // Idle detection settings
        static let idleDetectionEnabled: Bool = true
        static let idleThresholdSeconds: TimeInterval = 120 // 2 minutes
        
        // UI settings
        static let selectedWallpaper: String = "gradient"
        static let motivationalQuotes = [
            "Even a short pause can refresh a weary mind.",
            "Step away to come back stronger.",
            "Breathe deep, you're doing great!",
            "A moment of rest is a moment of strength.",
            "Hydrate, stretch, and smile.",
            "Rest is not a reward, it's a necessity.",
            "Mindful breaks create mindful work.",
            "Every break is a step toward better focus.",
            "Your mind deserves this moment of peace.",
            "Make space for greatness - take a break."
        ]
        
        // Onboarding
        static let hasCompletedOnboarding: Bool = false
    }
    
    // MARK: - Save/Load Methods
    
    static func saveSettings(_ settings: TakeABreakSettings) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(settings)
            UserDefaults.standard.set(data, forKey: settingsKey)
        } catch {
            print("Error saving settings: \(error)")
        }
    }
    
    static func loadSettings() -> TakeABreakSettings? {
        guard let data = UserDefaults.standard.data(forKey: settingsKey) else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(TakeABreakSettings.self, from: data)
        } catch {
            print("Failed to decode settings: \(error)")
            return nil
        }
    }
    
    static func clearSettings() {
        UserDefaults.standard.removeObject(forKey: settingsKey)
    }
} 
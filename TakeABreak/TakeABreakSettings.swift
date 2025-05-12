import Foundation
import Combine

public class TakeABreakSettings: ObservableObject, Codable {
    // Break settings
    @Published public var breakIntervalMinutes: Double {
        didSet { UserDefaultsManager.saveSettings(self) }
    }
    @Published public var isEnabled: Bool {
        didSet { UserDefaultsManager.saveSettings(self) }
    }
    
    // Notification settings
    @Published public var preBreakNotificationMinutes: Double {
        didSet { UserDefaultsManager.saveSettings(self) }
    }
    @Published public var autoDismissDuration: TimeInterval {
        didSet { UserDefaultsManager.saveSettings(self) }
    }
    @Published public var preBreakNotificationDuration: TimeInterval {
        didSet { UserDefaultsManager.saveSettings(self) }
    }
    
    // Idle detection settings
    @Published public var idleDetectionEnabled: Bool {
        didSet { UserDefaultsManager.saveSettings(self) }
    }
    @Published public var idleThresholdSeconds: TimeInterval {
        didSet { UserDefaultsManager.saveSettings(self) }
    }
    
    // UI settings
    @Published public var selectedWallpaper: String {
        didSet { UserDefaultsManager.saveSettings(self) }
    }
    @Published public var motivationalQuotes: [String] {
        didSet { UserDefaultsManager.saveSettings(self) }
    }
    
    // Onboarding
    @Published public var hasCompletedOnboarding: Bool {
        didSet { UserDefaultsManager.saveSettings(self) }
    }
    
    // MARK: - Initialization
    
    public init() {
        // Initialize with default values
        self.breakIntervalMinutes = UserDefaultsManager.DefaultSettings.breakIntervalMinutes
        self.preBreakNotificationMinutes = UserDefaultsManager.DefaultSettings.preBreakNotificationMinutes
        self.isEnabled = UserDefaultsManager.DefaultSettings.isEnabled
        self.autoDismissDuration = UserDefaultsManager.DefaultSettings.autoDismissDuration
        self.preBreakNotificationDuration = UserDefaultsManager.DefaultSettings.preBreakNotificationDuration
        self.idleDetectionEnabled = UserDefaultsManager.DefaultSettings.idleDetectionEnabled
        self.idleThresholdSeconds = UserDefaultsManager.DefaultSettings.idleThresholdSeconds
        self.selectedWallpaper = UserDefaultsManager.DefaultSettings.selectedWallpaper
        self.motivationalQuotes = UserDefaultsManager.DefaultSettings.motivationalQuotes
        self.hasCompletedOnboarding = UserDefaultsManager.DefaultSettings.hasCompletedOnboarding
        
        // Try to load saved settings
        if let savedSettings = UserDefaultsManager.loadSettings() {
            self.breakIntervalMinutes = savedSettings.breakIntervalMinutes
            self.preBreakNotificationMinutes = savedSettings.preBreakNotificationMinutes
            self.isEnabled = savedSettings.isEnabled
            self.autoDismissDuration = savedSettings.autoDismissDuration
            self.preBreakNotificationDuration = savedSettings.preBreakNotificationDuration
            self.idleDetectionEnabled = savedSettings.idleDetectionEnabled
            self.idleThresholdSeconds = savedSettings.idleThresholdSeconds
            self.selectedWallpaper = savedSettings.selectedWallpaper
            self.motivationalQuotes = savedSettings.motivationalQuotes
            self.hasCompletedOnboarding = savedSettings.hasCompletedOnboarding
        }
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case breakIntervalMinutes
        case preBreakNotificationMinutes
        case isEnabled
        case autoDismissDuration
        case preBreakNotificationDuration
        case idleDetectionEnabled
        case idleThresholdSeconds
        case selectedWallpaper
        case motivationalQuotes
        case hasCompletedOnboarding
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        breakIntervalMinutes = try container.decode(Double.self, forKey: .breakIntervalMinutes)
        preBreakNotificationMinutes = try container.decode(Double.self, forKey: .preBreakNotificationMinutes)
        isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        autoDismissDuration = try container.decode(TimeInterval.self, forKey: .autoDismissDuration)
        preBreakNotificationDuration = try container.decode(TimeInterval.self, forKey: .preBreakNotificationDuration)
        idleDetectionEnabled = try container.decodeIfPresent(Bool.self, forKey: .idleDetectionEnabled) ?? true
        idleThresholdSeconds = try container.decodeIfPresent(TimeInterval.self, forKey: .idleThresholdSeconds) ?? 120
        selectedWallpaper = try container.decode(String.self, forKey: .selectedWallpaper)
        motivationalQuotes = try container.decode([String].self, forKey: .motivationalQuotes)
        hasCompletedOnboarding = try container.decodeIfPresent(Bool.self, forKey: .hasCompletedOnboarding) ?? false
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(breakIntervalMinutes, forKey: .breakIntervalMinutes)
        try container.encode(preBreakNotificationMinutes, forKey: .preBreakNotificationMinutes)
        try container.encode(isEnabled, forKey: .isEnabled)
        try container.encode(autoDismissDuration, forKey: .autoDismissDuration)
        try container.encode(preBreakNotificationDuration, forKey: .preBreakNotificationDuration)
        try container.encode(idleDetectionEnabled, forKey: .idleDetectionEnabled)
        try container.encode(idleThresholdSeconds, forKey: .idleThresholdSeconds)
        try container.encode(selectedWallpaper, forKey: .selectedWallpaper)
        try container.encode(motivationalQuotes, forKey: .motivationalQuotes)
        try container.encode(hasCompletedOnboarding, forKey: .hasCompletedOnboarding)
    }
    
    // MARK: - Public Methods
    
    public func resetToDefaults() {
        breakIntervalMinutes = UserDefaultsManager.DefaultSettings.breakIntervalMinutes
        preBreakNotificationMinutes = UserDefaultsManager.DefaultSettings.preBreakNotificationMinutes
        isEnabled = UserDefaultsManager.DefaultSettings.isEnabled
        autoDismissDuration = UserDefaultsManager.DefaultSettings.autoDismissDuration
        preBreakNotificationDuration = UserDefaultsManager.DefaultSettings.preBreakNotificationDuration
        idleDetectionEnabled = UserDefaultsManager.DefaultSettings.idleDetectionEnabled
        idleThresholdSeconds = UserDefaultsManager.DefaultSettings.idleThresholdSeconds
        selectedWallpaper = UserDefaultsManager.DefaultSettings.selectedWallpaper
        motivationalQuotes = UserDefaultsManager.DefaultSettings.motivationalQuotes
        hasCompletedOnboarding = UserDefaultsManager.DefaultSettings.hasCompletedOnboarding
    }
    
    public func resetMotivationalQuotes() {
        motivationalQuotes = UserDefaultsManager.DefaultSettings.motivationalQuotes
    }
} 
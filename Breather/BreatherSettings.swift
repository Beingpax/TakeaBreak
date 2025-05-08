import Foundation
import Combine

public class BreatherSettings: ObservableObject, Codable {
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
    
    // UI settings
    @Published public var selectedWallpaper: String {
        didSet { UserDefaultsManager.saveSettings(self) }
    }
    @Published public var motivationalQuotes: [String] {
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
        self.selectedWallpaper = UserDefaultsManager.DefaultSettings.selectedWallpaper
        self.motivationalQuotes = UserDefaultsManager.DefaultSettings.motivationalQuotes
        
        // Try to load saved settings
        if let savedSettings = UserDefaultsManager.loadSettings() {
            self.breakIntervalMinutes = savedSettings.breakIntervalMinutes
            self.preBreakNotificationMinutes = savedSettings.preBreakNotificationMinutes
            self.isEnabled = savedSettings.isEnabled
            self.autoDismissDuration = savedSettings.autoDismissDuration
            self.preBreakNotificationDuration = savedSettings.preBreakNotificationDuration
            self.selectedWallpaper = savedSettings.selectedWallpaper
            self.motivationalQuotes = savedSettings.motivationalQuotes
        }
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case breakIntervalMinutes
        case preBreakNotificationMinutes
        case isEnabled
        case autoDismissDuration
        case preBreakNotificationDuration
        case selectedWallpaper
        case motivationalQuotes
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        breakIntervalMinutes = try container.decode(Double.self, forKey: .breakIntervalMinutes)
        preBreakNotificationMinutes = try container.decode(Double.self, forKey: .preBreakNotificationMinutes)
        isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        autoDismissDuration = try container.decode(TimeInterval.self, forKey: .autoDismissDuration)
        preBreakNotificationDuration = try container.decode(TimeInterval.self, forKey: .preBreakNotificationDuration)
        selectedWallpaper = try container.decode(String.self, forKey: .selectedWallpaper)
        motivationalQuotes = try container.decode([String].self, forKey: .motivationalQuotes)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(breakIntervalMinutes, forKey: .breakIntervalMinutes)
        try container.encode(preBreakNotificationMinutes, forKey: .preBreakNotificationMinutes)
        try container.encode(isEnabled, forKey: .isEnabled)
        try container.encode(autoDismissDuration, forKey: .autoDismissDuration)
        try container.encode(preBreakNotificationDuration, forKey: .preBreakNotificationDuration)
        try container.encode(selectedWallpaper, forKey: .selectedWallpaper)
        try container.encode(motivationalQuotes, forKey: .motivationalQuotes)
    }
    
    // MARK: - Public Methods
    
    public func resetToDefaults() {
        breakIntervalMinutes = UserDefaultsManager.DefaultSettings.breakIntervalMinutes
        preBreakNotificationMinutes = UserDefaultsManager.DefaultSettings.preBreakNotificationMinutes
        isEnabled = UserDefaultsManager.DefaultSettings.isEnabled
        autoDismissDuration = UserDefaultsManager.DefaultSettings.autoDismissDuration
        preBreakNotificationDuration = UserDefaultsManager.DefaultSettings.preBreakNotificationDuration
        selectedWallpaper = UserDefaultsManager.DefaultSettings.selectedWallpaper
        motivationalQuotes = UserDefaultsManager.DefaultSettings.motivationalQuotes
    }
    
    public func resetMotivationalQuotes() {
        motivationalQuotes = UserDefaultsManager.DefaultSettings.motivationalQuotes
    }
} 
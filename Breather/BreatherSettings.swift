import Foundation
import Combine

public class BreatherSettings: ObservableObject, Codable {
    // Keys for UserDefaults
    private enum Keys {
        static let breakInterval = "breakInterval"
        static let isEnabled = "isEnabled"
        static let autoDismissDuration = "autoDismissDuration"
        static let preBreakNotificationTime = "preBreakNotificationTime"
        static let preBreakNotificationDuration = "preBreakNotificationDuration"
        static let selectedWallpaper = "selectedWallpaper"
    }
    
    // Published properties that will update the UI when changed
    @Published public var breakIntervalMinutes: Double = 20.0 {
        didSet { saveSettings() }
    }
    @Published public var preBreakNotificationMinutes: Double = 0.5 {
        didSet { saveSettings() }
    }
    @Published public var isEnabled: Bool = true {
        didSet { saveSettings() }
    }
    @Published public var autoDismissDuration: TimeInterval = 20 {
        didSet { saveSettings() }
    }
    @Published public var preBreakNotificationDuration: TimeInterval = 10 {
        didSet { saveSettings() }
    }
    @Published public var selectedWallpaper: String = "gradient" {
        didSet { saveSettings() }
    }
    
    // Codable conformance
    enum CodingKeys: String, CodingKey {
        case breakIntervalMinutes
        case preBreakNotificationMinutes
        case isEnabled
        case autoDismissDuration
        case preBreakNotificationDuration
        case selectedWallpaper
    }

    // Default initializer - loads settings
    public init() {
        loadSettings()
    }

    // Required initializer for Decodable
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        breakIntervalMinutes = try container.decodeIfPresent(Double.self, forKey: .breakIntervalMinutes) ?? 20.0
        preBreakNotificationMinutes = try container.decodeIfPresent(Double.self, forKey: .preBreakNotificationMinutes) ?? 0.5
        isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
        autoDismissDuration = try container.decodeIfPresent(TimeInterval.self, forKey: .autoDismissDuration) ?? 20
        preBreakNotificationDuration = try container.decodeIfPresent(TimeInterval.self, forKey: .preBreakNotificationDuration) ?? 10
        selectedWallpaper = try container.decodeIfPresent(String.self, forKey: .selectedWallpaper) ?? "gradient"
    }

    // Required method for Encodable
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(breakIntervalMinutes, forKey: .breakIntervalMinutes)
        try container.encode(preBreakNotificationMinutes, forKey: .preBreakNotificationMinutes)
        try container.encode(isEnabled, forKey: .isEnabled)
        try container.encode(autoDismissDuration, forKey: .autoDismissDuration)
        try container.encode(preBreakNotificationDuration, forKey: .preBreakNotificationDuration)
        try container.encode(selectedWallpaper, forKey: .selectedWallpaper)
    }

    // Load settings using Codable
    private func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: "breatherSettingsData") {
            do {
                let decoder = JSONDecoder()
                let decodedSettings = try decoder.decode(BreatherSettings.self, from: data)
                self.breakIntervalMinutes = decodedSettings.breakIntervalMinutes
                self.preBreakNotificationMinutes = decodedSettings.preBreakNotificationMinutes
                self.isEnabled = decodedSettings.isEnabled
                self.autoDismissDuration = decodedSettings.autoDismissDuration
                self.preBreakNotificationDuration = decodedSettings.preBreakNotificationDuration
                self.selectedWallpaper = decodedSettings.selectedWallpaper
            } catch {
                print("Failed to decode new settings structure, attempting to migrate or using defaults: \(error)")
                setDefaults()
            }
        } else {
            setDefaults()
            saveSettings(force: true)
        }
    }

    // Save settings using Codable
    private func saveSettings(force: Bool = false) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(self)
            UserDefaults.standard.set(data, forKey: "breatherSettingsData")
        } catch {
            print("Error saving settings: \(error)")
        }
    }
    
    // Helper to set default values
    private func setDefaults() {
        self.breakIntervalMinutes = 20.0
        self.preBreakNotificationMinutes = 0.5
        self.isEnabled = true
        self.autoDismissDuration = 20
        self.preBreakNotificationDuration = 10
        self.selectedWallpaper = "gradient"
    }
} 
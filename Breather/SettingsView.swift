import SwiftUI
import LaunchAtLogin

// MARK: - Wallpaper Data Structures
struct WallpaperOption: Identifiable, Hashable {
    let id: String
    let name: String
    let previewImageName: String // For actual image assets or SF Symbols
}

let availableWallpapers: [WallpaperOption] = [
    WallpaperOption(id: "gradient", name: "Default Gradient", previewImageName: "gradient"),
    WallpaperOption(id: "mountain", name: "Mountain View", previewImageName: "mountain") // Assumes "mountain" is in assets
]

// Enum for TabView tags
enum SettingsTabTag {
    case general, look, rules, more
}

public struct SettingsView: View {
    @ObservedObject var settings: BreatherSettings
    @State private var selectedTab: SettingsTabTag = .look // Default to "Look" tab

    // Shared formatters
    private var minutesFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimum = 0.5
        formatter.maximum = 120
        formatter.maximumFractionDigits = 1
        return formatter
    }()

    private var secondsFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimum = 5
        formatter.maximum = 300
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    public init(settings: BreatherSettings) {
        self.settings = settings
    }

    public var body: some View {
        TabView(selection: $selectedTab) {
            // General Tab
            Form {
                Section {
                    GeneralSettingsContent(settings: settings)
                } header: {
                    SectionHeader(title: "General", systemImage: "gearshape")
                }
            }
            .tabItem {
                Label("General", systemImage: "gearshape")
            }
            .tag(SettingsTabTag.general)

            // Look Tab
            LookSettingsView(settings: settings)
                .tabItem {
                    Label("Look", systemImage: "sparkles")
                }
                .tag(SettingsTabTag.look)

            // Rules Tab (using Timing content for now)
            Form {
                Section {
                    TimingSettingsContent(settings: settings, minutesFormatter: minutesFormatter, secondsFormatter: secondsFormatter)
                } header: {
                    // Using a more generic header for this tab
                    SectionHeader(title: "Break Behavior", systemImage: "desktopcomputer")
                }
            }
            .tabItem {
                Label("Rules", systemImage: "desktopcomputer")
            }
            .tag(SettingsTabTag.rules)

            // More Tab (using Notifications content for now)
            Form {
                Section {
                     NotificationSettingsContent(settings: settings, minutesFormatter: minutesFormatter, secondsFormatter: secondsFormatter)
                } header: {
                     // Using a more generic header for this tab
                    SectionHeader(title: "Additional Options", systemImage: "ellipsis.circle")
                }
            }
            .tabItem {
                Label("More", systemImage: "ellipsis.circle")
            }
            .tag(SettingsTabTag.more)
        }
        .frame(minWidth: 520, idealWidth: 580, maxWidth: 650, minHeight: 450, idealHeight: 500, maxHeight: 600) // Adjusted frame for tab view
        .navigationTitle("") // Keep the title bar clean
    }
}

// MARK: - Content Views for Each Section (Existing ones modified slightly if needed or kept as is)

private struct SectionHeader: View {
    let title: String
    let systemImage: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundColor(.accentColor)
            Text(title)
                .font(.title3)
                .fontWeight(.medium)
        }
        .padding(.vertical, 8)
    }
}

private struct GeneralSettingsContent: View {
    @ObservedObject var settings: BreatherSettings
    var body: some View {
        Toggle(isOn: $settings.isEnabled) {
           Text("Enable Breather")
        }
        .toggleStyle(.switch)
        LaunchAtLogin.Toggle()
    }
}

private struct TimingSettingsContent: View {
    @ObservedObject var settings: BreatherSettings
    let minutesFormatter: NumberFormatter
    let secondsFormatter: NumberFormatter
    var body: some View {
        NumericSetting(label: "Work Duration",
                       description: "Time before a break is due.",
                       value: $settings.breakIntervalMinutes,
                       formatter: minutesFormatter, unit: "min", range: 0.5...120, step: 1.0)
        NumericSetting(label: "Break Auto-Dismiss",
                       description: "How long break screen shows.",
                       value: $settings.autoDismissDuration,
                       formatter: secondsFormatter, unit: "sec", range: 5...300, step: 5)
    }
}

private struct NotificationSettingsContent: View {
     @ObservedObject var settings: BreatherSettings
    let minutesFormatter: NumberFormatter
    let secondsFormatter: NumberFormatter
    var body: some View {
        NumericSetting(label: "Pre-break Warning",
                       description: "Notify this long before break.",
                       value: $settings.preBreakNotificationMinutes,
                       formatter: minutesFormatter, unit: "min", range: 0.5...10, step: 0.5)
        NumericSetting(label: "Warning Duration",
                       description: "How long warning stays visible.",
                       value: $settings.preBreakNotificationDuration,
                       formatter: secondsFormatter, unit: "sec", range: 5...60, step: 5)
    }
}


// MARK: - Look Tab Content
struct LookSettingsView: View {
    @ObservedObject var settings: BreatherSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Appearance")
                .font(.title2)
                .fontWeight(.semibold)
                .padding([.leading, .top])
                .padding(.bottom, 5)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(availableWallpapers) { option in
                        WallpaperPreviewCard(
                            option: option,
                            isSelected: settings.selectedWallpaper == option.id,
                            onTap: {
                                withAnimation(.spring()) {
                                    settings.selectedWallpaper = option.id
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 10)
            }
            .frame(height: 170) // Height for preview cards container

            Text("Choose the background style for your break screen.")
                .font(.callout)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.vertical) // Add some vertical padding to the whole tab content
    }
}

struct WallpaperPreviewCard: View {
    let option: WallpaperOption
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Image(option.previewImageName) // Ensures Image is used directly
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 130, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.4), lineWidth: isSelected ? 3.5 : 1.5)
                )
                .shadow(color: .black.opacity(0.1), radius: isSelected ? 5 : 2, x: 0, y: isSelected ? 2 : 1) // Restored shadow
            
            Text(option.name)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .primary : .secondary)
        }
        .padding(8)
        .background(Material.ultraThinMaterial) // Frosted glass background for card
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .scaleEffect(isSelected ? 1.0 : 0.97)
        .onTapGesture(perform: onTap)
    }
}


// MARK: - Reusable Numeric Setting Row (Keep as is)
private struct NumericSetting: View {
    let label: String
    let description: String?
    @Binding var value: Double
    let formatter: NumberFormatter
    let unit: String
    let range: ClosedRange<Double>
    let step: Double

    var body: some View {
        LabeledContent {
             HStack(spacing: 5) {
                TextField("Value", value: $value, formatter: formatter)
                     .multilineTextAlignment(.trailing)
                     .frame(minWidth: 45, maxWidth: 65)
                     .labelsHidden()
                     .textFieldStyle(.roundedBorder)

                Stepper("Value Stepper", value: $value, in: range, step: step)
                    .labelsHidden()

                Text(unit)
                    .frame(width: 30, alignment: .leading)
                    .foregroundColor(.secondary)
            }
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                if let description = description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}


// MARK: - Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        // Ensure BreatherSettings is correctly initialized for preview
        let previewSettings = BreatherSettings()
        SettingsView(settings: previewSettings)
            // You might want to set the selectedTab for specific previews
            // .onAppear { previewSettings.selectedTab = .look } // Example
    }
}


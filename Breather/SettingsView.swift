import SwiftUI
import LaunchAtLogin

// MARK: - Wallpaper Data Structures
struct WallpaperOption: Identifiable, Hashable {
    let id: String
    let name: String
    let previewImageName: String
}

let availableWallpapers: [WallpaperOption] = [
    WallpaperOption(id: "gradient", name: "Default Gradient", previewImageName: "gradient"),
    WallpaperOption(id: "mountain", name: "Mountain View", previewImageName: "mountain")
]

// Enum for TabView tags
enum SettingsTabTag {
    case general, customization, rules, more
}

// MARK: - Main Settings View
public struct SettingsView: View {
    @ObservedObject var settings: BreatherSettings
    @State private var selectedTab: SettingsTabTag = .customization

    private var minutesFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimum = 20
        formatter.maximum = 60
        formatter.maximumFractionDigits = 1
        return formatter
    }()

    private var secondsFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimum = 5
        formatter.maximum = 180
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    public init(settings: BreatherSettings) {
        self.settings = settings
    }

    public var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: GeneralSettingsContent(settings: settings)) {
                    Label {
                        Text("General")
                            .font(.system(size: 13, weight: .medium))
                    } icon: {
                        DetailedIcon(systemName: "gearshape.fill", themeColor: .blue)
                    }
                }
                
                NavigationLink(destination: CustomizationView(settings: settings)) {
                    Label {
                        Text("Customization")
                            .font(.system(size: 13, weight: .medium))
                    } icon: {
                        DetailedIcon(systemName: "paintbrush.fill", themeColor: .purple)
                    }
                }
                
                NavigationLink(destination: TimingSettingsContent(settings: settings, minutesFormatter: minutesFormatter, secondsFormatter: secondsFormatter)) {
                    Label {
                        Text("Break Timer")
                            .font(.system(size: 13, weight: .medium))
                    } icon: {
                        DetailedIcon(systemName: "clock.fill", themeColor: .green)
                    }
                }
                
                NavigationLink(destination: NotificationSettingsContent(settings: settings, minutesFormatter: minutesFormatter, secondsFormatter: secondsFormatter)) {
                    Label {
                        Text("Notifications")
                            .font(.system(size: 13, weight: .medium))
                    } icon: {
                        DetailedIcon(systemName: "bell.badge.fill", themeColor: .orange)
                    }
                }
            }
            .listStyle(SidebarListStyle())
            .frame(minWidth: 200, maxWidth: 250)
            
            CustomizationView(settings: settings)
        }
        .frame(minWidth: 700, minHeight: 400)
        .navigationTitle("")
    }
}

// MARK: - Detailed Icon & Header Components
struct DetailedIcon: View {
    let systemName: String
    let themeColor: Color
    var size: CGFloat = 24 // Sidebar icon size
    var iconFontSize: CGFloat = 12
    var cornerRadius: CGFloat = 7

    var body: some View {
        ZStack {
            // Base with gradient and outer shadow
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [themeColor.opacity(0.8), themeColor.opacity(0.6)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: themeColor.opacity(0.3), radius: 3, x: 1, y: 2)
                .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)


            // Inner Bevel Effect
            RoundedRectangle(cornerRadius: cornerRadius - 1)
                .strokeBorder(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.white.opacity(0.3), Color.clear, themeColor.opacity(0.2), themeColor.opacity(0.5)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .padding(0.5) // To ensure stroke is inside

            // Symbol
            Image(systemName: systemName)
                .font(.system(size: iconFontSize, weight: .bold))
                .foregroundColor(.white.opacity(0.9))
                .shadow(color: .black.opacity(0.25), radius: 1.5, x: 0, y: 0.75) // Symbol shadow for pop
        }
        .frame(width: size, height: size)
    }
}

struct DetailedSectionHeader: View {
    let title: String
    let subtitle: String
    let systemName: String
    let themeColor: Color

    var body: some View {
        HStack(spacing: 14) {
            DetailedIcon(systemName: systemName, themeColor: themeColor, size: 34, iconFontSize: 16, cornerRadius: 9)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.leading, 4) // Slight indent for header
    }
}

// MARK: - Content Views
private struct GeneralSettingsContent: View {
    @ObservedObject var settings: BreatherSettings
    var body: some View {
        Form {
            Section {
                VStack(spacing: 16) {
                    Toggle(isOn: $settings.isEnabled) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Enable Break Reminders")
                                .font(.system(size: 13, weight: .medium))
                            Text("Get gentle reminders to take breaks while working")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                    .toggleStyle(.switch)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        LaunchAtLogin.Toggle()
                        Text("Start Breather automatically at login")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }.padding(.vertical, 8)
            } header: {
                DetailedSectionHeader(
                    title: "General",
                    subtitle: "Basic app settings and behavior",
                    systemName: "gearshape.fill",
                    themeColor: .blue
                )
            }
        }
        .formStyle(.grouped)
    }
}

struct CustomizationView: View {
    @ObservedObject var settings: BreatherSettings
    
    var body: some View {
        Form {
            // Main title area for the "Customization" screen
            DetailedSectionHeader(
                title: "Customization",
                subtitle: "Personalize your break experience",
                systemName: "paintbrush.fill",
                themeColor: .purple
            )
            .listRowInsets(EdgeInsets(top: 0, leading: -10, bottom: 10, trailing: 0))

            // Section 1: Reminder Background
            Section(
                header: Text("Reminder Background")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .textCase(nil)
            ) {
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
                }
                .frame(height: 170)
            }
            
            // Section 2: Motivational Quotes - Now using MotivationalQuotesSectionView
            MotivationalQuotesSectionView(settings: settings)
        }
        .formStyle(.grouped)
    }
}

private struct TimingSettingsContent: View {
    @ObservedObject var settings: BreatherSettings
    let minutesFormatter: NumberFormatter
    let secondsFormatter: NumberFormatter
    
    var body: some View {
        Form {
            Section {
                EnhancedNumericSetting(
                    label: "Work Interval",
                    description: "Time between breaks",
                    value: $settings.breakIntervalMinutes,
                    formatter: minutesFormatter,
                    unit: "min",
                    range: 20...60,
                    step: 5.0
                )
                EnhancedNumericSetting(
                    label: "Break Duration",
                    description: "Length of each break",
                    value: $settings.autoDismissDuration,
                    formatter: secondsFormatter,
                    unit: "sec",
                    range: 20...180,
                    step: 10
                )
            } header: {
                DetailedSectionHeader(
                    title: "Break Timer",
                    subtitle: "Configure your work and break intervals",
                    systemName: "clock.fill",
                    themeColor: .green
                )
            }
        }
        .formStyle(.grouped)
    }
}

private struct NotificationSettingsContent: View {
    @ObservedObject var settings: BreatherSettings
    let minutesFormatter: NumberFormatter
    let secondsFormatter: NumberFormatter
    
    var body: some View {
            Form {
                Section {
                EnhancedNumericSetting(
                    label: "Advance Notice",
                    description: "Get notified before break starts",
                    value: Binding(
                        get: { Double(settings.preBreakNotificationMinutes * 60) },
                        set: { settings.preBreakNotificationMinutes = $0 / 60 }
                    ),
                    formatter: secondsFormatter,
                    unit: "sec",
                    range: 10...60,
                    step: 5
                )
                EnhancedNumericSetting(
                    label: "Notice Duration",
                    description: "How long notification appears",
                    value: $settings.preBreakNotificationDuration,
                    formatter: secondsFormatter,
                    unit: "sec",
                    range: 5...30,
                    step: 5
                )
                } header: {
                DetailedSectionHeader(
                    title: "Notifications",
                    subtitle: "Configure break reminders and alerts",
                    systemName: "bell.badge.fill",
                    themeColor: .orange
                )
                }
            }
        .formStyle(.grouped)
    }
}

// Enhanced helper views
struct EnhancedNumericSetting: View {
    let label: String
    let description: String
    @Binding var value: Double
    let formatter: NumberFormatter
    let unit: String
    let range: ClosedRange<Double>
    let step: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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
                        .font(.system(size: 13, weight: .medium))
                    Text(description)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Helper Views
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

struct WallpaperPreviewCard: View {
    let option: WallpaperOption
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Image(option.previewImageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 130, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.4), lineWidth: isSelected ? 3.5 : 1.5)
                )
                .shadow(color: .black.opacity(0.1), radius: isSelected ? 5 : 2, x: 0, y: isSelected ? 2 : 1)
            
            Text(option.name)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .primary : .secondary)
        }
        .padding(8)
        .background(Material.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .scaleEffect(isSelected ? 1.0 : 0.97)
        .onTapGesture(perform: onTap)
    }
}

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
        let previewSettings = BreatherSettings()
        SettingsView(settings: previewSettings)
            .preferredColorScheme(.dark) 
        SettingsView(settings: previewSettings)
            .preferredColorScheme(.light)
    }
}

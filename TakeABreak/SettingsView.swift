import SwiftUI
import LaunchAtLogin
import Sparkle

struct WallpaperOption: Identifiable, Hashable {
    let id: String
    let name: String
    let previewImageName: String
}

let availableWallpapers: [WallpaperOption] = [
    WallpaperOption(id: "gradient", name: "Default Gradient", previewImageName: "gradient"),
    WallpaperOption(id: "mountain", name: "Mountain View", previewImageName: "mountain"),
    WallpaperOption(id: "sunset", name: "Peaceful Sunset", previewImageName: "sunset")
]

enum SettingsTabTag {
    case general, customization, rules, more
}

public struct SettingsView: View {
    @ObservedObject var settings: TakeABreakSettings
    @State private var selectedTab: SettingsTabTag = .general

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

    public init(settings: TakeABreakSettings, updater: SPUUpdater? = nil) {
        self.settings = settings
        // updater is not used directly in SettingsView as Sparkle manages its own preferences
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
                
                NavigationLink(destination: AboutSettingsContent()) {
                    Label {
                        Text("About")
                            .font(.system(size: 13, weight: .medium))
                    } icon: {
                        DetailedIcon(systemName: "info.circle.fill", themeColor: .gray)
                    }
                }
            }
            .listStyle(SidebarListStyle())
            .frame(minWidth: 220, maxWidth: 280)
            
            GeneralSettingsContent(settings: settings)
        }
        .frame(minWidth: 800, minHeight: 500)
        .navigationTitle("")
    }
}

struct DetailedIcon: View {
    let systemName: String
    let themeColor: Color
    var size: CGFloat = 24
    var iconFontSize: CGFloat = 12
    var cornerRadius: CGFloat = 7

    var body: some View {
        ZStack {
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


            RoundedRectangle(cornerRadius: cornerRadius - 1)
                .strokeBorder(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.white.opacity(0.3), Color.clear, themeColor.opacity(0.2), themeColor.opacity(0.5)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .padding(0.5)

            Image(systemName: systemName)
                .font(.system(size: iconFontSize, weight: .bold))
                .foregroundColor(.white.opacity(0.9))
                .shadow(color: .black.opacity(0.25), radius: 1.5, x: 0, y: 0.75)
        }
        .frame(width: size, height: size)
    }
}

struct DetailedSectionHeader: View {
    let title: String
    let subtitle: String?
    let systemName: String
    let themeColor: Color

    init(title: String, subtitle: String? = nil, systemName: String, themeColor: Color) {
        self.title = title
        self.subtitle = subtitle
        self.systemName = systemName
        self.themeColor = themeColor
    }

    var body: some View {
        HStack(spacing: 14) {
            DetailedIcon(systemName: systemName, themeColor: themeColor, size: 34, iconFontSize: 16, cornerRadius: 9)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.leading, 4)
    }
}

private struct GeneralSettingsContent: View {
    @ObservedObject var settings: TakeABreakSettings
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
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
                                Text("Start app automatically at login")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }.padding(.vertical, 4)
                    } header: {
                        DetailedSectionHeader(
                            title: "General",
                            subtitle: "Configure app behavior",
                            systemName: "gearshape.fill",
                            themeColor: .blue
                        )
                    }
                }
                .formStyle(.grouped)
                
                Form {
                    Section {
                        Link(destination: URL(string: "https://tryvoiceink.com")!) {
                            HStack(spacing: 15) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.purple.opacity(0.8), Color.purple.opacity(0.6)]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .shadow(color: Color.purple.opacity(0.3), radius: 3, x: 1, y: 2)
                                        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                                    
                                    RoundedRectangle(cornerRadius: 9)
                                        .strokeBorder(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.white.opacity(0.3), Color.clear, Color.purple.opacity(0.2), Color.purple.opacity(0.5)]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1.5
                                        )
                                        .padding(0.5)
                                    
                                    Image("voiceink")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .padding(8)
                                }
                                .frame(width: 40, height: 40)
                                
                                Text("VoiceInk - Voice-to-text Dictation app")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.primary)
                            }
                        }
                        .buttonStyle(.plain)
                    } header: {
                        Text("Check out my other apps")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .padding(.bottom, 4)
                    }
                }
                .formStyle(.grouped)
            }
            .padding(.horizontal, 8)
        }
    }
}

struct CustomizationView: View {
    @ObservedObject var settings: TakeABreakSettings
    
    var body: some View {
        Form {
            Section {
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
            } header: {
                DetailedSectionHeader(
                    title: "Reminder Background", 
                    subtitle: "Choose your break screen background",
                    systemName: "photo.fill",
                    themeColor: .blue
                )
            }
            
            MotivationalQuotesSectionView(settings: settings)
        }
        .formStyle(.grouped)
    }
}

private struct TimingSettingsContent: View {
    @ObservedObject var settings: TakeABreakSettings
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
                    range: 5...60,
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
            
            Section {
                VStack(spacing: 16) {
                    Toggle(isOn: $settings.idleDetectionEnabled) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Enable Idle Detection")
                                .font(.system(size: 13, weight: .medium))
                            Text("Pause and reset timer when you're away from your computer")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                    .toggleStyle(.switch)
                    
                    Divider()
                    
                    EnhancedNumericSetting(
                        label: "Idle Threshold",
                        description: "Time without activity before considering you idle",
                        value: $settings.idleThresholdSeconds,
                        formatter: secondsFormatter,
                        unit: "sec",
                        range: 30...300,
                        step: 30
                    )
                    .disabled(!settings.idleDetectionEnabled)
                    .opacity(settings.idleDetectionEnabled ? 1.0 : 0.5)
                }.padding(.vertical, 4)
            } header: {
                DetailedSectionHeader(
                    title: "Idle Detection",
                    subtitle: "Automatically pause & reset timer when you're away",
                    systemName: "person.fill.questionmark",
                    themeColor: .blue
                )
            }
        }
        .formStyle(.grouped)
    }
}

private struct NotificationSettingsContent: View {
    @ObservedObject var settings: TakeABreakSettings
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

private struct AboutSettingsContent: View {
    var body: some View {
        Form {
            Section {
                VStack(spacing: 20) {
                    Image(nsImage: NSApplication.shared.applicationIconImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 128, height: 128)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .shadow(radius: 10)
                    
                    VStack(spacing: 8) {
                        Text("Take A Break")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
                           let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String {
                            Text("Version \(version) (Build \(build))")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Text("Take a Break reminds you to take regular breaks during your work sessions. Taking short breaks helps maintain good back and eye health, keeping you productive and feeling great!")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 40)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.windowBackgroundColor))
            }
        }
    }
}

import SwiftUI
import AppKit
import LaunchAtLogin

struct OnboardingView: View {
    @ObservedObject var settings: TakeABreakSettings
    @State private var currentStep = 0
    
    // Temporary settings that will be applied at the end
    @State private var workDuration: Double // Stored in minutes
    @State private var breakDuration: Double // Will be stored in seconds
    @State private var preBreakNotificationMinutes: Double // Stored in minutes
    @State private var preBreakNotificationDuration: Double // Stored in seconds
    
    private let onboardingCompleted: () -> Void
    
    init(settings: TakeABreakSettings, onboardingCompleted: @escaping () -> Void) {
        self.settings = settings
        self.onboardingCompleted = onboardingCompleted
        
        // Initialize temporary settings with current values, ensuring a default is selected from available options
        let initialWorkOptions = [20.0, 25.0, 30.0, 40.0]
        if initialWorkOptions.contains(settings.breakIntervalMinutes) {
            _workDuration = State(initialValue: settings.breakIntervalMinutes)
        } else {
            _workDuration = State(initialValue: initialWorkOptions[1]) // Default to 25 minutes
        }
        
        let initialBreakOptions = [20.0, 30.0, 60.0, 120.0]
        if initialBreakOptions.contains(settings.autoDismissDuration) {
            _breakDuration = State(initialValue: settings.autoDismissDuration)
        } else {
            _breakDuration = State(initialValue: initialBreakOptions[1]) // Default to 30 seconds
        }
        
        let initialPreBreakOptions = [0.25, 0.5, 0.75, 1.0]
        if initialPreBreakOptions.contains(settings.preBreakNotificationMinutes) {
            _preBreakNotificationMinutes = State(initialValue: settings.preBreakNotificationMinutes)
        } else {
            _preBreakNotificationMinutes = State(initialValue: initialPreBreakOptions[1]) // Default to 30 seconds (0.5 min)
        }
        
        let initialNoticeDurationOptions = [5.0, 10.0, 15.0, 20.0]
        if initialNoticeDurationOptions.contains(settings.preBreakNotificationDuration) {
            _preBreakNotificationDuration = State(initialValue: settings.preBreakNotificationDuration)
        } else {
            _preBreakNotificationDuration = State(initialValue: initialNoticeDurationOptions[1]) // Default to 10 seconds
        }
    }
    
    var body: some View {
        ZStack {
            // Background with blur effect
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Custom title bar area that allows dragging
                DragHandleView()
                
                // Progress bar - Updated to show 6 steps
                HStack(spacing: 10) {
                    ForEach(0..<6) { index in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(index == currentStep ? Color.accentColor : Color.gray.opacity(0.3))
                            .frame(width: 35, height: 6)
                            .animation(.easeInOut, value: currentStep)
                    }
                }
                .padding(.top, 4)
                .padding(.bottom, 20)
                .padding(.horizontal, 40)
                
                // Content area with improved spacing
                ZStack {
                    switch currentStep {
                    case 0:
                        WelcomeView()
                    case 1:
                        WorkDurationView(workDuration: $workDuration)
                    case 2:
                        BreakDurationView(breakDuration: $breakDuration)
                    case 3:
                        AdvanceNoticeView(preBreakNotification: $preBreakNotificationMinutes)
                    case 4:
                        NoticeDurationView(noticeDuration: $preBreakNotificationDuration)
                    case 5:
                        LaunchAtLoginView()
                    default:
                        EmptyView()
                    }
                }
                .frame(height: 360)
                .padding(.horizontal, 40)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .animation(.easeInOut, value: currentStep)
                
                Spacer()
                
                // Navigation buttons with better spacing and alignment
                HStack {
                    if currentStep > 0 {
                        Button(action: {
                            currentStep -= 1
                        }) {
                            Text("Back")
                                .frame(width: 80)
                        }
                        .buttonStyle(.plain)
                        .controlSize(.large)
                        .padding(.leading, 20)
                    } else {
                        Spacer()
                            .frame(width: 100)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        if currentStep < 5 {
                            currentStep += 1
                        } else {
                            // Apply settings and complete onboarding
                            settings.breakIntervalMinutes = workDuration
                            settings.autoDismissDuration = breakDuration
                            settings.preBreakNotificationMinutes = preBreakNotificationMinutes
                            settings.preBreakNotificationDuration = preBreakNotificationDuration
                            settings.hasCompletedOnboarding = true
                            onboardingCompleted()
                        }
                    }) {
                        HStack(spacing: 8) {
                            if currentStep < 5 {
                                Text("Next")
                                Image(systemName: "chevron.right")
                            } else {
                                Text("Complete")
                                Image(systemName: "checkmark.circle.fill")
                            }
                        }
                        .frame(width: 120)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .keyboardShortcut(.defaultAction)
                    .padding(.trailing, 20)
                }
                .padding(.bottom, 30)
                .padding(.top, 20)
            }
        }
        .frame(width: 600, height: 520)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 5)
    }
}

// MARK: - Drag Handle
struct DragHandleView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = DraggableView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.wantsLayer = true
        
        // Add a subtle visual indicator for dragging
        let handleView = NSView()
        handleView.translatesAutoresizingMaskIntoConstraints = false
        handleView.wantsLayer = true
        handleView.layer?.backgroundColor = NSColor.gray.withAlphaComponent(0.3).cgColor
        handleView.layer?.cornerRadius = 2
        
        view.addSubview(handleView)
        
        NSLayoutConstraint.activate([
            view.heightAnchor.constraint(equalToConstant: 26), // Fixed height for drag handle
            handleView.widthAnchor.constraint(equalToConstant: 40),
            handleView.heightAnchor.constraint(equalToConstant: 4),
            handleView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            handleView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}

class DraggableView: NSView {
    override func mouseDown(with event: NSEvent) {
        guard let window = self.window else { return }
        window.performDrag(with: event)
    }
}

// MARK: - Step Views

struct WelcomeView: View {
    var body: some View {
        VStack(spacing: 30) {
            // App icon
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            
            // Welcome text with better typography
            Text("Welcome to Take A Break")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
            
            // Description with improved messaging
            VStack(spacing: 20) {
                Text("Your Focus & Wellness Companion")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("Take A Break helps you maintain productivity and wellbeing by reminding you to take regular breaks throughout your workday.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: 450)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Reusable Template View
struct SettingsOptionView<T: Hashable>: View {
    let title: String
    let description: String
    let options: [(value: T, label: String)]
    @Binding var selectedValue: T
    
    var body: some View {
        VStack(alignment: .center, spacing: 30) {
            // Title and description
            VStack(spacing: 10) {
                Text(title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Duration selection grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                ForEach(options, id: \.value) { option in
                    DurationOptionButton(
                        value: option.label,
                        isSelected: selectedValue == option.value,
                        action: { selectedValue = option.value }
                    )
                }
            }
            .padding(.horizontal, 40)
            
            Spacer().frame(height: 30)
        }
    }
}

struct WorkDurationView: View {
    @Binding var workDuration: Double // in minutes
    
    let workDurations: [(value: Double, label: String)] = [
        (20, "20 min"),
        (25, "25 min"),
        (30, "30 min"),
        (40, "40 min")
    ]
    
    var body: some View {
        SettingsOptionView(
            title: "Work Duration",
            description: "How long would you like to work before taking a break?",
            options: workDurations,
            selectedValue: $workDuration
        )
    }
}

struct BreakDurationView: View {
    @Binding var breakDuration: Double // in seconds
    
    let breakDurations: [(value: Double, label: String)] = [
        (20, "20 sec"),
        (30, "30 sec"),
        (60, "60 sec"),
        (120, "120 sec")
    ]
    
    var body: some View {
        SettingsOptionView(
            title: "Break Duration",
            description: "How long would you like your breaks to be?",
            options: breakDurations,
            selectedValue: $breakDuration
        )
    }
}

struct AdvanceNoticeView: View {
    @Binding var preBreakNotification: Double // in minutes
    
    let advanceNoticeOptions: [(value: Double, label: String)] = [
        (0.25, "15 sec"),
        (0.5, "30 sec"),
        (0.75, "45 sec"),
        (1.0, "60 sec")
    ]
    
    var body: some View {
        SettingsOptionView(
            title: "Advance Notice",
            description: "How early would you like to be notified before a break?",
            options: advanceNoticeOptions,
            selectedValue: $preBreakNotification
        )
    }
}

struct NoticeDurationView: View {
    @Binding var noticeDuration: Double // in seconds
    
    let noticeDurationOptions: [(value: Double, label: String)] = [
        (5.0, "5 sec"),
        (10.0, "10 sec"),
        (15.0, "15 sec"),
        (20.0, "20 sec")
    ]
    
    var body: some View {
        SettingsOptionView(
            title: "Notice Duration",
            description: "How long should the notification stay visible?",
            options: noticeDurationOptions,
            selectedValue: $noticeDuration
        )
    }
}

// Update DurationOptionButton to use string value
struct DurationOptionButton: View {
    let value: String // Changed to String to be more flexible
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(value)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(isSelected ? .white : .primary)
                .frame(height: 80)
                .frame(maxWidth: .infinity)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.1))
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.accentColor.opacity(0.7) : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
                    }
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Helper Views

struct NotificationOptionButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.vertical, 10) // Increased padding for better touch area
                .padding(.horizontal, 18) // Increased padding
                .background(
                    Capsule()
                        .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.15))
                        // Adding a subtle stroke for unselected state for better definition
                        .overlay(Capsule().stroke(isSelected ? Color.clear : Color.gray.opacity(0.2), lineWidth: 1))
                )
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Visual Effect View for macOS translucency
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = .active
        return visualEffectView
    }
    
    func updateNSView(_ visualEffectView: NSVisualEffectView, context: Context) {
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
    }
}

struct LaunchAtLoginView: View {
    @State private var isAutoStart = LaunchAtLogin.isEnabled
    
    var body: some View {
        VStack(alignment: .center, spacing: 30) {
            // Icon and Title
            VStack(spacing: 16) {
                Image(systemName: "sunrise")
                    .font(.system(size: 48))
                    .foregroundColor(.accentColor)
                    .symbolEffect(.bounce, value: isAutoStart)
                
                Text("Start at Login")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
            }
            .padding(.top, 20)
            
            // Description
            Text("TakeABreak can start automatically when you log in to your Mac.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            // Modern Toggle Card
            Button(action: {
                withAnimation {
                    isAutoStart.toggle()
                    LaunchAtLogin.isEnabled.toggle()
                }
            }) {
                HStack(spacing: 20) {
                    Circle()
                        .fill(isAutoStart ? Color.accentColor : Color.secondary.opacity(0.2))
                        .frame(width: 24, height: 24)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .opacity(isAutoStart ? 1 : 0)
                        )
                    
                    Text("Start automatically")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isAutoStart ? .primary : .secondary)
                    
                    Spacer()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.secondary.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isAutoStart ? Color.accentColor : Color.clear, lineWidth: 2)
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 40)
            .padding(.top, 20)
            
            Spacer()
            
            // Subtle hint text
            Text("You can change this later in Preferences")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .opacity(0.8)
                .padding(.bottom, 20)
        }
    }
} 
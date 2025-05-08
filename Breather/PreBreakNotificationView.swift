import SwiftUI
import Combine
import AppKit

struct PreBreakNotificationView: View {
    let duration: TimeInterval
    var skipAction: () -> Void
    var takeBreakNowAction: () -> Void
    var postponeAction: () -> Void
    
    @State private var remainingTime: Int
    @State private var countdownTimer: Timer? = nil
    @State private var opacity: Double = 0
    @State private var slideOffset: CGFloat = 500  // Start off-screen
    @State private var isExiting: Bool = false
    
    init(duration: TimeInterval, skipAction: @escaping () -> Void, takeBreakNowAction: @escaping () -> Void, postponeAction: @escaping () -> Void) {
        self.duration = duration
        self.skipAction = skipAction
        self.takeBreakNowAction = takeBreakNowAction
        self.postponeAction = postponeAction
        _remainingTime = State(initialValue: Int(ceil(duration)))
    }
    
    private var formattedTime: String {
        let minutes = remainingTime / 60
        let seconds = remainingTime % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header with icon and text
            HStack(spacing: 16) {
                // Left side with icon and message
                HStack(spacing: 16) {
                    // Icon Circle
                    Circle()
                        .fill(Color.black.opacity(0.05))
                        .frame(width: 42, height: 42)
                        .overlay(
                            Image(systemName: "bell.badge.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(Color.black)
                        )
                    
                    // Encouraging message
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Time to Recharge")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black)
                        
                        Text("Take a moment to refresh")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Timer on the right
                HStack(spacing: 6) {
                    Image(systemName: "timer")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    Text(formattedTime)
                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                        .foregroundColor(.black)
                }
            }
            
            // Buttons in new order
            HStack(spacing: 10) {
                AnimatedButton(
                    action: {
                        performExitAnimation {
                            takeBreakNowAction()
                        }
                    },
                    iconName: "cup.and.saucer.fill",
                    text: "Take Break",
                    type: .primary
                )
                
                AnimatedButton(
                    action: {
                        performExitAnimation {
                            postponeAction()
                        }
                    },
                    iconName: "zzz",
                    text: "Snooze (5m)",
                    type: .secondary
                )
                
                AnimatedButton(
                    action: {
                        performExitAnimation {
                            skipAction()
                        }
                    },
                    iconName: "arrow.counterclockwise",
                    text: "Skip",
                    type: .secondary
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(width: 420, height: 140)
        .background(Color(white: 0.96))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.black.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 5)
        .opacity(opacity)
        .offset(x: slideOffset, y: 0)
        .onAppear {
            NSSound.beep()
            
            // Entry animation
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                slideOffset = 0
                opacity = 1
            }
            
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    private func performExitAnimation(completion: @escaping () -> Void) {
        if isExiting { return }
        isExiting = true
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            slideOffset = 500  // Slide off to the right
            opacity = 0
        }
        
        // Delay action execution to allow animation to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            completion()
        }
    }
    
    private func startTimer() {
        stopTimer()
        
        if remainingTime <= 0 {
            stopTimer()
            return
        }
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if remainingTime > 1 {
                remainingTime -= 1
            } else {
                remainingTime = 0
                stopTimer()
                performExitAnimation {
                    takeBreakNowAction()
                }
            }
        }
        RunLoop.current.add(countdownTimer!, forMode: .common)
    }
    
    private func stopTimer() {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }
}

// Button content view
struct ButtonContent: View {
    let iconName: String
    let text: String
    let type: ButtonType
    
    @State private var isPressed = false
    @GestureState private var isPressing = false
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: iconName)
                .font(.system(size: 12, weight: .medium))
            
            Text(text)
                .font(.system(size: 13, weight: .medium))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 14)
        .foregroundColor(type == .primary ? .white : .black)
        .background(
            Capsule()
                .fill(type == .primary ? Color.black : Color.white)
        )
        .overlay(
            Capsule()
                .strokeBorder(Color.black.opacity(type == .primary ? 0 : 0.15), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(type == .primary ? 0.2 : 0.05), radius: 2, x: 0, y: 1)
        .scaleEffect(isPressing ? 0.95 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.4, blendDuration: 0), value: isPressing)
    }
}

// Updated PreBreakNotificationView buttons
struct AnimatedButton: View {
    let action: () -> Void
    let iconName: String
    let text: String
    let type: ButtonType
    
    var body: some View {
        Button(action: action) {
            ButtonContent(
                iconName: iconName,
                text: text,
                type: type
            )
        }
        .buttonStyle(SpringButtonStyle())
    }
}

// Custom button style for spring animation
struct SpringButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.4, blendDuration: 0), value: configuration.isPressed)
    }
}

// Button style types
enum ButtonType {
    case primary, secondary, tertiary
}

#Preview {
    PreBreakNotificationView(
        duration: 56,
        skipAction: { },
        takeBreakNowAction: { },
        postponeAction: { }
    )
    .padding(50)
    .frame(width: 520, height: 200)
}
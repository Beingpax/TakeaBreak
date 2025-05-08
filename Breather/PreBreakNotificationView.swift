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
    @State private var scale: CGFloat = 0.95
    
    init(duration: TimeInterval, skipAction: @escaping () -> Void, takeBreakNowAction: @escaping () -> Void, postponeAction: @escaping () -> Void) {
        self.duration = duration
        self.skipAction = skipAction
        self.takeBreakNowAction = takeBreakNowAction
        self.postponeAction = postponeAction
        _remainingTime = State(initialValue: Int(ceil(duration)))
    }
    
    private var progress: Double {
        1 - (Double(remainingTime) / Double(duration))
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
                
                // New Circular Timer Design
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(Color.black.opacity(0.05), lineWidth: 3)
                        .frame(width: 52, height: 52)
                    
                    // Progress circle
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.black, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 52, height: 52)
                        .rotationEffect(.degrees(-90))
                    
                    // Time display
                    VStack(spacing: -2) {
                        Text("\(remainingTime)")
                            .font(.system(size: 16, weight: .medium))
                            .monospacedDigit()
                        Text(remainingTime >= 60 ? "min" : "sec")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 52, height: 52)
            }
            
            // Buttons
            HStack(spacing: 10) {
                Button(action: postponeAction) {
                    ButtonContent(
                        iconName: "alarm.fill",
                        text: "Snooze",
                        type: .secondary
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: skipAction) {
                    ButtonContent(
                        iconName: "forward.fill",
                        text: "Skip",
                        type: .secondary
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: takeBreakNowAction) {
                    ButtonContent(
                        iconName: "cup.and.saucer.fill",
                        text: "Take Break",
                        type: .primary
                    )
                }
                .buttonStyle(PlainButtonStyle())
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
        .scaleEffect(scale)
        .onAppear {
            NSSound.beep()
            
            withAnimation(.easeOut(duration: 0.35)) {
                opacity = 1
                scale = 1
            }
            
            startTimer()
        }
        .onDisappear {
            stopTimer()
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
                takeBreakNowAction()
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
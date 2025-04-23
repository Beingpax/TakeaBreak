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
    
    var formattedCountdown: String {
        let minutes = remainingTime / 60
        let seconds = remainingTime % 60
        return remainingTime >= 60 ? String(format: "%d:%02d", minutes, seconds) : String(format: "%d sec", seconds)
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 18) {
            // Icon with subtle background
            Image(systemName: "sparkles") // Changed icon
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 50, height: 50)
                .background(Color.primary.opacity(0.05))
                .clipShape(Circle())

            // Content: Text and Buttons
            VStack(alignment: .leading, spacing: 10) { // Increased spacing
                // Text
                VStack(alignment: .leading, spacing: 3) {
                     Text("Break Time Soon - \(formattedCountdown)") // Updated text
                        .font(.system(size: 15, weight: .medium)) // Slightly smaller
                        .foregroundColor(.primary)
                    Text("A moment to refresh is near.") // Updated text
                         .font(.system(size: 13))
                         .foregroundColor(.secondary)
                }

                // Buttons
                HStack(spacing: 10) { // Increased spacing
                    Button("Start Break", action: takeBreakNowAction)
                        .buttonStyle(SubtleButtonStyle(isProminent: true))

                    Button("Snooze 5 min", action: postponeAction) // Updated text
                        .buttonStyle(SubtleButtonStyle())
                    
                    Button("Skip", action: skipAction)
                        .buttonStyle(SubtleButtonStyle())
                        
                    Spacer() // Push buttons left
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(width: 420, height: 95) // Adjusted size slightly
        .background(.thinMaterial) // Frosted glass effect
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 5)
        .opacity(opacity)
        .scaleEffect(scale)
        .onAppear {
            NSSound.beep() // Play system notification sound
            
            withAnimation(.easeOut(duration: 0.35)) { // Slightly slower animation
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
             // Don't automatically take break - just stop the timer
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

// Subtle button style (no changes needed here for now)
struct SubtleButtonStyle: ButtonStyle {
    var isProminent: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 7) // Slightly more vertical padding
            .background(
                isProminent
                    ? Color.primary.opacity(configuration.isPressed ? 0.25 : 0.15)
                    : Color.primary.opacity(configuration.isPressed ? 0.15 : 0.08)
            )
            .foregroundColor(.primary)
            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}


#Preview {
    PreBreakNotificationView(
        duration: 56,
        skipAction: { print("Skip") },
        takeBreakNowAction: { print("Take Now") },
        postponeAction: { print("Postpone") }
    )
    .padding(50) // Add padding to see shadow in preview
    .frame(width: 520, height: 200)
} 
import SwiftUI
import Combine

struct ReminderView: View {
    let autoDismissDuration: TimeInterval
    var dismissAction: () -> Void
    @ObservedObject var settings: BreatherSettings
    
    @State private var currentTime = Date()
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.95
    @State private var remainingTime: Int
    @State private var countdownTimer: Timer? = nil

    let clockTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    init(autoDismissDuration: TimeInterval, dismissAction: @escaping () -> Void, settings: BreatherSettings) {
        self.autoDismissDuration = autoDismissDuration
        self.dismissAction = dismissAction
        self.settings = settings
        _remainingTime = State(initialValue: Int(ceil(autoDismissDuration)))
    }
    
    var formattedCountdown: String {
        let minutes = remainingTime / 60
        let seconds = remainingTime % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func adjustTime(by seconds: Int) {
        let newTime = max(0, remainingTime + seconds)
        remainingTime = newTime
    }
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 10) {
                Text("Time to Take a Break")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .multilineTextAlignment(.center)
                
                Text("Rest your eyes and stretch your body")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.top, 60)
            
            // Current time
            Text(currentTime, formatter: dateFormatter)
                .font(.system(size: 72, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .padding(.vertical, 15)
                .onReceive(clockTimer) { _ in
                    currentTime = Date()
                }
            
            // Break suggestions
            VStack(spacing: 22) {
                SuggestionRow(
                    icon: "eye", 
                    title: "Look away", 
                    description: "Focus on something at least 20 feet away for 20 seconds"
                )
                
                SuggestionRow(
                    icon: "figure.walk", 
                    title: "Stand up", 
                    description: "Take a short walk or do some light stretching"
                )
                
                SuggestionRow(
                    icon: "cup.and.saucer", 
                    title: "Hydrate", 
                    description: "Drink some water to stay hydrated"
                )
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 30)
            .frame(maxWidth: 600)
            .background(Color.white.opacity(0.08))
            .cornerRadius(20)
            
            Spacer()
            
            // Countdown Timer with adjustment buttons
            HStack(spacing: 24) {
                // Decrease button
                Button(action: { adjustTime(by: -Int(autoDismissDuration)) }) {
                    Image(systemName: "minus.circle")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.8))
                }
                .buttonStyle(.plain)
                
                // Timer display
                VStack(spacing: 8) {
                    Text("Resuming in")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(formattedCountdown)
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
                
                // Increase button
                Button(action: { adjustTime(by: Int(autoDismissDuration)) }) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 60)
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            ZStack {
                Image(settings.selectedWallpaper)
                    .resizable()
                    .scaledToFill()
                    .blur(radius: 10)
                Color.black.opacity(0.2)
            }
            .edgesIgnoringSafeArea(.all)
        )
        .opacity(opacity)
        .scaleEffect(scale)
        .onAppear {
            withAnimation(.easeOut(duration: 0.7)) {
                opacity = 1
                scale = 1
            }
            startTimers()
        }
        .onDisappear {
            stopCountdownTimer()
        }
    }
    
    private func startTimers() {
        if countdownTimer == nil {
            remainingTime = Int(ceil(autoDismissDuration))
            countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                if remainingTime > 0 {
                    remainingTime -= 1
                } else {
                    autoDismiss()
                }
            }
        }
    }

    private func stopCountdownTimer() {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }

    private func autoDismiss() {
        stopCountdownTimer()
        withAnimation(.easeIn(duration: 0.3)) {
            opacity = 0
            scale = 0.9
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            dismissAction()
        }
    }
}

// Helper components
struct SuggestionRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 18) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.white)
                .frame(width: 48, height: 48)
                .background(Color.white.opacity(0.15))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
            }
            
            Spacer()
        }
    }
}

struct DismissButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding(.vertical, 18)
            .padding(.horizontal, 36)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.2, green: 0.4, blue: 0.8), Color(red: 0.3, green: 0.5, blue: 0.9)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .opacity(configuration.isPressed ? 0.8 : 1)
            )
            .cornerRadius(30)
            .shadow(color: Color(red: 0.2, green: 0.4, blue: 0.8).opacity(0.5), radius: configuration.isPressed ? 5 : 10, x: 0, y: configuration.isPressed ? 2 : 5)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview {
    ReminderView(autoDismissDuration: 30, dismissAction: {}, settings: BreatherSettings())
}

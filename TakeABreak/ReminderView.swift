import SwiftUI
import Combine
import AppKit

struct ReminderView: View {
    let autoDismissDuration: TimeInterval
    var dismissAction: () -> Void
    @ObservedObject var settings: TakeABreakSettings
    @ObservedObject var timerManager: TimerManager
    let motivationalQuote: String
    
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.95
    @State private var showLockError = false
    @State private var isDismissButtonDisabled = true
    @State private var currentTime = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    init(autoDismissDuration: TimeInterval, 
         dismissAction: @escaping () -> Void, 
         settings: TakeABreakSettings, 
         timerManager: TimerManager,
         motivationalQuote: String) {
        self.autoDismissDuration = autoDismissDuration
        self.dismissAction = dismissAction
        self.settings = settings
        self.timerManager = timerManager
        self.motivationalQuote = motivationalQuote
    }
    
    var formattedCountdown: String {
        return timerManager.formattedBreakCountdown()
    }
    
    var formattedCurrentTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: currentTime)
    }
    
    func adjustTime(by seconds: Int) {
        timerManager.adjustBreakTime(by: seconds)
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            GeometryReader { geometry in
                ZStack {
                    Image(settings.selectedWallpaper)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(
                            width: geometry.size.width + 20,
                            height: geometry.size.height + 20
                        )
                        .position(
                            x: geometry.size.width/2,
                            y: geometry.size.height/2
                        )
                        .blur(radius: 10)
                        .clipped()

                    Color.black.opacity(0.2)
                }
            }
            .ignoresSafeArea()
            
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // Top section with equal height as bottom
                    VStack(spacing: 16) {
                        Text("Time to Take a Break")
                            .font(.system(size: 52, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, .white.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .multilineTextAlignment(.center)
                        
                        Text("Rest your eyes and stretch your body")
                            .font(.system(size: 22, weight: .regular, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            
                        Text(formattedCurrentTime)
                            .font(.system(size: 40, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.top, 8)
                    }
                    .padding(.top, 60)
                    .frame(height: geometry.size.height * 0.3)
                    
                    // Center section - Motivational quote
                    Spacer()
                    
                    Text(motivationalQuote)
                        .font(.system(size: 50, weight: .semibold, design: .rounded))
                        .italic()
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.5)
                        .padding(.horizontal, 40)
                    
                    Spacer()
                    
                    // Bottom section with equal height as top
                    VStack(spacing: 16) {
                        Text(formattedCountdown)
                            .font(.system(size: 92, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(minWidth: 180)

                        HStack(alignment: .center, spacing: 40) {
                            Button(action: {
                                do {
                                    let task = Process()
                                    task.launchPath = "/usr/bin/pmset"
                                    task.arguments = ["displaysleepnow"]
                                    try task.run()
                                } catch {
                                    showLockError = true
                                }
                            }) {
                                VStack(spacing: 6) {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 34))
                                    Text("Lock Screen")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .frame(width: 100)
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.white.opacity(0.8))

                            Button(action: {
                                adjustTime(by: Int(autoDismissDuration))
                            }) {
                                VStack(spacing: 6) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 34, weight: .semibold))
                                    Text("Add Time")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .frame(width: 100)
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.white.opacity(0.8))
                            
                            Button(action: {
                                autoDismiss()
                            }) {
                                VStack(spacing: 6) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 34, weight: .semibold))
                                    Text("Dismiss")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .frame(width: 100)
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.white.opacity(0.8))
                            .disabled(isDismissButtonDisabled)
                        }
                    }
                    .padding(.bottom, 60)
                    .frame(height: geometry.size.height * 0.3)
                }
                .padding(.horizontal, 40)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .opacity(opacity)
        .scaleEffect(scale)
        .onAppear {
            NSSound(named: "Hero")?.play()

            withAnimation(.easeOut(duration: 0.7)) {
                opacity = 1
                scale = 1
            }
            
            self.isDismissButtonDisabled = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 7.0) {
                self.isDismissButtonDisabled = false
            }
        }
        .onReceive(timerManager.$remainingBreakTime) { time in
            if time <= 0 {
                autoDismiss()
            }
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }

    private func autoDismiss() {
        withAnimation(.easeIn(duration: 0.3)) {
            opacity = 0
            scale = 0.9
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            dismissAction()
        }
    }
}

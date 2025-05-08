import SwiftUI
import Combine
import AppKit

struct ReminderView: View {
    let autoDismissDuration: TimeInterval
    var dismissAction: () -> Void
    @ObservedObject var settings: BreatherSettings
    @ObservedObject var timerManager: TimerManager
    let motivationalQuote: String
    
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.95
    @State private var showLockError = false
    @State private var isDismissButtonDisabled = true
    
    init(autoDismissDuration: TimeInterval, 
         dismissAction: @escaping () -> Void, 
         settings: BreatherSettings, 
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
            
            VStack(spacing: 0) {
                VStack(spacing: 15) {
                    Text("Time to Take a Break")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .multilineTextAlignment(.center)
                    
                    Text("Rest your eyes and stretch your body")
                        .font(.system(size: 24, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 60)
                
                Spacer()
                
                Text(motivationalQuote)
                    .font(.system(size: 80, weight: .semibold, design: .rounded))
                    .italic()
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.5)
                    .padding(.horizontal, 40)
                
                Spacer()
                
                VStack(spacing: 20) {
                    Text(formattedCountdown)
                        .font(.system(size: 96, weight: .bold, design: .rounded))
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
                            VStack(spacing: 8) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 36))
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
                            VStack(spacing: 8) {
                                Image(systemName: "plus")
                                    .font(.system(size: 36, weight: .semibold))
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
                            VStack(spacing: 8) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 36, weight: .semibold))
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
            }
            .padding(.horizontal, 40)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .opacity(opacity)
        .scaleEffect(scale)
        .onAppear {
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

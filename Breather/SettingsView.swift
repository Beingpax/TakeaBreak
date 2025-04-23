import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: BreatherSettings
    
    @State private var durationMinutesString: String = ""
    @State private var autoDismissSecondsString: String = ""
    @State private var preNotificationTimeString: String = ""
    @State private var preNotificationDurationString: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Breather Settings")
                .font(.title)
                .padding(.bottom, 5)
            
            Divider()
            
            VStack(alignment: .leading) {
                Text("Break Interval")
                    .font(.headline)
                HStack {
                    TextField("Minutes", text: $durationMinutesString)
                        .frame(width: 80)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: durationMinutesString) {
                            updateBreakInterval()
                        }
                    Text("minutes")
                }
            }
            .padding(.bottom, 10)
            
            VStack(alignment: .leading) {
                Text("Auto-dismiss Delay")
                    .font(.headline)
                HStack {
                    TextField("Seconds", text: $autoDismissSecondsString)
                        .frame(width: 80)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: autoDismissSecondsString) {
                            updateAutoDismissDuration()
                        }
                    Text("seconds")
                }
            }
            .padding(.bottom, 10)
            
            VStack(alignment: .leading) {
                Text("Pre-break Notification")
                    .font(.headline)
                HStack {
                    TextField("Seconds", text: $preNotificationTimeString)
                        .frame(width: 80)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: preNotificationTimeString) {
                            updatePreNotificationTime()
                        }
                    Text("seconds before break")
                }
            }
            .padding(.bottom, 10)
            
            VStack(alignment: .leading) {
                Text("Notification Duration")
                    .font(.headline)
                HStack {
                    TextField("Seconds", text: $preNotificationDurationString)
                        .frame(width: 80)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: preNotificationDurationString) {
                            updatePreNotificationDuration()
                        }
                    Text("seconds")
                }
            }
            .padding(.bottom, 10)
            
            Toggle("Enable break reminders", isOn: $settings.isEnabled)
                .toggleStyle(.switch)
            
            Spacer()
        }
        .frame(width: 350, height: 300)
        .padding()
        .onAppear(perform: loadInitialValues)
    }
    
    private func loadInitialValues() {
        let intervalInSeconds = settings.breakInterval
        let intervalInMinutes = intervalInSeconds / 60.0
        durationMinutesString = String(format: "%g", intervalInMinutes)
        
        autoDismissSecondsString = String(Int(settings.autoDismissDuration))
        preNotificationTimeString = String(Int(settings.preBreakNotificationTime))
        preNotificationDurationString = String(Int(settings.preBreakNotificationDuration))
    }
    
    private func updateBreakInterval() {
        guard let minutesValue = Double(durationMinutesString), minutesValue > 0 else {
             return
        }
        
        let newIntervalInSeconds = minutesValue * 60.0
        
        if abs(settings.breakInterval - newIntervalInSeconds) > 0.1 { 
             settings.breakInterval = newIntervalInSeconds
        }
    }
    
    private func updateAutoDismissDuration() {
        // Ensure minimum value is 1 second
        guard let secondsValue = Double(autoDismissSecondsString), secondsValue >= 1 else {
            // Optionally revert the string or show an error if input is invalid
            return
        }
        if abs(settings.autoDismissDuration - secondsValue) > 0.1 {
            settings.autoDismissDuration = secondsValue
        }
    }
    
    private func updatePreNotificationTime() {
        guard let secondsValue = Double(preNotificationTimeString), secondsValue >= 1 else {
            return
        }
        if abs(settings.preBreakNotificationTime - secondsValue) > 0.1 {
            settings.preBreakNotificationTime = secondsValue
        }
    }
    
    private func updatePreNotificationDuration() {
        guard let secondsValue = Double(preNotificationDurationString), secondsValue >= 1 else {
            return
        }
        if abs(settings.preBreakNotificationDuration - secondsValue) > 0.1 {
            settings.preBreakNotificationDuration = secondsValue
        }
    }
}

#Preview {
    let dummyTimerManager = TimerManager()
    let dummySettings = BreatherSettings(timerManager: dummyTimerManager)
    dummySettings.breakInterval = 120
    dummySettings.autoDismissDuration = 30 // Example dismiss duration
    dummySettings.preBreakNotificationTime = 30 // 30 seconds before break
    dummySettings.preBreakNotificationDuration = 10 // 10 seconds duration
    return SettingsView(settings: dummySettings)
} 
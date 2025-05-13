import SwiftUI
import AppKit

class OnboardingWindowManager: NSObject {
    private var onboardingWindow: NSPanel?
    private var onboardingHostingView: NSHostingView<OnboardingView>?
    private var settings: TakeABreakSettings
    private var onCompletionHandler: (() -> Void)?
    
    init(settings: TakeABreakSettings, onCompletionHandler: (() -> Void)? = nil) {
        self.settings = settings
        self.onCompletionHandler = onCompletionHandler
        super.init()
    }
    
    func showOnboardingWindow() {
        closeOnboardingWindow()
        
        NSApp.setActivationPolicy(.accessory)
        
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 520),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        let contentView = OnboardingView(settings: settings) { [weak self] in
            self?.onboardingCompleted()
        }
        
        let hostingView = NSHostingView(rootView: contentView)
        panel.contentView = hostingView
        
        panel.center()
        
        panel.isReleasedWhenClosed = false
        
        onboardingWindow = panel
        onboardingHostingView = hostingView
        
        NSApp.activate(ignoringOtherApps: true)
        panel.orderFrontRegardless()
        
        panel.delegate = self
    }
    
    func closeOnboardingWindow() {
        onboardingWindow?.close()
        onboardingWindow = nil
        onboardingHostingView = nil
    }
    
    private func onboardingCompleted() {
        closeOnboardingWindow()
        
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(.accessory)
        }
        
        onCompletionHandler?()
    }
}

extension OnboardingWindowManager: NSWindowDelegate {
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if !settings.hasCompletedOnboarding {
            return false
        }
        return true
    }
} 
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
        // Close any existing window first
        closeOnboardingWindow()
        
        // Create a new panel with no title bar
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 520),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        // Configure panel appearance for a completely borderless look
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        
        // Set panel behavior
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // Create content view with a close handler to ensure users can exit
        let contentView = OnboardingView(settings: settings) { [weak self] in
            self?.onboardingCompleted()
        }
        
        let hostingView = NSHostingView(rootView: contentView)
        panel.contentView = hostingView
        
        // Center panel on screen
        panel.center()
        
        // Configure panel properties
        panel.isReleasedWhenClosed = false
        
        // Store references
        onboardingWindow = panel
        onboardingHostingView = hostingView
        
        // Show the panel
        NSApp.activate(ignoringOtherApps: true)
        panel.orderFrontRegardless()
        
        // Add panel delegate
        panel.delegate = self
    }
    
    func closeOnboardingWindow() {
        onboardingWindow?.close()
        onboardingWindow = nil
        onboardingHostingView = nil
    }
    
    private func onboardingCompleted() {
        closeOnboardingWindow()
        onCompletionHandler?()
    }
}

// MARK: - Window Delegate
extension OnboardingWindowManager: NSWindowDelegate {
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // For borderless windows, this might not be called since there's no close button,
        // but we'll keep it in case we programmatically close the window
        if !settings.hasCompletedOnboarding {
            return false
        }
        return true
    }
} 
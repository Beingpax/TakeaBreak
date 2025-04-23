import AppKit

// A custom NSPanel subclass that allows becoming the key window
// even when borderless, necessary for receiving keyboard events directly.
class KeyablePanel: NSPanel {
    // Override canBecomeKey to allow the panel to receive keyboard events
    override var canBecomeKey: Bool {
        return true // Allow this panel to become key
    }
} 
import SwiftUI
import AppKit

@main
struct EngramDesktopApp: App {
    @StateObject private var supervisor = DaemonSupervisor.shared
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarPopoverView(
                onOpenHUD: { WindowManager.shared.showHUD() },
                onOpenWiring: { WindowManager.shared.showWiring() },
                onOpenSync: { WindowManager.shared.showSync() },
                onOpenLogs: { WindowManager.shared.showLogs() }
            )
        } label: {
            Image(nsImage: .engramMenuIcon)
        }
        .menuBarExtraStyle(.window)
    }
}

// MARK: - App Delegate & Hotkey Support
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Auto-check and auto-start daemon on launch
        Task { @MainActor in
            await DaemonSupervisor.shared.checkHealth()
            if DaemonSupervisor.shared.state != .running {
                DaemonSupervisor.shared.start()
            }
        }

        // Global hotkey monitor for Cmd+Shift+M
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            if event.modifierFlags.contains([.command, .shift]) && event.charactersIgnoringModifiers?.lowercased() == "m" {
                Task { @MainActor in
                    WindowManager.shared.toggleHUD()
                }
            }
        }
    }
}

// MARK: - Window Manager
@MainActor
final class WindowManager {
    static let shared = WindowManager()

    private var hudWindow: NSPanel?
    private var wiringWindow: NSWindow?
    private var syncWindow: NSWindow?
    private var logWindow: NSWindow?

    func toggleHUD() {
        if let hud = hudWindow, hud.isVisible {
            hud.orderOut(nil)
        } else {
            showHUD()
        }
    }

    func showHUD() {
        if hudWindow == nil {
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 580, height: 420),
                styleMask: [.titled, .closable, .fullSizeContentView, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.isFloatingPanel = true
            panel.level = .floating
            panel.titleVisibility = .hidden
            panel.titlebarAppearsTransparent = true
            panel.isMovableByWindowBackground = true
            panel.contentView = NSHostingView(rootView: QuickRecallHUDView())
            self.hudWindow = panel
        }

        guard let hud = hudWindow else { return }
        hud.center()
        hud.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func showWiring() {
        if wiringWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 440, height: 320),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "Agent Integrations"
            window.contentView = NSHostingView(rootView: AgentWiringView())
            self.wiringWindow = window
        }

        wiringWindow?.center()
        wiringWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func showSync() {
        if syncWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 440, height: 280),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "Zero-Knowledge Sync"
            window.contentView = NSHostingView(rootView: SyncView())
            self.syncWindow = window
        }

        syncWindow?.center()
        syncWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func showLogs() {
        if logWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 520, height: 350),
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.title = "Daemon Logs"
            window.contentView = NSHostingView(rootView: DaemonLogView())
            self.logWindow = window
        }

        logWindow?.center()
        logWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - Menu Bar Template Icon
extension NSImage {
    static let engramMenuIcon: NSImage = {
        let size = NSSize(width: 18, height: 18)
        let img = NSImage(size: size, flipped: false) { rect in
            let scale = 18.0 / 512.0
            let path = NSBezierPath()
            // Invert Y for NSBezierPath coordinate system
            path.move(to: NSPoint(x: 424 * scale, y: (512 - 80) * scale))
            path.line(to: NSPoint(x: 224 * scale, y: (512 - 80) * scale))
            path.curve(
                to: NSPoint(x: 40 * scale, y: (512 - 264) * scale),
                controlPoint1: NSPoint(x: 122.4 * scale, y: (512 - 80) * scale),
                controlPoint2: NSPoint(x: 40 * scale, y: (512 - 162.4) * scale)
            )
            path.curve(
                to: NSPoint(x: 224 * scale, y: (512 - 448) * scale),
                controlPoint1: NSPoint(x: 40 * scale, y: (512 - 365.6) * scale),
                controlPoint2: NSPoint(x: 122.4 * scale, y: (512 - 448) * scale)
            )
            path.line(to: NSPoint(x: 424 * scale, y: (512 - 448) * scale))
            path.line(to: NSPoint(x: 424 * scale, y: (512 - 384) * scale))
            path.line(to: NSPoint(x: 224 * scale, y: (512 - 384) * scale))
            path.curve(
                to: NSPoint(x: 104 * scale, y: (512 - 264) * scale),
                controlPoint1: NSPoint(x: 157.7 * scale, y: (512 - 384) * scale),
                controlPoint2: NSPoint(x: 104 * scale, y: (512 - 330.3) * scale)
            )
            path.curve(
                to: NSPoint(x: 224 * scale, y: (512 - 144) * scale),
                controlPoint1: NSPoint(x: 104 * scale, y: (512 - 197.7) * scale),
                controlPoint2: NSPoint(x: 157.7 * scale, y: (512 - 144) * scale)
            )
            path.line(to: NSPoint(x: 360 * scale, y: (512 - 144) * scale))
            path.line(to: NSPoint(x: 360 * scale, y: (512 - 224) * scale))
            path.line(to: NSPoint(x: 208 * scale, y: (512 - 224) * scale))
            path.line(to: NSPoint(x: 208 * scale, y: (512 - 288) * scale))
            path.line(to: NSPoint(x: 424 * scale, y: (512 - 288) * scale))
            path.close()
            NSColor.black.setFill()
            path.fill()
            return true
        }
        img.isTemplate = true
        return img
    }()
}

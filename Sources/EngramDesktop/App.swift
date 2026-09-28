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
                onOpenLogs: { WindowManager.shared.showLogs() }
            )
        } label: {
            EngramLogoView(size: 16, primaryColor: .primary, traceColor: Color(NSColor.windowBackgroundColor))
        }
        .menuBarExtraStyle(.window)
    }
}

// MARK: - App Delegate & Hotkey Support
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Auto-check daemon on launch
        Task { @MainActor in
            await DaemonSupervisor.shared.checkHealth()
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

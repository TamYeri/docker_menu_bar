import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var viewModel = ContainerViewModel()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupMenuBarItem()
        setupLaunchAtStartup()
    }

    private func setupMenuBarItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            let dockerIcon = NSImage(systemSymbolName: "cube.box.fill", accessibilityDescription: "Docker")
            dockerIcon?.size = NSSize(width: 18, height: 18)

            if let icon = dockerIcon {
                let coloredIcon = icon.copy() as! NSImage
                coloredIcon.lockFocus()
                NSColor(red: 30/255, green: 166/255, blue: 225/255, alpha: 1.0).set()
                NSRect(origin: .zero, size: coloredIcon.size).fill(using: .sourceAtop)
                coloredIcon.unlockFocus()
                button.image = coloredIcon
            }

            button.toolTip = NSLocalizedString("docker_menubar", comment: "")
            button.target = self
            button.action = #selector(togglePopover(_:))
        }

        popover = NSPopover()
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(rootView: PopoverView(viewModel: viewModel))

        viewModel.refresh()

        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.viewModel.refresh()
        }
    }

    @objc private func togglePopover(_ sender: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            if let button = statusItem.button {
                viewModel.refresh()
                NSApp.activate(ignoringOtherApps: true)
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }

    private func setupLaunchAtStartup() {
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.dockermenubar.app"
        let appPath = Bundle.main.bundlePath

        let plistContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>\(bundleIdentifier)</string>
            <key>ProgramArguments</key>
            <array>
                <string>\(appPath)/Contents/MacOS/DockerMenuBar</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
            <key>KeepAlive</key>
            <false/>
        </dict>
        </plist>
        """

        let launchAgentPath = NSHomeDirectory() + "/Library/LaunchAgents/\(bundleIdentifier).plist"

        do {
            let launchAgentsDir = NSHomeDirectory() + "/Library/LaunchAgents"
            try FileManager.default.createDirectory(atPath: launchAgentsDir, withIntermediateDirectories: true, attributes: nil)
            try plistContent.write(toFile: launchAgentPath, atomically: true, encoding: .utf8)
        } catch {
            print("Launch agent oluşturulamadı: \(error)")
        }
    }
}

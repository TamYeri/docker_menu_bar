//
//  DockerMenuBarApp.swift
//  DockerMenuBar
//
//  Created by Mesut KURT on 14.09.2025.
//

import SwiftUI

@main
struct DockerMenuBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var dockerManager = DockerManager()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        
        setupMenuBarItem()
        
        // Otomatik başlangıç için launch agent ayarla
        setupLaunchAtStartup()
    }
    
    private func setupMenuBarItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            // Docker benzeri ikonu kullan - shippingbox daha uygun
            let dockerIcon = NSImage(systemSymbolName: "cube.box.fill", accessibilityDescription: "Docker")
            dockerIcon?.size = NSSize(width: 18, height: 18)
            
            // İkonu mavi renge çevir
            if let icon = dockerIcon {
                let coloredIcon = icon.copy() as! NSImage
                coloredIcon.lockFocus()
                NSColor(red: 30/255, green: 166/255, blue: 225/255, alpha: 1.0).set()
                NSRect(origin: .zero, size: coloredIcon.size).fill(using: .sourceAtop)
                coloredIcon.unlockFocus()
                button.image = coloredIcon
            }
            
            button.toolTip = NSLocalizedString("docker_menubar", comment: "MenuBar tooltip")
        }
        
        updateMenu()
        
        // Her 5 saniyede bir menüyü güncelle
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            self.updateMenu()
        }
    }
    
    private func updateMenu() {
        let menu = NSMenu()
        
        // Önce Docker'ın çalışıp çalışmadığını kontrol et
        dockerManager.isDockerRunning { isRunning in
            if !isRunning {
                DispatchQueue.main.async {
                    menu.removeAllItems()
                    
                    let errorItem = NSMenuItem(title: NSLocalizedString("docker_not_running", comment: "Docker not running"), action: nil, keyEquivalent: "")
                    errorItem.isEnabled = false
                    menu.addItem(errorItem)
                    
                    let infoItem = NSMenuItem(title: NSLocalizedString("start_docker_engine", comment: "Start Docker Engine"), action: nil, keyEquivalent: "")
                    infoItem.isEnabled = false
                    menu.addItem(infoItem)
                    
                    menu.addItem(NSMenuItem.separator())
                    
                    let refreshItem2 = NSMenuItem(title: NSLocalizedString("refresh", comment: "Refresh"), action: #selector(self.refreshContainers), keyEquivalent: "r")
                    refreshItem2.image = NSImage(systemSymbolName: "arrow.clockwise.circle", accessibilityDescription: NSLocalizedString("refresh_accessibility", comment: "Refresh accessibility"))
                    menu.addItem(refreshItem2)
                    
                    let donateItem2 = NSMenuItem(title: NSLocalizedString("donate", comment: "Donate"), action: #selector(self.openDonationPage), keyEquivalent: "")
                    donateItem2.image = NSImage(systemSymbolName: "heart.fill", accessibilityDescription: NSLocalizedString("donate_accessibility", comment: "Donate accessibility"))
                    menu.addItem(donateItem2)
                    
                    let quitItem2 = NSMenuItem(title: NSLocalizedString("quit", comment: "Quit"), action: #selector(self.quit), keyEquivalent: "q")
                    quitItem2.image = NSImage(systemSymbolName: "power", accessibilityDescription: NSLocalizedString("quit_accessibility", comment: "Quit accessibility"))
                    menu.addItem(quitItem2)
                    
                    self.statusItem.menu = menu
                }
                return
            }
            
            // Docker çalışıyorsa konteynerları al
            self.dockerManager.getContainers { containers in
                DispatchQueue.main.async {
                    menu.removeAllItems()
                    
                    if containers.isEmpty {
                        let noContainersItem = NSMenuItem(title: NSLocalizedString("no_containers_found", comment: "No containers found"), action: nil, keyEquivalent: "")
                        noContainersItem.isEnabled = false
                        menu.addItem(noContainersItem)
                    } else {
                        // Konteynerları listele
                        for container in containers {
                            let containerMenu = NSMenu()
                            
                            // Konteyner durum kontrolü
                            let statusIcon = container.isRunning ? "🟢" : "🔴"
                            let containerItem = NSMenuItem(title: "\(statusIcon) \(container.name)", action: nil, keyEquivalent: "")
                            
                            // Alt menüler
                            if container.isRunning {
                                let stopItem = NSMenuItem(title: NSLocalizedString("stop", comment: "Stop"), action: #selector(self.stopContainer(_:)), keyEquivalent: "")
                                stopItem.image = NSImage(systemSymbolName: "stop.fill", accessibilityDescription: NSLocalizedString("stop_accessibility", comment: "Stop accessibility"))
                                containerMenu.addItem(stopItem)
                                
                                let restartItem = NSMenuItem(title: NSLocalizedString("restart", comment: "Restart"), action: #selector(self.restartContainer(_:)), keyEquivalent: "")
                                restartItem.image = NSImage(systemSymbolName: "arrow.clockwise", accessibilityDescription: NSLocalizedString("restart_accessibility", comment: "Restart accessibility"))
                                containerMenu.addItem(restartItem)
                                
                                let terminalItem = NSMenuItem(title: NSLocalizedString("open_bash", comment: "Open Bash"), action: #selector(self.openTerminal(_:)), keyEquivalent: "")
                                terminalItem.image = NSImage(systemSymbolName: "terminal", accessibilityDescription: NSLocalizedString("terminal_accessibility", comment: "Terminal accessibility"))
                                containerMenu.addItem(terminalItem)
                                
                                let logsItem = NSMenuItem(title: NSLocalizedString("show_logs", comment: "Show Logs"), action: #selector(self.showLogs(_:)), keyEquivalent: "")
                                logsItem.image = NSImage(systemSymbolName: "doc.text", accessibilityDescription: NSLocalizedString("logs_accessibility", comment: "Logs accessibility"))
                                containerMenu.addItem(logsItem)
                            } else {
                                let startItem = NSMenuItem(title: NSLocalizedString("start", comment: "Start"), action: #selector(self.startContainer(_:)), keyEquivalent: "")
                                startItem.image = NSImage(systemSymbolName: "play.fill", accessibilityDescription: NSLocalizedString("start_accessibility", comment: "Start accessibility"))
                                containerMenu.addItem(startItem)
                            }
                            
                            containerMenu.addItem(NSMenuItem.separator())
                            
                            let removeItem = NSMenuItem(title: NSLocalizedString("delete", comment: "Delete"), action: #selector(self.removeContainer(_:)), keyEquivalent: "")
                            removeItem.image = NSImage(systemSymbolName: "trash", accessibilityDescription: NSLocalizedString("delete_accessibility", comment: "Delete accessibility"))
                            containerMenu.addItem(removeItem)
                            
                            // Her alt menü öğesine konteyner ID'sini ekle
                            for item in containerMenu.items {
                                item.representedObject = container.id
                            }
                            
                            containerItem.submenu = containerMenu
                            menu.addItem(containerItem)
                        }
                    }
                    
                    menu.addItem(NSMenuItem.separator())
                    
                    let refreshItem = NSMenuItem(title: NSLocalizedString("refresh", comment: "Refresh"), action: #selector(self.refreshContainers), keyEquivalent: "r")
                    refreshItem.image = NSImage(systemSymbolName: "arrow.clockwise.circle", accessibilityDescription: NSLocalizedString("refresh_accessibility", comment: "Refresh accessibility"))
                    menu.addItem(refreshItem)
                    
                    let donateItem = NSMenuItem(title: NSLocalizedString("donate", comment: "Donate"), action: #selector(self.openDonationPage), keyEquivalent: "")
                    donateItem.image = NSImage(systemSymbolName: "heart.fill", accessibilityDescription: NSLocalizedString("donate_accessibility", comment: "Donate accessibility"))
                    menu.addItem(donateItem)
                    
                    let quitItem = NSMenuItem(title: NSLocalizedString("quit", comment: "Quit"), action: #selector(self.quit), keyEquivalent: "q")
                    quitItem.image = NSImage(systemSymbolName: "power", accessibilityDescription: NSLocalizedString("quit_accessibility", comment: "Quit accessibility"))
                    menu.addItem(quitItem)
                    
                    self.statusItem.menu = menu
                }
            }
        }
    }
    
    @objc private func refreshContainers() {
        updateMenu()
    }
    
    @objc private func startContainer(_ sender: NSMenuItem) {
        guard let containerID = sender.representedObject as? String else { return }
        dockerManager.startContainer(id: containerID) { success in
            if success {
                DispatchQueue.main.async {
                    self.updateMenu()
                }
            }
        }
    }
    
    @objc private func stopContainer(_ sender: NSMenuItem) {
        guard let containerID = sender.representedObject as? String else { return }
        dockerManager.stopContainer(id: containerID) { success in
            if success {
                DispatchQueue.main.async {
                    self.updateMenu()
                }
            }
        }
    }
    
    @objc private func restartContainer(_ sender: NSMenuItem) {
        guard let containerID = sender.representedObject as? String else { return }
        dockerManager.restartContainer(id: containerID) { success in
            if success {
                DispatchQueue.main.async {
                    self.updateMenu()
                }
            }
        }
    }
    
    @objc private func removeContainer(_ sender: NSMenuItem) {
        guard let containerID = sender.representedObject as? String else { return }
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("container_delete_title", comment: "Container delete title")
        alert.informativeText = NSLocalizedString("container_delete_message", comment: "Container delete message")
        alert.alertStyle = .warning
        alert.addButton(withTitle: NSLocalizedString("delete_button", comment: "Delete button"))
        alert.addButton(withTitle: NSLocalizedString("cancel_button", comment: "Cancel button"))
        
        if alert.runModal() == .alertFirstButtonReturn {
            dockerManager.removeContainer(id: containerID) { success in
                if success {
                    DispatchQueue.main.async {
                        self.updateMenu()
                    }
                }
            }
        }
    }
    
    @objc private func openTerminal(_ sender: NSMenuItem) {
        guard let containerID = sender.representedObject as? String else { return }
        dockerManager.openTerminal(containerID: containerID)
    }
    
    @objc private func showLogs(_ sender: NSMenuItem) {
        guard let containerID = sender.representedObject as? String else { return }
        dockerManager.showLogs(containerID: containerID)
    }
    
    @objc private func openDonationPage() {
        if let url = URL(string: "https://www.iddef.org/") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc private func quit() {
        NSApplication.shared.terminate(nil)
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
        
        // Launch agent dosyasını oluştur
        do {
            let launchAgentsDir = NSHomeDirectory() + "/Library/LaunchAgents"
            try FileManager.default.createDirectory(atPath: launchAgentsDir, withIntermediateDirectories: true, attributes: nil)
            try plistContent.write(toFile: launchAgentPath, atomically: true, encoding: .utf8)
        } catch {
            print("Launch agent oluşturulamadı: \(error)")
        }
    }
}

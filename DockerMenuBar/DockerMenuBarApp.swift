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
            
            button.toolTip = "Docker MenuBar"
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
                    
                    let errorItem = NSMenuItem(title: "⚠️ Docker Engine çalışmıyor", action: nil, keyEquivalent: "")
                    errorItem.isEnabled = false
                    menu.addItem(errorItem)
                    
                    let infoItem = NSMenuItem(title: "Docker Engine'i başlatın", action: nil, keyEquivalent: "")
                    infoItem.isEnabled = false
                    menu.addItem(infoItem)
                    
                    menu.addItem(NSMenuItem.separator())
                    
                    let refreshItem2 = NSMenuItem(title: "Yenile", action: #selector(self.refreshContainers), keyEquivalent: "r")
                    refreshItem2.image = NSImage(systemSymbolName: "arrow.clockwise.circle", accessibilityDescription: "Yenile")
                    menu.addItem(refreshItem2)
                    
                    menu.addItem(NSMenuItem.separator())
                    
                    let quitItem2 = NSMenuItem(title: "Çıkış", action: #selector(self.quit), keyEquivalent: "q")
                    quitItem2.image = NSImage(systemSymbolName: "power", accessibilityDescription: "Çıkış")
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
                        let noContainersItem = NSMenuItem(title: "Docker konteyner bulunamadı", action: nil, keyEquivalent: "")
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
                                let stopItem = NSMenuItem(title: "Durdur", action: #selector(self.stopContainer(_:)), keyEquivalent: "")
                                stopItem.image = NSImage(systemSymbolName: "stop.fill", accessibilityDescription: "Durdur")
                                containerMenu.addItem(stopItem)
                                
                                let restartItem = NSMenuItem(title: "Yeniden Başlat", action: #selector(self.restartContainer(_:)), keyEquivalent: "")
                                restartItem.image = NSImage(systemSymbolName: "arrow.clockwise", accessibilityDescription: "Yeniden Başlat")
                                containerMenu.addItem(restartItem)
                                
                                let terminalItem = NSMenuItem(title: "Bash Ekranını Aç", action: #selector(self.openTerminal(_:)), keyEquivalent: "")
                                terminalItem.image = NSImage(systemSymbolName: "terminal", accessibilityDescription: "Terminal")
                                containerMenu.addItem(terminalItem)
                                
                                let logsItem = NSMenuItem(title: "Logları Göster", action: #selector(self.showLogs(_:)), keyEquivalent: "")
                                logsItem.image = NSImage(systemSymbolName: "doc.text", accessibilityDescription: "Loglar")
                                containerMenu.addItem(logsItem)
                            } else {
                                let startItem = NSMenuItem(title: "Başlat", action: #selector(self.startContainer(_:)), keyEquivalent: "")
                                startItem.image = NSImage(systemSymbolName: "play.fill", accessibilityDescription: "Başlat")
                                containerMenu.addItem(startItem)
                            }
                            
                            containerMenu.addItem(NSMenuItem.separator())
                            
                            let removeItem = NSMenuItem(title: "Sil", action: #selector(self.removeContainer(_:)), keyEquivalent: "")
                            removeItem.image = NSImage(systemSymbolName: "trash", accessibilityDescription: "Sil")
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
                    
                    let refreshItem = NSMenuItem(title: "Yenile", action: #selector(self.refreshContainers), keyEquivalent: "r")
                    refreshItem.image = NSImage(systemSymbolName: "arrow.clockwise.circle", accessibilityDescription: "Yenile")
                    menu.addItem(refreshItem)
                    
                    menu.addItem(NSMenuItem.separator())
                    
                    let quitItem = NSMenuItem(title: "Çıkış", action: #selector(self.quit), keyEquivalent: "q")
                    quitItem.image = NSImage(systemSymbolName: "power", accessibilityDescription: "Çıkış")
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
        alert.messageText = "Konteyner Silme"
        alert.informativeText = "Bu konteyneri silmek istediğinizden emin misiniz?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Sil")
        alert.addButton(withTitle: "İptal")
        
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

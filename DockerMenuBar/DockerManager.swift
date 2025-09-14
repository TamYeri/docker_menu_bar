//
//  DockerManager.swift
//  DockerMenuBar
//
//  Created by Mesut KURT on 14.09.2025.
//

import Foundation
import AppKit

struct DockerContainer {
    let id: String
    let name: String
    let image: String
    let status: String
    
    var isRunning: Bool {
        return status.contains("Up")
    }
}

class DockerManager {
    
    func getContainers(completion: @escaping ([DockerContainer]) -> Void) {
        executeShellCommand("docker ps -a --format \"{{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}\"") { output in
            let containers = self.parseContainers(from: output)
            completion(containers)
        }
    }
    
    func startContainer(id: String, completion: @escaping (Bool) -> Void) {
        executeShellCommand("docker start \(id)") { output in
            completion(!output.isEmpty)
        }
    }
    
    func stopContainer(id: String, completion: @escaping (Bool) -> Void) {
        executeShellCommand("docker stop \(id)") { output in
            completion(!output.isEmpty)
        }
    }
    
    func restartContainer(id: String, completion: @escaping (Bool) -> Void) {
        executeShellCommand("docker restart \(id)") { output in
            completion(!output.isEmpty)
        }
    }
    
    func removeContainer(id: String, completion: @escaping (Bool) -> Void) {
        executeShellCommand("docker rm -f \(id)") { output in
            completion(!output.isEmpty)
        }
    }
    
    func openTerminal(containerID: String) {
        let dockerPath = getDockerPath()
        
        let script = """
        tell application "Terminal"
            activate
            do script "export PATH=/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:$PATH && \(dockerPath) exec -it \(containerID) /bin/bash || \(dockerPath) exec -it \(containerID) /bin/sh"
        end tell
        """
        
        var errorInfo: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&errorInfo)
            
            if let error = errorInfo {
                print("Terminal AppleScript Error: \(error)")
            }
        }
    }
    
    func showLogs(containerID: String) {
        let dockerPath = getDockerPath()
        
        let script = """
        tell application "Terminal"
            activate
            do script "export PATH=/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:$PATH && \(dockerPath) logs -f \(containerID)"
        end tell
        """
        
        var errorInfo: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&errorInfo)
            
            if let error = errorInfo {
                print("Logs AppleScript Error: \(error)")
            }
        }
    }
    
    private func getDockerPath() -> String {
        let dockerPaths = [
            "/usr/local/bin/docker",
            "/opt/homebrew/bin/docker", 
            "/usr/bin/docker"
        ]
        
        for path in dockerPaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        
        return "docker" // Fallback to PATH
    }
    
    
    private func executeShellCommand(_ command: String, completion: @escaping (String) -> Void) {
        let task = Process()
        let pipe = Pipe()
        let errorPipe = Pipe()
        
        task.standardOutput = pipe
        task.standardError = errorPipe
        task.arguments = ["-c", self.prepareDockerCommand(command)]
        task.launchPath = "/bin/bash"
        
        // Docker için gerekli environment variables ayarla
        var environment = ProcessInfo.processInfo.environment
        environment["PATH"] = "/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:" + (environment["PATH"] ?? "")
        task.environment = environment
        
        DispatchQueue.global(qos: .background).async {
            do {
                try task.run()
                task.waitUntilExit()
                
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""
                let errorOutput = String(data: errorData, encoding: .utf8) ?? ""
                
                DispatchQueue.main.async {
                    if !errorOutput.isEmpty && task.terminationStatus != 0 {
                        // Hata durumunda error output'u döndür
                        completion("ERROR: " + errorOutput.trimmingCharacters(in: .whitespacesAndNewlines))
                    } else {
                        completion(output.trimmingCharacters(in: .whitespacesAndNewlines))
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion("ERROR: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func prepareDockerCommand(_ command: String) -> String {
        // Docker binary yollarını kontrol et
        let dockerPaths = [
            "/usr/local/bin/docker",
            "/opt/homebrew/bin/docker",
            "/usr/bin/docker"
        ]
        
        for path in dockerPaths {
            if FileManager.default.fileExists(atPath: path) {
                return command.replacingOccurrences(of: "docker", with: path)
            }
        }
        
        // Sistem PATH'inde docker'ı ara
        return "which docker > /dev/null 2>&1 && " + command + " || echo 'ERROR: Docker bulunamadı. Docker Engine kurulu değil veya PATH'te yok.'"
    }
    
    private func parseContainers(from output: String) -> [DockerContainer] {
        let lines = output.components(separatedBy: .newlines)
        var containers: [DockerContainer] = []
        
        for line in lines {
            let components = line.components(separatedBy: "\t")
            if components.count >= 4 {
                let container = DockerContainer(
                    id: components[0],
                    name: components[1],
                    image: components[2],
                    status: components[3]
                )
                containers.append(container)
            }
        }
        
        return containers
    }
    
    func isDockerRunning(completion: @escaping (Bool) -> Void) {
        executeShellCommand("docker version --format '{{.Server.Version}}'") { output in
            let isRunning = !output.isEmpty && 
                           !output.contains("ERROR") && 
                           !output.contains("Cannot connect") &&
                           !output.contains("permission denied") &&
                           !output.contains("Is the docker daemon running")
            completion(isRunning)
        }
    }
    
    func getDockerInfo(completion: @escaping (String) -> Void) {
        executeShellCommand("docker system info --format 'Docker Engine: {{.ServerVersion}}\\nContainers: {{.ContainersRunning}}/{{.Containers}}\\nImages: {{.Images}}'") { output in
            completion(output)
        }
    }
}
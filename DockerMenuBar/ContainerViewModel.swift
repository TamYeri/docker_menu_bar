import Combine
import AppKit

class ContainerViewModel: ObservableObject {
    @Published var containers: [DockerContainer] = []
    @Published var isDockerRunning: Bool = true
    @Published var isRefreshing: Bool = false
    @Published var loadingContainerIDs: Set<String> = []

    private let dockerManager = DockerManager()
    private var pendingRefresh = false

    func refresh() {
        if isRefreshing {
            pendingRefresh = true
            return
        }
        pendingRefresh = false
        isRefreshing = true

        dockerManager.isDockerRunning { [weak self] isRunning in
            self?.isDockerRunning = isRunning
            if isRunning {
                self?.dockerManager.getContainers { containers in
                    self?.containers = containers
                    self?.finishRefresh()
                }
            } else {
                self?.containers = []
                self?.finishRefresh()
            }
        }
    }

    private func finishRefresh() {
        isRefreshing = false
        if pendingRefresh {
            refresh()
        }
    }

    func startContainer(id: String) {
        loadingContainerIDs.insert(id)
        dockerManager.startContainer(id: id) { [weak self] _ in
            self?.loadingContainerIDs.remove(id)
            self?.refresh()
        }
    }

    func stopContainer(id: String) {
        loadingContainerIDs.insert(id)
        dockerManager.stopContainer(id: id) { [weak self] _ in
            self?.loadingContainerIDs.remove(id)
            self?.refresh()
        }
    }

    func restartContainer(id: String) {
        loadingContainerIDs.insert(id)
        dockerManager.restartContainer(id: id) { [weak self] _ in
            self?.loadingContainerIDs.remove(id)
            self?.refresh()
        }
    }

    func removeContainer(id: String) {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("container_delete_title", comment: "")
        alert.informativeText = NSLocalizedString("container_delete_message", comment: "")
        alert.alertStyle = .warning
        alert.addButton(withTitle: NSLocalizedString("delete_button", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("cancel_button", comment: ""))

        if alert.runModal() == .alertFirstButtonReturn {
            loadingContainerIDs.insert(id)
            dockerManager.removeContainer(id: id) { [weak self] _ in
                self?.loadingContainerIDs.remove(id)
                self?.refresh()
            }
        }
    }

    func openTerminal(containerID: String) {
        dockerManager.openTerminal(containerID: containerID)
    }

    func showLogs(containerID: String) {
        dockerManager.showLogs(containerID: containerID)
    }

    func openDonationPage() {
        if let url = URL(string: "https://www.iddef.org/") {
            NSWorkspace.shared.open(url)
        }
    }

    func isLoading(id: String) -> Bool {
        loadingContainerIDs.contains(id)
    }
}

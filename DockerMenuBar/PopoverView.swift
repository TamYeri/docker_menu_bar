import SwiftUI

struct PopoverView: View {
    @ObservedObject var viewModel: ContainerViewModel

    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()
            contentView
            Divider()
            footerView
        }
        .frame(width: 310)
    }

    private var headerView: some View {
        HStack(spacing: 8) {
            Image(systemName: "cube.box.fill")
                .foregroundColor(Color(red: 30/255, green: 166/255, blue: 225/255))
                .font(.system(size: 15))

            Text("Docker MenuBar")
                .font(.system(size: 13, weight: .semibold))

            Spacer()

            if viewModel.isRefreshing {
                ProgressView()
                    .scaleEffect(0.65)
                    .frame(width: 16, height: 16)
            } else {
                Button(action: { viewModel.refresh() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var contentView: some View {
        if !viewModel.isDockerRunning {
            dockerNotRunningView
        } else if viewModel.containers.isEmpty && !viewModel.isRefreshing {
            noContainersView
        } else {
            containerListView
        }
    }

    private var dockerNotRunningView: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.system(size: 28))
            Text(NSLocalizedString("docker_not_running", comment: ""))
                .font(.system(size: 13, weight: .medium))
            Text(NSLocalizedString("start_docker_engine", comment: ""))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private var noContainersView: some View {
        VStack(spacing: 8) {
            Image(systemName: "shippingbox")
                .foregroundColor(.secondary)
                .font(.system(size: 28))
            Text(NSLocalizedString("no_containers_found", comment: ""))
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private var containerListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.containers, id: \.id) { container in
                    ContainerRowView(container: container, viewModel: viewModel)
                    if container.id != viewModel.containers.last?.id {
                        Divider().padding(.leading, 28)
                    }
                }
            }
        }
        .frame(maxHeight: 380)
    }

    private var footerView: some View {
        HStack {
            Button(action: { viewModel.openDonationPage() }) {
                Label(NSLocalizedString("donate", comment: ""), systemImage: "heart.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.pink)
            }
            .buttonStyle(.plain)

            Spacer()

            Button(action: { NSApplication.shared.terminate(nil) }) {
                Label(NSLocalizedString("quit", comment: ""), systemImage: "power")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

struct ContainerRowView: View {
    let container: DockerContainer
    @ObservedObject var viewModel: ContainerViewModel

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(container.isRunning ? Color.green : Color.secondary.opacity(0.5))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 1) {
                Text(container.name)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                Text(container.image)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if viewModel.isLoading(id: container.id) {
                ProgressView()
                    .scaleEffect(0.65)
                    .frame(width: 60, height: 16)
            } else {
                actionButtons
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var actionButtons: some View {
        HStack(spacing: 4) {
            if container.isRunning {
                iconButton("stop.fill", color: .orange, tip: NSLocalizedString("stop", comment: "")) {
                    viewModel.stopContainer(id: container.id)
                }
                iconButton("arrow.clockwise", color: Color(red: 30/255, green: 166/255, blue: 225/255), tip: NSLocalizedString("restart", comment: "")) {
                    viewModel.restartContainer(id: container.id)
                }
                iconButton("terminal", color: .secondary, tip: NSLocalizedString("open_bash", comment: "")) {
                    viewModel.openTerminal(containerID: container.id)
                }
                iconButton("doc.text", color: .secondary, tip: NSLocalizedString("show_logs", comment: "")) {
                    viewModel.showLogs(containerID: container.id)
                }
            } else {
                iconButton("play.fill", color: .green, tip: NSLocalizedString("start", comment: "")) {
                    viewModel.startContainer(id: container.id)
                }
            }
            iconButton("trash", color: .red, tip: NSLocalizedString("delete", comment: "")) {
                viewModel.removeContainer(id: container.id)
            }
        }
    }

    private func iconButton(_ icon: String, color: Color, tip: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(color)
                .frame(width: 22, height: 22)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(tip)
    }
}

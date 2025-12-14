import SwiftUI

struct ConnectView: View {
    @ObservedObject var viewModel: TranscriptViewModel
    @Binding var showTranscript: Bool

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Logo / Title
            VStack(spacing: 8) {
                Image(systemName: "eyeglasses")
                    .font(.system(size: 64))
                    .foregroundStyle(.blue)

                Text("Rounds")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Connect your Meta glasses to begin")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Connection Status
            connectionStatusView

            // Device List
            if !viewModel.wearablesManager.availableDevices.isEmpty {
                deviceListView
            }

            Spacer()

            // Action Button
            actionButton

            Spacer()
        }
        .padding()
        .alert("Connection Error", isPresented: $viewModel.wearablesManager.showError) {
            Button("OK") {
                viewModel.wearablesManager.dismissError()
            }
        } message: {
            Text(viewModel.wearablesManager.errorMessage)
        }
    }

    @ViewBuilder
    private var connectionStatusView: some View {
        HStack(spacing: 12) {
            statusIndicator
            statusText
        }
        .padding()
        .background(statusBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var statusIndicator: some View {
        switch viewModel.wearablesManager.connectionState {
        case .unavailable:
            Circle()
                .fill(.gray)
                .frame(width: 12, height: 12)
        case .available:
            Circle()
                .fill(.blue)
                .frame(width: 12, height: 12)
        case .registering:
            ProgressView()
                .scaleEffect(0.8)
        case .registered:
            Circle()
                .fill(.green)
                .frame(width: 12, height: 12)
        case .notReady:
            Circle()
                .fill(.orange)
                .frame(width: 12, height: 12)
        case .error:
            Circle()
                .fill(.red)
                .frame(width: 12, height: 12)
        }
    }

    @ViewBuilder
    private var statusText: some View {
        switch viewModel.wearablesManager.connectionState {
        case .unavailable:
            Text("Initializing...")
                .foregroundStyle(.secondary)
        case .available:
            Text("Ready to connect")
                .foregroundStyle(.secondary)
        case .registering:
            Text("Connecting via Meta app...")
                .foregroundStyle(.secondary)
        case .registered:
            if let device = viewModel.wearablesManager.connectedDevice {
                VStack(alignment: .leading, spacing: 2) {
                    Text(device.name)
                        .fontWeight(.medium)
                    if let battery = device.batteryLevel {
                        Text("Battery: \(battery)%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Text("Connected")
            }
        case .notReady(let reason):
            Text(reason.userMessage)
                .foregroundStyle(.orange)
                .lineLimit(3)
                .font(.subheadline)
        case .error(let message):
            Text(message)
                .foregroundStyle(.red)
                .lineLimit(2)
                .font(.caption)
        }
    }

    private var statusBackground: Color {
        switch viewModel.wearablesManager.connectionState {
        case .registered:
            return .green.opacity(0.1)
        case .error:
            return .red.opacity(0.1)
        case .notReady:
            return .orange.opacity(0.1)
        case .available:
            return .blue.opacity(0.1)
        default:
            return .gray.opacity(0.1)
        }
    }

    @ViewBuilder
    private var deviceListView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Connected Devices")
                .font(.headline)
                .padding(.horizontal)

            ForEach(viewModel.wearablesManager.availableDevices, id: \.id) { device in
                Button {
                    viewModel.wearablesManager.connect(to: device)
                } label: {
                    HStack {
                        Image(systemName: "eyeglasses")
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading) {
                            Text(device.name)
                                .fontWeight(.medium)
                            Text(device.model.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if viewModel.wearablesManager.connectedDevice?.id == device.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else {
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var actionButton: some View {
        switch viewModel.wearablesManager.connectionState {
        case .unavailable:
            VStack(spacing: 12) {
                ProgressView()
                Text("Setting up...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

        case .notReady(let reason):
            VStack(spacing: 12) {
                // Primary action: Open Meta AI
                Button {
                    viewModel.wearablesManager.openMetaAI()
                } label: {
                    Label("Open Meta AI", systemImage: "arrow.up.forward.app")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.orange)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Secondary action: Retry after connecting
                Button {
                    viewModel.wearablesManager.retryConfiguration()
                } label: {
                    Label("Connect Glasses", systemImage: "antenna.radiowaves.left.and.right")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                if reason == .metaViewNotInstalled {
                    Text("Install Meta AI from the App Store first")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)

        case .available, .error:
            Button {
                viewModel.wearablesManager.startRegistration()
            } label: {
                Label("Connect Glasses", systemImage: "antenna.radiowaves.left.and.right")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)

        case .registering:
            VStack(spacing: 12) {
                ProgressView()
                Text("Opening Meta app...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button {
                    viewModel.wearablesManager.stopScanning()
                } label: {
                    Text("Cancel")
                        .foregroundStyle(.secondary)
                }
            }
            .padding()

        case .registered:
            VStack(spacing: 12) {
                Button {
                    showTranscript = true
                } label: {
                    Label("Start Session", systemImage: "mic.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.green)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    viewModel.wearablesManager.disconnect()
                } label: {
                    Text("Disconnect")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    ConnectView(
        viewModel: TranscriptViewModel(),
        showTranscript: .constant(false)
    )
}

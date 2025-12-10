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
            if !viewModel.glassesManager.availableDevices.isEmpty {
                deviceListView
            }

            Spacer()

            // Action Button
            actionButton

            Spacer()
        }
        .padding()
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
        switch viewModel.glassesManager.connectionState {
        case .disconnected:
            Circle()
                .fill(.gray)
                .frame(width: 12, height: 12)
        case .scanning:
            ProgressView()
                .scaleEffect(0.8)
        case .connecting:
            ProgressView()
                .scaleEffect(0.8)
        case .connected:
            Circle()
                .fill(.green)
                .frame(width: 12, height: 12)
        case .error:
            Circle()
                .fill(.red)
                .frame(width: 12, height: 12)
        }
    }

    @ViewBuilder
    private var statusText: some View {
        switch viewModel.glassesManager.connectionState {
        case .disconnected:
            Text("Not connected")
                .foregroundStyle(.secondary)
        case .scanning:
            Text("Scanning for devices...")
                .foregroundStyle(.secondary)
        case .connecting:
            Text("Connecting...")
                .foregroundStyle(.secondary)
        case .connected:
            if let device = viewModel.glassesManager.connectedDevice {
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
        case .error(let message):
            Text(message)
                .foregroundStyle(.red)
        }
    }

    private var statusBackground: Color {
        switch viewModel.glassesManager.connectionState {
        case .connected:
            return .green.opacity(0.1)
        case .error:
            return .red.opacity(0.1)
        default:
            return .gray.opacity(0.1)
        }
    }

    @ViewBuilder
    private var deviceListView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Available Devices")
                .font(.headline)
                .padding(.horizontal)

            ForEach(viewModel.glassesManager.availableDevices, id: \.id) { device in
                Button {
                    viewModel.glassesManager.connect(to: device)
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
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
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
        switch viewModel.glassesManager.connectionState {
        case .disconnected, .error:
            Button {
                viewModel.glassesManager.startScanning()
            } label: {
                Label("Scan for Glasses", systemImage: "antenna.radiowaves.left.and.right")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)

        case .scanning:
            Button {
                viewModel.glassesManager.stopScanning()
            } label: {
                Label("Stop Scanning", systemImage: "xmark")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.gray)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)

        case .connecting:
            ProgressView("Connecting...")
                .padding()

        case .connected:
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

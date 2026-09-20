import SwiftUI

struct ContentView: View {
    @StateObject private var model = TypingModel()
    @State private var optionsExpanded = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .topLeading) {
                PlainTextEditor(text: $model.text, isEditable: !model.isRunning)
                if model.text.isEmpty {
                    Text("Paste code or text here…")
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .padding(.leading, 23)
                        .padding(.top, 18)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
            .frame(minHeight: 240)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(.primary.opacity(0.1)))

            Button {
                if model.isRunning { model.stop() } else { model.start() }
            } label: {
                Text(model.isRunning ? "Stop" : "Send")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(model.isRunning ? .red : .accentColor)
            .disabled(!model.isRunning && model.text.isEmpty)
            .accessibilityIdentifier(model.isRunning ? "autotype-stop" : "autotype-send")
            .help("Wait \(model.startDelay) seconds, then send to the focused app. Press Esc to stop.")

            DisclosureGroup("Options", isExpanded: $optionsExpanded) {
                VStack(alignment: .leading, spacing: 14) {
                    Stepper("Start delay: \(model.startDelay) \(model.startDelay == 1 ? "second" : "seconds")",
                            value: $model.startDelay, in: 1...60)
                        .accessibilityIdentifier("autotype-delay")

                    Toggle("Fix automatic indentation", isOn: $model.fixIndentation)
                        .help("Start on an empty line. Requires Command-Shift-Left in the destination. Disable automatic quote or bracket completion if it changes your text.")
                    Toggle("Instant mode (experimental)", isOn: $model.instant)
                        .help("Send text in quick bursts. Compatibility varies by app.")

                    HStack(spacing: 12) {
                        Text("Speed")
                        Slider(value: $model.speed, in: 10...40, step: 1)
                            .accessibilityLabel("Typing speed")
                            .accessibilityValue("\(Int(model.speed)) characters per second")
                        Text("\(Int(model.speed)) chars/s")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    .disabled(model.instant)

                    if !model.hasPermission {
                        Button("Open Accessibility settings", action: model.openPermissionSettings)
                    }
                }
                .toggleStyle(.checkbox)
                .padding(.top, 10)
                .disabled(model.isRunning)
            }
            .foregroundStyle(.secondary)

            if !model.status.isEmpty {
                Text(model.status)
                    .font(.caption)
                    .foregroundStyle(model.hasError ? Color.orange : Color.secondary)
                    .accessibilityIdentifier("autotype-status")
            }
        }
        .padding(16)
        .frame(minWidth: 420, minHeight: 360)
        .background(Color(nsColor: .windowBackgroundColor))
        .onChange(of: scenePhase) { phase in
            if phase == .active { model.refreshPermission() }
        }
        .onDisappear { model.stop() }
    }
}

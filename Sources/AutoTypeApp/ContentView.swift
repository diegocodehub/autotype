import SwiftUI

struct ContentView: View {
    @StateObject private var model = TypingModel()
    @Environment(\.scenePhase) private var scenePhase
    private let accent = Color(red: 0.29, green: 0.31, blue: 0.88)

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 14) {
                Image(systemName: "keyboard")
                    .font(.system(size: 25, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(accent.gradient, in: RoundedRectangle(cornerRadius: 14))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text("AutoType").font(.system(size: 27, weight: .semibold, design: .rounded))
                    Text("Your text. Sent as keystrokes.").foregroundStyle(.secondary)
                }
                Spacer()
                Text("ON YOUR MAC")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .tracking(1.4)
                    .foregroundStyle(.secondary)
            }

            if !model.hasPermission { permissionBanner }

            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    Text("TEXT TO SEND").font(.system(size: 10, weight: .semibold)).tracking(1.2)
                    Spacer()
                    Text("\(model.text.count.formatted()) characters")
                        .font(.system(size: 11, design: .monospaced))
                }
                .foregroundStyle(.secondary)

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
                .frame(minHeight: 210)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.primary.opacity(0.1)))
            }

            VStack(alignment: .leading, spacing: 16) {
                option("Fix automatic indentation", detail: "Clear spaces your editor adds after Enter.", value: $model.fixIndentation)
                    .help("Start on an empty line. Requires Command-Shift-Left in the destination. Disable automatic quote or bracket completion if it changes your text.")
                option("Instant mode", detail: "Send text in quick bursts. Compatibility varies by app.", value: $model.instant, experimental: true)
                Divider()
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Typing speed").fontWeight(.medium)
                        Text(model.instant ? "Managed by instant mode" : "\(Int(model.speed)) characters per second")
                            .font(.caption).foregroundStyle(.secondary)
                            .frame(width: 180, alignment: .leading)
                    }
                    Text("Slow").font(.caption).foregroundStyle(.secondary)
                    Slider(value: $model.speed, in: 10...40, step: 1)
                        .accessibilityLabel("Typing speed")
                        .accessibilityValue("\(Int(model.speed)) characters per second")
                        .disabled(model.instant)
                    Text("Fast").font(.caption).foregroundStyle(.secondary)
                }
            }
            .disabled(model.isRunning)
            .padding(18)
            .background(.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 12))

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(model.status)
                        .font(.callout)
                        .foregroundStyle(model.hasError ? Color.orange : Color.primary)
                        .accessibilityIdentifier("autotype-status")
                    Text("3 seconds to switch apps. Press Esc to stop.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                if model.isRunning {
                    Button(action: model.stop) { Label("Stop", systemImage: "stop.fill").frame(width: 110) }
                        .tint(.red)
                        .accessibilityIdentifier("autotype-stop")
                } else {
                    Button(action: model.start) { Label("Send text", systemImage: "arrow.up.right").frame(width: 110) }
                        .disabled(model.text.isEmpty || !model.hasPermission)
                        .accessibilityIdentifier("autotype-send")
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(28)
        .frame(minWidth: 650, minHeight: 660)
        .background(Color(nsColor: .windowBackgroundColor))
        .tint(accent)
        .onChange(of: scenePhase) { phase in
            if phase == .active { model.refreshPermission() }
        }
        .onDisappear { model.stop() }
    }

    private var permissionBanner: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "hand.raised").foregroundStyle(accent)
            VStack(alignment: .leading, spacing: 3) {
                Text("Allow AutoType to send keystrokes").fontWeight(.medium)
                Text("Enable AutoType in Accessibility, then return here.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button("Open Settings", action: model.openPermissionSettings)
        }
        .padding(14)
        .background(accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }

    private func option(_ title: String, detail: String, value: Binding<Bool>, experimental: Bool = false) -> some View {
        Toggle(isOn: value) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(title).fontWeight(.medium)
                    if experimental {
                        Text("EXPERIMENTAL")
                            .font(.system(size: 8, weight: .bold))
                            .tracking(0.6)
                            .padding(.horizontal, 6).padding(.vertical, 3)
                            .foregroundStyle(accent)
                            .background(accent.opacity(0.09), in: Capsule())
                    }
                }
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
        }
        .toggleStyle(.checkbox)
    }
}

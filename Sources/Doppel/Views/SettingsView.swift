import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: ClonerSettings
    @State private var newExclude = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("除外ディレクトリ設定")
                    .font(.headline)
                Spacer()
                Button("完了") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding()

            Divider()

            // Add new exclude
            HStack(spacing: 8) {
                TextField("除外するディレクトリ名を入力...", text: $newExclude)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        addExclude()
                    }

                Button("追加") {
                    addExclude()
                }
                .buttonStyle(.bordered)
                .disabled(newExclude.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding()

            // List
            List {
                ForEach(settings.excludedDirectories, id: \.self) { dir in
                    HStack {
                        Image(systemName: "folder.badge.minus")
                            .foregroundColor(.orange)
                        Text(dir)
                            .font(.body.monospaced())
                        Spacer()
                        if ClonerSettings.defaultExcludes.contains(dir) {
                            Text("デフォルト")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(.quaternary))
                        }
                    }
                }
                .onDelete { indexSet in
                    settings.excludedDirectories.remove(atOffsets: indexSet)
                }
            }

            Divider()

            // Reset button
            HStack {
                Button("デフォルトに戻す") {
                    settings.resetToDefaults()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                Spacer()
            }
            .padding()
        }
        .frame(width: 480, height: 400)
    }

    private func addExclude() {
        let trimmed = newExclude.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !settings.excludedDirectories.contains(trimmed) else { return }
        settings.excludedDirectories.append(trimmed)
        newExclude = ""
    }
}

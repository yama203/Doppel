import SwiftUI

struct ConfirmationView: View {
    let mode: ClonerMode
    let source: DiskInfo
    let destination: DiskInfo
    let excludes: [String]
    var hasHomebrewRsync: Bool = true

    var body: some View {
        VStack(spacing: 24) {
            Text("確認")
                .font(.title2)
                .fontWeight(.bold)

            VStack(spacing: 16) {
                // Mode
                InfoRow(label: "モード", value: mode.title, icon: mode.icon)

                Divider()

                // Source
                InfoRow(label: "コピー元", value: source.name, icon: "arrow.up.doc.fill")
                Text(source.mountPoint)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 40)
                    .padding(.top, -12)

                // Arrow
                Image(systemName: "arrow.down")
                    .font(.title3)
                    .foregroundColor(.accentColor)

                // Destination
                InfoRow(label: "コピー先", value: destination.name, icon: "arrow.down.doc.fill")
                Text(destination.mountPoint)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 40)
                    .padding(.top, -12)

                Divider()

                // Excludes
                VStack(alignment: .leading, spacing: 4) {
                    Text("除外ディレクトリ")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(excludes.joined(separator: ", "))
                        .font(.caption.monospaced())
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Warning for missing Homebrew rsync
                if !hasHomebrewRsync {
                    HStack(spacing: 8) {
                        Image(systemName: "tag.fill")
                            .foregroundColor(.yellow)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Finderタグをコピーするには Homebrew 版 rsync が必要です")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            Text("ターミナルで実行: brew install rsync")
                                .font(.caption.monospaced())
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.yellow.opacity(0.1)))
                }

                // Warning for clone mode
                if mode == .clone && !destination.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("クローン先にデータがあります。フォーマットされます。")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.orange.opacity(0.1)))
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.controlBackgroundColor)))
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 28)

            Text(label)
                .font(.body)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)

            Text(value)
                .font(.body)
                .fontWeight(.medium)

            Spacer()
        }
    }
}

import SwiftUI

struct CloneProgressView: View {
    let progress: Double
    let currentFile: String
    let statusMessage: String
    let state: ClonerState
    let onCancel: () -> Void
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            if state == .completed {
                completedView
            } else if case .completedWithWarnings(let message) = state {
                warningView(message)
            } else if case .error(let message) = state {
                errorView(message)
            } else {
                progressView
            }

            Spacer()
        }
        .padding(32)
    }

    private var progressView: some View {
        VStack(spacing: 20) {
            Image(systemName: state == .formatting ? "disk.2.fill" : "arrow.triangle.2.circlepath")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)

            Text(statusMessage)
                .font(.title3)
                .fontWeight(.medium)

            if state == .cloning {
                VStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(.linear)
                        .frame(maxWidth: 400)

                    if !currentFile.isEmpty {
                        Text(currentFile)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .frame(maxWidth: 400)
                    }
                }
            } else {
                ProgressView()
                    .progressViewStyle(.circular)
            }

            Button("キャンセル", role: .cancel) {
                onCancel()
            }
            .buttonStyle(.bordered)
        }
    }

    private var completedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.green)

            Text("クローン完了")
                .font(.title)
                .fontWeight(.bold)

            Text(statusMessage)
                .font(.body)
                .foregroundColor(.secondary)

            Button("閉じる") {
                onDone()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    private func warningView(_ message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 64))
                .foregroundColor(.orange)

            Text("一部のファイルを転送できませんでした")
                .font(.title)
                .fontWeight(.bold)

            ScrollView {
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: 400, alignment: .leading)
            }
            .frame(maxHeight: 120)

            Button("閉じる") {
                onDone()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.red)

            Text("エラーが発生しました")
                .font(.title)
                .fontWeight(.bold)

            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)

            Button("戻る") {
                onDone()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }
}

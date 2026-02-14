import SwiftUI

struct ModeSelectionView: View {
    @Binding var selectedMode: ClonerMode
    @Binding var deleteRemovedFiles: Bool

    var body: some View {
        VStack(spacing: 24) {
            Text("モードを選択")
                .font(.title2)
                .fontWeight(.bold)

            HStack(spacing: 16) {
                ForEach(ClonerMode.allCases, id: \.self) { mode in
                    ModeCard(
                        mode: mode,
                        isSelected: selectedMode == mode
                    )
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedMode = mode
                        }
                    }
                }
            }

            if selectedMode == .backup {
                Toggle(isOn: $deleteRemovedFiles) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("コピー元で削除されたファイルをコピー先からも削除する")
                            .font(.body)
                        Text("オフの場合、コピー先にのみ残っているファイルはそのまま保持されます")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color(.controlBackgroundColor)))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selectedMode)
    }
}

struct ModeCard: View {
    let mode: ClonerMode
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: mode.icon)
                .font(.system(size: 36))
                .foregroundColor(isSelected ? .white : .accentColor)

            Text(mode.title)
                .font(.headline)
                .foregroundColor(isSelected ? .white : .primary)

            Text(mode.description)
                .font(.caption)
                .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
        }
        .frame(width: 200, height: 160)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.accentColor : Color(.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.clear : Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

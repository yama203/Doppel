import SwiftUI

struct DiskSelectorView: View {
    let label: String
    let icon: String
    let volumes: [DiskInfo]
    @Binding var selection: DiskInfo?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(label, systemImage: icon)
                .font(.headline)
                .foregroundColor(.secondary)

            if volumes.isEmpty {
                Text("ボリュームが見つかりません")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 8).fill(.quaternary))
            } else {
                ForEach(volumes) { volume in
                    DiskRow(volume: volume, isSelected: selection?.id == volume.id)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selection = volume
                            }
                        }
                }
            }
        }
    }
}

struct DiskRow: View {
    let volume: DiskInfo
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: volume.isRemovable ? "externaldrive.fill" : "internaldrive.fill")
                .font(.title2)
                .foregroundColor(isSelected ? .white : .accentColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(volume.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)

                HStack(spacing: 8) {
                    Text(volume.mountPoint)
                        .font(.caption)
                    Text("•")
                        .font(.caption)
                    Text("\(volume.totalSizeFormatted)")
                        .font(.caption)
                    Text("(\(volume.freeSizeFormatted) 空き)")
                        .font(.caption)
                }
                .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.white)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? Color.accentColor : Color(.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.clear : Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

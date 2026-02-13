import Foundation

struct DiskInfo: Identifiable, Hashable {
    let id: String
    let name: String
    let mountPoint: String
    let totalSize: Int64
    let freeSize: Int64
    let isRemovable: Bool

    var totalSizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }

    var freeSizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: freeSize, countStyle: .file)
    }

    var usedSize: Int64 {
        totalSize - freeSize
    }

    var isEmpty: Bool {
        usedSize < 1_000_000 // less than 1MB considered empty
    }

    static func detectVolumes() -> [DiskInfo] {
        let fileManager = FileManager.default
        let keys: [URLResourceKey] = [
            .volumeNameKey,
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityKey,
            .volumeIsRemovableKey,
            .volumeUUIDStringKey
        ]

        guard let volumeURLs = fileManager.mountedVolumeURLs(
            includingResourceValuesForKeys: keys,
            options: [.skipHiddenVolumes]
        ) else {
            return []
        }

        return volumeURLs.compactMap { url -> DiskInfo? in
            guard let values = try? url.resourceValues(forKeys: Set(keys)) else {
                return nil
            }

            let name = values.volumeName ?? url.lastPathComponent
            let total = Int64(values.volumeTotalCapacity ?? 0)
            let free = Int64(values.volumeAvailableCapacity ?? 0)
            let removable = values.volumeIsRemovable ?? false
            let uuid = values.volumeUUIDString ?? url.path

            return DiskInfo(
                id: uuid,
                name: name,
                mountPoint: url.path,
                totalSize: total,
                freeSize: free,
                isRemovable: removable
            )
        }
    }
}

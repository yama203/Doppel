import Foundation

enum ClonerMode: String, CaseIterable {
    case clone
    case backup

    var title: String {
        switch self {
        case .clone: return "クローン"
        case .backup: return "バックアップ"
        }
    }

    var description: String {
        switch self {
        case .clone: return "クローン先をフォーマットし、完全なミラーコピーを作成します"
        case .backup: return "フォーマットせず、ファイルを追加・更新のみコピーします"
        }
    }

    var icon: String {
        switch self {
        case .clone: return "doc.on.doc.fill"
        case .backup: return "arrow.triangle.2.circlepath"
        }
    }
}

class ClonerSettings: ObservableObject {
    private static let excludeKey = "excludedDirectories"

    static let defaultExcludes: [String] = [
        "node_modules",
        ".Trash",
        ".Trashes",
        ".Spotlight-V100",
        ".fseventsd",
        ".TemporaryItems",
        ".DS_Store"
    ]

    @Published var excludedDirectories: [String] {
        didSet {
            UserDefaults.standard.set(excludedDirectories, forKey: Self.excludeKey)
        }
    }

    init() {
        if let saved = UserDefaults.standard.stringArray(forKey: Self.excludeKey) {
            self.excludedDirectories = saved
        } else {
            self.excludedDirectories = Self.defaultExcludes
        }
    }

    func resetToDefaults() {
        excludedDirectories = Self.defaultExcludes
    }
}

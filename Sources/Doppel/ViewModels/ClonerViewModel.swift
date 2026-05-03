import Foundation
import SwiftUI

enum ClonerState: Equatable {
    case idle
    case formatting
    case cloning
    case completed
    case completedWithWarnings(String)
    case error(String)
}

@MainActor
class ClonerViewModel: ObservableObject {
    @Published var availableVolumes: [DiskInfo] = []
    @Published var mode: ClonerMode = .clone
    @Published var sourceVolume: DiskInfo?
    @Published var destinationVolume: DiskInfo?
    @Published var step: Int = 0  // 0=mode, 1=source, 2=dest, 3=confirm, 4=running
    @Published var state: ClonerState = .idle
    @Published var progress: Double = 0
    @Published var currentFile: String = ""
    @Published var statusMessage: String = ""
    @Published var showFormatWarning = false
    @Published var deleteRemovedFiles = false

    let settings: ClonerSettings
    let hasHomebrewRsync: Bool

    private var rsyncProcess: Process?
    private var transferredFiles = 0

    init(settings: ClonerSettings) {
        self.settings = settings
        self.hasHomebrewRsync = FileManager.default.fileExists(atPath: "/opt/homebrew/bin/rsync")
        refreshVolumes()
    }

    func refreshVolumes() {
        availableVolumes = DiskInfo.detectVolumes()
    }

    // MARK: - Step Navigation

    func nextStep() {
        if step < 4 {
            step += 1
            if step == 1 || step == 2 {
                refreshVolumes()
            }
        }
    }

    func previousStep() {
        if step > 0 {
            step -= 1
        }
    }

    var canAdvance: Bool {
        switch step {
        case 0: return true  // mode always selected
        case 1: return sourceVolume != nil
        case 2: return destinationVolume != nil
        case 3: return true  // confirm screen
        default: return false
        }
    }

    // MARK: - Clone / Backup Execution

    func startExecution() {
        guard let source = sourceVolume, let dest = destinationVolume else { return }

        step = 4

        switch mode {
        case .clone:
            if !dest.isEmpty {
                showFormatWarning = true
            } else {
                performSync(source: source, destination: dest)
            }
        case .backup:
            performSync(source: source, destination: dest)
        }
    }

    func confirmFormatAndClone() {
        guard let source = sourceVolume, let dest = destinationVolume else { return }
        showFormatWarning = false
        formatAndSync(source: source, destination: dest)
    }

    func cancelFormatWarning() {
        showFormatWarning = false
        step = 3
    }

    func reset() {
        state = .idle
        progress = 0
        currentFile = ""
        statusMessage = ""
        sourceVolume = nil
        destinationVolume = nil
        step = 0
        mode = .clone
        deleteRemovedFiles = false
        refreshVolumes()
    }

    func cancelClone() {
        rsyncProcess?.terminate()
        rsyncProcess = nil
        state = .idle
        statusMessage = "キャンセルしました"
        step = 3
    }

    // MARK: - Internal

    private func formatAndSync(source: DiskInfo, destination: DiskInfo) {
        state = .formatting
        statusMessage = "ディスクをフォーマット中..."

        Task {
            do {
                try await formatDisk(destination)
                refreshVolumes()
                if let updatedDest = availableVolumes.first(where: { $0.mountPoint == destination.mountPoint }) {
                    performSync(source: source, destination: updatedDest)
                } else {
                    performSync(source: source, destination: destination)
                }
            } catch {
                state = .error("フォーマット失敗: \(error.localizedDescription)")
            }
        }
    }

    private nonisolated func formatDiskSync(_ disk: DiskInfo) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/diskutil")
        process.arguments = ["eraseVolume", "APFS", disk.name, disk.mountPoint]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "Doppel", code: Int(process.terminationStatus),
                         userInfo: [NSLocalizedDescriptionKey: output])
        }
    }

    private func formatDisk(_ disk: DiskInfo) async throws {
        try await Task.detached {
            try self.formatDiskSync(disk)
        }.value
    }

    private func performSync(source: DiskInfo, destination: DiskInfo) {
        state = .cloning
        progress = 0
        let modeLabel = mode.title
        statusMessage = "\(modeLabel)開始中..."
        transferredFiles = 0

        let excludes = settings.excludedDirectories
        let srcPath = source.mountPoint
        let dstPath = destination.mountPoint
        let useDelete = mode == .clone || (mode == .backup && deleteRemovedFiles)

        Task {
            do {
                let warning = try await runRsync(source: srcPath, destination: dstPath, excludes: excludes, useDelete: useDelete)
                if let warning {
                    state = .completedWithWarnings(warning)
                    statusMessage = "\(modeLabel)が完了しました（一部エラーあり）"
                } else {
                    state = .completed
                    statusMessage = "\(modeLabel)が完了しました"
                }
            } catch {
                if state != .idle {
                    state = .error("\(modeLabel)失敗: \(error.localizedDescription)")
                }
            }
        }
    }

    private func runRsync(source: String, destination: String, excludes: [String], useDelete: Bool) async throws -> String? {
        // Homebrew rsync (3.x) supports --xattrs for Finder tags
        let homebrewRsync = "/opt/homebrew/bin/rsync"
        let useHomebrew = FileManager.default.fileExists(atPath: homebrewRsync)
        let rsyncPath = useHomebrew ? homebrewRsync : "/usr/bin/rsync"

        var arguments = useHomebrew ? ["-avh", "--xattrs"] : ["-avhE"]

        if useDelete {
            arguments.append("--delete")
        }

        for exclude in excludes {
            arguments.append("--exclude=\(exclude)")
        }

        let src = source.hasSuffix("/") ? source : source + "/"
        let dst = destination.hasSuffix("/") ? destination : destination + "/"
        arguments.append(src)
        arguments.append(dst)

        return try await Task.detached { [weak self] in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: rsyncPath)
            process.arguments = arguments

            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe

            await MainActor.run {
                self?.rsyncProcess = process
                self?.transferredFiles = 0
            }

            try process.run()

            // Read stdout in a blocking loop until EOF (pipe closed = process done writing)
            let handle = stdoutPipe.fileHandleForReading
            while true {
                let data = handle.availableData
                if data.isEmpty { break }  // EOF: rsync closed stdout

                if let output = String(data: data, encoding: .utf8) {
                    Task { @MainActor in
                        self?.parseRsyncOutput(output)
                    }
                }
            }

            // Ensure process has fully exited
            process.waitUntilExit()

            let errData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
            let errMsg = String(data: errData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            await MainActor.run {
                self?.rsyncProcess = nil
            }

            let code = process.terminationStatus
            if code == 0 {
                return nil  // 完全成功
            }

            // 1 = generic error (often permission denied on extended attributes)
            // 23 = partial transfer (permission denied on some system files)
            // 24 = some files vanished before transfer
            if [1, 23, 24].contains(code) {
                let summary = errMsg.isEmpty
                    ? "一部のファイルを転送できませんでした（rsync コード \(code)）"
                    : "一部のファイルを転送できませんでした（rsync コード \(code)）:\n\(errMsg)"
                return summary
            }

            let detail = errMsg.isEmpty ? "" : "\n\(errMsg)"
            throw NSError(domain: "Doppel", code: Int(code),
                         userInfo: [NSLocalizedDescriptionKey: "rsync がエラーコード \(code) で終了しました\(detail)"])
        }.value
    }

    private func parseRsyncOutput(_ output: String) {
        let lines = output.components(separatedBy: .newlines)
        let modeLabel = mode.title
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            if trimmed.hasPrefix("Transfer starting:") {
                if let match = trimmed.range(of: #"(\d[\d,]*)\s*files?"#, options: .regularExpression) {
                    let numStr = String(trimmed[match]).replacingOccurrences(of: ",", with: "")
                        .components(separatedBy: .whitespaces).first ?? ""
                    self.statusMessage = "\(modeLabel)中... (全 \(numStr) ファイル)"
                }
                continue
            }

            if trimmed.hasPrefix("sent") && trimmed.contains("bytes") { continue }
            if trimmed.hasPrefix("sending") || trimmed.hasPrefix("total")
                || trimmed.hasPrefix("building") || trimmed.hasPrefix("deleting")
                || trimmed.hasPrefix("./") { continue }

            transferredFiles += 1
            let filesStr = formatNumber(transferredFiles)
            self.statusMessage = "\(modeLabel)中... \(filesStr) ファイル転送済み"

            let displayFile = trimmed.count > 60 ? "..." + String(trimmed.suffix(57)) : trimmed
            self.currentFile = displayFile
        }
    }

    private func formatNumber(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}

import SwiftUI

struct ContentView: View {
    @StateObject private var settings = ClonerSettings()
    @StateObject private var viewModel: ClonerViewModel
    @State private var showSettings = false

    init() {
        let settings = ClonerSettings()
        _settings = StateObject(wrappedValue: settings)
        _viewModel = StateObject(wrappedValue: ClonerViewModel(settings: settings))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerBar

            Divider()

            // Step content
            Group {
                switch viewModel.step {
                case 0:
                    stepWrapper("1/4") {
                        ModeSelectionView(selectedMode: $viewModel.mode)
                    }
                case 1:
                    stepWrapper("2/4") {
                        VStack(spacing: 16) {
                            Text("コピー元を選択")
                                .font(.title2)
                                .fontWeight(.bold)

                            DiskSelectorView(
                                label: "ボリューム",
                                icon: "arrow.up.doc.fill",
                                volumes: viewModel.availableVolumes,
                                selection: $viewModel.sourceVolume
                            )
                        }
                    }
                case 2:
                    stepWrapper("3/4") {
                        VStack(spacing: 16) {
                            Text("コピー先を選択")
                                .font(.title2)
                                .fontWeight(.bold)

                            DiskSelectorView(
                                label: "ボリューム",
                                icon: "arrow.down.doc.fill",
                                volumes: viewModel.availableVolumes.filter { $0.id != viewModel.sourceVolume?.id },
                                selection: $viewModel.destinationVolume
                            )
                        }
                    }
                case 3:
                    stepWrapper("4/4") {
                        if let src = viewModel.sourceVolume, let dst = viewModel.destinationVolume {
                            ConfirmationView(
                                mode: viewModel.mode,
                                source: src,
                                destination: dst,
                                excludes: settings.excludedDirectories,
                                hasHomebrewRsync: viewModel.hasHomebrewRsync
                            )
                        }
                    }
                case 4:
                    CloneProgressView(
                        progress: viewModel.progress,
                        currentFile: viewModel.currentFile,
                        statusMessage: viewModel.statusMessage,
                        state: viewModel.state,
                        onCancel: { viewModel.cancelClone() },
                        onDone: { viewModel.reset() }
                    )
                default:
                    EmptyView()
                }
            }

            // Footer with navigation (hidden during execution)
            if viewModel.step < 4 {
                Divider()
                navigationBar
            }
        }
        .frame(minWidth: 560, minHeight: 500)
        .alert("クローン先ディスクにデータがあります", isPresented: $viewModel.showFormatWarning) {
            Button("フォーマットして続行", role: .destructive) {
                viewModel.confirmFormatAndClone()
            }
            Button("キャンセル", role: .cancel) {
                viewModel.cancelFormatWarning()
            }
        } message: {
            Text("クローン先のディスク「\(viewModel.destinationVolume?.name ?? "")」にデータが存在します。フォーマットするとすべてのデータが削除されます。続行しますか？")
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(settings: settings)
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            Text("Doppel")
                .font(.title2)
                .fontWeight(.bold)

            Spacer()

            if viewModel.step == 1 || viewModel.step == 2 {
                Button {
                    viewModel.refreshVolumes()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .help("ボリュームを更新")
            }

            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.borderless)
            .help("除外設定")
        }
        .padding()
    }

    // MARK: - Step Wrapper

    private func stepWrapper<Content: View>(_ stepLabel: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            // Step indicator
            Text("ステップ \(stepLabel)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 12)

            ScrollView {
                content()
                    .padding(24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Navigation Bar

    private var navigationBar: some View {
        HStack {
            if viewModel.step > 0 {
                Button("戻る") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.previousStep()
                    }
                }
                .buttonStyle(.bordered)
            }

            Spacer()

            if viewModel.step < 3 {
                Button("次へ") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.nextStep()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canAdvance)
            } else if viewModel.step == 3 {
                Button("\(viewModel.mode.title)開始") {
                    viewModel.startExecution()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding()
    }
}

# Doppel

macOS向けディスククローンアプリ（Swift / SwiftUI）

## 概要

rsyncを使ったボリュームクローン/バックアップツール。ステップ形式のウィザードUIで操作する。
UIは全て日本語。外部パッケージ依存なし（純粋なSwift/SwiftUI/Foundation）。

- **クローンモード**: 宛先をAPFSフォーマット後、`--delete`付きrsyncで完全ミラー
- **バックアップモード**: フォーマットせず、ファイルの追加・更新のみ

## 動作要件

- Swift 5.9+、macOS 13.0+
- `/usr/bin/rsync`（標準）、`/usr/sbin/diskutil`（フォーマット用）
- `/opt/homebrew/bin/rsync`（オプション、Finderタグの`--xattrs`対応）

## プロジェクト構成

```
Sources/Doppel/
├── DoppelApp.swift              # @main エントリポイント（WindowGroup）
├── Models/
│   ├── DiskInfo.swift           # ボリューム情報（detectVolumes()でマウント済みボリュームを列挙）
│   └── ClonerSettings.swift     # 除外ディレクトリ設定（UserDefaults永続化）、ClonerMode enum
├── ViewModels/
│   └── ClonerViewModel.swift    # 中核ロジック。ステップ管理、diskutilフォーマット、rsync実行、出力パース
└── Views/
    ├── ContentView.swift        # メインコンテナ。ステップナビ、設定シート、フォーマット警告
    ├── ModeSelectionView.swift  # Step0: クローン/バックアップ選択カード
    ├── DiskSelectorView.swift   # Step1-2: ボリューム一覧と選択
    ├── ConfirmationView.swift   # Step3: 設定確認画面（Homebrew rsync警告含む）
    ├── CloneProgressView.swift  # Step4: 進捗表示（転送中/完了/エラー）
    └── SettingsView.swift       # 除外ディレクトリ管理シート

Resources/
├── Info.plist                   # Bundle ID: com.local.doppel
├── AppIcon.icns / AppIcon.png   # アプリアイコン

build-app.sh                     # アプリバンドル作成スクリプト
generate-icon.swift              # アイコン生成スクリプト（プログラムで描画）
```

## アーキテクチャ

- **MVVM**: ClonerViewModel(@MainActor, ObservableObject) + SwiftUI Views
- **ステップナビゲーション**: step 0→1→2→3→4 のウィザード形式
- **非同期処理**: Task.detachedでrsync/diskutilをバックグラウンド実行
- **リアルタイム進捗**: rsyncのstdoutを行単位で読み取り、parseRsyncOutput()でUI更新

### rsync実行の詳細

- Homebrew版があれば `[-avh, --xattrs, ...]`、なければ `[-avhE, ...]`
- 終了コード 0/1/23/24 は成功扱い（権限エラーやファイル消失は許容）
- `--delete`はクローンモードのみ
- 除外リストのデフォルト: node_modules, .Trash, .Trashes, .Spotlight-V100, .fseventsd, .TemporaryItems, .DS_Store

### ディスクフォーマット

- `diskutil eraseVolume APFS <name> <mountPoint>` で実行
- クローンモードで宛先にデータがある場合（usedSize >= 1MB）は警告ダイアログ表示

## ビルド

```bash
swift build -c release
```

## アプリバンドル作成

```bash
./build-app.sh
```

## リリース手順

```bash
# 1. ビルド
./build-app.sh

# 2. zip化
ditto -c -k --sequesterRsrc --keepParent Doppel.app Doppel.app.zip

# 3. コミット & タグ作成
git add .
git commit -m "Release vX.Y.Z"
git tag vX.Y.Z
git push origin main --tags

# 4. GitHub Releaseを作成（zipを添付）
gh release create vX.Y.Z Doppel.app.zip --title "Doppel vX.Y.Z" --notes "変更内容"
```

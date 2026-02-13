# Doppel

macOS向けディスククローンアプリ（Swift / SwiftUI）

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

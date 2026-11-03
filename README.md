# DOPAGAKI

Godot 4.7 のアクションゲーム(試作)。

- 開発者向け(渡し方・管理者の手順): [docs/開発者向け.md](docs/開発者向け.md)
- テスター向け: [docs/テスター向け.md](docs/テスター向け.md)

## 仕組み

```
開発者が Google Drive の共有フォルダに ZIP を入れる
   → 管理者が tools\publish.bat で確認して配信
   → GitHub が自動でビルドして新しい版(Release)を作る
   → テスターのランチャーが最新版に更新して起動
```

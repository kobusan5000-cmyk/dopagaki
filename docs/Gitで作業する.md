# Git で直接作業する手順(ZIP を使わない方法)

`main` に push すると、自動でビルド・公開されます。テスターに配信されるので、**push の前に必ず `tools\check.ps1` で OK を確認**してください。

## 最初の1回だけ
1. Git for Windows を入れる: https://git-scm.com/download/win (全部 Next でよい)
2. GitHub の招待メールを承認する(Write 権限)。
3. PowerShell で、作業したい場所に移動して:
   ```
   git clone https://github.com/kobusan5000-cmyk/dopagaki.git
   cd dopagaki
   git config user.name  "あなたの名前"
   git config user.email "GitHub に登録したメール"
   ```
   push のときに GitHub のログイン画面が出たら、ログインします。
4. Godot でそのフォルダ(`dopagaki`)を開きます。
5. `tools\check.ps1` が Godot を見つけられないときは、Godot の場所を渡します。
   ```
   powershell -File tools\check.ps1 -Godot "C:\...\Godot_v4.7.2-stable_win64_console.exe"
   ```
   (console と付いた方の exe です)

## 毎回の流れ
```
git pull --rebase                    # 作業を始める前に、必ず最新にする
(Godot で編集)
powershell -File tools\check.ps1     # OK が出ることを確認(NG なら直す)
git add -A
git commit -m "何を変えたか(例: 大剣の絵を差し替え)"
git pull --rebase                    # 他の人の変更を取り込む
git push
```
- push が拒否されたら、`git pull --rebase` をして、もう一度 `git push` します。
- `CHANGELOG.txt` の一番上に、今回の変更を書いてください(テスターの画面の「更新内容」に出ます)。
- 2〜5分で公開され、結果は GitHub の Actions タブで見られます。

## 注意
- `.godot` フォルダ、`*.import`、`*.uid` は、自動で除外されます(`.gitignore`)。
- `tools/`、`ci/`、`.github/`、`docs/` は、触らないでください(配信の仕組みです)。
- 衝突(`CONFLICT`)が出たら、無理に進めず、管理者に声をかけてください。
- 迷ったら push しないで、管理者に聞いてください。

## ZIP の方法に戻したいとき
Drive の `ここにZIPを入れる` に、ZIP を入れる方法も使えます(`開発者向け.md`)。同じ人が git と ZIP を混ぜると衝突しやすいので、どちらかに決めてください。

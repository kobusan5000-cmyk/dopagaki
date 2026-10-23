# DOPAGAKI (Godot 4.7.2) - notes for Claude Code sessions

## Project
- Godot game, almost everything in `scripts/main.gd` (~4400 lines). Public repo `kobusan5000-cmyk/dopagaki`, branch `main`.
- Developers: the owner (git), dev2 "keita" (GitHub account `keitakeitam2-creator`, Write access invited; works with git directly, see `docs/Gitで作業する.md`; the Drive ZIP flow still works), and `buchinu` (Write, invited).
- Before any push of game changes run `powershell -File tools\check.ps1` (headless start, prints OK / NG). `*.import` / `*.uid` are in `.gitignore`.
- Reply to the owner in Japanese, plain language.

## Delivery pipeline (all in the cloud, the PC does not need to be on)
Drive `DOPA/ここにZIPを入れる` -> Apps Script (`tools/cloud/drive-ingest.gs`, 1-min trigger) -> GitHub Actions `ingest.yml`
-> `ci/ingest-merge.sh` (3-way merge using `BASE_VERSION.txt` in the ZIP) -> `build.yml` (smoke test, export, Release `bNN`) -> tester launcher.
- A push to `main` that changes game files also builds and publishes a release. Docs/CI-only changes are in `paths-ignore`.
- The build smoke test starts the game headless; a parse error means no release. Run it locally before pushing game changes:
  `Godot_v4.7.2-stable_win64_console.exe --headless --import` then `--headless --quit-after 300` and look for `SCRIPT ERROR`.
  Godot path: `C:\Users\kobus\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\`
  Do not commit generated `*.import` / `*.uid` files.
- Merge/starter ZIP: each release has `DOPAGAKI_latest.zip` (with `BASE_VERSION.txt`); Apps Script copies it to Drive `最新版(読むだけ)`.
  Held ZIPs go to Drive `要確認` (same lines edited by both, or most files missing). Tests: `bash ci/test-ingest-merge.sh`.
- Docs: `docs/開発者向け.md` (for dev2), `docs/クラウド自動配信の設定.md` (admin).

## Lessons learned
- dev2's ZIPs have twice arrived unable to start (missing indent in v0.15; v0.16.1 called functions it never defined). Always smoke-test merged results.
- When merging by hand, do not use `git merge -X theirs` with a wrong base: it silently dropped non-conflicting parts. Use `git merge-file` with markers and resolve each hunk.
- Do not upload twice from the same base; that makes the second ZIP conflict with the first.
- Windows/Git Bash: no rsync, sed strips CR, Japanese file names break sed/perl; keep `tools/publish.ps1` UTF-8 with BOM.
- Cloning on Windows: use `git -c core.autocrlf=false clone`, or the working tree looks modified.

## Branch freshness (always, before and after developing)
- Start every task from the latest `main`: `git fetch origin` then branch from `origin/main`.
- Before opening or updating a PR, `git fetch origin` and check `git rev-list --left-right --count origin/main...HEAD` (or `git merge-base --is-ancestor origin/main HEAD`). If `origin/main` moved (another developer merged), bring the branch up to date first (`git rebase origin/main`, or merge it), resolve conflicts hunk by hunk, re-run `tools\check.ps1`, and only then push/open the PR.
- Never force-push over someone else's work; use `--force-with-lease` only on your own branch. If `CHANGELOG.txt` conflicts, keep the newest block on top (see below).

## Merging (owner's rule)
- Claude never merges to `main` on its own and never pushes game/doc changes directly to `main`. Always: branch -> PR, then stop. The owner's PRs are merged by keita (`keitakeitam2-creator`), not by the owner and not by Claude. Do not use `gh pr merge`, auto-merge, or admin overrides, and do not change branch protection unless the owner explicitly asks.

## Launcher "更新内容" (what testers see)
- The launcher's first screen shows the release notes = the FIRST block of `CHANGELOG.txt` (up to the first blank line). Every implementation or fix must add a new block at the very top of `CHANGELOG.txt`: `# DOPAGAKI vX.Y — <title> (date)` then `- ` lines for what was added / fixed, in Japanese, followed by a blank line. Never leave an old block above it.

## Open items
- Multiplayer was discussed (see `ONLINE_4PLAYER_PLAN.txt`) and postponed.
- v0.16.1: `draw_equipped_greatsword` / `greatsword_art_for_rarity` were written by Claude as a stopgap (size/offset untuned); `assets/wanderer_ash.png` is not used yet.
- Designer asset folder: Drive `DOPA/素材置き場` (storage only, not auto-imported).

#!/usr/bin/env bash
# Three-way merge of an uploaded project folder into the checked-out branch (used by .github/workflows/ingest.yml).
#
#   ci/ingest-merge.sh SRC_DIR OUT_FILE
#
# SRC_DIR  the project folder taken from the uploaded ZIP (the one that holds project.godot)
# OUT_FILE receives lines "key=value":
#   mode=merge|legacy   legacy = the ZIP has no (known) BASE_VERSION.txt, the caller must do a full replace
#   result=go|nochange|held
#   msg=...             reason (when held)
#   base=<sha>
#   changed=<n>         files changed by the merge
#
# The ZIP carries BASE_VERSION.txt = the commit its author started from. Three trees are compared:
# base (what the author started from), ours (current branch) and theirs (the ZIP). Changes on only one side
# are kept, edits to different places of the same file are combined, and only the same place edited by both
# sides is a conflict (-> held). On success the branch holds ONE new commit "tmp" (the caller amends it).
# Exit codes: 0 = decided (see result), 3 = legacy ZIP (no usable BASE_VERSION.txt).
set -euo pipefail

src=$(cd "$1" && pwd)
out=$2
: > "$out"
emit() { printf '%s=%s\n' "$1" "$2" >> "$out"; }

protected_re='^(\.git|\.github|\.godot|ci|tools|docs|build)/|^(README\.md|\.gitignore|export_presets\.cfg|BASE_VERSION\.txt)$|\.tmp$'
export GIT_AUTHOR_NAME=kouta GIT_AUTHOR_EMAIL=kobusan5000-cmyk@users.noreply.github.com
export GIT_COMMITTER_NAME=kouta GIT_COMMITTER_EMAIL=kobusan5000-cmyk@users.noreply.github.com
gitdir=$(git rev-parse --absolute-git-dir)

# ---- the ZIP's starting point ------------------------------------------------------------------------
base=""
if [ -f "$src/BASE_VERSION.txt" ]; then
  base=$(tr -d '\r' < "$src/BASE_VERSION.txt" | head -1 | tr -d '[:space:]')
fi
if ! [[ "$base" =~ ^[0-9a-f]{40}$ ]] || ! git cat-file -e "${base}^{commit}" 2>/dev/null; then
  emit mode legacy
  exit 3
fi
emit mode merge
emit base "$base"
if ! git merge-base --is-ancestor "$base" HEAD; then
  emit result held
  emit msg "ZIP の出発点(BASE_VERSION.txt)が、今の最新版の履歴にありません。最新版ZIPから作り直してください"
  exit 0
fi

# ---- line endings: text files become LF, so a CRLF editor does not turn every line into a change -------
( cd "$src" && find . -type f -print0 ) | while IFS= read -r -d '' f; do
  rel=${f#./}
  if printf '%s' "$rel" | grep -Eq "$protected_re"; then continue; fi
  if grep -Iq . "$src/$rel"; then sed -i 's/\r$//' "$src/$rel"; fi
done

# ---- build "theirs": the base tree with the non-protected files replaced by the ZIP's files ----------
idx=$(mktemp -u)
trap 'rm -f "$idx" "$idx.base" "$idx.new"' EXIT
gitidx() { GIT_INDEX_FILE="$idx" git "$@"; }
gitidx read-tree "$base"

git ls-tree -r --name-only -z "$base" | { grep -zEv "$protected_re" || true; } > "$idx.base"
nbase=$(tr -cd '\0' < "$idx.base" | wc -c)
if [ -s "$idx.base" ]; then
  GIT_INDEX_FILE="$idx" xargs -0 -a "$idx.base" git update-index --force-remove --
fi

( cd "$src" && find . -type f -print0 | sed -z 's|^\./||' | { grep -zEv "$protected_re" || true; } ) > "$idx.new"
if [ -s "$idx.new" ]; then
  ( cd "$src" && GIT_DIR="$gitdir" GIT_WORK_TREE="$src" GIT_INDEX_FILE="$idx" git -c core.fileMode=false update-index --add -z --stdin < "$idx.new" )
fi

# files the ZIP removed, compared with the base
ndeleted=$(comm -z -23 <(sort -z "$idx.base") <(sort -z "$idx.new") | tr -cd '\0' | wc -c)
if [ "$nbase" -gt 4 ] && [ $((ndeleted * 2)) -gt "$nbase" ]; then
  emit result held
  emit msg "ZIP に元のファイルの半分以上が入っていません(${ndeleted}/${nbase} 個がなくなる内容)。ZIP が不完全な可能性があります"
  exit 0
fi

# CHANGELOG.txt: both sides usually write a new block on top. Keep ours and add the ZIP's new top block afterwards.
prefix_file=$(mktemp)
trap 'rm -f "$idx" "$idx.base" "$idx.new" "$prefix_file" "$prefix_file.base"' EXIT
if git cat-file -e "$base:CHANGELOG.txt" 2>/dev/null && [ -f "$src/CHANGELOG.txt" ]; then
  git show "$base:CHANGELOG.txt" > "$prefix_file.base"
  bs=$(wc -c < "$prefix_file.base"); ts=$(wc -c < "$src/CHANGELOG.txt")
  if [ "$ts" -gt "$bs" ] && tail -c "$bs" "$src/CHANGELOG.txt" | cmp -s - "$prefix_file.base"; then
    head -c $((ts - bs)) "$src/CHANGELOG.txt" > "$prefix_file"
    if git cat-file -e HEAD:CHANGELOG.txt 2>/dev/null; then
      gitidx update-index --add --cacheinfo "100644,$(git rev-parse HEAD:CHANGELOG.txt),CHANGELOG.txt"
    fi
  fi
fi

theirs_tree=$(gitidx write-tree)
theirs=$(git commit-tree "$theirs_tree" -p "$base" -m "uploaded ZIP")

# ---- merge ------------------------------------------------------------------------------------------
set +e
merged=$(git merge-tree --write-tree --name-only --merge-base="$base" HEAD "$theirs" 2>&1)
rc=$?
set -e
if [ "$rc" -ne 0 ]; then
  files=$(printf '%s\n' "$merged" | tail -n +2 | awk 'NF==0 {exit} {print}' | head -8 | paste -sd, -)
  hint=""
  if git log -50 --format=%B | grep -q "^Base: $base"; then
    hint=" 同じ最新版ZIPから2回目のアップロードの可能性があります。公開後の最新版ZIPをダウンロードし直して作業してください。"
  fi
  emit result held
  emit msg "同じ場所を両方の開発者が編集したため自動で合体できません(${files:-不明})。${hint}"
  exit 0
fi

tree=$(printf '%s\n' "$merged" | head -1)
git reset -q --hard "$(git commit-tree "$tree" -p HEAD -m tmp)"
if [ -s "$prefix_file" ]; then
  { cat "$prefix_file"; cat CHANGELOG.txt 2>/dev/null || true; } > CHANGELOG.txt.new
  mv CHANGELOG.txt.new CHANGELOG.txt
fi
git add -A
if git diff --cached --quiet HEAD~1; then
  git reset -q --hard HEAD~1
  emit result nochange
  emit changed 0
  exit 0
fi
emit result go
emit changed "$(git diff --cached --name-only HEAD~1 | wc -l | tr -d ' ')"

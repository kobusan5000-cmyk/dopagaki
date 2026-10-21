#!/usr/bin/env bash
# Builds the "starter ZIP" for the other developer: the project as it is on the checked-out commit, without the
# release/CI files, plus BASE_VERSION.txt (the commit it was made from). Uploading a ZIP that still carries that
# file lets ci/ingest-merge.sh merge the two developers' work instead of overwriting it.
#   ci/make-starter.sh OUT.zip
set -euo pipefail
out=$(cd "$(dirname "$1")" && pwd)/$(basename "$1")
repo=$(git rev-parse --show-toplevel)
sha=$(git rev-parse HEAD)
stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT
git -C "$repo" archive HEAD --prefix=DOPAGAKI/ | tar -x -C "$stage"
( cd "$stage/DOPAGAKI" && rm -rf .github ci tools docs .gitignore README.md )
printf '%s\nこのファイルは消さないでください(この版から作業を始めた印です。2人の修正を自動で合体するために使います)。\n' "$sha" > "$stage/DOPAGAKI/BASE_VERSION.txt"
rm -f "$out"
if command -v zip > /dev/null; then
  ( cd "$stage" && zip -qr "$out" DOPAGAKI )
else
  "${SYSTEMROOT:-/c/Windows}/System32/tar.exe" -a -c -f "$(cygpath -w "$out" 2>/dev/null || echo "$out")" -C "$(cygpath -w "$stage" 2>/dev/null || echo "$stage")" DOPAGAKI
fi
echo "starter ZIP for $sha -> $out"

#!/usr/bin/env bash
# Scenario tests for ci/ingest-merge.sh. Needs only git + coreutils:  bash ci/test-ingest-merge.sh
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
script="$here/ingest-merge.sh"
root=$(mktemp -d)
pass=0; fail=0
export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.autocrlf GIT_CONFIG_VALUE_0=false
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t

ok()  { pass=$((pass + 1)); echo "  ok   $1"; }
bad() { fail=$((fail + 1)); echo "  FAIL $1"; }
check() { # description, command...
  local d=$1; shift
  if "$@" >/dev/null 2>&1; then ok "$d"; else bad "$d"; fi
}
get() { grep "^$1=" "$out" | head -1 | cut -d= -f2-; }

# --- a small project: ~60 lines of script, a binary, changelog, protected folders --------------------------
make_base() {
  local d=$1
  mkdir -p "$d/scripts" "$d/assets" "$d/tools" "$d/.github" "$d/ci"
  : > "$d/project.godot"; echo "config_version=5" > "$d/project.godot"
  for i in $(seq 1 60); do echo "line $i of main"; done > "$d/scripts/main.gd"
  for i in $(seq 1 10); do echo "other $i"; done > "$d/scripts/other.gd"
  printf '\x89PNG\x00\x01\x02\x03binary-A' > "$d/assets/a.png"
  printf '\x89PNG\x00\x01\x02\x03binary-B' > "$d/assets/b.png"
  printf 'DOPAGAKI v1\n- first\n' > "$d/CHANGELOG.txt"
  echo "tools" > "$d/tools/t.txt"; echo "wf" > "$d/.github/w.yml"; echo "ci" > "$d/ci/c.sh"
  echo "hello" > "$d/README.md"
  echo "obsolete" > "$d/old.gd"
  echo "keep1" > "$d/k1.gd"; echo "keep2" > "$d/k2.gd"; echo "keep3" > "$d/k3.gd"
}

# new scenario: $work = repo with base commit, $base = its sha, $src = project folder as dev2 got it
begin() {
  work="$root/work_$1"; src="$root/src_$1"; out="$root/out_$1"
  rm -rf "$work" "$src"; mkdir -p "$work" "$src"
  make_base "$work"
  ( cd "$work" && git init -q -b main && git add -A && git commit -q -m base )
  base=$(cd "$work" && git rev-parse HEAD)
  ( cd "$work" && git archive HEAD | tar -x -C "$src" )
  rm -rf "$src/tools" "$src/.github" "$src/ci" "$src/README.md"
  echo "$base" > "$src/BASE_VERSION.txt"
}
ours() { ( cd "$work" && "$@" && git add -A && git commit -q -m ours ); }
run()  { ( cd "$work" && bash "$script" "$src" "$out" ) >/dev/null 2>&1; rc=$?; }
fileis() { # path expected-first-line
  [ "$(head -1 "$work/$1" 2>/dev/null)" = "$2" ]
}

echo "1. different functions of main.gd edited on each side -> both kept"
begin 1
ours sed -i 's/^line 5 of main/OURS five/' scripts/main.gd
sed -i 's/^line 50 of main/THEIRS fifty/' "$src/scripts/main.gd"
run
check "rc 0" [ $rc -eq 0 ]
check "result go" [ "$(get result)" = go ]
check "ours kept" grep -q "OURS five" "$work/scripts/main.gd"
check "theirs applied" grep -q "THEIRS fifty" "$work/scripts/main.gd"
check "one tmp commit on top" [ "$(cd "$work" && git log --format=%s -1)" = tmp ]

echo "2. same line edited on both sides -> held, nothing changed"
begin 2
ours sed -i 's/^line 10 of main/OURS ten/' scripts/main.gd
sed -i 's/^line 10 of main/THEIRS ten/' "$src/scripts/main.gd"
before=$(cd "$work" && git rev-parse HEAD)
run
check "result held" [ "$(get result)" = held ]
check "names the file" grep -q "scripts/main.gd" "$out"
check "branch untouched" [ "$(cd "$work" && git rev-parse HEAD)" = "$before" ]
check "tree clean" [ -z "$(cd "$work" && git status --porcelain)" ]

echo "3. CHANGELOG prepended on both sides -> resolved, dev2 block on top"
begin 3
ours bash -c "printf 'DOPAGAKI v1.1 (ours)\n- ours change\n\n' | cat - CHANGELOG.txt > c.new && mv c.new CHANGELOG.txt"
printf 'DOPAGAKI v1.2 (theirs)\n- theirs change\n\n' | cat - "$src/CHANGELOG.txt" > "$root/c3" && mv "$root/c3" "$src/CHANGELOG.txt"
sed -i 's/^line 20 of main/THEIRS twenty/' "$src/scripts/main.gd"
run
check "result go" [ "$(get result)" = go ]
check "dev2 block first" fileis CHANGELOG.txt "DOPAGAKI v1.2 (theirs)"
check "our block kept" grep -q "DOPAGAKI v1.1 (ours)" "$work/CHANGELOG.txt"
check "old block kept" grep -q "DOPAGAKI v1" "$work/CHANGELOG.txt"
check "ours block once" [ "$(grep -c 'v1.1 (ours)' "$work/CHANGELOG.txt")" = 1 ]

echo "4. dev2 deletes a file that existed at base (we did not touch it) -> deleted, no hold"
begin 4
rm "$src/old.gd"
run
check "result go" [ "$(get result)" = go ]
check "file gone" [ ! -e "$work/old.gd" ]

echo "5. file added on main after the base -> kept"
begin 5
ours bash -c "echo newfile > added_on_main.gd"
sed -i 's/^line 7 of main/THEIRS seven/' "$src/scripts/main.gd"
run
check "result go" [ "$(get result)" = go ]
check "main's new file survives" [ -f "$work/added_on_main.gd" ]
check "theirs applied" grep -q "THEIRS seven" "$work/scripts/main.gd"

echo "6a. no marker -> legacy"
begin 6
rm "$src/BASE_VERSION.txt"
run
check "rc 3" [ $rc -eq 3 ]
check "mode legacy" [ "$(get mode)" = legacy ]
echo "6b. bogus sha -> legacy"
begin 7
echo "0123456789012345678901234567890123456789" > "$src/BASE_VERSION.txt"
run
check "rc 3" [ $rc -eq 3 ]
echo "6c. garbage marker -> legacy"
begin 8
echo "hello" > "$src/BASE_VERSION.txt"
run
check "rc 3" [ $rc -eq 3 ]

echo "7. unchanged ZIP -> nochange (also when main moved on)"
begin 9
run
check "result nochange" [ "$(get result)" = nochange ]
check "no commit added" [ "$(cd "$work" && git rev-parse HEAD)" = "$base" ]
begin 10
ours bash -c "echo changed > k1.gd"
run
check "result nochange" [ "$(get result)" = nochange ]
check "main's change kept" fileis k1.gd changed
check "no extra commit" [ "$(cd "$work" && git log --format=%s -1)" = ours ]

echo "8. CRLF files and backslash-era zips: CRLF copy of an unchanged file is no change"
begin 11
sed -i 's/$/\r/' "$src/scripts/main.gd" "$src/scripts/other.gd"
ours sed -i 's/^line 5 of main/OURS five/' scripts/main.gd
run
check "result nochange" [ "$(get result)" = nochange ]
check "ours kept" grep -q "OURS five" "$work/scripts/main.gd"
begin 12
sed -i 's/$/\r/' "$src/scripts/main.gd"
sed -i 's/^line 40 of main/THEIRS forty/' "$src/scripts/main.gd"
ours sed -i 's/^line 5 of main/OURS five/' scripts/main.gd
run
check "result go" [ "$(get result)" = go ]
check "both applied" bash -c "grep -q 'OURS five' '$work/scripts/main.gd' && grep -q 'THEIRS forty' '$work/scripts/main.gd'"
check "no CR in result" bash -c "! grep -q $'\r' '$work/scripts/main.gd'"

echo "9. binary file: only dev2 changed -> taken; both changed -> held"
begin 13
printf '\x89PNG\x00NEW-A' > "$src/assets/a.png"
run
check "result go" [ "$(get result)" = go ]
check "binary replaced" grep -q NEW-A "$work/assets/a.png"
begin 14
printf '\x89PNG\x00NEW-A' > "$src/assets/a.png"
ours bash -c "printf '\x89PNG\x00OURS-A' > assets/a.png"
run
check "result held" [ "$(get result)" = held ]
check "names the file" grep -q "assets/a.png" "$out"

echo "10. protected folders inside the ZIP are ignored"
begin 15
mkdir -p "$src/tools" "$src/.github/workflows" "$src/ci" "$src/build"
echo evil > "$src/tools/t.txt"; echo evil > "$src/.github/workflows/x.yml"; echo evil > "$src/ci/c.sh"; echo "# mine" > "$src/README.md"
echo x > "$src/build/o.bin"; echo x > "$src/junk.tmp"
sed -i 's/^line 3 of main/THEIRS three/' "$src/scripts/main.gd"
run
check "result go" [ "$(get result)" = go ]
check "tools untouched" fileis tools/t.txt tools
check "workflow untouched" [ ! -e "$work/.github/workflows/x.yml" ]
check "ci untouched" fileis ci/c.sh ci
check "README untouched" fileis README.md hello
check "build/ and .tmp ignored" bash -c "[ ! -e '$work/build' ] && [ ! -e '$work/junk.tmp' ]"
check "marker not committed" [ ! -e "$work/BASE_VERSION.txt" ]

echo "11. nested folder layout is handled by the caller; marker next to project.godot works at any depth"
begin 16
sed -i 's/^line 3 of main/THEIRS three/' "$src/scripts/main.gd"
run
check "result go" [ "$(get result)" = go ]

echo "12. new file from dev2 + new file from us (different names) -> both"
begin 17
echo dev2file > "$src/dev2_new.gd"
ours bash -c "echo ourfile > our_new.gd"
run
check "result go" [ "$(get result)" = go ]
check "both exist" bash -c "[ -f '$work/dev2_new.gd' ] && [ -f '$work/our_new.gd' ]"

echo "13. delete vs modify -> held"
begin 18
rm "$src/k2.gd"
ours bash -c "echo modified > k2.gd"
run
check "result held" [ "$(get result)" = held ]

echo "14. ZIP missing most files -> held (incomplete ZIP)"
begin 19
rm -rf "$src/scripts" "$src/assets" "$src/k1.gd" "$src/k2.gd" "$src/k3.gd" "$src/old.gd"
run
check "result held" [ "$(get result)" = held ]
check "branch untouched" [ "$(cd "$work" && git rev-parse HEAD)" = "$(cd "$work" && git rev-parse HEAD)" ]

echo "15. base is not part of this history -> held"
begin 20
( cd "$work" && git checkout -q --orphan other && git rm -rfq . >/dev/null 2>&1; echo z > z.txt && git add -A && git commit -q -m other )
echo "$base" > "$src/BASE_VERSION.txt"
run
check "result held" [ "$(get result)" = held ]

echo "16. second upload from the same base -> held with hint"
begin 21
sed -i 's/^line 12 of main/FIRST twelve/' "$src/scripts/main.gd"
run
( cd "$work" && git commit -q --amend -m "Drive upload: first
Base: $base" )
cp -r "$src" "$root/src21b"
sed -i "s/^FIRST twelve/SECOND twelve/" "$root/src21b/scripts/main.gd"
src="$root/src21b"; run
check "result held" [ "$(get result)" = held ]
check "hint about re-download" grep -q "2回目" "$out"

echo "17. identical change on both sides -> no conflict"
begin 22
ours sed -i 's/^line 12 of main/SAME twelve/' scripts/main.gd
sed -i 's/^line 12 of main/SAME twelve/' "$src/scripts/main.gd"
run
check "result nochange" [ "$(get result)" = nochange ]

echo
echo "passed: $pass   failed: $fail"
rm -rf "$root"
[ "$fail" -eq 0 ]

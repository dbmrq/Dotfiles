#!/usr/bin/env bash
#
# Functional tests for the stow.sh adoption safety hardening.
#
# Verified behaviors:
#   1. Clean repo + conflicting $HOME file: --adopt runs, the adopted file is
#      reset to its repo version, the symlink is created, and the repo is clean
#      again (intended bootstrap behavior preserved).
#   2. Idempotency: a second run on a clean repo changes nothing.
#   3. Dirty tracked file + --force: stow.sh aborts (exit 1) instead of running
#      `git checkout .`; the pre-existing edit and the conflicting $HOME file
#      are both untouched.
#   4. Dirty tracked file + interactive: default answer aborts (exit 3) and
#      preserves the pre-existing edit.
#   5. Dirty tracked file + interactive "proceed anyway": adoption runs, only
#      the adopted file is reset, and the pre-existing edit survives (restore is
#      scoped, never `git checkout .`).
#
# Uses throwaway fake repos and fake HOME dirs only; never touches the real
# repo, the real $HOME, or your working tree. Requires git and stow.
#
# Usage:
#   ./Bootstrap/test-stow-adopt.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STOW_SH="$SCRIPT_DIR/stow.sh"

PASS=0
FAIL=0

ok()  { printf '  ✓ %s\n' "$1"; PASS=$((PASS + 1)); }
bad() { printf '  ✗ %s\n' "$1"; FAIL=$((FAIL + 1)); }

# expect <desc> <result>  (result 0 = ok, non-zero = bad)
expect() {
    local desc="$1" result="$2"
    if [[ $result -eq 0 ]]; then
        ok "$desc"
    else
        bad "$desc"
    fi
}

# expect_equal <desc> <actual> <expected>
expect_equal() {
    local desc="$1" actual="$2" expected="$3"
    if [[ "$actual" == "$expected" ]]; then
        ok "$desc"
    else
        bad "$desc (expected '$expected', got '$actual')"
    fi
}

# make_fixture <repo-dir> <home-dir>
# Creates a minimal stow package with two tracked files and a committed repo.
make_fixture() {
    local repo="$1" home="$2"
    mkdir -p "$repo/FakePkg" "$home"
    printf 'managed version\n' >"$repo/FakePkg/.fakerc"
    printf 'other content\n' >"$repo/FakePkg/.otherfile"
    git -C "$repo" init -q
    git -C "$repo" add -A
    git -C "$repo" -c user.name=test -c user.email=test@example.com commit -q -m init
}

# run_stow <home-dir> <repo-dir> <stow.sh args...>
# Runs stow.sh against a fake HOME and fake repo via environment overrides.
# Returns stow.sh's exit code; on failure the captured output is printed to
# stderr so a CI regression shows the real stow error instead of silently
# swallowing it behind `>/dev/null 2>&1`.
run_stow() {
    local home="$1" repo="$2"
    shift 2
    local out rc=0
    out=$(HOME="$home" DOTFILES_DIR="$repo" "$STOW_SH" "$@" 2>&1) || rc=$?
    if (( rc != 0 )); then
        printf 'run_stow failed (exit %s):\n%s\n' "$rc" "$out" >&2
    fi
    return "$rc"
}

echo "stow.sh adoption safety tests"
echo "============================="

# --- 1. Clean repo + conflicting HOME file (happy path) ---------------------
T=$(mktemp -d)
R="$T/repo"; H="$T/home"
make_fixture "$R" "$H"
printf 'user local version\n' >"$H/.fakerc"

rc=0
run_stow "$H" "$R" FakePkg --force || rc=$?
expect "clean repo + conflicting HOME file: stow --force succeeds" "$rc"

if [[ -L "$H/.fakerc" ]]; then
    ok "adopted file became a symlink"
else
    bad "adopted file became a symlink"
fi
expect_equal "adopted file reset to repo version" "$(cat "$R/FakePkg/.fakerc")" "managed version"
if [[ -z "$(git -C "$R" status --porcelain)" ]]; then
    ok "repo clean after adoption + reset"
else
    bad "repo clean after adoption + reset: $(git -C "$R" status --porcelain)"
fi

# --- 2. Idempotency ----------------------------------------------------------
rc=0
run_stow "$H" "$R" FakePkg --force || rc=$?
expect "second run on clean repo is idempotent" "$rc"
if [[ -z "$(git -C "$R" status --porcelain)" ]]; then
    ok "repo still clean after second run"
else
    bad "repo still clean after second run: $(git -C "$R" status --porcelain)"
fi
rm -rf "$T"

# --- 3. Dirty tracked file + --force aborts, nothing discarded --------------
T=$(mktemp -d)
R="$T/repo"; H="$T/home"
make_fixture "$R" "$H"
printf 'uncommitted user edit\n' >>"$R/FakePkg/.otherfile"
printf 'user local version\n' >"$H/.fakerc"

if run_stow "$H" "$R" FakePkg --force; then
    bad "dirty repo + --force should abort"
else
    ok "dirty repo + --force aborts"
fi
grep -q 'uncommitted user edit' "$R/FakePkg/.otherfile"; rc=$?
expect "pre-existing uncommitted edit preserved" "$rc"
if [[ -f "$H/.fakerc" && ! -L "$H/.fakerc" ]]; then
    ok "conflicting HOME file untouched (no adoption, no symlink)"
else
    bad "conflicting HOME file untouched (no adoption, no symlink)"
fi
expect_equal "repo file unchanged (no adoption ran)" "$(cat "$R/FakePkg/.fakerc")" "managed version"
rm -rf "$T"

# --- 4. Dirty tracked file + interactive default aborts ---------------------
T=$(mktemp -d)
R="$T/repo"; H="$T/home"
make_fixture "$R" "$H"
printf 'uncommitted user edit\n' >>"$R/FakePkg/.otherfile"
printf 'user local version\n' >"$H/.fakerc"

# Empty input = accept every default: Proceed? y, then Abort before adopting? y.
set +e
out=$(printf '\n' | HOME="$H" DOTFILES_DIR="$R" "$STOW_SH" FakePkg 2>&1)
rc=$?
set -e
if [[ $rc -ne 0 ]]; then
    printf 'stow.sh failed (exit %s):\n%s\n' "$rc" "$out" >&2
fi
if [[ $rc -eq 3 ]]; then
    ok "interactive + dirty repo: default answer aborts (exit 3)"
else
    bad "interactive + dirty repo: expected abort exit 3, got $rc"
fi
grep -q 'uncommitted user edit' "$R/FakePkg/.otherfile"; rc=$?
expect "interactive abort preserved pre-existing edit" "$rc"
rm -rf "$T"

# --- 5. Interactive proceed-anyway: restore scoped to adopted files ---------
T=$(mktemp -d)
R="$T/repo"; H="$T/home"
make_fixture "$R" "$H"
printf 'uncommitted user edit\n' >>"$R/FakePkg/.otherfile"
printf 'user local version\n' >"$H/.fakerc"

# Proceed? y | Abort before adopting? n | Reset adopted files? y
set +e
out=$(printf 'y\nn\ny\n' | HOME="$H" DOTFILES_DIR="$R" "$STOW_SH" FakePkg 2>&1)
rc=$?
set -e
if [[ $rc -ne 0 ]]; then
    printf 'stow.sh failed (exit %s):\n%s\n' "$rc" "$out" >&2
fi
if [[ $rc -eq 0 ]]; then
    ok "interactive proceed-anyway completes (exit 0)"
else
    bad "interactive proceed-anyway failed (exit $rc)"
fi
grep -q 'uncommitted user edit' "$R/FakePkg/.otherfile"; rc=$?
expect "pre-existing edit preserved after scoped reset" "$rc"
expect_equal "adopted file reset to repo version" "$(cat "$R/FakePkg/.fakerc")" "managed version"
[[ -L "$H/.fakerc" ]]; rc=$?
expect "HOME file symlinked after adoption" "$rc"
rm -rf "$T"

echo ""
echo "============================="
if [[ $FAIL -eq 0 ]]; then
    echo "✓ All $PASS stow adoption safety tests passed!"
    exit 0
else
    echo "✗ $FAIL of $((PASS + FAIL)) stow adoption safety tests failed"
    exit 1
fi

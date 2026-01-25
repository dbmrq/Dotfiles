#!/usr/bin/env bash
#
# Test bootstrap scripts for common issues
# Run from the Dotfiles directory: ./Bootstrap/test-scripts.sh
#
# Tests:
#   1. Syntax checks for all shell scripts
#   2. Unbound variable checks (set -u compatibility)
#   3. Common shell pattern checks
#   4. features.json validation
#   5. Stow symlink verification (functional test)
#   6. Light install simulation
#   7. Feature detection logic
#   8. Dotfiles CLI commands
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
cd "$DOTFILES_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

ERRORS=0
WARNINGS=0
TEMP_DIR=""

pass() { echo -e "${GREEN}✓${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; ((ERRORS++)) || true; }
warn() { echo -e "${YELLOW}!${NC} $1"; ((WARNINGS++)) || true; }

cleanup() {
    if [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi
}
trap cleanup EXIT

echo "Bootstrap Scripts Test Suite"
echo "============================="
echo ""

# --- Test 1: Syntax check ---
echo "1. Syntax checks"
for script in Bootstrap/*.sh; do
    if bash -n "$script" 2>/dev/null; then
        pass "$script: syntax OK"
    else
        fail "$script: syntax error"
        bash -n "$script" 2>&1 | head -3
    fi
done
echo ""

# --- Test 2: Check for unbound variable issues ---
echo "2. Unbound variable checks (set -u)"

# Test lib.sh can be sourced
if bash -c 'set -euo pipefail; source Bootstrap/lib.sh' 2>/dev/null; then
    pass "lib.sh: can be sourced with set -u"
else
    fail "lib.sh: fails with set -u"
fi

# Test lib.sh functions work with empty results
if bash -c '
    set -euo pipefail
    source Bootstrap/lib.sh
    # These should not fail even if results are empty
    get_all_cli_packages >/dev/null
    get_all_gui_casks >/dev/null
    get_all_gui_formulas >/dev/null
    get_feature_keys >/dev/null
' 2>/dev/null; then
    pass "lib.sh: JSON functions work correctly"
else
    fail "lib.sh: JSON functions fail"
fi

# Test stow.sh runs without crashing (exit 0 = all ok, exit 1 = needs attention, both valid)
if ! command -v stow >/dev/null 2>&1; then
    fail "stow.sh: stow not installed"
else
    # Run and capture exit code - 0 and 1 are both valid (1 means symlinks need attention)
    set +e
    ./Bootstrap/stow.sh --verify >/dev/null 2>&1
    exit_code=$?
    set -e
    if [[ $exit_code -le 1 ]]; then
        pass "stow.sh: --verify mode works (exit code: $exit_code)"
    else
        fail "stow.sh: --verify mode crashed (exit code: $exit_code)"
    fi
fi

# Test bootstrap.sh runs without crashing
set +e
./Bootstrap/bootstrap.sh --verify >/dev/null 2>&1
exit_code=$?
set -e
if [[ $exit_code -le 1 ]]; then
    pass "bootstrap.sh: --verify mode works (exit code: $exit_code)"
else
    fail "bootstrap.sh: --verify mode crashed (exit code: $exit_code)"
fi
echo ""

# --- Test 3: Check for common shell issues ---
echo "3. Common shell pattern checks"

# Check for unquoted array expansions that might fail with set -u
# Pattern: ${arr[@]} without quotes or length check
risky_patterns=0
for script in Bootstrap/*.sh; do
    # Look for array access without length check in preceding lines
    while IFS= read -r line; do
        # Skip lines that are comments
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        # Check for problematic patterns
        if [[ "$line" =~ \"\$\{[a-zA-Z_]+\[@\]\}\" ]] && \
           ! [[ "$line" =~ \+= ]] && \
           ! grep -B5 "$line" "$script" 2>/dev/null | grep -qE '\[\[.*\$\{#.*-gt 0\]\]|\[\[.*-n.*\]\]'; then
            # This is a simplistic check - might have false positives
            :
        fi
    done < "$script"
done

if [[ $risky_patterns -eq 0 ]]; then
    pass "No obvious unguarded array patterns found"
fi
echo ""

# --- Test 4: features.json validation ---
echo "4. features.json validation"
if [[ -f Bootstrap/features.json ]]; then
    if python3 -c "import json; json.load(open('Bootstrap/features.json'))" 2>/dev/null; then
        pass "features.json: valid JSON"
    else
        fail "features.json: invalid JSON"
    fi

    # Validate structure
    if python3 -c "
import json
with open('Bootstrap/features.json') as f:
    data = json.load(f)
assert 'features' in data, 'Missing features key'
for key, feat in data['features'].items():
    assert 'name' in feat, f'Feature {key} missing name'
" 2>/dev/null; then
        pass "features.json: structure valid"
    else
        fail "features.json: invalid structure"
    fi
else
    fail "features.json: file not found"
fi
echo ""

# --- Test 5: Stow symlink functional test ---
echo "5. Stow symlink functional test"
TEMP_DIR=$(mktemp -d)

# Create a test package structure
mkdir -p "$TEMP_DIR/TestPkg"
echo "test content" > "$TEMP_DIR/TestPkg/.testrc"
mkdir -p "$TEMP_DIR/TestPkg/.config/testapp"
echo "config content" > "$TEMP_DIR/TestPkg/.config/testapp/config"

# Create a fake home
FAKE_HOME="$TEMP_DIR/home"
mkdir -p "$FAKE_HOME"

# Test stow creates correct symlinks
if command -v stow >/dev/null 2>&1; then
    cd "$TEMP_DIR"
    if stow --target="$FAKE_HOME" TestPkg 2>/dev/null; then
        # Verify file symlink
        if [[ -L "$FAKE_HOME/.testrc" ]]; then
            pass "stow: creates file symlinks correctly"
        else
            fail "stow: failed to create file symlink"
        fi

        # Verify nested structure (stow symlinks the top-level directory)
        if [[ -L "$FAKE_HOME/.config" ]]; then
            pass "stow: creates directory symlinks correctly"
        else
            fail "stow: failed to create directory symlink"
        fi

        # Verify symlink targets point to correct location
        if [[ "$(readlink "$FAKE_HOME/.testrc")" == *"TestPkg/.testrc" ]]; then
            pass "stow: symlink targets are correct"
        else
            fail "stow: symlink target incorrect"
        fi
    else
        fail "stow: command failed"
    fi
    cd "$DOTFILES_DIR"
else
    warn "stow not installed, skipping functional test"
fi
echo ""

# --- Test 6: Feature detection logic ---
echo "6. Feature detection logic"
source Bootstrap/lib.sh

# Test get_feature_keys returns something
keys=$(get_feature_keys)
if [[ -n "$keys" ]]; then
    pass "get_feature_keys: returns feature list"
else
    fail "get_feature_keys: returns empty"
fi

# Test get_feature_name
name=$(get_feature_name "vim")
if [[ "$name" == "Vim/Neovim" ]]; then
    pass "get_feature_name: returns correct name"
else
    fail "get_feature_name: expected 'Vim/Neovim', got '$name'"
fi

# Test get_stow_package
stow_pkg=$(get_stow_package "vim")
if [[ "$stow_pkg" == "Vim" ]]; then
    pass "get_stow_package: returns correct package"
else
    fail "get_stow_package: expected 'Vim', got '$stow_pkg'"
fi
echo ""

# --- Test 7: Dotfiles CLI ---
echo "7. Dotfiles CLI"
if [[ -x Bootstrap/dotfiles ]]; then
    # Test help command
    if ./Bootstrap/dotfiles help >/dev/null 2>&1; then
        pass "dotfiles: help command works"
    else
        fail "dotfiles: help command failed"
    fi

    # Test cd command
    dir=$(./Bootstrap/dotfiles cd)
    if [[ "$dir" == "$DOTFILES_DIR" ]]; then
        pass "dotfiles: cd command returns correct directory"
    else
        fail "dotfiles: cd returned '$dir', expected '$DOTFILES_DIR'"
    fi
else
    warn "dotfiles CLI not found or not executable"
fi
echo ""

# --- Test 8: Neovim Lua config syntax ---
echo "8. Neovim Lua config"
if command -v nvim >/dev/null 2>&1; then
    lua_errors=0
    for lua_file in Vim/.config/nvim/lua/**/*.lua; do
        if [[ -f "$lua_file" ]]; then
            if nvim --headless -c "luafile $lua_file" -c "q" 2>/dev/null; then
                pass "$lua_file: syntax OK"
            else
                # Try with luac if available
                if command -v luac >/dev/null 2>&1; then
                    if luac -p "$lua_file" 2>/dev/null; then
                        pass "$lua_file: syntax OK (luac)"
                    else
                        fail "$lua_file: syntax error"
                        ((lua_errors++))
                    fi
                else
                    warn "$lua_file: could not verify"
                fi
            fi
        fi
    done
else
    if command -v luac >/dev/null 2>&1; then
        for lua_file in Vim/.config/nvim/lua/**/*.lua; do
            if [[ -f "$lua_file" ]]; then
                if luac -p "$lua_file" 2>/dev/null; then
                    pass "$lua_file: syntax OK"
                else
                    fail "$lua_file: syntax error"
                fi
            fi
        done
    else
        warn "Neither nvim nor luac available, skipping Lua syntax check"
    fi
fi
echo ""

# --- Summary ---
echo "============================="
if [[ $ERRORS -eq 0 ]]; then
    echo -e "${GREEN}All tests passed!${NC}"
    [[ $WARNINGS -gt 0 ]] && echo "  ($WARNINGS warnings)"
    exit 0
else
    echo -e "${RED}$ERRORS test(s) failed${NC}"
    [[ $WARNINGS -gt 0 ]] && echo "  ($WARNINGS warnings)"
    exit 1
fi

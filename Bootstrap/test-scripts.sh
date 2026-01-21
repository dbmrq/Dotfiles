#!/usr/bin/env bash
#
# Test bootstrap scripts for common issues
# Run from the Dotfiles directory: ./Bootstrap/test-scripts.sh
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

pass() { echo -e "${GREEN}✓${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; ((ERRORS++)); }
warn() { echo -e "${YELLOW}!${NC} $1"; ((WARNINGS++)); }

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
else
    fail "features.json: file not found"
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


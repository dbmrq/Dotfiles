#!/usr/bin/env bash
#
# Export current macOS preferences and compare with prefs.sh
# Shows what's different from the expected configuration
#
# Usage:
#   ./prefs-export.sh           # Show differences from expected
#   ./prefs-export.sh --dump    # Dump all tracked preferences
#   ./prefs-export.sh --update  # Show commands to update prefs.sh
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m'

MODE="${1:-diff}"

# Define expected preferences (domain, key, expected_value, type)
# Types: bool, string, int
declare -a PREFS=(
    # Dock
    "com.apple.dock|autohide|true|bool"
    "com.apple.dock|show-recents|false|bool"
    "com.apple.dock|minimize-to-application|true|bool"
    "com.apple.dock|mru-spaces|false|bool"
    # Screenshots
    "com.apple.screencapture|disable-shadow|true|bool"
    # Safari
    "com.apple.safari|ShowFullURLInSmartSearchField|true|bool"
    # Finder
    "com.apple.finder|QuitMenuItem|true|bool"
    "com.apple.finder|FXPreferredViewStyle|clmv|string"
    "com.apple.finder|_FXSortFoldersFirst|true|bool"
    "com.apple.finder|_FXSortFoldersFirstOnDesktop|true|bool"
    "com.apple.finder|FXDefaultSearchScope|SCcf|string"
    "com.apple.finder|ShowExternalHardDrivesOnDesktop|false|bool"
    "com.apple.finder|ShowRemovableMediaOnDesktop|false|bool"
    "com.apple.finder|ShowHardDrivesOnDesktop|false|bool"
    "com.apple.finder|ShowMountedServersOnDesktop|false|bool"
    "com.apple.finder|ShowStatusBar|true|bool"
    "com.apple.finder|NewWindowTarget|PfLo|string"
    # Other Apps
    "com.apple.TextEdit|RichText|false|bool"
    "com.apple.TimeMachine|DoNotOfferNewDisksForBackup|true|bool"
    "com.apple.LaunchServices|LSQuarantine|false|bool"
    "com.apple.CrashReporter|DialogType|none|string"
    # Global
    "NSGlobalDomain|NSDocumentSaveNewDocumentsToCloud|false|bool"
)

get_current_value() {
    local domain="$1"
    local key="$2"
    defaults read "$domain" "$key" 2>/dev/null || echo "__NOT_SET__"
}

normalize_bool() {
    local val="$1"
    case "$val" in
        1|true|yes) echo "true" ;;
        0|false|no) echo "false" ;;
        *) echo "$val" ;;
    esac
}

echo ""
echo -e "${BOLD}macOS Preferences Status${NC}"
echo "========================="
echo ""

matches=0
differs=0
missing=0

for pref in "${PREFS[@]}"; do
    IFS='|' read -r domain key expected type <<< "$pref"
    current=$(get_current_value "$domain" "$key")

    # Normalize booleans for comparison
    if [[ "$type" == "bool" ]]; then
        current=$(normalize_bool "$current")
        expected=$(normalize_bool "$expected")
    fi

    if [[ "$MODE" == "--dump" ]]; then
        echo "$domain $key = $current"
    elif [[ "$current" == "__NOT_SET__" ]]; then
        echo -e "${YELLOW}!${NC} $domain $key: ${YELLOW}not set${NC} (expected: $expected)"
        ((missing++))
    elif [[ "$current" != "$expected" ]]; then
        echo -e "${RED}✗${NC} $domain $key: ${RED}$current${NC} (expected: $expected)"
        ((differs++))
        if [[ "$MODE" == "--update" ]]; then
            if [[ "$type" == "bool" ]]; then
                echo "    defaults write $domain $key -bool $expected"
            elif [[ "$type" == "int" ]]; then
                echo "    defaults write $domain $key -int $expected"
            else
                echo "    defaults write $domain $key -string \"$expected\""
            fi
        fi
    else
        if [[ "$MODE" != "--dump" ]]; then
            echo -e "${GREEN}✓${NC} $domain $key"
        fi
        ((matches++))
    fi
done

echo ""
echo "─────────────────────────"
echo -e "Matching: ${GREEN}$matches${NC}  Different: ${RED}$differs${NC}  Missing: ${YELLOW}$missing${NC}"
echo ""

if [[ $differs -gt 0 || $missing -gt 0 ]]; then
    echo "Run ./prefs.sh to apply expected preferences."
    echo "Run ./prefs-export.sh --update to see the commands needed."
    exit 1
else
    echo -e "${GREEN}All preferences match expected values.${NC}"
    exit 0
fi

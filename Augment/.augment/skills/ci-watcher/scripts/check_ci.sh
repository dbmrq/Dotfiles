#!/bin/bash
# Check GitHub Actions CI status for the most recent workflow run on the current branch
# Usage: check_ci.sh [--wait SECONDS]
#
# Options:
#   --wait SECONDS   Wait up to SECONDS for the run to complete (polls every 15s)
#
# Exit codes:
#   0 - Success (workflow completed successfully)
#   1 - Failure (workflow failed or error occurred)
#   2 - Timeout (workflow still running after wait period)
#   3 - No workflow runs found

set -e

WAIT_SECONDS=0
while [[ $# -gt 0 ]]; do
    case $1 in
        --wait)
            WAIT_SECONDS="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

# Check if gh CLI is available
if ! command -v gh &> /dev/null; then
    echo "Error: GitHub CLI (gh) is not installed or not in PATH" >&2
    exit 1
fi

# Check if we're in a git repository
if ! git rev-parse --git-dir &> /dev/null; then
    echo "Error: Not in a git repository" >&2
    exit 1
fi

# Get current branch
BRANCH=$(git branch --show-current)
if [[ -z "$BRANCH" ]]; then
    echo "Error: Could not determine current branch" >&2
    exit 1
fi

echo "Checking CI status for branch: $BRANCH"

check_status() {
    # Get the most recent workflow run for this branch
    RUN_JSON=$(gh run list --branch "$BRANCH" --limit 1 --json databaseId,status,conclusion,name,headSha,createdAt 2>/dev/null)
    
    if [[ -z "$RUN_JSON" ]] || [[ "$RUN_JSON" == "[]" ]]; then
        echo "No workflow runs found for branch: $BRANCH"
        return 3
    fi
    
    RUN_ID=$(echo "$RUN_JSON" | jq -r '.[0].databaseId')
    STATUS=$(echo "$RUN_JSON" | jq -r '.[0].status')
    CONCLUSION=$(echo "$RUN_JSON" | jq -r '.[0].conclusion')
    NAME=$(echo "$RUN_JSON" | jq -r '.[0].name')
    SHA=$(echo "$RUN_JSON" | jq -r '.[0].headSha' | cut -c1-7)
    CREATED=$(echo "$RUN_JSON" | jq -r '.[0].createdAt')
    
    echo "Workflow: $NAME"
    echo "Commit: $SHA"
    echo "Started: $CREATED"
    echo "Status: $STATUS"
    
    if [[ "$STATUS" == "completed" ]]; then
        echo "Conclusion: $CONCLUSION"
        if [[ "$CONCLUSION" == "success" ]]; then
            echo "✅ CI passed!"
            return 0
        else
            echo "❌ CI failed!"
            echo ""
            echo "Run 'gh run view $RUN_ID --log-failed' to see failure logs"
            return 1
        fi
    else
        echo "⏳ CI is still running..."
        return 2
    fi
}

# Initial check
check_status
RESULT=$?

if [[ $RESULT -ne 2 ]] || [[ $WAIT_SECONDS -eq 0 ]]; then
    exit $RESULT
fi

# Poll until complete or timeout
ELAPSED=0
POLL_INTERVAL=15

while [[ $ELAPSED -lt $WAIT_SECONDS ]]; do
    echo ""
    echo "Waiting ${POLL_INTERVAL}s before next check... (${ELAPSED}s / ${WAIT_SECONDS}s elapsed)"
    sleep $POLL_INTERVAL
    ELAPSED=$((ELAPSED + POLL_INTERVAL))
    
    echo ""
    check_status
    RESULT=$?
    
    if [[ $RESULT -ne 2 ]]; then
        exit $RESULT
    fi
done

echo ""
echo "⏱️ Timeout: CI still running after ${WAIT_SECONDS}s"
exit 2


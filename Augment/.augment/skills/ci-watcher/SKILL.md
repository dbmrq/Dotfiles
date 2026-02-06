---
name: ci-watcher
description: Automatically check GitHub Actions CI status after pushing changes. Triggers after every `git push` in projects with a `.github/workflows` directory. Monitors build status, reports results, and helps debug failures.
---

# CI Watcher

After performing a `git push` in a project with `.github/workflows`, check CI status.

## Workflow

1. **After pushing**, wait before checking (CI needs time to start)
2. **Determine polling strategy** based on project:
   - Small projects / fast CI: wait 30-60s initially, poll every 15-30s
   - Large projects / slow CI: wait 2-5min initially, poll every 30-60s
   - Consider workflow file complexity, project size, and any prior knowledge
3. **Check status** using the check_ci.sh script or `gh run list`
4. **On success**: Report and continue
5. **On failure**: Fetch logs, analyze the error, propose a fix, and ask user if they want it implemented

## Checking Status

Use the bundled script:

```bash
scripts/check_ci.sh              # Check once
scripts/check_ci.sh --wait 300   # Poll for up to 5 minutes
```

Or directly with gh CLI:

```bash
# List recent runs for current branch
gh run list --branch $(git branch --show-current) --limit 1

# View failed logs
gh run view <run-id> --log-failed
```

## On Failure

1. Fetch failure logs: `gh run view <run-id> --log-failed`
2. Analyze the error and identify root cause
3. Propose a specific fix with code changes
4. Ask: "CI failed due to [reason]. I can fix this by [solution]. Should I implement this fix?"

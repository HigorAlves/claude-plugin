---
description: Show pipeline status across all active Compozy orchestrations
allowed-tools:
  - Read
  - Glob
---

# Compozy: Pipeline Status

Quick read-only command to check the status of all active orchestrations.

## Actions

1. **Scan for orchestrations** — Glob for `compozy/*/files/checkpoint.md` in the current project root

2. **If no orchestrations found**: Report "No active Compozy orchestrations found." and stop.

3. **For each checkpoint found**, read the file and extract:
   - `**Command**` — originating command (orchestrate, sentry-fix, jira)
   - `**Phase**` — last completed phase number and name
   - `**Status**` — complete, in_progress, or failed
   - `**Branch name**` — the git branch
   - `**Auto mode**` — yes/no
   - `**Started**` — timestamp
   - Any additional context fields (Sentry input, Jira input, Flow, etc.)

4. **Present a summary table**:

   ```
   ## Active Orchestrations

   | Branch | Command | Phase | Status | Started |
   |--------|---------|-------|--------|---------|
   | feat/142-notification-prefs | orchestrate | 5 — Execution (3/6 tasks) | in_progress | 2026-03-15 |
   | fix/PROJ-789-login-bug | jira (bug) | 3 — Root Cause | complete | 2026-03-14 |
   ```

5. **For each in-progress orchestration**, also show:
   - If Phase 5: task completion count from `progress.md` (if it exists)
   - If blocked: the blocker description from the checkpoint
   - Suggested next action: "Run `/compozy:resume` to continue" or "Run `/compozy:resume [phase]` to restart from phase [N]"

6. **Check for stale orchestrations** — If any checkpoint's `**Started**` date is more than 7 days old, flag it: "This orchestration may be stale. Consider cleaning up with `rm -rf compozy/<dir>`."

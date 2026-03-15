---
description: Show pipeline status across all active Compozy orchestrations
allowed-tools:
  - Read
  - Glob
---

# Compozy: Pipeline Status

Quick read-only command to check the status of all active orchestrations.

## Actions

1. **Scan for orchestrations** — First check for `compozy/compozy.json` (central registry) at the project root. This is the primary data source and gives a complete picture in a single read.

2. **If central registry exists**, read it and use the `orchestrations` array:
   - Each entry has: `session_id`, `command`, `status`, `branch`, `input`, `workspace`, `current_phase`, `total_phases`, `progress`, `created_at`, `updated_at`, and `detail_path`
   - For richer detail on any specific orchestration, follow `detail_path` to read the per-orchestration `compozy.json`

3. **If central registry does NOT exist** (backwards compatibility), fall back to scanning:
   - Glob for `compozy/*/files/checkpoint.md` in the current project root
   - For each checkpoint found, read the file and extract: `**Command**`, `**Phase**`, `**Status**`, `**Branch name**`, `**Auto mode**`, `**Started**`, and any additional context fields

4. **If no orchestrations found** (neither registry nor checkpoints): Report "No active Compozy orchestrations found." and stop.

5. **Present a summary table**:

   ```
   ## Active Orchestrations

   | Branch | Command | Phase | Status | Progress | Started |
   |--------|---------|-------|--------|----------|---------|
   | feat/142-notification-prefs | orchestrate | 5/7 | in_progress | 3/6 tasks (Wave 2 of 3) | 2026-03-15 |
   | fix/PROJ-789-login-bug | jira (bug) | 3/6 | in_progress | Root cause identified | 2026-03-14 |
   | feat/PROJ-567-settings | jira (story) | 6/6 | complete | PR created | 2026-03-13 |
   ```

   When data comes from the central registry, use `progress` field directly. When from checkpoints, derive progress from the phase-specific fields.

6. **For each in-progress orchestration**, also show:
   - If Phase 5: task completion count — from registry `progress` field, or from `progress.md` if using checkpoint fallback
   - Workspace info: whether running in main workspace or a worktree (and which path)
   - If blocked: the blocker description
   - Suggested next action: "Run `/compozy:resume` to continue" or "Run `/compozy:resume [phase]` to restart from phase [N]"

7. **Check for stale orchestrations** — If any orchestration's `created_at` (or `**Started**` from checkpoint) is more than 7 days old, flag it: "This orchestration may be stale. Consider cleaning up with `rm -rf compozy/<dir>`."

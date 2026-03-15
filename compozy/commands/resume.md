---
description: Resume an interrupted Compozy orchestration from the last checkpoint
argument-hint: "[phase-number]"
allowed-tools:
  - "Bash(gh issue view:*)"
  - "Bash(gh issue list:*)"
  - "Bash(gh pr create:*)"
  - "Bash(gh pr view:*)"
  - "Bash(git *)"
  - "Bash(npm *:*)"
  - "Bash(yarn *:*)"
  - "Bash(pnpm *:*)"
  - "Bash(npx *:*)"
  - "Bash(go *:*)"
  - "Bash(cargo *:*)"
  - "Bash(pip *:*)"
  - "Bash(make *:*)"
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Task
  - AskUserQuestion
  - "mcp__plugin_github_github__*"
  - "mcp__plugin_sentry_sentry__*"
  - "mcp__jira_*"
---

# Compozy: Resume Orchestration

Resume an interrupted Compozy pipeline from the last checkpoint or a specified phase.

## Core Principles

- **Never add AI attribution** — Do not include "Generated with Claude", "AI-generated", or similar references
- **Never mention "CLAUDE.md"** — Refer to "project guidelines" or "our guidelines" instead
- **Restore full context** before resuming — read all `$COMPOZY_DIR/` artifacts to rebuild understanding
- **Always use interactive UI** — Every user interaction MUST use the `AskUserQuestion` tool with clear menu options. Never ask questions via plain text output — always present structured choices so the user can click to respond

## Working Directory

Pipeline artifacts are stored in `compozy/<branch-name>/files/` — see the orchestrate command for details on this convention. Throughout this document, **`$COMPOZY_DIR`** refers to the resolved directory path for the orchestration being resumed.

---

## Arguments

- **$1** (optional): Phase number to jump to (1-7). If omitted, resume from last checkpoint.

---

## Step 1: Verify State

1. Check that `compozy/` directory exists at the project root
   - If not: "No Compozy state found. Run `/compozy:orchestrate` to start a new pipeline."

2. **Discover the orchestration directory**:
   - List subdirectories under `compozy/` (these are sanitized branch names)
   - For each, check if `<subdir>/files/checkpoint.md` exists
   - If **one** orchestration found: use it as `$COMPOZY_DIR`
   - If **multiple** found: use `AskUserQuestion` to ask which to resume (list branch names as options)
   - If **none** have a checkpoint: "No checkpoint found. Run `/compozy:orchestrate` to start a new pipeline."

3. Read `$COMPOZY_DIR/checkpoint.md` and parse:
   - **Command** field — identifies the originating command (`orchestrate`, `sentry-fix`, or `jira`). If no `**Command**` field is present, assume `orchestrate` for backwards compatibility. The resume flow follows that command's phase definitions.
   - Last completed phase number
   - Status of that phase
   - Branch name (`$BRANCH_NAME`)
   - Any notes or context

4. **Validate checkpoint integrity**:
   - Verify required fields exist: `**Phase**`, `**Status**`, `**Branch name**`, `**Compozy dir**`
   - Verify phase number is a valid integer (0-7 for orchestrate, 0-6 for sentry-fix/jira)
   - Verify status is one of: `complete`, `in_progress`, `failed`
   - Verify `$COMPOZY_DIR` path exists on disk
   - If the `**Command**` field references `sentry-fix`, verify `**Sentry input**` exists
   - If the `**Command**` field references `jira`, verify `**Jira input**` and `**Flow**` exist
   - If any validation fails, report the specific error and suggest: "The checkpoint may be corrupted. Run `/compozy:orchestrate` to start fresh, or manually fix `$COMPOZY_DIR/checkpoint.md`."

5. Determine resume point:
   - If `$1` provided: use that phase number (warn if jumping backward or skipping phases)
   - If no argument: resume from the phase after the last completed one

## Step 2: Restore Context

Read all available `$COMPOZY_DIR/` artifacts to rebuild context:

1. **Always read** (if they exist):
   - `$COMPOZY_DIR/checkpoint.md` — current state
   - `$COMPOZY_DIR/tech-spec.md` — the approved spec

2. **Read based on resume phase**:

   **For `orchestrate` command:**
   - Resuming Phase 2+: read `$COMPOZY_DIR/codebase-context.md`
   - Resuming Phase 4+: read `$COMPOZY_DIR/task-manifest.md`
   - Resuming Phase 5+: read `$COMPOZY_DIR/progress.md`

   **For `sentry-fix` command:**
   - Resuming Phase 2+: read `$COMPOZY_DIR/sentry-analysis.md` (if exists)
   - Resuming Phase 3+: read `$COMPOZY_DIR/root-cause.md` (if exists)
   - Resuming Phase 5+: read `$COMPOZY_DIR/verification.md` (if exists)

   **For `jira` command:**
   - Resuming Phase 2+: read `$COMPOZY_DIR/ticket-analysis.md` (if exists)
   - Resuming Phase 3+ (bug flow): read `$COMPOZY_DIR/root-cause.md` (if exists)
   - Resuming Phase 3+ (story flow): read `$COMPOZY_DIR/tech-spec.md` (if exists)
   - Resuming Phase 4+ (story flow): read `$COMPOZY_DIR/task-manifest.md`, `$COMPOZY_DIR/progress.md` (if exist)
   - Resuming Phase 5+: read `$COMPOZY_DIR/verification.md` (if exists)
   - Note: Check `**Flow**` field in checkpoint (`bug` or `story`) to determine which artifacts to read

3. Summarize restored context:
   ```
   ## Resuming Compozy Pipeline

   **Last checkpoint**: Phase [N] — [Phase Name]
   **Resuming from**: Phase [N+1] — [Phase Name]
   **Branch**: [branch name from checkpoint]
   **Working dir**: [resolved $COMPOZY_DIR path]
   **Spec**: [title from tech-spec.md]
   **Tasks**: [count] tasks across [count] waves
   **Progress**: [X]/[Y] tasks completed
   ```

## Step 3: Resume Execution

Continue the orchestration pipeline from the determined phase. Follow the exact same workflow as defined in the orchestrate command for each phase.

**Phase-specific resume notes**:

### Resuming Phase 1 (PRD Analysis)
- Re-run PRD analysis from scratch (no partial state for this phase)

### Resuming Phase 2 (Codebase Discovery)
- Re-run codebase discovery (it's fast and context may have changed)

### Resuming Phase 3 (Tech Spec)
- If spec exists, use `AskUserQuestion`:
  ```
  AskUserQuestion:
    question: "An existing tech spec was found. What would you like to do?"
    header: "Spec"
    options:
      - label: "Use existing"
        description: "Continue with the current spec as-is"
      - label: "Regenerate"
        description: "Generate a new spec from scratch"
    multiSelect: false
  ```
- If no spec: generate from scratch using available requirements

### Resuming Phase 4 (Task Decomposition)
- If manifest exists, use `AskUserQuestion`:
  ```
  AskUserQuestion:
    question: "An existing task manifest was found. What would you like to do?"
    header: "Tasks"
    options:
      - label: "Use existing"
        description: "Continue with the current task breakdown"
      - label: "Redecompose"
        description: "Generate a new task breakdown from the spec"
    multiSelect: false
  ```
- If no manifest: decompose from the approved spec

### Resuming Phase 5 (Task Execution)
- Read progress to determine which waves/tasks are complete
- Skip completed tasks
- Resume from the first incomplete wave
- Re-run failed tasks (they may succeed with fresh context)

### Resuming Phase 6 (Review)
- Re-run integration validation and quality review (code may have changed)

### Resuming Phase 7 (PR Generation)
- Check if branch already exists
- Check if PR already exists
- If PR exists, use `AskUserQuestion`:
  ```
  AskUserQuestion:
    question: "A PR already exists for this branch. What would you like to do?"
    header: "PR"
    options:
      - label: "Update existing"
        description: "Push changes and update the existing PR"
      - label: "Create new"
        description: "Create a fresh PR from current state"
    multiSelect: false
  ```

---

## Sentry-Fix Phase Resume Notes

When the checkpoint's `**Command**` field is `sentry-fix`, follow these phase definitions instead of the orchestrate phases above.

### Resuming Phase 1 (Issue Discovery)
- Re-run issue discovery from scratch — call `get_issue_details` with the Sentry issue ID from the checkpoint

### Resuming Phase 2 (Deep Sentry Analysis)
- Read `$COMPOZY_DIR/sentry-analysis.md` if it exists
- If stale (e.g., checkpoint notes indicate incomplete analysis), re-gather Sentry data via the `sentry-analyzer` agent
- If complete, proceed to Phase 3

### Resuming Phase 3 (Root Cause Investigation)
- Read `$COMPOZY_DIR/root-cause.md` if it exists
- Cross-reference the root cause against the current codebase (files may have changed since the analysis)
- If root cause file is missing, re-run investigation starting from the Sentry analysis

### Resuming Phase 4 (Implementation)
- Check if a reproduction test already exists (look for test files in the diff)
- Check if a fix has been partially applied
- If test exists but fix is incomplete, continue from fix implementation
- If no test yet, start from writing the reproduction test

### Resuming Phase 5 (Verification)
- Re-run verification from scratch (tests should be re-run fresh, not trusted from prior runs)

### Resuming Phase 6 (PR & Resolution)
- Check if branch already exists and has commits
- Check if PR already exists
- Check if Sentry issue is already resolved
- Only perform actions not yet completed

## Jira Phase Resume Notes

When the checkpoint's `**Command**` field is `jira`, follow these phase definitions. The checkpoint also stores a `**Flow**` field (`bug` or `story`) which determines the investigation and implementation path.

### Resuming Phase 1 (Ticket Discovery)
- Re-fetch the ticket via Jira MCP tools using the ticket key from the checkpoint — status may have changed since the last run
- Re-detect `$FLOW` from ticket type

### Resuming Phase 2 (Deep Ticket Analysis)
- Read `$COMPOZY_DIR/ticket-analysis.md` if it exists
- Check `$FLOW` from checkpoint to know which team pattern to use (if `--team`)
- If stale or incomplete, re-gather Jira data via the `jira-analyzer` agent
- If complete, proceed to Phase 3

### Resuming Phase 3 (Investigation)
- **If `$FLOW = bug`**: Read `$COMPOZY_DIR/root-cause.md` if it exists. Cross-reference root cause against the current codebase (files may have changed). If missing, re-run investigation from ticket analysis.
- **If `$FLOW = story`**: Read `$COMPOZY_DIR/tech-spec.md` if it exists. Check if it's still current against the codebase. If missing, re-run spec generation from ticket analysis.

### Resuming Phase 4 (Implementation)
- Check if tests and/or implementation already exist (look for test files and changes in the diff)
- **If `$FLOW = bug`**: Check for existing reproduction test; if fix is partially applied, continue from where it left off
- **If `$FLOW = story`**: Read `$COMPOZY_DIR/task-manifest.md` and `$COMPOZY_DIR/progress.md` to determine which waves/tasks are complete; skip completed tasks, resume from first incomplete wave

### Resuming Phase 5 (Verification)
- Re-run verification from scratch — tests and acceptance criteria checks should be run fresh, not trusted from prior runs

### Resuming Phase 6 (PR & Ticket Resolution)
- Check if branch already exists and has commits
- Check if PR already exists
- Check current Jira ticket status — only transition if not already in the target state
- Check if Jira comment with PR link was already added
- Only perform actions not yet completed

## Error Handling

### Missing Artifacts
If a required artifact for the resume phase is missing, use `AskUserQuestion`:
```
AskUserQuestion:
  question: "The [artifact] is missing. How would you like to proceed?"
  header: "Missing"
  options:
    - label: "Run from Phase [N]"
      description: "Resume from the phase that generates this artifact"
    - label: "Abort"
      description: "Stop and start fresh with /compozy:orchestrate"
  multiSelect: false
```

### Stale Checkpoint
If the checkpoint references files that no longer exist or have changed, use `AskUserQuestion` to ask whether to re-run from the affected phase or abort.

### Phase Jump Warning
If the user requests jumping to a phase that skips prerequisite work, use `AskUserQuestion`:
```
AskUserQuestion:
  question: "Phase [N] requires artifacts from Phase [M] which don't exist. What would you like to do?"
  header: "Skip"
  options:
    - label: "Run Phase [M] first"
      description: "Execute the prerequisite phase, then continue"
    - label: "Abort"
      description: "Stop and run /compozy:orchestrate from the beginning"
  multiSelect: false
```

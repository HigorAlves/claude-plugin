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
   - Last completed phase number
   - Status of that phase
   - Branch name (`$BRANCH_NAME`)
   - Any notes or context

4. Determine resume point:
   - If `$1` provided: use that phase number (warn if jumping backward or skipping phases)
   - If no argument: resume from the phase after the last completed one

## Step 2: Restore Context

Read all available `$COMPOZY_DIR/` artifacts to rebuild context:

1. **Always read** (if they exist):
   - `$COMPOZY_DIR/checkpoint.md` — current state
   - `$COMPOZY_DIR/tech-spec.md` — the approved spec

2. **Read based on resume phase**:
   - Resuming Phase 2+: read `$COMPOZY_DIR/codebase-context.md`
   - Resuming Phase 4+: read `$COMPOZY_DIR/task-manifest.md`
   - Resuming Phase 5+: read `$COMPOZY_DIR/progress.md`

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

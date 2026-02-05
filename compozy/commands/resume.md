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
  - "mcp__plugin_github_github__*"
---

# Compozy: Resume Orchestration

Resume an interrupted Compozy pipeline from the last checkpoint or a specified phase.

## Core Principles

- **Never add AI attribution** — Do not include "Generated with Claude", "AI-generated", or similar references
- **Never mention "CLAUDE.md"** — Refer to "project guidelines" or "our guidelines" instead
- **Restore full context** before resuming — read all `.compozy/` artifacts to rebuild understanding

---

## Arguments

- **$1** (optional): Phase number to jump to (1-7). If omitted, resume from last checkpoint.

---

## Step 1: Verify State

1. Check that `.compozy/` directory exists
   - If not: "No Compozy state found. Run `/compozy:orchestrate` to start a new pipeline."

2. Read `.compozy/checkpoint.md`
   - If not found: "No checkpoint found. Run `/compozy:orchestrate` to start a new pipeline."

3. Parse the checkpoint:
   - Last completed phase number
   - Status of that phase
   - Any notes or context

4. Determine resume point:
   - If `$1` provided: use that phase number (warn if jumping backward or skipping phases)
   - If no argument: resume from the phase after the last completed one

## Step 2: Restore Context

Read all available `.compozy/` artifacts to rebuild context:

1. **Always read** (if they exist):
   - `.compozy/checkpoint.md` — current state
   - `.compozy/tech-spec.md` — the approved spec

2. **Read based on resume phase**:
   - Resuming Phase 2+: read `.compozy/codebase-context.md`
   - Resuming Phase 4+: read `.compozy/task-manifest.md`
   - Resuming Phase 5+: read `.compozy/progress.md`

3. Summarize restored context:
   ```
   ## Resuming Compozy Pipeline

   **Last checkpoint**: Phase [N] — [Phase Name]
   **Resuming from**: Phase [N+1] — [Phase Name]
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
- If spec exists: ask user if they want to regenerate or use existing
- If no spec: generate from scratch using available requirements

### Resuming Phase 4 (Task Decomposition)
- If manifest exists: ask user if they want to redecompose or use existing
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
- If PR exists: ask user if they want to update it or create a new one

## Error Handling

### Missing Artifacts
If a required artifact for the resume phase is missing:
- Report what's missing
- Suggest running from an earlier phase: "The tech spec is missing. Resume from Phase 3 instead? (yes/no)"

### Stale Checkpoint
If the checkpoint references files that no longer exist or have changed:
- Warn the user
- Suggest re-running from the affected phase

### Phase Jump Warning
If the user requests jumping to a phase that skips prerequisite work:
```
Warning: Jumping to Phase 5 (Execution) but Phase 4 (Decomposition) has no manifest.
Options:
- Run Phase 4 first, then continue to Phase 5
- Abort and run /compozy:orchestrate from the beginning
```

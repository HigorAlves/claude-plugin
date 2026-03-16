---
description: Systematic debugging — find root cause before fixing, with structured investigation phases
argument-hint: "[bug description, error message, or test failure] [--auto] [--team] [--worktree] [--repo=name] [--pr] [--ex-ticket=<url>]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Task
  - AskUserQuestion
  - "Bash(npm *:*)"
  - "Bash(yarn *:*)"
  - "Bash(pnpm *:*)"
  - "Bash(npx *:*)"
  - "Bash(go *:*)"
  - "Bash(cargo *:*)"
  - "Bash(pip *:*)"
  - "Bash(make *:*)"
  - "Bash(git *)"
  - "Bash(gh pr create:*)"
  - "Bash(gh pr view:*)"
---

# Compozy Debug

You are running the Compozy debug flow — a structured, 4-phase debugging process that finds root cause before attempting fixes.

## The Iron Law

```
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
```

If you haven't completed Phase 1, you cannot propose fixes.

## Core Principles

- **NEVER commit to main/master/develop** — Always create a fix branch before any commits. If currently on a protected branch, create and switch to `fix/<bug-slug>` BEFORE making changes. This is non-negotiable.
- **No AI attribution** — No `Co-Authored-By`, no "Generated with Claude", no AI references in commits or PRs
- **Always use `AskUserQuestion`** for user interactions
- **Evidence before claims** — run commands, read output, then report
- **One variable at a time** — never change multiple things at once

## Flags

- `--auto` → Full autopilot. Skip ALL user interactions — make best-guess decisions at every checkpoint. Auto-approves root cause hypotheses, auto-selects fix approach, auto-runs verification. The debug flow runs end-to-end without stopping.
- `--team` → Enable team debugging. Dispatches 3 investigation agents in parallel (Data Flow Tracer, Change Analyst, Pattern Scout), then synthesizes findings. See `compozy:team-agents` skill for the full Debugging Team pattern.
- `--worktree` → Run debugging in an isolated git worktree. Creates a worktree using the `compozy:worktrees` skill before investigation begins. This allows running multiple Claude instances on different bugs in parallel without file conflicts. The worktree branch is named `fix/<bug-slug>`.
- `--repo=<name>` → When running from a parent directory that contains multiple repositories, `cd` into the named repository before starting. Example: `--repo=Discover` will `cd Discover` first.
- `--pr` → After fixing the bug, automatically create a branch (if not already on one), commit, push, and open a pull request. Runs Phase 5 (PR Creation) after Phase 4. Implies committing the fix.
- `--ex-ticket=<url>` → Associate an external ticket URL (Linear, Notion, internal tools, etc.) with this orchestration. Stored in `$COMPOZY_DIR/compozy.json` as `external_ticket.url` and included in the PR description if a PR is created.

## Process

### Phase 0: Setup (if `--repo` or `--worktree`)

1. **Repository selection** — If `--repo=<name>` is set, `cd` into that directory first. Verify it's a git repository. If not found, report error and stop.
2. **Worktree creation** — If `--worktree` flag is set:
   - Derive a branch name from the bug description: `fix/<bug-slug>` (lowercase, hyphens, max 50 chars)
   - Use the `compozy:worktrees` skill to create an isolated worktree
   - All subsequent phases run inside the worktree

3. **Create `$COMPOZY_DIR`** — `compozy/<sanitized-branch-name>/files/`

4. **Create `$COMPOZY_DIR/compozy.json`** — the per-orchestration detail file with:
    - `session_id`: generate a UUID (`uuidgen` or `python3 -c "import uuid; print(uuid.uuid4())"`)
    - `claude_session_id`: capture from `python3 -c "import json; print(json.load(open('$HOME/.claude/sessions/' + str($PPID) + '.json')).get('sessionId', ''))" 2>/dev/null`. If the command fails or returns empty, store `null`. This enables resuming the Claude Code session later via `claude --resume <id>`.
    - `schema_version`: `"1.0.0"`, `command`: `"debug"`, `status`: `"in_progress"`
    - `created_at` / `updated_at`: current ISO-8601 timestamp
    - `repository`: from `git remote get-url origin`, `git rev-parse --show-toplevel`, default branch
    - `workspace`, `branch`, `input`, `flags`: same structure as orchestrate
    - `external_ticket`: `{ url: "<url>" }` if `--ex-ticket` was provided, otherwise omit
    - `pipeline`: `{ current_phase: 0, total_phases: 5, phases: [{ number: 0, name: "Setup", status: "complete", started_at, completed_at }] }`
    - `artifacts`: `{ checkpoint: { path: "checkpoint.md", created_at, updated_at, size_bytes, created_by: { type: "command", name: "debug" }, summary: "Phase 0 — Setup complete" } }`
    - `contributors.human`: from git config, `contributors.agents`: `[]`

5. **Register in central registry** `compozy/compozy.json`:
    - If the file doesn't exist: create it with `schema_version`, `repository` block, and empty `orchestrations` array
    - Append entry with: `session_id`, `command: "debug"`, `status`, `branch`, `input`, `workspace`, `current_phase: 0`, `total_phases: 5`, `progress: "Setup complete"`, timestamps, `detail_path`

### Phase 1: Root Cause Investigation

**If `--team` flag is set:** Use the `compozy:team-agents` skill's Debugging Team pattern. Dispatch 3 agents simultaneously:
- **Data Flow Tracer** — traces the error backward through call chains
- **Change Analyst** — examines git history for suspicious changes
- **Pattern Scout** — finds similar working code and identifies differences

Synthesize their findings, then present the consolidated root cause hypothesis to the user. Skip the manual investigation steps below and proceed to Phase 2.

**If solo mode (default):**

**BEFORE attempting ANY fix:**

1. **Read the bug description** from `$ARGUMENTS` or ask the user to describe it

2. **Read Error Messages Carefully**

   Don't skip past errors or warnings — they often contain the exact solution.
   - Read stack traces completely, from bottom to top
   - Note line numbers, file paths, error codes
   - Look for "caused by" chains — the deepest cause is usually the real one
   - Check for warnings that preceded the error

3. **Reproduce Consistently**

   Can you trigger it reliably?
   - Run the failing test or trigger the bug
   - Verify it fails the same way every time
   - Note exact error messages and output
   - If not reproducible → gather more data, don't guess
   - If intermittent → look for timing, ordering, or state dependencies

4. **Check Recent Changes**

   What changed that could cause this?
   ```bash
   git diff                    # Unstaged changes
   git diff --cached           # Staged changes
   git log --oneline -10       # Recent commits
   git diff HEAD~3..HEAD       # Last 3 commits
   ```
   - New dependencies or version bumps?
   - Configuration changes?
   - Environmental differences (CI vs local)?

5. **Gather Evidence in Multi-Component Systems**

   **WHEN system has multiple components (CI → build → deploy, API → service → database):**

   Add diagnostic instrumentation at EACH component boundary:
   ```bash
   # At each layer boundary, log what enters and exits:
   echo "=== Layer N input: ==="
   echo "VAR: ${VAR:+SET}${VAR:-UNSET}"

   # Run once to gather evidence showing WHERE it breaks
   # THEN analyze evidence to identify failing component
   # THEN investigate that specific component
   ```

   **This reveals:** Which layer fails — don't guess, instrument and observe.

6. **Trace Data Flow**

   See `compozy:systematic-debugging` skill for the complete backward tracing technique.

   **Quick version:**
   - Where does the bad value originate?
   - What called this function with the bad value?
   - Keep tracing up the call chain until you find the source
   - Fix at source, not at symptom

   **Add instrumentation when you can't trace manually:**
   ```typescript
   const stack = new Error().stack;
   console.error('DEBUG:', { value, cwd: process.cwd(), stack });
   ```
   Use `console.error()` in tests — logger may be suppressed.

Present findings (skip if `--auto`) using `AskUserQuestion`:
```
AskUserQuestion:
  question: "Root cause investigation complete. Here's what I found: [findings]. How to proceed?"
  header: "Root Cause Analysis"
  options:
    - label: "Proceed to fix"
      description: "Root cause identified, proceed to hypothesis testing"
    - label: "Investigate more"
      description: "Need more investigation (provide direction via Other)"
    - label: "Discuss"
      description: "Let's discuss the findings before proceeding"
  multiSelect: false
```
If `--auto`: proceed to fix immediately.

**Update compozy.json** (if `$COMPOZY_DIR` exists):
- Detail file: Set `pipeline.current_phase` to `1`. Add Phase 1 to `pipeline.phases` with `{ number: 1, name: "Root Cause Investigation", status: "complete", started_at, completed_at }`. Update `updated_at`.
- Central registry: Update `current_phase` to `1`, `progress` to `"Root cause investigation complete"`, `updated_at` to now.

### Phase 2: Pattern Analysis

1. **Find working examples** — similar working code in the same codebase
2. **Compare** — what's different between working and broken?
3. **Identify differences** — list every difference, however small
4. **Understand dependencies** — what components, config, environment does this need?

### Phase 3: Hypothesis and Testing

1. **Form single hypothesis**: "I think X is the root cause because Y"
2. **Test minimally**: make the SMALLEST possible change
3. **Verify**: did it work?
   - Yes → Phase 4
   - No → form NEW hypothesis (don't add more fixes on top)

**If 3+ fixes have failed:** STOP. Question the architecture.

Use `AskUserQuestion` (skip if `--auto`):
```
AskUserQuestion:
  question: "3+ fix attempts have failed. This may be an architectural problem. How to proceed?"
  header: "Architecture Question"
  options:
    - label: "Question architecture"
      description: "Step back and evaluate if the pattern is fundamentally sound"
    - label: "Try one more fix"
      description: "I have a specific idea (describe via Other)"
    - label: "Stop here"
      description: "Stop debugging, revisit later"
  multiSelect: false
```
If `--auto`: question architecture automatically, then retry.

**Update compozy.json** (if `$COMPOZY_DIR` exists):
- Detail file: Set `pipeline.current_phase` to `3`. Add phases 2-3 to `pipeline.phases`. Update `updated_at`.
- Central registry: Update `current_phase` to `3`, `progress` to `"Hypothesis validated"`, `updated_at` to now.

### Phase 4: Implementation

1. **Write failing test** reproducing the bug (use `compozy:tdd` discipline)
2. **Verify the test fails** for the right reason
3. **Implement single fix** addressing the root cause
4. **Verify the test passes**
5. **Run full test suite** to check for regressions
6. **Report results** with evidence (test output, not claims)

Present results (skip if `--auto`):
```
AskUserQuestion:
  question: "Bug fixed. [Test output summary]. What's next?"
  header: "Fix Complete"
  options:
    - label: "Done"
      description: "Fix verified, move on"
    - label: "Add defense-in-depth"
      description: "Add validation at multiple layers to prevent recurrence"
    - label: "Commit"
      description: "Create a commit with this fix"
  multiSelect: false
```
If `--auto`: commit the fix automatically.

**Update compozy.json** (if `$COMPOZY_DIR` exists):
- Detail file: Set `pipeline.current_phase` to `4`. Add Phase 4 to `pipeline.phases` with `{ number: 4, name: "Implementation", status: "complete", started_at, completed_at }`. Update `updated_at`.
- Central registry: Update `current_phase` to `4`, `progress` to `"Fix implemented"`, `updated_at` to now.

### Phase 5: PR Creation (if `--pr`)

If `--pr` flag is set, after the fix is committed:

1. **Ensure on a branch** — If on `main`/`master`, create and switch to `fix/<bug-slug>`
2. **Run full test suite** — verify everything passes before pushing
3. **Push** — `git push -u origin <branch>`
4. **Create PR**:
   ```bash
   gh pr create --title "fix: <short bug description>" --body "$(cat <<'EOF'
   ## Summary
   [If --ex-ticket was provided: `- **External ticket**: <url>`]
   - Root cause: <1-line root cause>
   - Fix: <1-line fix description>

   ## Test Plan
   - [x] Failing test added reproducing the bug
   - [x] Fix implemented, test passes
   - [x] Full test suite passes
   EOF
   )"
   ```
5. **Report PR URL**

**Update compozy.json** (if `$COMPOZY_DIR` exists):
- Detail file: Set `pipeline.current_phase` to `5`. Set `status` to `"complete"`. Add Phase 5 to `pipeline.phases` with `{ number: 5, name: "PR Creation", status: "complete", started_at, completed_at }`. Update `updated_at`.
- Central registry: Set `status` to `"complete"`, `current_phase` to `5`, `progress` to `"PR created"`, `updated_at` to now.

6. **Cleanup worktree** (if `--worktree` was used): `git worktree remove <path>`

If `--auto` + `--pr`: the entire flow runs without stopping — debug → fix → commit → push → PR.

## Red Flags — STOP and Return to Phase 1

- "Quick fix for now, investigate later"
- "Just try changing X and see"
- "It's probably X, let me fix that"
- "I don't fully understand but this might work"
- Proposing solutions before tracing data flow
- "One more fix attempt" (when already tried 2+)

---
description: Spec-driven development orchestration — analyze requirements, generate tech specs, decompose into parallel tasks, execute, review, and create PRs
argument-hint: "[PRD text, file path, or GitHub issue URL/number] [--auto] [--team] [--worktree] [--repo=name] [--ex-ticket=<url>] [--jira-sync=<PROJECT|TICKET>]"
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
  - "mcp__plugin_atlassian_atlassian__*"
  - "mcp__jira_*"
---

# Compozy: Spec-Driven Development Orchestration

You are running the Compozy pipeline — a structured workflow that transforms product requirements into a reviewed pull request through technical specification, parallel task execution, and quality gates.

## Core Principles

- **NEVER commit to main/master/develop** — Always create a feature branch before any commits. If currently on a protected branch, create and switch to a new branch BEFORE making changes. This is non-negotiable.
- **Never add AI attribution** — Do not include "Generated with Claude", "AI-generated", `Co-Authored-By`, or any similar references in code, comments, commits, or PR descriptions. Never add co-author trailers to commits.
- **Never mention "CLAUDE.md"** — Refer to "project guidelines" or "our guidelines" instead
- **Spec is the source of truth** — All implementation follows the approved spec. No ad-hoc additions
- **File exclusivity** — During parallel execution, each file is owned by exactly one task agent
- **Quality gates** — The user approves at key checkpoints before proceeding
- **Checkpoint everything** — Save state after each phase for recovery via `/compozy:resume`
- **Always use interactive UI** — Every user interaction MUST use the `AskUserQuestion` tool with clear menu options. Never ask questions via plain text output — always present structured choices with `AskUserQuestion` so the user can click to respond. The user can always select "Other" for free-text input when none of the options fit

---

## Working Directory

All pipeline artifacts are stored in `compozy/<branch-name>/files/` where `<branch-name>` is the sanitized branch name determined in Phase 0. The branch name is derived from the input:
- **GitHub issue**: `feat/<issue-number>-<short-slug>` or `fix/<issue-number>-<short-slug>`
- **Inline text or file**: `feat/<short-slug>` or `fix/<short-slug>`

The branch name is sanitized for directory use: slashes are replaced with dashes. For example, branch `feat/142-notification-prefs` creates directory `compozy/feat-142-notification-prefs/files/`.

Throughout this document, **`$COMPOZY_DIR`** refers to this resolved directory path (e.g., `compozy/feat-142-notification-prefs/files/`). The actual git branch name (with slashes) is stored in the checkpoint as `$BRANCH_NAME`.

---

## Arguments

Parse the user's input from `$ARGUMENTS`:

**Input source** (first positional argument):
- **GitHub issue URL or number** (e.g., `#42`, `42`, `https://github.com/org/repo/issues/42`) → fetch with `gh issue view`
- **File path** (e.g., `./prd.md`, `docs/requirements.txt`) → read with Read tool
- **Inline text** (anything else) → use directly as the PRD
- **Empty** → use `AskUserQuestion` to ask user to describe what they want to build (they'll provide via "Other" free-text)

**Flags**:
- `--auto` → Full autopilot. Skip ALL gates and user interactions — make best-guess decisions at every checkpoint and keep driving. No `AskUserQuestion` calls. Defaults: approve spec as-is, proceed with recommended task decomposition, fix all critical+moderate review issues, include artifacts in commit, fix failing tests. The pipeline runs end-to-end without stopping.
- `--team` → Enable team mode for Phases 3, 4, and 5. In Phase 3, a spec critic and testability reviewer validate the generated spec. In Phase 4, a dependency auditor and complexity estimator review the task breakdown. In Phase 5, implementation teams include reviewer and architect agents. See `compozy:team-agents` skill for team compositions and flow.
- `--worktree` → Run the entire pipeline in an isolated git worktree. Creates a worktree using the `compozy:worktrees` skill before any work begins (Phase 0). This allows running multiple Claude instances on different tasks in parallel without file conflicts.
- `--repo=<name>` → When running from a parent directory that contains multiple repositories, `cd` into the named repository before starting the pipeline. Example: `--repo=Discover` will `cd Discover` first. If the directory doesn't exist, report an error.
- `--ex-ticket=<url>` → Associate an external ticket URL (Linear, Notion, internal tools, etc.) with this orchestration. Stored in `$COMPOZY_DIR/compozy.json` as `external_ticket.url` and included in the PR description if a PR is created.
- `--jira-sync=<value>` → Sync task manifest to Jira for progress visibility. Value can be a project key (e.g., `WOR`) to create a new parent Story, or an existing ticket key (e.g., `WOR-361`) to add subtasks under it. Creates subtasks after Phase 4, updates status during Phase 5, adds PR link after Phase 7. Requires a Jira MCP server (`mcp__plugin_atlassian_atlassian__*` or `mcp__jira_*`).

---

## Phase 0: Setup

**Goal**: Initialize the orchestration environment and determine the working directory

**Actions**:
1. **Repository selection** — If `--repo=<name>` is set, `cd` into that directory first. Verify it's a git repository (`git rev-parse --git-dir`). If not found, report error and stop.
2. Detect the input source type and load the PRD content
3. Check for `--auto` flag in arguments
4. **Generate the branch name** from the input:
   - GitHub issue: `feat/<issue-number>-<slug>` (or `fix/` for bug labels) — derive slug from issue title
   - Inline text or file: `feat/<slug>` — derive slug from the first few meaningful words
   - Rules: lowercase, hyphens for spaces, max 50 characters, no special characters
5. **Sanitize for directory use**: replace `/` with `-` to get the directory name
6. Create `compozy/<sanitized-branch-name>/files/` directory (the `$COMPOZY_DIR`)
7. **Worktree creation** — If `--worktree` flag is set, use the `compozy:worktrees` skill to create an isolated worktree for this work. All subsequent phases run inside the worktree. This enables running multiple Claude instances on different tasks in parallel.
8. Create todo list tracking all 7 phases
9. Save initial checkpoint:

```markdown
# Checkpoint
**Phase**: 0 — Setup
**Status**: complete
**Input source**: [type and reference]
**Branch name**: [branch-name with slashes, e.g., feat/142-notification-prefs]
**Compozy dir**: [resolved $COMPOZY_DIR path, e.g., compozy/feat-142-notification-prefs/files]
**Auto mode**: [yes/no]
**External ticket**: [url or "none"]
**Jira sync**: [project key, ticket key, or "none"]
**Started**: [timestamp]
```

Write to `$COMPOZY_DIR/checkpoint.md`.

10. **Create `$COMPOZY_DIR/compozy.json`** — the per-orchestration detail file with:
    - `session_id`: generate a UUID (`uuidgen` or `python3 -c "import uuid; print(uuid.uuid4())"`)
    - `claude_session_id`: capture from `python3 -c "import json; print(json.load(open('$HOME/.claude/sessions/' + str($PPID) + '.json')).get('sessionId', ''))" 2>/dev/null`. If the command fails or returns empty, store `null`. This enables resuming the Claude Code session later via `claude --resume <id>`.
    - `schema_version`: `"1.0.0"`
    - `command`: `"orchestrate"`
    - `status`: `"in_progress"`
    - `created_at` / `updated_at`: current ISO-8601 timestamp
    - `repository`: from `git remote get-url origin`, `git rev-parse --show-toplevel`, `basename` of toplevel, default branch from `git symbolic-ref refs/remotes/origin/HEAD`
    - `workspace.type`: `"worktree"` if `--worktree`, otherwise `"main"`
    - `workspace.worktree_path` / `workspace.main_repo_path` / `workspace.compozy_dir` / `workspace.compozy_dir_absolute`: resolved paths
    - `branch`: `{ name: "$BRANCH_NAME", created_from: "<branch-before-checkout>", sanitized: "<directory-name>" }`
    - `input`: `{ type, source, resolved_url (if applicable), title }`
    - `flags`: `{ auto, team, worktree, repo, pr, jira_sync }`
    - `external_ticket`: `{ url: "<url>" }` if `--ex-ticket` was provided, otherwise omit
    - `pipeline`: `{ current_phase: 0, total_phases: 7, phases: [{ number: 0, name: "Setup", status: "complete", started_at, completed_at }] }`
    - `artifacts.checkpoint`: `{ path: "checkpoint.md", created_at, updated_at, size_bytes, created_by: { type: "command", name: "orchestrate" }, summary: "Phase 0 — Setup complete" }`
    - `contributors.human`: from `git config user.name`, `git config user.email`, and `gh api /user --jq .login` (if gh available)
    - `contributors.agents`: `[]`

11. **Register in central registry** `compozy/compozy.json`:
    - If the file doesn't exist: create it with `schema_version: "1.0.0"`, `repository` block (same git info as above), and empty `orchestrations` array
    - Append a new entry to `orchestrations` with: `session_id`, `command: "orchestrate"`, `status: "in_progress"`, `branch` (the full `$BRANCH_NAME`), `input` (`{ type, source, title }`), `workspace` (`{ type, path }` — path is relative to repo root), `current_phase: 0`, `total_phases: 7`, `progress: "Setup complete"`, `created_at`, `updated_at`, and `detail_path` pointing to `$COMPOZY_DIR/compozy.json` (relative to repo root)

---

## Phase 1: PRD Analysis `[GATE unless --auto]`

**Goal**: Understand what needs to be built

**Actions**:
1. Launch the `prd-analyzer` agent (opus) with the PRD content:
   - `subagent_type`: `compozy:prd-analyzer`
   - `model`: `opus`
   - Provide the full PRD text
   - Ask it to extract requirements, identify gaps, and generate clarifying questions

2. Present the analysis to the user:
   - Core objective
   - Requirements table (FR and NFR)
   - Assumptions made
   - Clarifying questions (blocking and non-blocking)

3. **Gate** (skip if `--auto`):
   - If there are blocking questions, present each using `AskUserQuestion` with relevant answer options
   - Then use `AskUserQuestion` for the approval gate:
     ```
     AskUserQuestion:
       question: "Does this PRD analysis capture your intent?"
       header: "PRD Review"
       options:
         - label: "Approved"
           description: "Analysis looks correct, proceed to codebase discovery"
         - label: "Revise"
           description: "Re-run the analysis with your feedback (provide via Other)"
       multiSelect: false
     ```
   - If "Revise" or "Other" with feedback: re-run analyzer with feedback
   - If `--auto`: proceed with recommended defaults for all questions

4. Save analyzed requirements for Phase 3

5. Update checkpoint:
```markdown
**Phase**: 1 — PRD Analysis
**Status**: complete
**Requirements**: [count] FR, [count] NFR
**Questions answered**: [count]
```

**Update compozy.json**:
- Detail file (`$COMPOZY_DIR/compozy.json`): Set `pipeline.current_phase` to `1`. Add Phase 1 to `pipeline.phases` with `{ number: 1, name: "PRD Analysis", status: "complete", started_at, completed_at, agent: "prd-analyzer", model: "opus" }`. Add `prd-analyzer` to `contributors.agents` with `{ name: "prd-analyzer", model: "opus", phases: [1] }`. Update `updated_at`.
- Central registry (`compozy/compozy.json`): Update this orchestration's entry (match by `session_id`) — set `current_phase` to `1`, `progress` to `"PRD analyzed"`, `updated_at` to now.

---

## Phase 2: Codebase Discovery `[No gate]`

**Goal**: Understand the existing codebase architecture, patterns, and conventions

**Actions**:
1. Read CLAUDE.md and any project guidelines if they exist

2. Launch 2-3 Explore agents in parallel targeting different aspects:
   - `subagent_type`: `Explore`
   - Agent 1: "Map the project architecture — directory structure, key abstractions, module organization, build system, and technology stack. List the 10 most important files."
   - Agent 2: "Find existing features similar to [the feature being built]. Trace their implementation patterns — how routes/endpoints are structured, how services are organized, how data flows, how errors are handled. List 10 key files."
   - Agent 3 (if applicable): "Analyze testing patterns, CI/CD configuration, and deployment setup. What test framework is used? How are tests organized? List 5-10 key test files."

3. Read all key files identified by the explore agents

4. Compile findings into `$COMPOZY_DIR/codebase-context.md`:
   ```markdown
   # Codebase Context

   ## Architecture
   [High-level architecture summary]

   ## Patterns and Conventions
   - Naming: [conventions]
   - File structure: [patterns]
   - Error handling: [approach]
   - Testing: [framework and patterns]

   ## Key Files
   [List of important files with brief descriptions]

   ## Relevant Existing Features
   [Features similar to what we're building, with file references]

   ## Project Guidelines
   [Summary of CLAUDE.md and other guidelines]
   ```

5. Update checkpoint:
```markdown
**Phase**: 2 — Codebase Discovery
**Status**: complete
**Key files identified**: [count]
**Patterns documented**: [list]
```

**Update compozy.json**:
- Detail file (`$COMPOZY_DIR/compozy.json`): Set `pipeline.current_phase` to `2`. Add Phase 2 to `pipeline.phases` with `{ number: 2, name: "Codebase Discovery", status: "complete", started_at, completed_at }`. Add `artifacts.codebase_context` with `{ path: "codebase-context.md", created_at, updated_at, size_bytes, created_by: { type: "command", name: "orchestrate" }, summary: "<architecture summary>" }`. Update `updated_at`.
- Central registry (`compozy/compozy.json`): Update this orchestration's `current_phase` to `2`, `progress` to `"Codebase analyzed"`, `updated_at` to now.

---

## Phase 3: Tech Spec Generation `[GATE unless --auto]`

**Goal**: Generate a complete, implementation-ready technical specification

**Actions**:
1. Launch the `spec-generator` agent (opus) with:
   - `subagent_type`: `compozy:spec-generator`
   - `model`: `opus`
   - The analyzed requirements from Phase 1
   - The codebase context from Phase 2
   - The spec template from the spec-authoring skill
   - Instruction to fill in all 12 sections

2. Write the generated spec to `$COMPOZY_DIR/tech-spec.md`

3. **If `--team` flag is set:** Use the `compozy:team-agents` skill's Spec Review Team pattern. Dispatch 2 review agents in parallel:
   - **Spec Critic** — Reviews for gaps: missing edge cases, unclear interfaces, over-engineering, inconsistencies with codebase patterns
   - **Testability Reviewer** — Checks every acceptance criterion is testable, every interface is mockable, no untestable requirements

   Synthesize findings and fix the spec before presenting to the user. If critical issues found, re-run spec-generator with the feedback.

4. Present a summary to the user:
   ```
   ## Tech Spec Summary

   **Title**: [spec title]
   **Components**: [count] components
   **New files**: [count]
   **Modified files**: [count]
   **Architecture decisions**: [count]

   ### Key Design Choices
   - [Decision 1]: [Choice and rationale]
   - [Decision 2]: [Choice and rationale]

   ### Acceptance Criteria
   - [AC-1]: [Brief description]
   - [AC-2]: [Brief description]
   ...
   ```

5. **Gate** (skip if `--auto`) — use `AskUserQuestion`:
   ```
   AskUserQuestion:
     question: "Review the spec at $COMPOZY_DIR/tech-spec.md. How would you like to proceed?"
     header: "Spec Review"
     options:
       - label: "Approved"
         description: "Spec looks good, proceed to task decomposition"
       - label: "Revise"
         description: "Regenerate spec with your feedback (provide via Other)"
       - label: "Edit manually"
         description: "You'll edit the spec file directly, then confirm when done"
     multiSelect: false
   ```
   - If "Revise" or "Other" with feedback: re-run spec-generator with feedback, present again
   - If "Edit manually": wait for user to finish editing, then re-present for approval
   - If `--auto`: approve spec as-is and proceed

6. Update checkpoint:
```markdown
**Phase**: 3 — Tech Spec
**Status**: complete (approved)
**Spec version**: [version]
**Components**: [count]
**Files planned**: [count]
```

**Update compozy.json**:
- Detail file (`$COMPOZY_DIR/compozy.json`): Set `pipeline.current_phase` to `3`. Add Phase 3 to `pipeline.phases` with `{ number: 3, name: "Tech Spec", status: "complete", started_at, completed_at, agent: "spec-generator", model: "opus" }`. Add `artifacts.tech_spec` with `{ path: "tech-spec.md", created_at, updated_at, size_bytes, created_by: { type: "agent", name: "spec-generator", model: "opus" }, summary: "<spec summary>" }`. Add `spec-generator` to `contributors.agents` with `{ name: "spec-generator", model: "opus", phases: [3] }`. Update `updated_at`.
- Central registry (`compozy/compozy.json`): Update this orchestration's `current_phase` to `3`, `progress` to `"Spec approved"`, `updated_at` to now.

---

## Phase 4: Task Decomposition `[GATE unless --auto]`

**Goal**: Break the spec into parallel-safe tasks organized in waves

**Actions**:
1. Launch the `task-decomposer` agent (sonnet) with:
   - `subagent_type`: `compozy:task-decomposer`
   - `model`: `sonnet`
   - The approved tech spec
   - The task manifest format reference
   - Codebase conventions from Phase 2

2. Write the manifest to `$COMPOZY_DIR/task-manifest.md`

3. **If `--team` flag is set:** Use the `compozy:team-agents` skill's Decomposition Review Team pattern. Dispatch 2 review agents in parallel:
   - **Dependency Auditor** — Validates wave ordering is correct, checks for hidden dependencies between tasks, verifies file exclusivity (no two tasks in the same wave touch the same file)
   - **Complexity Estimator** — Flags tasks that are too large (should be split), identifies high-risk tasks that need opus model, checks that acceptance criteria are specific enough to implement

   Synthesize findings and fix the manifest before presenting to the user. If wave ordering or file exclusivity is wrong, re-run task-decomposer with the feedback.

4. Present the wave/task summary table:
   ```
   ## Task Plan

   | Wave | Tasks | Files | Complexity |
   |------|-------|-------|------------|
   | 1: Foundation | T-1, T-2 | 4 | Low |
   | 2: Implementation | T-3, T-4, T-5 | 8 | Medium |
   | 3: Integration | T-6 | 3 | Medium |

   Total: 6 tasks, 3 waves, max 3 parallel
   ```

5. **Gate** (skip if `--auto`) — use `AskUserQuestion`:
   ```
   AskUserQuestion:
     question: "Does this task breakdown look right?"
     header: "Task Plan"
     options:
       - label: "Proceed"
         description: "Start executing tasks wave by wave"
       - label: "Adjust"
         description: "Re-run decomposition with your feedback (provide via Other)"
     multiSelect: false
   ```
   - If "Adjust" or "Other" with feedback: re-run decomposer with feedback
   - If `--auto`: proceed without confirmation

6. Update checkpoint:
```markdown
**Phase**: 4 — Task Decomposition
**Status**: complete
**Tasks**: [count]
**Waves**: [count]
**Max parallelism**: [count]
```

**Update compozy.json**:
- Detail file (`$COMPOZY_DIR/compozy.json`): Set `pipeline.current_phase` to `4`. Add Phase 4 to `pipeline.phases` with `{ number: 4, name: "Task Decomposition", status: "complete", started_at, completed_at, agent: "task-decomposer", model: "sonnet" }`. Add `artifacts.task_manifest` with `{ path: "task-manifest.md", created_at, updated_at, size_bytes, created_by: { type: "agent", name: "task-decomposer", model: "sonnet" }, summary: "[N] tasks across [N] waves" }`. Add `task-decomposer` to `contributors.agents` with `{ name: "task-decomposer", model: "sonnet", phases: [4] }`. Update `updated_at`.
- Central registry (`compozy/compozy.json`): Update this orchestration's `current_phase` to `4`, `progress` to `"[N] tasks across [N] waves"`, `updated_at` to now.

---

## Phase 4.5: Jira Sync `[No gate — only runs if --jira-sync]`

**Goal**: Create Jira tickets from the approved task manifest for progress tracking

**Condition**: Only runs if `--jira-sync` flag is set. If the flag is not set, skip to Phase 5.

**Actions**:
1. **Verify Jira MCP availability** — attempt a lightweight call (`mcp__plugin_atlassian_atlassian__getVisibleJiraProjects` or `mcp__jira_*` equivalent). If no Jira MCP is available, warn the user and skip this phase (non-blocking).

2. **Launch `jira-sync` agent** (sonnet) in **create mode**:
   - `subagent_type`: `compozy:jira-sync`
   - `model`: `sonnet`
   - Provide:
     - Mode: `create`
     - Task manifest path: `$COMPOZY_DIR/task-manifest.md`
     - Jira target: the `--jira-sync` value (project key or existing ticket key)
     - Tech spec title: from `$COMPOZY_DIR/tech-spec.md`
     - `$COMPOZY_DIR` path

3. The agent will:
   - Create a parent Story (if project key given) or use the existing ticket
   - Create subtasks for each task in the manifest
   - Create dependency links between subtasks
   - Write `$COMPOZY_DIR/jira-sync.json` mapping file

4. **If `--team` flag is also set**: Use the Jira Sync Validation Team pattern (see `compozy/skills/team-agents/references/jira-sync-team.md`). After the Ticket Creator finishes, dispatch the Mapping Validator and Dependency Linker agents in parallel to verify correctness. Fix any issues found.

5. **Present summary to user**:
   ```
   ## Jira Sync

   **Parent**: {ticket-key} — {feature name}
   **Subtasks created**: {count}
   **Dependency links**: {count}
   ```

6. Update checkpoint:
```markdown
**Phase**: 4.5 — Jira Sync
**Status**: complete
**Parent ticket**: {key}
**Subtasks created**: {count}
```

**Update compozy.json**:
- Detail file (`$COMPOZY_DIR/compozy.json`): Add `artifacts.jira_sync` with `{ path: "jira-sync.json", parent_ticket: "{key}", subtasks_created: {count}, created_at: "ISO-8601" }`. Add `jira-sync` to `contributors.agents` with `{ name: "jira-sync", model: "sonnet", phases: [4.5] }`. Update `updated_at`.
- Central registry (`compozy/compozy.json`): Update this orchestration's `progress` to `"Jira synced ({count} subtasks)"`, `updated_at` to now.

---

## Phase 5: Task Execution `[No gate]`

**Goal**: Implement all tasks, wave by wave

**Actions**:
1. Initialize progress file `$COMPOZY_DIR/progress.md`:
   ```markdown
   # Execution Progress

   **Started**: [timestamp]
   **Spec**: $COMPOZY_DIR/tech-spec.md
   **Manifest**: $COMPOZY_DIR/task-manifest.md
   ```

2. **If `--team` flag is set:** Use the `compozy:team-agents` skill's Implementation Team pattern. For each wave, dispatch implementers in parallel, then a reviewer agent checks all outputs before proceeding. After all waves, an architect agent reviews the complete implementation for cross-wave coherence. Fix any issues found before Phase 6.

   **Pre-flight validation** (run before either mode):
   - Parse the task manifest and build a file→task map
   - For each wave, verify no two tasks in the same wave touch the same file
   - If a conflict is found, report it: "File exclusivity violation: `[file]` is owned by both `[T-X]` and `[T-Y]` in Wave [N]. Re-run Phase 4 to fix the manifest."
   - Block execution until the conflict is resolved

3. **If solo mode (default):** For each wave (sequential):

   a. **Launch all tasks in the wave in parallel** using the Task tool:
      - `subagent_type`: `compozy:task-implementer`
      - `model`: `sonnet` (or as specified in manifest)
      - For each task, provide:
        - Task definition (ID, description, files, acceptance criteria)
        - Relevant spec sections (component specs, data models, interfaces)
        - Codebase conventions from Phase 2
        - What was built in previous waves (available types/interfaces)

   b. **Collect results and handle implementer status** from all task agents:

      - **`DONE`** → Proceed normally, task ready for review
      - **`DONE_WITH_CONCERNS`** → Read the concerns. If critical (file grew too large, design issue found), address before review. If minor, note for review phase.
      - **`NEEDS_CONTEXT`** → Provide the requested context and re-dispatch the task agent
      - **`BLOCKED`** → Escalate through retry tiers:
        1. **Retry with context** — provide the missing context and re-dispatch with the same model
        2. **Retry with opus** — if still blocked, re-dispatch with `model: opus` for stronger reasoning
        3. **Decompose** — if still blocked, split the task into 2-3 subtasks and dispatch each independently
        4. **Escalate** — if all retries fail, use `AskUserQuestion` to present the blocker to the user with options: "Provide guidance" / "Skip this task" / "Abort pipeline"

   c. **Update progress** in `$COMPOZY_DIR/progress.md`:
      ```markdown
      ## Wave [N]: [Purpose]
      **Status**: complete
      **Tasks**: [N]/[N] succeeded

      ### T-[ID]: [Title]
      - Status: completed | done_with_concerns | blocked
      - Files created: [list]
      - Files modified: [list]
      - Notes: [any issues or concerns]
      ```

   d. **Jira sync** (if `--jira-sync`):
      - Read `$COMPOZY_DIR/jira-sync.json`
      - Launch `jira-sync` agent (sonnet) in **update mode**:
        - `subagent_type`: `compozy:jira-sync`
        - `model`: `sonnet`
        - Provide: jira-sync.json path, wave number, completed task IDs and their statuses from progress.md
      - Agent transitions Jira subtasks to Done for completed tasks
      - Agent adds comments on failed/blocked tasks with the reason

   e. **Handle failures**:
      - If a task fails or remains blocked after re-dispatch: log the failure, mark dependents as "skipped"
      - Continue with independent tasks in the same wave
      - Report all failures in Phase 6

   f. **Save checkpoint** after each wave:
      ```markdown
      **Phase**: 5 — Execution
      **Status**: in_progress
      **Current wave**: [N] of [total]
      **Tasks completed**: [N] of [total]
      **Tasks failed**: [N]
      ```

      **Update compozy.json** (per wave):
      - Detail file: Update Phase 5 in `pipeline.phases` with `{ number: 5, name: "Execution", status: "in_progress", started_at, progress: { current_wave, total_waves, tasks_completed, tasks_total, tasks_failed } }`. Add/update `artifacts.progress` with `{ path: "progress.md", created_at, updated_at, size_bytes, created_by: { type: "agent", name: "task-implementer", model: "sonnet" }, summary: "Wave [N] of [M] complete" }`. Update `updated_at`.
      - Central registry: Update this orchestration's `current_phase` to `5`, `progress` to `"[N]/[M] tasks (Wave [X] of [Y])"`, `updated_at` to now.

4. After all waves complete, update checkpoint to phase 5 complete. **Update compozy.json**: Mark Phase 5 as `"complete"` in `pipeline.phases` with `completed_at`. Add `task-implementer` to `contributors.agents` with `{ name: "task-implementer", model: "sonnet", phases: [5], instances: <parallel-count> }`. Update registry `progress` to `"Execution complete"`.

---

## Phase 6: Integration & Review `[GATE always]`

**Goal**: Validate integration and review code quality through a two-stage review process

**Actions**:

1. **Stage 1 — Integration + Spec Compliance** (run in parallel):

   a. Launch `integration-validator` agent (sonnet):
      - `subagent_type`: `compozy:integration-validator`
      - `model`: `sonnet`
      - Provide: tech spec, task manifest, all file paths, progress notes

   b. Launch `spec-compliance-reviewer` agent (sonnet):
      - `subagent_type`: `compozy:spec-compliance-reviewer`
      - `model`: `sonnet`
      - Provide: tech spec, task manifest with completion notes, implementer reports, all file paths
      - This agent independently verifies code matches spec — does NOT trust implementer reports

   c. **Gate Stage 1**: Spec compliance MUST pass (✅) before proceeding to Stage 2.
      - If ❌ Issues found: fix the spec compliance issues first (launch task-implementer agents), then re-run Stage 1
      - If ✅ Spec compliant: proceed to Stage 2

2. **Stage 2 — Code Quality** (only after Stage 1 passes):

   Launch `code-quality-reviewer` agent (sonnet):
   - `subagent_type`: `compozy:code-quality-reviewer`
   - `model`: `sonnet`
   - Provide: tech spec, file list, codebase conventions
   - Reviews: code quality, architecture, testing, robustness

3. **Stage 3 — QA Validation** (only after Stage 2 passes):

   Launch `qa-validator` agent (sonnet):
   - `subagent_type`: `compozy:qa-validator`
   - `model`: `sonnet`
   - Provide: tech spec, task manifest, all file paths, codebase conventions, progress notes

   The qa-validator runs a 5-phase workflow:
   - Discovers existing test patterns and framework
   - Validates each acceptance criterion against the implementation
   - Runs the existing test suite to detect regressions
   - Writes missing tests following repo patterns (if tests exist)
   - Runs the full suite again to verify everything passes

   If qa-validator finds:
   - **Unmet acceptance criteria** → launch `task-implementer` to fix, then re-run `qa-validator`
   - **New regressions** → launch `task-implementer` to fix, then re-run `qa-validator`
   - **Test gaps** → qa-validator writes tests itself (no re-dispatch needed)

4. **Consolidate findings** from all stages into severity categories:
   ```
   ## Review Results

   ### Critical (must fix before PR)
   - [Issue description + file + fix]

   ### Moderate (should fix)
   - [Issue description + file + fix]

   ### Minor (nice to fix)
   - [Issue description]

   ### Integration Issues
   - [Any cross-component problems from integration-validator]
   ```

5. **Gate** (skip if `--auto`) — present consolidated review, then use `AskUserQuestion`:
   ```
   AskUserQuestion:
     question: "How would you like to proceed with the review findings?"
     header: "Review"
     options:
       - label: "Fix all"
         description: "Fix all critical and moderate issues before PR"
       - label: "Fix critical only"
         description: "Fix only critical issues, skip moderate ones"
       - label: "Proceed as-is"
         description: "Create PR without fixing any issues"
       - label: "Abort"
         description: "Stop the pipeline entirely"
     multiSelect: false
   ```
   - If fixing: launch `task-implementer` agents for fixes, then re-run validation on changed files
   - If "Abort": clean up and exit
   - If `--auto`: fix all critical and moderate issues, then proceed

6. Update checkpoint:
```markdown
**Phase**: 6 — Review
**Status**: complete
**Issues found**: [N] critical, [N] moderate, [N] minor
**Issues fixed**: [N]
**User decision**: [fix all / fix critical / proceed]
```

**Update compozy.json**:
- Detail file (`$COMPOZY_DIR/compozy.json`): Set `pipeline.current_phase` to `6`. Add Phase 6 to `pipeline.phases` with `{ number: 6, name: "Review", status: "complete", started_at, completed_at }`. Add review agents to `contributors.agents`: `integration-validator` (sonnet, phase 6), `spec-compliance-reviewer` (sonnet, phase 6), `code-quality-reviewer` (sonnet, phase 6), `qa-validator` (sonnet, phase 6). Update `updated_at`.
- Central registry (`compozy/compozy.json`): Update this orchestration's `current_phase` to `6`, `progress` to `"Review complete"`, `updated_at` to now.

---

## Phase 7: PR Generation `[No gate]`

**Goal**: Package everything into a pull request

**Actions**:
1. **Verification discipline**: Run the full test suite, read the output, and confirm pass BEFORE creating the PR. Do not trust previous test runs — run fresh.
   - Look for test runners: `package.json` scripts, `pytest`, `go test`, `cargo test`, `Makefile` test target
   - Run the appropriate test command
   - Read the output completely — count passes, failures, errors
   - If tests fail, use `AskUserQuestion` (skip if `--auto`):
     ```
     AskUserQuestion:
       question: "Tests failed. How would you like to proceed?"
       header: "Tests"
       options:
         - label: "Fix"
           description: "Attempt to fix the failing tests"
         - label: "Proceed anyway"
           description: "Create PR with test failures noted in description"
         - label: "Abort"
           description: "Stop the pipeline"
       multiSelect: false
     ```
   - If `--auto` and tests fail: attempt to fix failing tests automatically, re-run, and proceed

2. **Ask about artifacts** (skip if `--auto`) — use `AskUserQuestion`:
   ```
   AskUserQuestion:
     question: "Include compozy/ spec artifacts in the commit?"
     header: "Artifacts"
     options:
       - label: "Yes"
         description: "Include spec and manifest for traceability"
       - label: "No"
         description: "Keep the commit clean, artifacts stay local only"
     multiSelect: false
   ```
   - If `--auto`: include artifacts in the commit

3. **Launch `pr-assembler` agent** (sonnet):
   - `subagent_type`: `compozy:pr-assembler`
   - `model`: `sonnet`
   - Provide: tech spec, task manifest, review results, file list, artifact preference, **the pre-determined `$BRANCH_NAME` from the checkpoint**, and the external ticket URL if provided via `--ex-ticket`

4. The pr-assembler will:
   - Create a feature branch using `$BRANCH_NAME` (the branch name determined in Phase 0)
   - Stage and commit files
   - Push to remote
   - Create the PR

5. **Jira finalization** (if `--jira-sync`):
   - Launch `jira-sync` agent (sonnet) in **finalize mode**:
     - `subagent_type`: `compozy:jira-sync`
     - `model`: `sonnet`
     - Provide: jira-sync.json path, PR URL from pr-assembler output
   - Agent adds PR link comment to parent ticket
   - Agent transitions parent to "In Review" if the transition is available

6. **Present final summary**:
   ```
   ## Orchestration Complete

   ### Pull Request
   **PR**: #[number] — [title]
   **URL**: [link]
   **Branch**: [branch-name]

   ### Stats
   - Files created: [N]
   - Files modified: [N]
   - Tasks executed: [N] across [N] waves
   - Issues found and fixed: [N]
   - Tests: [passing/failing/skipped]

   ### Spec Reference
   [Path to tech spec if included in commit, or note that it's in $COMPOZY_DIR/]
   ```

7. Update checkpoint:
```markdown
**Phase**: 7 — PR Generation
**Status**: complete
**PR**: #[number]
**URL**: [url]
**Pipeline duration**: [time]
```

**Update compozy.json**:
- Detail file (`$COMPOZY_DIR/compozy.json`): Set `pipeline.current_phase` to `7`. Set `status` to `"complete"`. Add Phase 7 to `pipeline.phases` with `{ number: 7, name: "PR Generation", status: "complete", started_at, completed_at }`. Add `pr-assembler` to `contributors.agents` with `{ name: "pr-assembler", model: "sonnet", phases: [7] }`. If `--jira-sync` was used, add `jira-sync` finalizer to `contributors.agents`. Update `updated_at`.
- Central registry (`compozy/compozy.json`): Set `status` to `"complete"`, `current_phase` to `7`, `progress` to `"PR #[number] created"`, `updated_at` to now.

---

## Error Recovery

### Context Limit Approaching
If the conversation is getting long:
1. Save a detailed checkpoint to `$COMPOZY_DIR/checkpoint.md`
2. Tell the user: "Context is getting long. Run `/compozy:resume` to continue from Phase [N]."

### Task Agent Failure
If a task-implementer agent fails or returns an error:
1. Log the failure in `$COMPOZY_DIR/progress.md`
2. Mark the task as "failed" in the manifest
3. Mark dependent tasks as "skipped"
4. Continue with independent tasks
5. Report all failures in Phase 6

### Build/Test Failure
If build or tests fail in Phase 7:
1. Present the failure output
2. Use `AskUserQuestion` with options: "Fix" / "Proceed anyway" / "Abort"
3. If "Fix": launch task-implementer to fix, re-run tests
4. If "Proceed anyway": create PR with test failure noted in description
5. If "Abort": clean up

### Interrupted Pipeline
If the user stops mid-pipeline:
- The checkpoint file always reflects the last completed phase
- All artifacts in `$COMPOZY_DIR/` are preserved
- `/compozy:resume` can pick up from any phase

---
description: Spec-driven development orchestration — analyze requirements, generate tech specs, decompose into parallel tasks, execute, review, and create PRs
argument-hint: "[PRD text, file path, or GitHub issue URL/number] [--auto]"
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

# Compozy: Spec-Driven Development Orchestration

You are running the Compozy pipeline — a structured workflow that transforms product requirements into a reviewed pull request through technical specification, parallel task execution, and quality gates.

## Core Principles

- **Never add AI attribution** — Do not include "Generated with Claude", "AI-generated", or similar references in code, comments, commits, or PR descriptions
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
- `--auto` → Reduce gates to only: spec approval (Phase 3) + final review (Phase 6). All other gates are skipped with best-guess defaults.

---

## Phase 0: Setup

**Goal**: Initialize the orchestration environment and determine the working directory

**Actions**:
1. Detect the input source type and load the PRD content
2. Check for `--auto` flag in arguments
3. **Generate the branch name** from the input:
   - GitHub issue: `feat/<issue-number>-<slug>` (or `fix/` for bug labels) — derive slug from issue title
   - Inline text or file: `feat/<slug>` — derive slug from the first few meaningful words
   - Rules: lowercase, hyphens for spaces, max 50 characters, no special characters
4. **Sanitize for directory use**: replace `/` with `-` to get the directory name
5. Create `compozy/<sanitized-branch-name>/files/` directory (the `$COMPOZY_DIR`)
6. Create todo list tracking all 7 phases
7. Save initial checkpoint:

```markdown
# Checkpoint
**Phase**: 0 — Setup
**Status**: complete
**Input source**: [type and reference]
**Branch name**: [branch-name with slashes, e.g., feat/142-notification-prefs]
**Compozy dir**: [resolved $COMPOZY_DIR path, e.g., compozy/feat-142-notification-prefs/files]
**Auto mode**: [yes/no]
**Started**: [timestamp]
```

Write to `$COMPOZY_DIR/checkpoint.md`.

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

---

## Phase 3: Tech Spec Generation `[GATE always — even with --auto]`

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

3. Present a summary to the user:
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

4. **Gate** (always, even with `--auto`) — use `AskUserQuestion`:
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

5. Update checkpoint:
```markdown
**Phase**: 3 — Tech Spec
**Status**: complete (approved)
**Spec version**: [version]
**Components**: [count]
**Files planned**: [count]
```

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

3. Present the wave/task summary table:
   ```
   ## Task Plan

   | Wave | Tasks | Files | Complexity |
   |------|-------|-------|------------|
   | 1: Foundation | T-1, T-2 | 4 | Low |
   | 2: Implementation | T-3, T-4, T-5 | 8 | Medium |
   | 3: Integration | T-6 | 3 | Medium |

   Total: 6 tasks, 3 waves, max 3 parallel
   ```

4. **Gate** (skip if `--auto`) — use `AskUserQuestion`:
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

5. Update checkpoint:
```markdown
**Phase**: 4 — Task Decomposition
**Status**: complete
**Tasks**: [count]
**Waves**: [count]
**Max parallelism**: [count]
```

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

2. For each wave (sequential):

   a. **Launch all tasks in the wave in parallel** using the Task tool:
      - `subagent_type`: `compozy:task-implementer`
      - `model`: `sonnet` (or as specified in manifest)
      - For each task, provide:
        - Task definition (ID, description, files, acceptance criteria)
        - Relevant spec sections (component specs, data models, interfaces)
        - Codebase conventions from Phase 2
        - What was built in previous waves (available types/interfaces)

   b. **Collect results** from all task agents

   c. **Update progress** in `$COMPOZY_DIR/progress.md`:
      ```markdown
      ## Wave [N]: [Purpose]
      **Status**: complete
      **Tasks**: [N]/[N] succeeded

      ### T-[ID]: [Title]
      - Status: completed
      - Files created: [list]
      - Files modified: [list]
      - Notes: [any issues]
      ```

   d. **Handle failures**:
      - If a task fails: log the failure, mark dependents as "skipped"
      - Continue with independent tasks in the same wave
      - Report all failures in Phase 6

   e. **Save checkpoint** after each wave:
      ```markdown
      **Phase**: 5 — Execution
      **Status**: in_progress
      **Current wave**: [N] of [total]
      **Tasks completed**: [N] of [total]
      **Tasks failed**: [N]
      ```

3. After all waves complete, update checkpoint to phase 5 complete

---

## Phase 6: Integration & Review `[GATE always]`

**Goal**: Validate integration and review code quality

**Actions**:
1. **Integration validation**: Launch `integration-validator` agent (sonnet):
   - `subagent_type`: `compozy:integration-validator`
   - `model`: `sonnet`
   - Provide: tech spec, task manifest, all file paths, progress notes

2. **Quality review**: Launch 3 `quality-reviewer` agents in parallel (sonnet):
   - `subagent_type`: `compozy:quality-reviewer`
   - `model`: `sonnet`
   - Agent 1 focus: **correctness** (spec compliance, logic errors, data integrity)
   - Agent 2 focus: **quality** (conventions, DRY, simplicity)
   - Agent 3 focus: **robustness** (error handling, edge cases, security)
   - Each receives: tech spec, file list, codebase conventions

3. **Consolidate findings** into severity categories:
   ```
   ## Review Results

   ### Critical (must fix before PR)
   - [Issue description + file + fix]

   ### Moderate (should fix)
   - [Issue description + file + fix]

   ### Minor (nice to fix)
   - [Issue description]

   ### Integration Issues
   - [Any cross-component problems]
   ```

4. **Gate** (always) — present consolidated review, then use `AskUserQuestion`:
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

5. Update checkpoint:
```markdown
**Phase**: 6 — Review
**Status**: complete
**Issues found**: [N] critical, [N] moderate, [N] minor
**Issues fixed**: [N]
**User decision**: [fix all / fix critical / proceed]
```

---

## Phase 7: PR Generation `[No gate]`

**Goal**: Package everything into a pull request

**Actions**:
1. **Run tests** (if detected):
   - Look for test runners: `package.json` scripts, `pytest`, `go test`, `cargo test`, `Makefile` test target
   - Run the appropriate test command
   - If tests fail, use `AskUserQuestion`:
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

2. **Ask about artifacts** — use `AskUserQuestion`:
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

3. **Launch `pr-assembler` agent** (sonnet):
   - `subagent_type`: `compozy:pr-assembler`
   - `model`: `sonnet`
   - Provide: tech spec, task manifest, review results, file list, artifact preference, **and the pre-determined `$BRANCH_NAME` from the checkpoint**

4. The pr-assembler will:
   - Create a feature branch using `$BRANCH_NAME` (the branch name determined in Phase 0)
   - Stage and commit files
   - Push to remote
   - Create the PR

5. **Present final summary**:
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

6. Update checkpoint:
```markdown
**Phase**: 7 — PR Generation
**Status**: complete
**PR**: #[number]
**URL**: [url]
**Pipeline duration**: [time]
```

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

---
description: Brainstorming and design — explore requirements, ask questions, propose approaches, and produce a design spec
argument-hint: "[topic or feature description] [--auto] [--worktree] [--repo=name] [--ex-ticket=<url>]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - AskUserQuestion
  - Task
---

# Compozy Design

You are running the Compozy design flow — a structured brainstorming and design process that produces a design spec before any implementation begins.

## Core Principles

- **NEVER commit to main/master/develop** — If work produces artifacts that need committing, create a branch first. This is non-negotiable.
- **HARD-GATE: Do NOT write code, scaffold, or take implementation action** until the design is approved
- **One question at a time** — never present multiple questions at once
- **Multiple choice preferred** — use `AskUserQuestion` with concrete options
- **YAGNI ruthlessly** — cut scope to the minimum viable design
- **No AI attribution** — Never mention Claude, AI, or automation

## Anti-Pattern

"This is too simple to need a design" — every project needs one. Simple designs are fast to write.

## Flags

- `--auto` → Full autopilot. Skip ALL user interactions — make best-guess decisions for clarifying questions, approach selection, and section approvals. Produces the design spec end-to-end without stopping.
- `--worktree` → Run design exploration in an isolated git worktree. Creates a worktree using the `compozy:worktrees` skill before exploration begins. This allows running multiple Claude instances on different design tasks in parallel without conflicts.
- `--repo=<name>` → When running from a parent directory that contains multiple repositories, `cd` into the named repository before starting. Example: `--repo=Discover` will `cd Discover` first.
- `--ex-ticket=<url>` → Associate an external ticket URL (Linear, Notion, internal tools, etc.) with this orchestration. Stored in `$COMPOZY_DIR/compozy.json` as `external_ticket.url`.

## Process

### Step 0: Setup (if `--repo` or `--worktree`)

1. **Repository selection** — If `--repo=<name>` is set, `cd` into that directory first. Verify it's a git repository. If not found, report error and stop.
2. **Worktree creation** — If `--worktree` flag is set:
   - Derive a branch name from the topic: `design/<topic-slug>` (lowercase, hyphens, max 50 chars)
   - Use the `compozy:worktrees` skill to create an isolated worktree
   - All subsequent steps run inside the worktree

3. **Create `$COMPOZY_DIR`** — `compozy/<sanitized-branch-name>/files/`

4. **Create `$COMPOZY_DIR/compozy.json`** — the per-orchestration detail file with:
    - `session_id`: generate a UUID (`uuidgen`)
    - `claude_session_id`: capture from `python3 -c "import json; print(json.load(open('$HOME/.claude/sessions/' + str($PPID) + '.json')).get('sessionId', ''))" 2>/dev/null`. If the command fails or returns empty, store `null`. This enables resuming the Claude Code session later via `claude --resume <id>`.
    - `schema_version`: `"1.0.0"`, `command`: `"design"`, `status`: `"in_progress"`
    - `created_at` / `updated_at`: current ISO-8601 timestamp
    - `repository`, `workspace`, `branch`, `input`, `flags`: standard structure (see orchestrate command)
    - `external_ticket`: `{ url: "<url>" }` if `--ex-ticket` was provided, otherwise omit
    - `pipeline`: `{ current_phase: 0, total_phases: 7, phases: [{ number: 0, name: "Setup", status: "complete", started_at, completed_at }] }`
    - `artifacts`: `{}`
    - `contributors.human`: from git config, `contributors.agents`: `[]`

5. **Register in central registry** `compozy/compozy.json`:
    - If the file doesn't exist: create with `schema_version`, `repository` block, and empty `orchestrations` array
    - Append entry with: `session_id`, `command: "design"`, `status: "in_progress"`, `branch`, `input`, `workspace`, `current_phase: 0`, `total_phases: 7`, `progress: "Setup complete"`, timestamps, `detail_path`

### Step 1: Explore Project Context

Understand what already exists:
1. Read CLAUDE.md and project guidelines if they exist
2. Launch 1-2 Explore agents (using `Task` tool with subagent_type `Explore`) to understand:
   - Relevant architecture and existing patterns
   - Similar features or components already built
   - Conventions for naming, file structure, and dependencies
   - Testing patterns used in the project
3. Identify what's similar to what we're building — reuse existing patterns, don't reinvent

### Step 2: Ask Clarifying Questions

Ask questions **one at a time** using `AskUserQuestion`:
- Start with the highest-impact question
- Provide concrete answer options based on what you've learned
- Each answer informs the next question
- Stop when you have enough to propose approaches (typically 3-5 questions)

### Step 3: Propose Approaches

Present 2-3 approaches with trade-offs:

```
## Approach A: [Name]
[2-3 sentences]
**Pros:** [list]
**Cons:** [list]

## Approach B: [Name]
[2-3 sentences]
**Pros:** [list]
**Cons:** [list]
```

Use `AskUserQuestion` to let the user choose or mix approaches.

### Step 4: Present Design

Present the design in sections, getting approval per section using `AskUserQuestion`:

1. **Overview** — What we're building and why
2. **Architecture** — How components fit together
3. **Data Models** — Types, schemas, interfaces
4. **API/Interface Contracts** — How components communicate
5. **Error Handling** — What can go wrong and how we handle it
6. **Acceptance Criteria** — How we know it works

### Step 5: Write Design Spec

Save the approved design to `compozy/<branch>/files/design-spec.md`.

**Update compozy.json**:
- Detail file (`$COMPOZY_DIR/compozy.json`): Set `pipeline.current_phase` to `5`. Add `artifacts.design_spec` with `{ path: "design-spec.md", created_at, updated_at, size_bytes, created_by: { type: "command", name: "design" }, summary: "<design title>" }`. Update `updated_at`.
- Central registry (`compozy/compozy.json`): Update `current_phase` to `5`, `progress` to `"Design spec written"`, `updated_at` to now.

Use the branch naming convention from the topic:
- `feat/<short-slug>` for features
- `fix/<short-slug>` for bug fixes

### Step 5.5: Spec Review Loop

Before presenting to the user, validate the design spec internally:

1. Launch a review subagent (using `Task` tool) with prompt:
   ```
   Review this design spec for completeness, consistency, and feasibility.
   Check: Are all acceptance criteria testable? Are error cases covered?
   Are there missing interfaces or undefined dependencies?
   Report issues found or confirm the spec is solid.
   ```
2. If issues found: fix them in the spec
3. If clean: proceed to user review

### Step 6: User Reviews Written Spec

Present the spec for final review using `AskUserQuestion`:
```
AskUserQuestion:
  question: "Review the design spec. How would you like to proceed?"
  header: "Design Review"
  options:
    - label: "Approved"
      description: "Design looks good"
    - label: "Revise"
      description: "Make changes (provide feedback via Other)"
    - label: "Start over"
      description: "Scrap this and redesign"
  multiSelect: false
```

### Step 7: Transition

After approval, present next steps using `AskUserQuestion`:
```
AskUserQuestion:
  question: "Design approved. What's next?"
  header: "Next Steps"
  options:
    - label: "Create implementation plan"
      description: "Run /compozy:plan to create a detailed plan from this design"
    - label: "Run full pipeline"
      description: "Run /compozy:orchestrate to go straight to implementation"
    - label: "Done for now"
      description: "Keep the design spec, implement later"
  multiSelect: false
```

**Update compozy.json**:
- Detail file: Set `status` to `"complete"`. Set `pipeline.current_phase` to `7`. Update `updated_at`.
- Central registry: Set `status` to `"complete"`, `progress` to `"Design approved"`, `updated_at` to now.

## Key Principles

- **One question at a time** — never dump multiple questions
- **Multiple choice preferred** — concrete options, not open-ended
- **YAGNI ruthlessly** — cut scope to minimum viable
- **Explore alternatives** — don't lock into the first idea
- **Incremental validation** — get approval per section, not all at once

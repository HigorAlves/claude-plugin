---
description: Brainstorming and design — explore requirements, ask questions, propose approaches, and produce a design spec
argument-hint: "[topic or feature description] [--auto] [--worktree] [--repo=name]"
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

## Process

### Step 0: Setup (if `--repo` or `--worktree`)

1. **Repository selection** — If `--repo=<name>` is set, `cd` into that directory first. Verify it's a git repository. If not found, report error and stop.
2. **Worktree creation** — If `--worktree` flag is set:
   - Derive a branch name from the topic: `design/<topic-slug>` (lowercase, hyphens, max 50 chars)
   - Use the `compozy:worktrees` skill to create an isolated worktree
   - All subsequent steps run inside the worktree

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

## Key Principles

- **One question at a time** — never dump multiple questions
- **Multiple choice preferred** — concrete options, not open-ended
- **YAGNI ruthlessly** — cut scope to minimum viable
- **Explore alternatives** — don't lock into the first idea
- **Incremental validation** — get approval per section, not all at once

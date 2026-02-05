---
description: Generate, view, or edit technical specifications without running the full orchestration pipeline
argument-hint: "generate [PRD text or file] | view | edit [section-number]"
allowed-tools:
  - "Bash(gh issue view:*)"
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Task
---

# Compozy: Spec Management

Standalone command for generating, viewing, and editing technical specifications outside the full orchestration pipeline. Useful for spec-first workflows or reviewing existing specs.

## Core Principles

- **Never add AI attribution** — Do not include "Generated with Claude", "AI-generated", or similar references
- **Never mention "CLAUDE.md"** — Refer to "project guidelines" or "our guidelines" instead

---

## Arguments

Parse `$ARGUMENTS` for a subcommand:

- **`generate [PRD]`** — Generate a new tech spec from requirements
- **`view`** — Display the current tech spec summary
- **`edit [section]`** — Edit a specific section of the existing spec
- **No arguments** — Show help

---

## Subcommand: generate

**Goal**: Generate a tech spec from a PRD without running the full pipeline

### Process

1. **Parse input** (same as orchestrate command):
   - GitHub issue URL/number → fetch with `gh issue view`
   - File path → read with Read tool
   - Inline text → use directly
   - Empty → ask user to describe what they want to build

2. **PRD Analysis**: Launch `prd-analyzer` agent (opus):
   - `subagent_type`: `compozy:prd-analyzer`
   - `model`: `opus`
   - Present analysis and ask clarifying questions
   - Wait for user answers

3. **Codebase Discovery**: Launch 2 Explore agents in parallel:
   - `subagent_type`: `Explore`
   - Map architecture and find similar features
   - Save to `.compozy/codebase-context.md`

4. **Spec Generation**: Launch `spec-generator` agent (opus):
   - `subagent_type`: `compozy:spec-generator`
   - `model`: `opus`
   - Provide requirements + codebase context + spec template
   - Write to `.compozy/tech-spec.md`

5. **Present and approve**:
   - Show spec summary (title, components, files, key decisions)
   - Ask: "approved / revise: [feedback] / edit"
   - Iterate until approved

6. Report:
   ```
   Spec saved to .compozy/tech-spec.md

   To run the full pipeline with this spec: /compozy:orchestrate
   To decompose into tasks: /compozy:orchestrate (it will detect the existing spec)
   ```

---

## Subcommand: view

**Goal**: Display the current tech spec in a readable summary

### Process

1. Check for `.compozy/tech-spec.md`
   - If not found: "No spec found. Run `/compozy:spec generate [PRD]` to create one."

2. Read the spec file

3. Present a structured summary:
   ```
   ## Tech Spec: [Title]

   **Status**: [from header]
   **Version**: [from header]
   **Date**: [from header]

   ### Overview
   [First 2-3 sentences from overview section]

   ### Requirements
   - [N] functional requirements ([N] must, [N] should, [N] could)
   - [N] non-functional requirements

   ### Components
   1. [Component name] — [responsibility]
   2. [Component name] — [responsibility]

   ### Files
   - [N] new files to create
   - [N] existing files to modify

   ### Architecture Decisions
   - [Decision]: [Choice]

   ### Acceptance Criteria
   - [AC-1]: [Brief]
   - [AC-2]: [Brief]
   ...

   Full spec: .compozy/tech-spec.md
   ```

---

## Subcommand: edit

**Goal**: Edit a specific section of the existing spec

### Process

1. Check for `.compozy/tech-spec.md`
   - If not found: "No spec found. Run `/compozy:spec generate [PRD]` to create one."

2. Parse the section argument:
   - Number (1-12) → map to section name
   - Section name → match directly
   - No argument → show section list and ask which to edit

   Section mapping:
   | # | Section |
   |---|---------|
   | 1 | Header |
   | 2 | Overview |
   | 3 | Requirements Summary |
   | 4 | Architecture |
   | 5 | Component Specifications |
   | 6 | Data Models |
   | 7 | File Ownership Map |
   | 8 | API/Interface Contracts |
   | 9 | Error Handling Strategy |
   | 10 | Acceptance Criteria |
   | 11 | Out of Scope |
   | 12 | Risks and Mitigations |

3. Read the current section content

4. Ask the user what changes they want:
   - "What would you like to change in the [section name] section?"

5. Apply the edits using the Edit tool

6. Show the updated section and confirm:
   - "Section updated. Looks good? (yes / more changes)"

---

## No Arguments: Help

If no subcommand is provided, display:

```
## Compozy Spec Commands

/compozy:spec generate [PRD]     Generate a new tech spec from requirements
/compozy:spec view               View current spec summary
/compozy:spec edit [section]     Edit a section (1-12 or section name)

Current spec: [exists at .compozy/tech-spec.md / not found]
```

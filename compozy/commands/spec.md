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
  - AskUserQuestion
---

# Compozy: Spec Management

Standalone command for generating, viewing, and editing technical specifications outside the full orchestration pipeline. Useful for spec-first workflows or reviewing existing specs.

## Core Principles

- **Never add AI attribution** — Do not include "Generated with Claude", "AI-generated", or similar references
- **Never mention "CLAUDE.md"** — Refer to "project guidelines" or "our guidelines" instead
- **Always use interactive UI** — Every user interaction MUST use the `AskUserQuestion` tool with clear menu options. Never ask questions via plain text output — always present structured choices so the user can click to respond

## Working Directory

All artifacts are stored in `compozy/<branch-name>/files/`. When generating a new spec, the branch name is derived from the input (same rules as the orchestrate command). When viewing or editing, the existing `compozy/` directory is scanned to find the spec. Throughout this document, **`$COMPOZY_DIR`** refers to the resolved directory path.

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
   - Empty → use `AskUserQuestion` to ask user to describe what they want to build (they'll provide via "Other" free-text)

2. **Generate branch name and create working directory**:
   - Derive branch name from input (same rules as orchestrate Phase 0)
   - Sanitize for directory use (replace `/` with `-`)
   - Create `compozy/<sanitized-branch-name>/files/` (`$COMPOZY_DIR`)

3. **PRD Analysis**: Launch `prd-analyzer` agent (opus):
   - `subagent_type`: `compozy:prd-analyzer`
   - `model`: `opus`
   - Present analysis and use `AskUserQuestion` for each clarifying question with relevant answer options
   - Collect user answers

4. **Codebase Discovery**: Launch 2 Explore agents in parallel:
   - `subagent_type`: `Explore`
   - Map architecture and find similar features
   - Save to `$COMPOZY_DIR/codebase-context.md`

5. **Spec Generation**: Launch `spec-generator` agent (opus):
   - `subagent_type`: `compozy:spec-generator`
   - `model`: `opus`
   - Provide requirements + codebase context + spec template
   - Write to `$COMPOZY_DIR/tech-spec.md`

6. **Present and approve** — show spec summary, then use `AskUserQuestion`:
   ```
   AskUserQuestion:
     question: "Review the spec at $COMPOZY_DIR/tech-spec.md. How would you like to proceed?"
     header: "Spec Review"
     options:
       - label: "Approved"
         description: "Spec looks good"
       - label: "Revise"
         description: "Regenerate spec with your feedback (provide via Other)"
       - label: "Edit manually"
         description: "You'll edit the spec file directly, then confirm when done"
     multiSelect: false
   ```
   - Iterate until approved

7. Report:
   ```
   Spec saved to $COMPOZY_DIR/tech-spec.md

   To run the full pipeline with this spec: /compozy:orchestrate
   To decompose into tasks: /compozy:orchestrate (it will detect the existing spec)
   ```

---

## Subcommand: view

**Goal**: Display the current tech spec in a readable summary

### Process

1. **Discover the working directory**:
   - Scan `compozy/` for subdirectories containing `files/tech-spec.md`
   - If one found: use it as `$COMPOZY_DIR`
   - If multiple found: use `AskUserQuestion` to ask which one to view (list branch names as options)
   - If none found: "No spec found. Run `/compozy:spec generate [PRD]` to create one."

2. Read the spec file at `$COMPOZY_DIR/tech-spec.md`

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

   Full spec: $COMPOZY_DIR/tech-spec.md
   ```

---

## Subcommand: edit

**Goal**: Edit a specific section of the existing spec

### Process

1. **Discover the working directory** (same as view):
   - Scan `compozy/` for subdirectories containing `files/tech-spec.md`
   - If one found: use it. If multiple: use `AskUserQuestion` to ask which one. If none: "No spec found."

2. Parse the section argument:
   - Number (1-12) → map to section name
   - Section name → match directly
   - No argument → use `AskUserQuestion` to ask which section to edit (list sections as options, max 4 per question — split across multiple questions if needed)

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

4. Use `AskUserQuestion` to ask what changes the user wants:
   ```
   AskUserQuestion:
     question: "What would you like to change in the [section name] section?"
     header: "Edit"
     options:
       - label: "Rewrite"
         description: "Regenerate this section with new guidance (provide via Other)"
       - label: "Add content"
         description: "Add new items to this section (provide via Other)"
     multiSelect: false
   ```

5. Apply the edits using the Edit tool

6. Show the updated section, then use `AskUserQuestion`:
   ```
   AskUserQuestion:
     question: "Section updated. How does it look?"
     header: "Confirm"
     options:
       - label: "Looks good"
         description: "Done editing this section"
       - label: "More changes"
         description: "Continue editing (provide feedback via Other)"
     multiSelect: false
   ```

---

## No Arguments: Help

If no subcommand is provided, display:

```
## Compozy Spec Commands

/compozy:spec generate [PRD]     Generate a new tech spec from requirements
/compozy:spec view               View current spec summary
/compozy:spec edit [section]     Edit a section (1-12 or section name)

Current spec: [exists at $COMPOZY_DIR/tech-spec.md / not found]
```

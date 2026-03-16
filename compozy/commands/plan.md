---
description: Create a TDD-structured implementation plan from a design spec or requirements
argument-hint: "[design spec path or inline requirements] [--ex-ticket=<url>]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - AskUserQuestion
  - Task
---

# Compozy Plan

You are running the Compozy plan flow — creating a comprehensive, TDD-structured implementation plan from a design spec or requirements.

## Core Principles

- **Every task follows TDD** — write failing test → verify fail → implement → verify pass → commit
- **Bite-sized tasks** — each step is one action (2-5 minutes)
- **DRY, YAGNI, TDD, frequent commits**
- **No AI attribution**
- **Always use `AskUserQuestion`** for all user interactions

## Process

### Step 1: Load Input

Determine the input source:
1. **Design spec path provided** → read the design spec
2. **Inline requirements** → use directly
3. **No input** → check for existing design spec in `compozy/*/files/design-spec.md`, or ask user

If a design spec exists at `compozy/<branch>/files/design-spec.md`, use it.

**Create `$COMPOZY_DIR/compozy.json`** if it doesn't already exist (it may exist from a prior `/compozy:design` run):
- `session_id`: generate a UUID (`uuidgen`)
- `claude_session_id`: capture from `python3 -c "import json; print(json.load(open('$HOME/.claude/sessions/' + str($PPID) + '.json')).get('sessionId', ''))" 2>/dev/null`. If the command fails or returns empty, store `null`. This enables resuming the Claude Code session later via `claude --resume <id>`.
- `schema_version`: `"1.0.0"`, `command`: `"plan"`, `status`: `"in_progress"`
- Standard structure: `repository`, `workspace`, `branch`, `input`, `contributors`
- `flags`: standard structure, plus `ex_ticket`
- `external_ticket`: `{ url: "<url>" }` if `--ex-ticket` was provided, otherwise omit
- `pipeline`: `{ current_phase: 0, total_phases: 2, phases: [{ number: 0, name: "Setup", status: "complete", started_at, completed_at }] }`

**Register in central registry** `compozy/compozy.json` if not already registered for this `session_id`.

### Step 2: Scope Check

If the spec covers multiple independent subsystems, suggest breaking into separate plans — one per subsystem. Each plan should produce working, testable software on its own.

Use `AskUserQuestion` to confirm scope.

### Step 3: Map File Structure

Before defining tasks, map out which files will be created or modified:
- Design units with clear boundaries and well-defined interfaces
- Each file should have one clear responsibility
- Prefer smaller, focused files over large ones
- Follow established patterns in existing codebases

Launch Explore agents if needed to understand the existing codebase structure.

### Step 4: Decompose into TDD Tasks

Create tasks following this structure:

````markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.ts`
- Modify: `exact/path/to/existing.ts`
- Test: `tests/exact/path/to/test.ts`

- [ ] **Step 1: Write the failing test**

```typescript
test('specific behavior', () => {
    const result = functionName(input);
    expect(result).toBe(expected);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npm test tests/path/test.ts`
Expected: FAIL with "functionName is not defined"

- [ ] **Step 3: Write minimal implementation**

```typescript
function functionName(input: Type): ReturnType {
    return expected;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npm test tests/path/test.ts`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add tests/path/test.ts src/path/file.ts
git commit -m "feat: add specific feature"
```
````

### Step 5: Plan Document Header

Every plan starts with:

```markdown
# [Feature Name] Implementation Plan

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

---
```

### Step 6: Save Plan

Save to `compozy/<branch>/files/implementation-plan.md`.

Use the same branch directory as the design spec if one exists.

**Update compozy.json**:
- Detail file: Add `artifacts.implementation_plan` with `{ path: "implementation-plan.md", created_at, updated_at, size_bytes, created_by: { type: "command", name: "plan" }, summary: "<plan title>" }`. Update `updated_at`.
- Central registry: Update `progress` to `"Plan created"`, `updated_at` to now.

### Step 7: Review Gate

Present the plan for review using `AskUserQuestion`:
```
AskUserQuestion:
  question: "Review the implementation plan. How would you like to proceed?"
  header: "Plan Review"
  options:
    - label: "Approved"
      description: "Plan looks good, ready to execute"
    - label: "Revise"
      description: "Make changes to the plan (provide feedback via Other)"
    - label: "Run full pipeline"
      description: "Feed this plan into /compozy:orchestrate"
  multiSelect: false
```

**Update compozy.json**:
- Detail file: Set `status` to `"complete"`, `pipeline.current_phase` to `2`. Update `updated_at`.
- Central registry: Set `status` to `"complete"`, `progress` to `"Plan approved"`, `updated_at` to now.

## Remember

- **Exact file paths always**
- **Complete code in plan** (not "add validation")
- **Exact commands with expected output**
- **DRY, YAGNI, TDD, frequent commits**
- **Each step = one action** (2-5 minutes)

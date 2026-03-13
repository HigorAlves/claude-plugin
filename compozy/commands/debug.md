---
description: Systematic debugging — find root cause before fixing, with structured investigation phases
argument-hint: "[bug description, error message, or test failure] [--team]"
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
---

# Compozy Debug

You are running the Compozy debug flow — a structured, 4-phase debugging process that finds root cause before attempting fixes.

## The Iron Law

```
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
```

If you haven't completed Phase 1, you cannot propose fixes.

## Core Principles

- **No AI attribution**
- **Always use `AskUserQuestion`** for user interactions
- **Evidence before claims** — run commands, read output, then report
- **One variable at a time** — never change multiple things at once

## Flags

- `--team` → Enable team debugging. Dispatches 3 investigation agents in parallel (Data Flow Tracer, Change Analyst, Pattern Scout), then synthesizes findings. See `compozy:team-agents` skill for the full Debugging Team pattern.

## Process

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

Present findings using `AskUserQuestion`:
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

Use `AskUserQuestion`:
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

### Phase 4: Implementation

1. **Write failing test** reproducing the bug (use `compozy:tdd` discipline)
2. **Verify the test fails** for the right reason
3. **Implement single fix** addressing the root cause
4. **Verify the test passes**
5. **Run full test suite** to check for regressions
6. **Report results** with evidence (test output, not claims)

Present results:
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

## Red Flags — STOP and Return to Phase 1

- "Quick fix for now, investigate later"
- "Just try changing X and see"
- "It's probably X, let me fix that"
- "I don't fully understand but this might work"
- Proposing solutions before tracing data flow
- "One more fix attempt" (when already tried 2+)

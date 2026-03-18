# Decomposition Review Team (orchestrate --team, Phase 4)

Used during Phase 4 (Task Decomposition). After the task-decomposer produces the manifest, two reviewers validate it before execution.

**Roles:**
1. **Dependency Auditor** — Validates task ordering and isolation
2. **Complexity Estimator** — Flags tasks that need splitting or special attention

**Flow:**
```
Phase 4 (after task decomposition):
  1. Dispatch both reviewers in parallel with the manifest + tech spec
  2. Dependency Auditor: "Review this task manifest for:
      - Hidden dependencies between tasks in the same wave
      - File exclusivity violations (two tasks touching the same file)
      - Incorrect wave ordering (task depends on something not yet built)
      - Missing interface contracts between waves
      Report ordering issues and file conflicts."
  3. Complexity Estimator: "Review this task manifest for:
      - Tasks that are too large (should be split into subtasks)
      - High-risk tasks that need opus model instead of sonnet
      - Acceptance criteria that are too vague to implement
      - Tasks with unclear scope boundaries
      Flag tasks and suggest adjustments."
  4. Synthesize findings
  5. If wave ordering or file exclusivity is wrong: re-run task-decomposer with feedback
  6. If clean: present manifest to user for approval
```

**Why this helps:**
- Prevents parallel execution conflicts (file exclusivity violations = broken builds)
- Catches tasks too large for a single agent (avoids BLOCKED status in Phase 5)
- Validates wave ordering before spending time on execution

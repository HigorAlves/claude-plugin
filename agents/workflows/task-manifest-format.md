# Task Manifest Format

The task manifest defines how a tech spec is decomposed into executable tasks organized in waves for parallel execution.

---

## Structure

```markdown
# Task Manifest: [Feature Name]

**Spec**: [Link or path to tech spec]
**Generated**: [YYYY-MM-DD]
**Total Tasks**: [N]
**Total Waves**: [N]

---

## Wave [N]: [Wave Purpose]

### Task T-[ID]: [Task Title]

**Status**: pending | in_progress | completed | failed | skipped
**Agent Model**: opus | sonnet | haiku
**Estimated Complexity**: low | medium | high

**Description**:
[2-5 sentences explaining what this task does and why]

**Spec Sections**: [List of spec section numbers this task implements, e.g., "5.1, 6.1, 8.1"]

**Files**:
| File | Action | Description |
|------|--------|-------------|
| `path/to/file.ts` | create | [What this file contains] |
| `path/to/other.ts` | modify | [What changes are made] |

**Dependencies**: [Task IDs this depends on, e.g., "T-1, T-2" or "none"]

**Acceptance Criteria**:
- [ ] [Specific condition from spec AC list]
- [ ] [Another condition]

**Notes**:
[Any implementation hints, gotchas, or context the agent should know]
```

---

## Field Definitions

### Status Values

| Status | Meaning |
|--------|---------|
| `pending` | Not yet started |
| `in_progress` | Currently being executed by an agent |
| `completed` | Successfully finished, acceptance criteria met |
| `failed` | Execution failed, needs retry or manual intervention |
| `skipped` | Skipped due to dependency failure or user decision |

### Wave Rules

1. **Sequential execution**: Wave N+1 starts only after ALL tasks in wave N complete
2. **Parallel within wave**: All tasks in the same wave execute simultaneously
3. **Dependency respect**: A task's dependencies must be in earlier waves (never same or later wave)
4. **Wave 1 convention**: Shared types, interfaces, configuration, and utilities
5. **Final wave convention**: Integration glue, cleanup, migration scripts, documentation

### File Ownership Rules

1. **Exclusivity**: Each file appears in exactly one task across the entire manifest
2. **Create vs Modify**: New files use "create", existing files use "modify"
3. **Shared code**: Files needed by multiple tasks go in Wave 1 tasks
4. **Test files**: Test files are owned by the task that tests the corresponding implementation
5. **No phantom files**: Every file listed must be referenced in the tech spec

### Complexity Guidelines

| Level | Characteristics |
|-------|-----------------|
| **Low** | 1-2 files, straightforward logic, clear patterns to follow |
| **Medium** | 3-5 files, some design decisions, moderate business logic |
| **High** | 5+ files, complex algorithms, significant error handling, new patterns |

### Agent Model Selection

| Model | Use When |
|-------|----------|
| **opus** | Complex logic, novel patterns, architectural decisions within a task |
| **sonnet** | Standard implementation, following established patterns, CRUD operations |
| **haiku** | Simple scaffolding, boilerplate, configuration files |

---

## Example Wave Structure

```
Wave 1: Foundation (2 tasks, parallel)
├── T-1: Create shared types and interfaces
└── T-2: Set up configuration and constants

Wave 2: Core Implementation (3 tasks, parallel)
├── T-3: Implement service layer
├── T-4: Implement API routes
└── T-5: Implement data access layer

Wave 3: Integration & Polish (2 tasks, parallel)
├── T-6: Wire up middleware and error handling
└── T-7: Add tests and documentation
```

---

## Validation Checklist

Before finalizing a task manifest, verify:

- [ ] Every file in the spec's file ownership map appears in exactly one task
- [ ] No file appears in more than one task
- [ ] All task dependencies point to earlier waves
- [ ] No circular dependencies exist
- [ ] Wave 1 contains all shared/foundational code
- [ ] Each task has at least one acceptance criterion
- [ ] Status for all tasks is "pending"
- [ ] Complexity ratings are reasonable (no wave with all "high" tasks)
- [ ] Total number of tasks per wave doesn't exceed 5 (practical parallel limit)

# Compozy 2.0

Full-lifecycle development orchestration for Claude Code. Design, plan, implement with TDD, review, and ship — with engineering discipline baked in at every step.

## Commands

### `/compozy:orchestrate [PRD] [--auto]`

The main pipeline. Takes a product requirement and produces a pull request.

**Input sources:**
- GitHub issue: `/compozy:orchestrate #42` or a full issue URL
- File: `/compozy:orchestrate ./prd.md`
- Inline: `/compozy:orchestrate "Add user notification preferences with email and push channels"`
- Interactive: `/compozy:orchestrate` (prompts for input)

**Pipeline phases:**

| Phase | Name | Gate | Description |
|-------|------|------|-------------|
| 0 | Setup | - | Generate branch name, create directory, optional worktree |
| 1 | PRD Analysis | Yes* | Extract requirements, identify gaps, ask questions |
| 2 | Codebase Discovery | No | Explore architecture, patterns, conventions |
| 3 | Tech Spec | **Always** | Generate implementation-ready spec (user must approve) |
| 4 | Task Decomposition | Yes* | Break spec into TDD-structured parallel tasks |
| 5 | Task Execution | No | Execute tasks wave-by-wave with TDD + status handling |
| 6 | Integration & Review | **Always** | Two-stage review: spec compliance → code quality |
| 7 | PR Generation | No | Verify tests, create branch, commit, push, open PR |

*Skipped with `--auto` flag

### `/compozy:design [topic]`

Brainstorming and design — explore requirements, ask questions one at a time, propose 2-3 approaches, and produce a design spec.

```
/compozy:design "Real-time notification system"
/compozy:design
```

### `/compozy:plan [spec]`

Create a TDD-structured implementation plan from a design spec or requirements.

```
/compozy:plan compozy/feat-notifications/files/design-spec.md
/compozy:plan "Add dark mode support"
```

### `/compozy:code-review [flags]`

Review a GitHub PR — checks code quality, test coverage, and requirements alignment.

```
/compozy:code-review
/compozy:code-review --jira PROJ-1234
/compozy:code-review --prd docs/feature-spec.md
/compozy:code-review --context "This adds pagination to the users endpoint"
```

### `/compozy:debug [description]`

Systematic debugging — 4-phase root cause investigation before fixing.

```
/compozy:debug "Tests in auth module failing after merge"
/compozy:debug "Users seeing blank screen on login"
```

### `/compozy:finish [branch]`

Complete a development branch — verify tests, present 4 integration options, execute choice, cleanup.

```
/compozy:finish
/compozy:finish feat/auth-refresh
```

### `/compozy:resume [phase]`

Resume an interrupted pipeline from the last checkpoint or a specific phase.

```
/compozy:resume
/compozy:resume 5
```

### `/compozy:spec <subcommand>`

Standalone spec management without the full pipeline.

```
/compozy:spec generate "Add dark mode support"
/compozy:spec view
/compozy:spec edit 5
```

## Development Lifecycle

Compozy supports the full development lifecycle, with composable commands:

```
design → plan → orchestrate → code-review → finish
```

Each step is independent. You can:
- `design` without building (explore ideas)
- `plan` without the full pipeline (prepare for manual implementation)
- `orchestrate` from a PRD directly (skip design/plan if requirements are clear)
- `code-review` any PR (standalone reviews)
- `debug` any issue (standalone debugging)
- `finish` any branch (standalone completion)

## Agents

| Agent | Model | Purpose |
|-------|-------|---------|
| `prd-analyzer` | opus | Parse requirements, identify gaps, ask questions |
| `spec-generator` | opus | Generate complete tech spec from requirements + context |
| `task-decomposer` | sonnet | Break spec into TDD-structured parallel tasks |
| `task-implementer` | sonnet | Execute a single task with TDD + status reporting |
| `integration-validator` | sonnet | Validate cross-task integration |
| `spec-compliance-reviewer` | sonnet | Stage 1: verify implementation matches spec |
| `code-quality-reviewer` | sonnet | Stage 2: verify implementation is well-built |
| `pr-assembler` | sonnet | Create branch, commit, and PR |
| `guidelines-reviewer` | sonnet | Audit PR for project guideline compliance |
| `bug-hunter` | opus | Find real bugs in PR diffs |
| `security-reviewer` | opus | Find security vulnerabilities in PR diffs |
| `test-analyzer` | sonnet | Analyze test coverage gaps |
| `requirements-checker` | sonnet | Verify PR implements ticket requirements |

## Skills

| Skill | Purpose |
|-------|---------|
| `using-compozy` | Core discipline — iron rules, skill routing (injected at session start) |
| `tdd` | RED-GREEN-REFACTOR cycle with mandatory verification |
| `systematic-debugging` | 4-phase root cause investigation |
| `verification` | Evidence before claims — run commands, read output, then report |
| `worktrees` | Isolated workspace creation with safety verification |
| `parallel-agents` | Focused subagent dispatch for independent problems |
| `pr-review` | Review methodology — comment tone, false positives, suggestion rules |
| `branch-completion` | Finish branch workflow — verify, present options, execute |
| `spec-authoring` | Spec writing conventions, templates, and examples |

## SessionStart Hook

Compozy injects the `using-compozy` skill at every session start (startup, resume, clear, compact). This establishes:
- Available skills and when to use them
- Iron rules (no code without test, no claims without verification, no fixes without root cause)
- Skill invocation discipline

## State Directory

All pipeline artifacts stored in `compozy/<branch-name>/files/`:

```
compozy/
  feat-142-notification-prefs/
    files/
      checkpoint.md
      design-spec.md
      codebase-context.md
      tech-spec.md
      task-manifest.md
      implementation-plan.md
      progress.md
```

## Common Workflows

### New Feature
```
/compozy:design "feature description"    → explore & design spec
/compozy:plan path/to/design-spec.md     → TDD implementation plan
/compozy:orchestrate path/to/spec.md     → implement, review, PR
```

### Bug Ticket
```
/compozy:debug "bug description or #issue"   → 4-phase root cause investigation + TDD fix
/compozy:finish                               → commit + PR
```

For simple bugs, `/compozy:debug` handles everything: investigation, failing test, fix, and verification. For complex multi-component bugs, add a code review step before finishing:

```
/compozy:debug "bug description"
/compozy:code-review                     → self-review the fix
/compozy:finish
```

### Quick Task (clear requirements)
```
/compozy:orchestrate "task description" --auto   → skip gates, straight to PR
```

### Standalone Operations
```
/compozy:code-review          → review any PR
/compozy:debug "description"  → debug any issue
/compozy:finish               → complete any branch
/compozy:spec generate "..."  → generate a spec without building
```

## Tips

- **Start with `/compozy:design`** for complex features — explore before committing
- **Use `/compozy:plan`** for detailed TDD plans before implementation
- **Review the spec carefully** in orchestrate — it's the single most important artifact
- **Use `--auto` for well-defined tasks** — clear requirements speed things up
- **Bug tickets don't need the full pipeline** — go straight to `/compozy:debug` → `/compozy:finish`
- **Add `compozy/` to `.gitignore`** if you don't want spec artifacts tracked

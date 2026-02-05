# Compozy

Spec-driven development orchestration for Claude Code. Transforms product requirements into reviewed pull requests through a structured pipeline: PRD analysis, tech spec generation, parallel task execution, quality review, and PR creation.

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
| 0 | Setup | - | Initialize `.compozy/` directory and parse input |
| 1 | PRD Analysis | Yes* | Extract requirements, identify gaps, ask questions |
| 2 | Codebase Discovery | No | Explore architecture, patterns, conventions |
| 3 | Tech Spec | **Always** | Generate implementation-ready spec (user must approve) |
| 4 | Task Decomposition | Yes* | Break spec into parallel tasks with waves |
| 5 | Task Execution | No | Execute tasks wave-by-wave with parallel agents |
| 6 | Integration & Review | **Always** | Validate integration, review quality |
| 7 | PR Generation | No | Create branch, commit, push, open PR |

*Skipped with `--auto` flag

**Auto mode** (`--auto`): Reduces approval gates to only spec approval (Phase 3) and final review (Phase 6). All other gates proceed with best-guess defaults.

### `/compozy:resume [phase-number]`

Resume an interrupted pipeline from the last checkpoint or a specific phase.

```
/compozy:resume       # Resume from last checkpoint
/compozy:resume 5     # Jump to Phase 5 (Task Execution)
```

### `/compozy:spec <subcommand>`

Standalone spec management without the full pipeline.

```
/compozy:spec generate "Add dark mode support"   # Generate a spec
/compozy:spec view                                 # View current spec summary
/compozy:spec edit 5                               # Edit Component Specifications section
```

## State Directory

The `.compozy/` directory stores all pipeline artifacts:

| File | Phase | Purpose |
|------|-------|---------|
| `checkpoint.md` | All | Resume point with phase and status |
| `codebase-context.md` | 2 | Architecture and convention analysis |
| `tech-spec.md` | 3 | The approved technical specification |
| `task-manifest.md` | 4 | Task breakdown with waves and file ownership |
| `progress.md` | 5 | Execution log per wave and task |

At the end of the pipeline, you choose whether to include these artifacts in the PR commit.

## Agents

| Agent | Model | Purpose |
|-------|-------|---------|
| `prd-analyzer` | opus | Parse requirements, identify gaps, ask questions |
| `spec-generator` | opus | Generate complete tech spec from requirements + context |
| `task-decomposer` | sonnet | Break spec into parallel tasks with wave ordering |
| `task-implementer` | sonnet | Execute a single task (exclusive file ownership) |
| `integration-validator` | sonnet | Validate cross-task integration |
| `quality-reviewer` | sonnet | Review code (launched 3x: correctness, quality, robustness) |
| `pr-assembler` | sonnet | Create branch, commit, and PR |

## How It Works

1. **You provide requirements** — a PRD document, GitHub issue, or plain text description
2. **Compozy analyzes** — extracts structured requirements and asks clarifying questions
3. **You approve a spec** — a detailed tech spec with components, interfaces, and file ownership
4. **Agents implement in parallel** — tasks are grouped into waves, with exclusive file ownership preventing conflicts
5. **Quality gates catch issues** — integration validation + 3-perspective code review
6. **A PR is created** — clean branch, descriptive commit, thorough PR description

## Tips

- **Start with a detailed PRD** — the more detail you provide, the fewer clarifying questions and the better the spec
- **Review the spec carefully** — it's the single most important artifact. Everything flows from it
- **Use `--auto` for well-defined tasks** — if your requirements are clear and unambiguous, auto mode speeds things up
- **Use `/compozy:spec generate` first** — if you want to iterate on the spec before committing to the full pipeline
- **Add `.compozy/` to `.gitignore`** — if you don't want spec artifacts tracked in version control

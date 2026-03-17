# Compozy 2.0

Full-lifecycle development orchestration for Claude Code. Design, plan, implement with TDD, review, and ship — with engineering discipline baked in at every step.

## Commands

### `/compozy:orchestrate [PRD] [--auto] [--team] [--worktree] [--repo=name]`

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
| 6 | Integration & Review | **Always** | Three-stage review: spec compliance → code quality → QA validation |
| 7 | PR Generation | No | Verify tests, create branch, commit, push, open PR |

*With `--auto`, ALL gates are skipped — the pipeline runs fully autonomously. With `--team`, Phase 3 adds spec critic + testability reviewer, Phase 4 adds dependency auditor + complexity estimator, and Phase 5 adds reviewer + architect agents per wave. With `--worktree`, Phase 0 creates an isolated git worktree. With `--repo=name`, changes into that repository directory first.

### `/compozy:design [topic] [--auto] [--worktree] [--repo=name]`

Brainstorming and design — explore requirements, ask questions one at a time, propose 2-3 approaches, and produce a design spec.

```
/compozy:design "Real-time notification system"
/compozy:design "Auth refactor" --worktree
/compozy:design "Caching layer" --auto --repo=Discover
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

### `/compozy:pr-respond [PR] [--auto] [--worktree] [--repo=name]`

Address PR review feedback — reads all unresolved comments, categorizes them (actionable fix / question / nitpick / disagreement), fixes code, replies to every thread, and pushes changes.

```
/compozy:pr-respond
/compozy:pr-respond 42
/compozy:pr-respond https://github.com/org/repo/pull/42
/compozy:pr-respond --auto --repo=Discover
```

### `/compozy:debug [description] [--auto] [--team] [--worktree] [--repo=name] [--pr]`

Systematic debugging — 4-phase root cause investigation before fixing.

```
/compozy:debug "Tests in auth module failing after merge"
/compozy:debug "Users seeing blank screen on login"
/compozy:debug "Payment flow broken after deploy" --team
/compozy:debug "Race condition in queue" --worktree
/compozy:debug "Login broken" --auto --pr --repo=Discover --worktree
```

### `/compozy:sentry-fix [issue] [--auto] [--team] [--worktree] [--repo=name] [--pr]`

Fix production errors from Sentry — discover, analyze, find root cause, fix with TDD, verify, and resolve.

**Input sources:**
- Sentry issue URL: `/compozy:sentry-fix https://sentry.io/organizations/org/issues/12345/`
- Issue ID: `/compozy:sentry-fix 12345`
- Short ID: `/compozy:sentry-fix PROJECT-ABC`
- Search: `/compozy:sentry-fix "TypeError in checkout flow"`
- Interactive: `/compozy:sentry-fix` (prompts for input)

**Pipeline phases:**

| Phase | Name | Gate | Description |
|-------|------|------|-------------|
| 0 | Setup | - | Repo selection, worktree creation, directory setup |
| 1 | Issue Discovery | Yes* | Parse input, fetch via Sentry MCP, confirm issue |
| 2 | Deep Sentry Analysis | No | Gather stack traces, breadcrumbs, traces, tags, Seer AI |
| 3 | Root Cause Investigation | Yes* | Cross-reference Sentry evidence against codebase |
| 4 | Implementation | Yes* | TDD: write failing test, implement fix, verify |
| 5 | Verification Audit | No | Confirm fix covers all affected environments/browsers |
| 6 | PR & Resolution | No | Create PR, resolve issue in Sentry |

*With `--auto`, ALL gates are skipped. With `--team`, Phase 2 dispatches 3 parallel investigation agents (Sentry Data Analyst, Codebase Investigator, Impact Assessor). With `--pr`, Phase 6 creates a PR and pushes.

**Requires:** Sentry MCP server (`sentry@claude-plugins-official`)

### `/compozy:jira [ticket] [--auto] [--team] [--worktree] [--repo=name] [--pr]`

Jira ticket-driven development — the ticket IS the unit of work. Routes to different flows based on ticket type (Bug → debug, Story/Task → spec).

**Input sources:**
- Ticket key: `/compozy:jira PROJ-1234`
- Jira URL: `/compozy:jira https://company.atlassian.net/browse/PROJ-1234`
- JQL: `/compozy:jira 'project = PROJ AND status = "To Do" ORDER BY priority DESC'`
- Search: `/compozy:jira "login page broken"`
- Interactive: `/compozy:jira` (prompts for input)

**Pipeline phases:**

| Phase | Name | Gate | Description |
|-------|------|------|-------------|
| 0 | Setup | - | Repo selection, worktree, branch prefix from ticket type |
| 1 | Ticket Discovery | Yes* | Parse input, fetch via Jira MCP, confirm, transition → In Progress |
| 2 | Deep Ticket Analysis | No | Gather description, AC, linked issues, subtasks, comments, sprint/epic |
| 3 | Investigation | Yes* | Bug: root cause investigation. Story: codebase discovery + spec |
| 4 | Implementation | Yes* | Bug: TDD fix. Story: task decomposition + wave execution |
| 5 | Verification Audit | No | Run tests + verify each acceptance criterion from ticket |
| 6 | PR & Ticket Resolution | No | Create PR, add Jira comment, transition → In Review |

*With `--auto`, ALL gates are skipped. With `--team`, Phase 2 dispatches 3 collaborative agents (Bug Investigation Team or Story Planning Team based on ticket type). With `--pr`, Phase 6 creates a PR and pushes.

**Requires:** Jira MCP server (Atlassian Remote MCP or `mcp-atlassian`)

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
design → plan → orchestrate → code-review → pr-respond → finish
```

Each step is independent. You can:
- `design` without building (explore ideas)
- `plan` without the full pipeline (prepare for manual implementation)
- `orchestrate` from a PRD directly (skip design/plan if requirements are clear)
- `jira` from a Jira ticket (ticket-driven development with lifecycle management)
- `code-review` any PR (standalone reviews)
- `pr-respond` to address review feedback on your PR
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
| `sentry-analyzer` | opus | Extract and synthesize Sentry issue data into structured reports |
| `jira-analyzer` | opus | Extract and synthesize Jira ticket data into structured reports |
| `qa-validator` | sonnet | Validate acceptance criteria, run regression checks, write missing tests |

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
| `team-agents` | Collaborative agent teams — reviewer + architect for implementation, 3-agent investigation for debugging |

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

### New Feature (full pipeline)

The complete workflow for features with unclear or complex requirements. Each step produces an artifact the next step consumes.

```
/compozy:design "real-time notification system"
```
1. Explores the codebase for similar patterns
2. Asks clarifying questions one at a time
3. Proposes 2-3 approaches with trade-offs
4. Produces a design spec at `compozy/<branch>/files/design-spec.md`

```
/compozy:plan compozy/feat-notifications/files/design-spec.md
```
5. Breaks the design into TDD-structured implementation tasks
6. Organizes tasks into parallel-safe waves
7. Produces an implementation plan

```
/compozy:orchestrate compozy/feat-notifications/files/tech-spec.md
```
8. Executes tasks wave-by-wave with TDD discipline
9. Two-stage review (spec compliance → code quality)
10. Creates branch, commits, pushes, opens PR

**With `--team`:** Add reviewer + architect agents that check each wave's output before proceeding:
```
/compozy:orchestrate compozy/feat-notifications/files/tech-spec.md --team
```

### New Feature (fast track)

When requirements are already clear — skip design and plan, go straight to implementation:

```
/compozy:orchestrate "Add pagination to the /users endpoint with cursor-based navigation" --auto
```

`--auto` runs fully autonomously — no questions, no gates, no stopping. Combine flags for full parallel autopilot:
```
/compozy:orchestrate #42 --auto --team
/compozy:orchestrate #42 --auto --worktree --repo=Discover
```

### Bug Ticket (simple)

For bugs where you have a clear reproduction or error message:

```
/compozy:debug "Login form accepts empty email — no validation error shown"
```

This runs the full 4-phase process:
1. **Root cause investigation** — reproduce, read errors, trace data flow
2. **Pattern analysis** — find working examples, compare
3. **Hypothesis testing** — smallest change to test theory
4. **TDD fix** — failing test → green → refactor

Then either finish manually or use `--pr` for end-to-end:
```
/compozy:finish                              → manual: choose merge/PR/keep
/compozy:debug "bug description" --pr        → auto-creates PR after fix
/compozy:debug "bug description" --auto --pr → fully autonomous: debug → fix → PR
```

### Bug Ticket (complex / multi-component)

For bugs that span multiple subsystems, use `--team` to dispatch 3 investigation agents simultaneously:

```
/compozy:debug "Payment flow broken after deploy — timeout in checkout but API logs show 200s" --team
```

The team investigates in parallel:
- **Data Flow Tracer** — traces the error backward through call chains
- **Change Analyst** — examines recent deploys, git diffs, config changes
- **Pattern Scout** — finds similar working flows, identifies what's different

Their findings are synthesized into a single root cause hypothesis. Then:
```
/compozy:code-review    → self-review the fix before finishing
/compozy:finish         → commit + PR
```

### Jira Ticket (bug)

For bugs tracked in Jira — the ticket drives the investigation and fix:

```
/compozy:jira PROJ-1234
```

This detects the ticket type (Bug) and routes to the debug flow:
1. **Ticket analysis** — gather description, AC, linked issues, comments, sprint context
2. **Root cause investigation** — systematic debugging from ticket evidence
3. **TDD fix** — failing test → green → refactor
4. **Acceptance criteria verification** — check each AC from the ticket

End-to-end with PR and ticket transitions:
```
/compozy:jira PROJ-1234 --pr                → fix + PR + transition to In Review
/compozy:jira PROJ-1234 --auto --pr         → fully autonomous: analyze → fix → PR → Done
/compozy:jira PROJ-1234 --auto --team --pr  → team investigation + autonomous fix
```

### Jira Ticket (story/task)

For stories and tasks tracked in Jira — the ticket drives spec generation and implementation:

```
/compozy:jira PROJ-5678
```

This detects the ticket type (Story) and routes to the spec flow:
1. **Ticket analysis** — gather description, AC, linked issues, subtasks, comments
2. **Codebase discovery + spec generation** — explore codebase, generate spec from ticket requirements
3. **Task decomposition + wave execution** — parallel TDD implementation
4. **Acceptance criteria verification** — check each AC from the ticket

```
/compozy:jira PROJ-5678 --pr               → implement + PR + transition to In Review
/compozy:jira PROJ-5678 --auto --pr        → fully autonomous end-to-end
/compozy:jira "login page broken"          → search Jira and pick a ticket
/compozy:jira                               → interactive: prompted for ticket
```

### Exploring Ideas (no implementation)

When you want to brainstorm without committing to building anything:

```
/compozy:design "should we use WebSockets or SSE for real-time updates?"
```

Design produces a spec. You can stop there, or continue later:
```
/compozy:plan compozy/feat-realtime/files/design-spec.md    → when ready to plan
/compozy:orchestrate compozy/feat-realtime/files/tech-spec.md  → when ready to build
```

### Code Review (standalone)

Review any PR — works independently of the pipeline:

```
/compozy:code-review                                    → review current PR
/compozy:code-review --jira PROJ-1234                   → check against Jira ticket
/compozy:code-review --prd docs/feature-spec.md         → check against requirements doc
/compozy:code-review --context "This adds rate limiting" → provide context for better review
```

### Addressing PR Review Feedback

After your PR gets review comments:

```
/compozy:pr-respond
```

This reads all unresolved comments, categorizes them, fixes code, replies to each thread, and pushes. For full autopilot:
```
/compozy:pr-respond --auto
/compozy:pr-respond 42 --auto --repo=Discover
```

### Spec Management (standalone)

Generate, view, or edit specs without running the full pipeline:

```
/compozy:spec generate "Add dark mode support"   → generate a spec
/compozy:spec view                                → view current spec
/compozy:spec edit 5                              → edit section 5
```

### Choosing the Right Workflow

| Situation | Workflow | Flags |
|-----------|----------|-------|
| Complex feature, unclear requirements | `design → plan → orchestrate` | |
| Feature with clear requirements | `orchestrate` | `--auto` |
| High-stakes feature, need extra review | `design → plan → orchestrate` | `--team` |
| Simple bug, clear reproduction | `debug` | `--pr` |
| Simple bug, fully autonomous | `debug` | `--auto --pr` |
| Complex bug, multiple subsystems | `debug → code-review → finish` | `--team` |
| Complex bug, fully autonomous with PR | `debug` | `--auto --team --pr` |
| Production error from Sentry | `sentry-fix` | `--pr` |
| Sentry error, fully autonomous | `sentry-fix` | `--auto --pr` |
| Sentry error, team investigation | `sentry-fix` | `--team --pr` |
| Jira bug ticket | `jira` | `--pr` |
| Jira story/task ticket | `jira` | `--pr` |
| Jira ticket, fully autonomous | `jira` | `--auto --pr` |
| Jira ticket, team investigation | `jira` | `--team --pr` |
| Exploring ideas, no implementation | `design` | |
| Review someone's PR | `code-review` | |
| Address review feedback on your PR | `pr-respond` | `--auto` |
| Finish work on current branch | `finish` | |
| Multiple tasks in parallel (separate terminals) | Any command | `--worktree` |
| Fully autonomous, no interaction | Any command | `--auto` |
| Working from multi-repo parent directory | Any command | `--repo=name` |
| Fire-and-forget parallel on different repos | `orchestrate` or `debug` | `--auto --worktree --repo=name` |

## Tips

- **Start with `/compozy:design`** for complex features — explore before committing
- **Use `/compozy:plan`** for detailed TDD plans before implementation
- **Review the spec carefully** in orchestrate — it's the single most important artifact
- **Use `--auto` for fire-and-forget** — runs fully autonomously, no questions asked. Combine with `--worktree` and `--repo` for parallel work across repos
- **Bug tickets don't need the full pipeline** — go straight to `/compozy:debug` → `/compozy:finish`
- **Production errors from Sentry** — use `/compozy:sentry-fix` which fetches all Sentry context (stack traces, breadcrumbs, traces, tags) before investigating
- **Jira ticket-driven development** — use `/compozy:jira PROJ-1234` to let the ticket drive the workflow. Bugs route to debug flow, stories route to spec flow. Manages ticket lifecycle (In Progress → In Review → Done)
- **Use `--team` for complex work** — adds reviewer/architect agents to orchestrate, 3-agent investigation to debug
- **Use `--worktree` for parallel work** — each command runs in its own isolated git worktree, so you can open multiple terminals and run different tasks simultaneously without file conflicts
- **Use `--repo=name` from parent directories** — if you keep repos in `~/Developer/`, run compozy from there and point at the right repo: `--repo=Discover`
- **Add `compozy/` to `.gitignore`** if you don't want spec artifacts tracked

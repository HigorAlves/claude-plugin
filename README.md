# Novac Stack

A collection of productivity plugins for Claude Code — development orchestration, code review, PR management, issue discovery, git workflows, output styles, and frontend design.

## Installation

### Step 1: Authenticate with GitHub

This is a private marketplace. Make sure you're authenticated:

```bash
gh auth login
gh auth status  # Verify authentication
```

### Step 2: Add the Marketplace

```bash
/plugin marketplace add higoralves/novac-stack
```

### Step 3: Install Plugins

Install the plugins you need:

```bash
/plugin install compozy@novac-stack
/plugin install pr-toolkit@novac-stack
/plugin install issue-finder@novac-stack
/plugin install commit-commands@novac-stack
/plugin install frontend-design@novac-stack
/plugin install explanatory-output-style@novac-stack
/plugin install learning-output-style@novac-stack
```

### Enable Auto-Updates (Optional)

For background auto-updates to work with private repos, add to your shell config (`~/.zshrc` or `~/.bashrc`):

```bash
export GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxx
```

Create a token at https://github.com/settings/tokens with `repo` scope.

## Updating

### Update All Plugins

Refresh the marketplace to get latest versions:

```bash
/plugin marketplace update novac-stack
```

### Check Installed Plugins

```bash
/plugin list
```

### Reinstall a Specific Plugin

To get the latest version of a specific plugin:

```bash
/plugin uninstall compozy@novac-stack
/plugin install compozy@novac-stack
```

## Available Plugins

### compozy `v2.6.0`

Full-lifecycle development orchestration — design, plan, implement with TDD, review, respond to feedback, and ship with engineering discipline. Supports Jira ticket-driven and Sentry error-driven workflows.

**Commands (12):**

| Command | Description |
|---------|-------------|
| `/orchestrate` | Spec-driven development — analyze requirements, generate specs, decompose into parallel tasks, execute, review, and create PRs |
| `/design` | Brainstorming and design — explore requirements, ask questions, propose approaches, produce a design spec |
| `/spec` | Generate, view, or edit technical specifications |
| `/plan` | Create a TDD-structured implementation plan from a design spec or requirements |
| `/code-review` | Review a GitHub PR — checks code quality, test coverage, and requirements alignment |
| `/pr-respond` | Address PR review feedback — read comments, fix code, reply to threads, push changes |
| `/debug` | Systematic debugging — find root cause before fixing, with structured investigation phases |
| `/jira` | Jira ticket-driven development — discover, analyze, implement with TDD, verify, and resolve |
| `/sentry-fix` | Fix Sentry issues — discover, analyze with rich context, find root cause, fix with TDD, verify, and resolve |
| `/finish` | Complete a development branch — verify tests, present integration options, execute choice, cleanup |
| `/resume` | Resume an interrupted orchestration from the last checkpoint |
| `/status` | Show pipeline status across all active orchestrations |

**Agents (15):** spec-generator, task-decomposer, task-implementer, integration-validator, pr-assembler, prd-analyzer, jira-analyzer, sentry-analyzer, spec-compliance-reviewer, code-quality-reviewer, guidelines-reviewer, security-reviewer, requirements-checker, bug-hunter, test-analyzer

**Skills (10):** tdd, systematic-debugging, verification, worktrees, parallel-agents, pr-review, branch-completion, spec-authoring, team-agents, using-compozy

**Flags:** `--auto` (full autopilot), `--team` (collaborative agents), `--worktree` (parallel isolation), `--repo` (multi-repo support)

---

### pr-toolkit `v1.1.0`

Comprehensive PR review using specialized agents for comments, tests, error handling, type design, code quality, and code simplification.

**Command:** `/review-pr [PR number or URL]`

**Agents (6):**

| Agent | Focus |
|-------|-------|
| code-reviewer | Project guidelines, style guides, best practices |
| code-simplifier | Clarity, consistency, maintainability |
| comment-analyzer | Comment accuracy, completeness, long-term maintainability |
| pr-test-analyzer | Test coverage quality and completeness |
| silent-failure-hunter | Silent failures, inadequate error handling, unsafe fallbacks |
| type-design-analyzer | Type encapsulation, invariant expression, enforcement |

---

### issue-finder `v1.1.0`

Analyze codebases to discover bugs, security vulnerabilities, architectural problems, and improvements, then create GitHub issues directly.

**Commands:**
- `/audit-codebase [scope]` — Run analysis agents and optionally create GitHub issues
- `/fix-issue` — Select a GitHub issue, plan and implement a fix, then create a PR

**Agents (7):**

| Agent | Focus |
|-------|-------|
| bug-hunter | Logic errors, null handling, race conditions |
| security-scanner | Injection vulnerabilities, auth issues, data exposure |
| architecture-critic | Coupling, circular deps, layer violations |
| database-expert | N+1 queries, schema issues, connection leaks |
| improvement-finder | Performance, tech debt, missing tests |
| issue-planner | Plans fixes by analyzing issues and codebase |
| issue-implementer | Implements fixes following a pre-defined plan |

---

### commit-commands `v1.1.0`

Streamline your git workflow with simple commands for committing, pushing, and creating pull requests.

**Commands:**
- `/commit` — Create a git commit
- `/commit-push-pr` — Commit, push, and open a PR
- `/clean_gone` — Clean up local branches deleted on remote, including associated worktrees

---

### frontend-design `v1.0.2`

Frontend design skill for creating distinctive, production-grade UI/UX implementations that avoid generic AI aesthetics.

**Skill:** `frontend-design` — activated automatically when working on frontend code

---

### explanatory-output-style `v1.0.2`

Adds educational insights about implementation choices and codebase patterns. Activates via hooks to provide `★ Insight` blocks alongside code output.

---

### learning-output-style `v1.0.2`

Interactive learning mode that requests meaningful code contributions at decision points. Activates via hooks to pause and ask the user to participate in implementation choices.

---

## Requirements

- Claude Code CLI
- GitHub CLI (`gh`) authenticated with repo access
- Git repository with remote configured

### MCP Server Dependencies

Some plugins require MCP servers. Install the ones needed by the plugins you use.

| MCP Server | Required By | Purpose | Install |
|------------|-------------|---------|---------|
| **GitHub** (`github@claude-plugins-official`) | compozy, issue-finder | PR creation, issue management, code review | `/mcp add github` |
| **Sentry** (`sentry@claude-plugins-official`) | compozy | Production error monitoring — fetch issues, stack traces, breadcrumbs, resolve issues | `/mcp add sentry` |
| **Jira** | compozy | Jira ticket-driven development, code review context (`--jira` flag) | Configure per your Jira instance |

**Which plugins need what:**

- **compozy** — GitHub (orchestrate, resume, pr-respond, code-review), Sentry (sentry-fix), Jira (jira, code-review `--jira`)
- **issue-finder** — GitHub (fix-issue)
- **pr-toolkit** — None
- **commit-commands** — None
- **frontend-design** — None
- **explanatory-output-style** — None
- **learning-output-style** — None

## Contributing

Each plugin is in its own directory with:
- `.claude-plugin/plugin.json` — Plugin manifest
- `commands/` — Slash commands
- `agents/` — Specialized agents
- `skills/` — Progressive disclosure skills (optional)
- `hooks/` — Event-driven hooks (optional)

Validation and version management scripts are in `scripts/`.

## License

MIT

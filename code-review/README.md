# Code Review Plugin

Contextual code review for pull requests — checks code quality and validates requirements alignment.

## Overview

Reviews PRs from two angles: **code quality** (bugs, security, guideline compliance) and **requirements alignment** (does the PR deliver what the ticket asks for). Multiple parallel agents provide independent perspectives, and every finding is validated before posting.

All feedback is written in a natural, conversational tone — like a senior engineer on the team.

## Usage

```bash
# Basic code review (code quality only)
/code-review

# Review against a Jira ticket (requires Jira MCP)
/code-review --jira PROJ-1234

# Review against a PRD or spec file
/code-review --prd docs/feature-spec.md

# Review with free-form context
/code-review --context "This PR adds cursor-based pagination to /users"

# Combine multiple sources
/code-review --jira PROJ-1234 --prd docs/spec.md
```

| Flag | Description |
|------|-------------|
| `--jira <ticket>` | Jira ticket ID or URL. Fetches details via Jira MCP. |
| `--prd <file>` | Path to a requirements/spec document. |
| `--context <text>` | Free-form description of expected behavior. |

## How It Works

1. **Eligibility** — skips closed, draft, trivial, or already-reviewed PRs
2. **Project guidelines** — finds relevant CLAUDE.md files
3. **Requirements context** — fetches Jira ticket, reads PRD, or uses provided context
4. **PR summary** — what changed and why
5. **Parallel code review** — 4 agents check guidelines compliance, bugs, and security
6. **Requirements alignment** — checks coverage, gaps, and drift against the ticket/spec
7. **Validation** — independent subagents confirm every finding
8. **Review** — posts inline comments + summary via GitHub pending review

## Requirements Alignment

When context is provided (`--jira`, `--prd`, `--context`), the review also checks:

- **Coverage** — Does the PR implement what's required?
- **Gaps** — Edge cases or constraints not handled
- **Partial** — Requirements only partly addressed
- **Drift** — Work outside ticket scope (informational)

## Comment Style

Comments use Conventional Commit prefixes (`fix:`, `perf:`, `security:`, etc.) and read like a colleague's feedback:

```
fix: This OAuth callback doesn't handle errors — if the auth flow fails,
users will see a blank screen. Worth wrapping in a try-catch.
```

## Requirements

- GitHub CLI (`gh`) installed and authenticated
- Jira MCP server (optional, for `--jira`)
- CLAUDE.md files (optional, for guideline checks)

## Author

Higor Alves (me@higoralves.dev)

## Version

2.0.0

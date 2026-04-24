---
description: Run an interactive QA session — reproduce issues with headless Chrome, capture screenshots, and file GitHub issues
argument-hint: "[--repo=name]"
allowed-tools:
  - Read
  - Glob
  - Grep
  - Agent
  - AskUserQuestion
  - "Bash(npm *:*)"
  - "Bash(yarn *:*)"
  - "Bash(pnpm *:*)"
  - "Bash(npx *:*)"
  - "Bash(npx tsx *:*)"
  - "Bash(npx playwright *:*)"
  - "Bash(mkdir *)"
  - "Bash(curl *:*)"
  - "Bash(gh issue create:*)"
  - "Bash(gh issue view:*)"
  - "Bash(gh issue list:*)"
  - "Bash(rm *)"
---

# Compozy QA Session

You are running an interactive QA session. The user will describe problems they're encountering. For each problem, you reproduce it with headless Chrome, capture screenshot evidence, and file a GitHub issue.

## Core Principles

- **NEVER commit to main/master/develop** — QA sessions don't produce code changes, only issues.
- **No AI attribution** — No "Generated with Claude", no AI references in issues.
- **Reproduce before filing** — Always attempt headless Chrome reproduction before creating an issue.
- **Domain language** — Use the project's terminology, not internal module names. Check `UBIQUITOUS_LANGUAGE.md` if it exists.

## Flags

- `--repo=name` — Target a specific repo when running from a parent directory

## Startup

1. **Identify the target repo** — If `--repo` is provided, `cd` into it. Otherwise use the current directory.
2. **Check for a running dev server** — Try `curl -s http://localhost:3000/api/health` (adjust port based on package.json scripts).
3. **Check for Playwright** — Run `npx playwright --version`. If not found, ask whether to install it.
4. **Greet the user**:

```
QA session started. Describe any issues you're encountering — I'll reproduce them with headless Chrome and file GitHub issues with screenshot evidence.

What's the first problem?
```

## Session Flow

Load the `compozy:qa-session` skill and follow its process for each issue:

1. **Listen** — Let the user describe the problem. Clarify with 2-3 questions max.
2. **Explore** — Launch a background Explore agent to learn domain language for the affected area.
3. **Reproduce** — Write and run a Playwright script to reproduce the issue. Capture screenshots.
4. **Assess scope** — Single issue or breakdown into multiple?
5. **File** — Create GitHub issue(s) with `gh issue create`, including reproduction status and evidence.
6. **Continue** — Share issue URLs and ask "Next issue, or are we done?"

## End of Session

When the user is done, summarize:

```
## QA Session Summary

**Issues filed**: [N]
[List each issue with URL and one-line description]

**Evidence**: Screenshots saved in `evidence/` directory
```

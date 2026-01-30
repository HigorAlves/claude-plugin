# Issue Finder Plugin

A Claude plugin that analyzes codebases to discover bugs, security vulnerabilities, architectural problems, and improvement opportunities, then creates GitHub issues directly.

## Installation

Add this plugin to your Claude configuration or symlink it to your plugins directory.

## Usage

```bash
/audit-codebase [scope] [--labels label1,label2]
```

### Arguments

- **scope**: Directory path, file pattern, or "all" (defaults to current directory)
- **--labels**: Optional comma-separated labels to add to all created issues

### Examples

```bash
# Audit entire codebase
/audit-codebase

# Audit specific directory
/audit-codebase src/services

# Audit with custom labels
/audit-codebase --labels needs-review,q1-2024

# Audit specific path with labels
/audit-codebase src/api --labels backend,security-review
```

## What It Finds

The plugin runs five specialized analysis agents in parallel:

### Bug Hunter (Red)
- Logic errors and incorrect conditionals
- Null/undefined handling issues
- Race conditions and async bugs
- Resource leaks (unclosed handles, missing cleanup)
- Error handling problems

### Security Scanner (Red)
- Injection vulnerabilities (SQL, XSS, command)
- Authentication and authorization flaws
- Data exposure and secrets in code
- Cryptographic weaknesses
- Security misconfigurations

### Architecture Critic (Yellow)
- Tight coupling between modules
- Circular dependencies
- Layer violations
- God objects and classes
- Modularity and abstraction issues

### Database Expert (Blue)
- N+1 query patterns
- Missing indexes on queried columns
- Connection leaks and pool exhaustion
- Schema issues (missing constraints, wrong types)
- ORM anti-patterns

### Improvement Finder (Green)
- Performance bottlenecks
- Code duplication and complexity
- Technical debt (TODO/FIXME markers)
- Missing tests for critical paths
- Documentation gaps

## Confidence Scoring

Each finding includes a confidence score (0-100). Only findings with **confidence >= 80** are presented for issue creation. This reduces noise and focuses on real problems.

## Workflow

1. **Analysis**: All five agents scan the codebase in parallel
2. **Filtering**: Results filtered to confidence >= 80
3. **Deduplication**: Existing GitHub issues checked to avoid duplicates
4. **Report**: Categorized findings presented with severity
5. **Confirmation**: User prompted to select which issues to create
6. **Auto-assignment**: Git blame used to assign issues to code authors
7. **Creation**: Selected issues created via `gh` CLI

## Issue Format

Created issues follow this format:

```markdown
## Description
[Clear explanation of the issue]

## Location
- **File**: `path/to/file.ext`
- **Line(s)**: X-Y

## Impact
[Why this matters]

## Suggested Fix
[Concrete recommendation]

---
*Discovered by automated codebase analysis*
```

## Label Mapping

| Category | GitHub Labels |
|----------|---------------|
| fix | bug |
| security | security, priority:high |
| perf | performance |
| refactor | tech-debt |
| docs | documentation |
| chore | maintenance |

## Requirements

- GitHub CLI (`gh`) installed and authenticated
- Git repository with remote configured
- Write access to create issues

## Privacy

This plugin:
- Only analyzes code in the specified scope
- Does not send code to external services (analysis is local)
- Only interacts with GitHub to list/create issues
- Always asks for confirmation before creating issues

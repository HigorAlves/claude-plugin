---
description: Analyze codebase for issues and optionally create GitHub issues
argument-hint: "[scope] [--labels label1,label2]"
allowed-tools:
  - "Bash(gh issue list:*)"
  - "Bash(gh issue create:*)"
  - "Bash(gh issue view:*)"
  - "Bash(git *)"
  - "Read"
  - "Glob"
  - "Grep"
  - "Task"
---

# Codebase Audit Command

You are performing a comprehensive codebase audit to identify bugs, security vulnerabilities, architectural problems, and improvement opportunities.

## Arguments

Parse the user's arguments:
- **scope**: Directory path, file pattern, or "all" (defaults to current directory)
- **--labels**: Optional comma-separated custom labels to add to all created issues

## Workflow

### Step 1: Gather Context

1. Read CLAUDE.md if it exists for project-specific context
2. Identify languages and frameworks by scanning file extensions and config files
3. Understand the project structure

### Step 2: Launch Analysis Agents

Launch all 5 agents in parallel using the Task tool:

1. **bug-hunter** - Find bugs, logic errors, null handling issues, race conditions
2. **security-scanner** - Find security vulnerabilities, injection risks, auth issues
3. **architecture-critic** - Find structural problems, coupling issues, layer violations
4. **improvement-finder** - Find performance issues, tech debt, missing tests
5. **database-expert** - Find query problems, N+1 patterns, schema issues, connection leaks

Each agent will return findings in this format:
```
FINDING:
- category: fix|security|perf|refactor|docs|chore
- confidence: 0-100
- file: path/to/file.ext
- line: X (or X-Y for ranges)
- title: Brief issue title
- description: Detailed explanation
- impact: Why this matters
- suggested_fix: How to address it
```

### Step 3: Filter and Deduplicate

1. Filter findings to only those with confidence >= 80
2. Fetch existing issues: `gh issue list --state all --limit 100 --json number,title,body`
3. Compare each finding against existing issues:
   - Check for similar titles (semantic match, not exact)
   - Check for same file/line locations in body
4. Mark duplicates to skip

### Step 4: Present Report

Display a categorized report:

```
## Audit Results

### Critical Issues (X found)
1. [SECURITY] Title - file.ext:123 (confidence: 95%)
2. [BUG] Title - file.ext:456 (confidence: 88%)

### Important Issues (Y found)
3. [ARCHITECTURE] Title - file.ext:789 (confidence: 85%)

### Improvements (Z found)
4. [PERF] Title - file.ext:012 (confidence: 82%)

### Duplicates Detected (N skipped)
- "Existing issue title" matches finding #X
```

### Step 5: User Confirmation

Always prompt the user before creating issues:

```
Found X issues ready to create:

| # | Category | Title | Confidence | Assignee |
|---|----------|-------|------------|----------|
| 1 | security | SQL injection risk | 95% | @developer1 |
| 2 | bug | Null pointer in handler | 88% | @developer2 |

Skipping N duplicates that already exist.

Options:
- Enter "all" to create all X issues
- Enter numbers (e.g., "1,3,5") to create specific issues
- Enter "none" to skip issue creation
```

Wait for user response before proceeding.

### Step 6: Create Issues (if approved)

For each approved issue:

1. **Determine assignee via git blame:**
   ```bash
   git blame -L <line>,<line> <file> --porcelain | grep "^author " | cut -d' ' -f2-
   ```
   Try to map author name to GitHub username if possible.

2. **Map category to labels:**
   | Category | Labels |
   |----------|--------|
   | fix | bug |
   | security | security, priority:high |
   | perf | performance |
   | refactor | tech-debt |
   | docs | documentation |
   | chore | maintenance |

3. **Create issue:**
   ```bash
   gh issue create \
     --title "Issue title" \
     --body "Issue body" \
     --label "label1,label2" \
     --assignee "username"
   ```

4. **Issue body format:**
   ```markdown
   ## Description
   [Clear explanation of the issue]

   ## Location
   - **File**: `path/to/file.ext`
   - **Line(s)**: X-Y

   ## Impact
   [Why this matters and potential consequences]

   ## Suggested Fix
   [Concrete recommendation for resolution]

   ---
   *Discovered by automated codebase analysis*
   ```

5. Add any custom labels from --labels argument

### Step 7: Report Results

After creating issues, report:

```
## Issues Created

✓ #123: SQL injection risk in auth handler
  → https://github.com/owner/repo/issues/123

✓ #124: Null pointer in request handler
  → https://github.com/owner/repo/issues/124

Created X issues successfully.
```

## Important Notes

- Never create issues without user confirmation
- Always check for duplicates before presenting options
- Use git blame to auto-assign when possible, fall back to no assignee
- Include the "Discovered by automated codebase analysis" footer in all issues
- Respect the confidence threshold of 80%

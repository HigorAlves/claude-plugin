---
description: Select a GitHub issue, plan and implement a fix, then create a PR
argument-hint: "[issue-number] [--labels label1,label2]"
allowed-tools:
  - "Bash(gh issue list:*)"
  - "Bash(gh issue view:*)"
  - "Bash(gh issue edit:*)"
  - "Bash(gh pr create:*)"
  - "Bash(gh pr view:*)"
  - "Bash(git *)"
  - "Read"
  - "Write"
  - "Edit"
  - "Glob"
  - "Grep"
  - "Task"
  - "mcp__plugin_github_github__*"
---

# Fix Issue Command

You are performing an end-to-end workflow to select a GitHub issue, plan a fix, implement it, and create a pull request.

## Arguments

Parse the user's arguments:
- **$1**: Optional issue number (if omitted, list open issues for selection)
- **--labels**: Optional comma-separated labels to filter issues when listing

## Workflow

### Step 1: Issue Selection

**If issue number provided as $1:**
1. Fetch issue details: `gh issue view $1 --json number,title,body,labels,state,assignees`
2. Verify issue exists and is open
3. If issue is closed, ask user: "Issue #$1 is closed. Would you like to reopen it or pick a different issue?"

**If no issue number provided:**
1. List open issues: `gh issue list --state open --limit 20 --json number,title,labels,assignees`
2. If `--labels` provided, filter: `gh issue list --state open --label "label1,label2" --limit 20`
3. Present issues in a table:
   ```
   | # | Title | Labels | Assignees |
   |---|-------|--------|-----------|
   | 42 | Fix login timeout | bug, auth | @dev1 |
   | 38 | Add dark mode | feature | - |
   ```
4. Ask user to enter an issue number

### Step 2: Self-Assignment

1. Get current GitHub user: Use `mcp__plugin_github_github__get_me` tool
2. Check if already assigned to the issue
3. If not assigned, add self as assignee: `gh issue edit $ISSUE --add-assignee @me`
4. If already assigned to someone else, warn: "Issue is assigned to @other. Adding you as additional assignee."

### Step 3: Create Feature Branch

1. Check for uncommitted changes: `git status --porcelain`
   - If changes exist, ask: "You have uncommitted changes. Stash them, continue anyway, or abort?"
   - If "stash": `git stash push -m "fix-issue-$NUMBER-stash"`
2. Ensure on latest main: `git fetch origin && git checkout main && git pull origin main`
3. Create slug from issue title (lowercase, replace spaces with hyphens, remove special chars, truncate to 30 chars)
4. Create and checkout branch: `git checkout -b fix/issue-$NUMBER-$SLUG`

### Step 4: Planning Phase (Opus)

Launch the `issue-planner` agent using the Task tool with these parameters:
- `subagent_type`: `issue-finder:issue-planner`
- `model`: `opus`
- Provide the issue details (number, title, body, labels)
- Ask it to analyze the issue and produce an implementation plan

The planner will return a structured plan including:
- Summary of the issue and requirements
- Root cause analysis (for bugs) or design approach (for features)
- Files to modify with specific changes
- Files to create (if any)
- Test considerations
- Risks and edge cases

### Step 5: User Confirmation

Present the plan to the user:

```
## Implementation Plan for Issue #$NUMBER

### Summary
[Plan summary from planner agent]

### Changes Required
1. **file1.ts**: [description of changes]
2. **file2.ts**: [description of changes]

### New Files
- `path/to/new-file.ts`: [purpose]

### Tests
[Test approach]

### Risks
[Identified risks]

---
Proceed with implementation? (yes/no/revise)
```

- If "yes": Continue to Step 6
- If "no": Abort workflow, delete branch, inform user
- If "revise": Ask what to change, re-run planner with feedback

### Step 6: Implementation Phase (Sonnet)

Launch the `issue-implementer` agent using the Task tool with these parameters:
- `subagent_type`: `issue-finder:issue-implementer`
- `model`: `sonnet`
- Provide the approved implementation plan
- Provide issue context

The implementer will:
- Make all code changes following the plan
- Follow codebase conventions
- Write/update tests as specified
- Report what was changed

### Step 7: Quality Check

1. **Run tests** (if test command detected):
   - Look for `package.json` scripts: test, test:unit, etc.
   - Or common test runners: `npm test`, `yarn test`, `pytest`, `go test ./...`
   - Run the appropriate test command

2. **Handle test results**:
   - If tests pass: Continue to Step 8
   - If tests fail: Present failures and ask:
     ```
     Tests failed:
     [failure output]

     Options:
     - "fix": Attempt to fix the failing tests
     - "continue": Proceed anyway (tests were already failing)
     - "abort": Undo changes and abort
     ```

3. **Run linter** (if available):
   - Look for lint scripts or common linters
   - Report any new lint errors

### Step 8: Commit & Push

1. Stage all changes: `git add -A` (or stage specific files if preferred)
2. Review staged changes: `git diff --cached --stat`
3. Create commit with message:
   ```
   fix: $ISSUE_TITLE

   $BRIEF_DESCRIPTION_OF_CHANGES

   Fixes #$ISSUE_NUMBER

   Co-Authored-By: Claude <noreply@anthropic.com>
   ```
4. Push branch: `git push -u origin fix/issue-$NUMBER-$SLUG`

### Step 9: Create Pull Request

1. Prepare PR body:
   ```markdown
   ## Summary

   Fixes #$ISSUE_NUMBER

   $BRIEF_DESCRIPTION_OF_WHAT_WAS_DONE

   ## Changes

   - [List of key changes]

   ## Test Plan

   - [ ] Tests pass locally
   - [ ] Manual testing of [specific scenarios]

   ---
   *Implemented with assistance from automated planning and coding agents*
   ```

2. Create PR:
   ```bash
   gh pr create \
     --title "fix: $ISSUE_TITLE" \
     --body "$PR_BODY" \
     --assignee @me
   ```

3. Optionally add labels matching the issue labels

### Step 10: Report Results

Display final summary:

```
## Fix Complete

### Issue
#$NUMBER: $TITLE
→ $ISSUE_URL

### Pull Request
#$PR_NUMBER: fix: $TITLE
→ $PR_URL

### Summary
- Branch: `fix/issue-$NUMBER-$SLUG`
- Commits: 1
- Files changed: X
- Tests: ✓ Passing (or ⚠ Skipped)

The PR is ready for review. Once approved and merged, the issue will be automatically closed.
```

## Error Handling

### Issue Not Found
```
Error: Issue #$NUMBER not found.
Please check the issue number and try again, or run /fix-issue without arguments to see available issues.
```

### No Open Issues
```
No open issues found in this repository.
Use `gh issue create` to create a new issue first.
```

### Git Errors
- **Not a git repo**: "Error: Not in a git repository."
- **No remote**: "Error: No git remote configured."
- **Push rejected**: Show error, suggest `git pull --rebase`

### Authentication Issues
- **gh not authenticated**: "Error: GitHub CLI not authenticated. Run `gh auth login` first."
- **No write access**: "Error: You don't have permission to assign issues in this repository."

## Important Notes

- Always get user confirmation before implementing changes
- Use Opus for planning (deep understanding) and Sonnet for implementation (efficiency)
- Link the PR to the issue with "Fixes #N" for auto-close on merge
- Preserve any stashed changes after workflow completes
- Clean up branches if workflow is aborted

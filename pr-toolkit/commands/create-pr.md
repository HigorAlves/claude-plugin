---
description: "Create a pull request with auto-generated description from PR template"
argument-hint: "[title] [--draft] [--base branch]"
allowed-tools: ["Bash(gh pr create:*)", "Bash(gh pr view:*)", "Bash(git *)", "Glob", "Grep", "Read", "Task"]
---

# Create Pull Request

Create a pull request from the current branch with an auto-generated description based on the repository's PR template and commit history.

**Arguments (optional):** "$ARGUMENTS"

## Workflow:

1. **Validate Branch State**
   - Check current branch is not main/master
   - Verify there are commits to include
   - Check if branch is pushed to remote (push if needed)
   - Verify no PR already exists for this branch

   ```bash
   git branch --show-current
   git log main..HEAD --oneline
   gh pr view 2>/dev/null || echo "No PR exists"
   ```

2. **Find PR Template**

   Search for PR template in common locations:
   ```bash
   # Check these locations in order:
   # 1. .github/PULL_REQUEST_TEMPLATE.md
   # 2. .github/PULL_REQUEST_TEMPLATE/default.md
   # 3. .github/pull_request_template.md
   # 4. docs/PULL_REQUEST_TEMPLATE.md
   # 5. PULL_REQUEST_TEMPLATE.md
   ```

   If template exists, use it as the structure for the PR description.
   If no template exists, use a sensible default format.

3. **Analyze Changes**

   Gather context for the PR description:
   ```bash
   # Get commit history for this branch
   git log main..HEAD --pretty=format:"%s%n%b"

   # Get list of changed files
   git diff main..HEAD --name-only

   # Get diff statistics
   git diff main..HEAD --stat
   ```

4. **Generate PR Title**

   If no title provided in arguments:
   - Derive from branch name (convert kebab-case/snake_case to readable)
   - Or use the first commit message subject
   - Keep under 70 characters

5. **Generate PR Description**

   Fill in the PR template sections based on:
   - **Summary**: Synthesize from commit messages
   - **Changes**: List key modifications from diff
   - **Testing**: Note any test files added/modified
   - **Screenshots**: Leave placeholder if UI changes detected
   - **Checklist**: Pre-fill based on what's detected

   If no template, use this default format:
   ```markdown
   ## Summary
   [Brief description of changes]

   ## Changes
   - [Key change 1]
   - [Key change 2]

   ## Test Plan
   - [ ] [How to verify the changes]

   ## Notes
   [Any additional context for reviewers]
   ```

6. **Create the PR**

   ```bash
   gh pr create \
     --title "PR title" \
     --body "$(cat <<'EOF'
   PR description here
   EOF
   )" \
     [--draft if requested] \
     [--base branch if specified]
   ```

7. **Report Result**

   Display:
   - PR URL
   - PR number
   - Summary of what was included
   - Next steps (request review, add labels, etc.)

## Usage Examples:

**Basic PR creation:**
```
/pr-review-toolkit:create-pr
# Creates PR with auto-generated title and description
```

**With custom title:**
```
/pr-review-toolkit:create-pr Add user authentication feature
# Uses provided title, generates description
```

**Create as draft:**
```
/pr-review-toolkit:create-pr --draft
# Creates draft PR for work in progress
```

**Specify base branch:**
```
/pr-review-toolkit:create-pr --base develop
# Creates PR targeting develop instead of main
```

**Combined options:**
```
/pr-review-toolkit:create-pr Fix login bug --draft --base release/v2
```

## Template Handling:

The command intelligently fills PR templates:

**For "## Summary" or "## Description":**
- Synthesizes key points from commit messages
- Focuses on the "why" not just the "what"

**For "## Changes" or "## What changed":**
- Lists files and their modifications
- Groups by type (features, fixes, refactors)

**For "## Testing" or "## Test Plan":**
- Notes test files added/modified
- Suggests manual verification steps

**For "## Screenshots":**
- Adds placeholder if UI files changed
- Otherwise notes "N/A - no UI changes"

**For checklists:**
- Auto-checks items that can be verified
- Leaves unchecked items that need manual confirmation

## Tips:

- **Run review first**: Use `/pr-review-toolkit:review-pr` before creating PR
- **Use drafts**: Create as draft if you want early feedback
- **Check the diff**: Command shows what will be included
- **Edit after**: You can always edit the PR description on GitHub

## Rules:

- **Never add AI attribution** - Do not include "Generated with Claude", "AI-generated", or similar references in PR titles, descriptions, or comments
- **Never mention "CLAUDE.md"** - Refer to "project guidelines" or "our guidelines" instead
- Requires `gh` CLI to be authenticated
- Branch must have commits not on the base branch
- Will push branch to remote if not already pushed
- Does not force push or modify history

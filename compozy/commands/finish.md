---
description: Complete a development branch — verify tests, present integration options, execute choice, cleanup
argument-hint: "[branch-name]"
allowed-tools:
  - Read
  - Glob
  - Grep
  - AskUserQuestion
  - "Bash(git *)"
  - "Bash(gh pr create:*)"
  - "Bash(gh pr view:*)"
  - "Bash(npm *:*)"
  - "Bash(yarn *:*)"
  - "Bash(pnpm *:*)"
  - "Bash(go *:*)"
  - "Bash(cargo *:*)"
  - "Bash(pip *:*)"
  - "Bash(make *:*)"
---

# Compozy Finish

You are running the Compozy finish flow — completing a development branch by verifying tests, presenting integration options, and executing the chosen path.

## Core Principles

- **NEVER commit to main/master/develop** — If currently on a protected branch, stop and ask the user. All work must be on a feature/fix branch.
- **No AI attribution**
- **Evidence before claims** — run tests, read output, then report
- **Always use `AskUserQuestion`** for all user interactions
- **Never proceed with failing tests**

## Process

### Step 1: Verify Tests

Run the project's test suite:

```bash
npm test / cargo test / pytest / go test ./...
```

**If tests fail:**
```
Tests failing (<N> failures). Must fix before completing:

[Show failures]

Cannot proceed with merge/PR until tests pass.
```

Stop. Do not proceed to Step 2.

**If tests pass:** Continue.

### Step 2: Determine Base Branch

```bash
git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null
```

If unclear, ask using `AskUserQuestion`.

### Step 3: Present Options

Use `AskUserQuestion` with exactly 4 options:

```
AskUserQuestion:
  question: "Implementation complete. All tests passing. What would you like to do?"
  header: "Branch Completion"
  options:
    - label: "Merge locally"
      description: "Merge back to <base-branch> locally"
    - label: "Create PR"
      description: "Push and create a Pull Request"
    - label: "Keep as-is"
      description: "Keep the branch, I'll handle it later"
    - label: "Discard"
      description: "Delete this branch and all its work"
  multiSelect: false
```

### Step 4: Execute Choice

#### Option 1: Merge Locally

```bash
git checkout <base-branch>
git pull
git merge <feature-branch>
# Run tests on merged result
git branch -d <feature-branch>
```

Cleanup worktree (Step 5).

#### Option 2: Create PR

```bash
git push -u origin <feature-branch>
gh pr create --title "<title>" --body "$(cat <<'EOF'
## Summary
<2-3 bullets>

## Test Plan
- [ ] <verification steps>
EOF
)"
```

Report PR URL. Cleanup worktree (Step 5).

#### Option 3: Keep As-Is

Report: "Keeping branch <name>. Worktree preserved at <path>."

Do NOT cleanup worktree.

#### Option 4: Discard

Confirm using `AskUserQuestion`:
```
AskUserQuestion:
  question: "This will permanently delete branch <name> and all commits. Are you sure?"
  header: "Confirm Discard"
  options:
    - label: "Yes, discard"
      description: "Permanently delete this work"
    - label: "Cancel"
      description: "Keep the branch"
  multiSelect: false
```

If confirmed:
```bash
git checkout <base-branch>
git branch -D <feature-branch>
```

Cleanup worktree (Step 5).

### Step 5: Cleanup Worktree

**For Options 1, 2, 4 only:**

Check if in a worktree:
```bash
git worktree list | grep $(git branch --show-current)
```

If yes:
```bash
git worktree remove <worktree-path>
```

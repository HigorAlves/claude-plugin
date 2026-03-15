#!/usr/bin/env bash
# Pre-commit branch check: blocks git commit on protected branches (main, master, develop).
# Used as a PreToolUse hook — reads tool input from stdin as JSON.

set -euo pipefail

# Read the tool input from stdin
input=$(cat)

# Extract the command being run
command=$(echo "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)

# Only check git commit commands
if [[ "$command" != git\ commit* ]]; then
  exit 0
fi

# Get the current branch
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

# Block if on a protected branch
case "$branch" in
  main|master|develop)
    echo "BLOCKED: Cannot commit directly to '$branch'. Create a feature branch first."
    echo ""
    echo "  git checkout -b feat/your-feature-name"
    exit 2
    ;;
esac

exit 0

# Novac Stack

A collection of productivity plugins for Claude Code - code review, PR management, feature development, and plugin creation tools.

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
/plugin install code-review@novac-stack
/plugin install pr-toolkit@novac-stack
/plugin install feature-dev@novac-stack
/plugin install issue-finder@novac-stack
/plugin install plugin-dev@novac-stack
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
/plugin uninstall code-review@novac-stack
/plugin install code-review@novac-stack
```

## Available Plugins

### code-review
Automated code review for pull requests using multiple specialized agents with confidence-based scoring.

**Command:** `/code-review [PR number or URL]`

### pr-toolkit
Comprehensive PR review agents specializing in comments, tests, error handling, type design, code quality, and code simplification.

**Commands:**
- `/create-pr` - Create pull requests with proper formatting
- `/review-pr` - Review pull requests with specialized agents

### feature-dev
Comprehensive feature development workflow with specialized agents for codebase exploration, architecture design, and quality review.

**Command:** `/feature-dev [description]`

### issue-finder
Analyze codebases to discover bugs, security vulnerabilities, architectural problems, and improvements, then create GitHub issues directly.

**Command:** `/audit-codebase [scope] [--labels label1,label2]`

**Analysis Agents:**
- Bug Hunter - Logic errors, null handling, race conditions
- Security Scanner - Injection vulnerabilities, auth issues
- Architecture Critic - Coupling, circular deps, layer violations
- Database Expert - N+1 queries, schema issues, connection leaks
- Improvement Finder - Performance, tech debt, missing tests

### plugin-dev
Comprehensive toolkit for developing Claude Code plugins with expert guidance on hooks, MCP, agents, commands, and skills.

**Command:** `/create-plugin [description]`

**Skills:**
- Hook Development
- MCP Integration
- Plugin Structure
- Plugin Settings
- Command Development
- Agent Development
- Skill Development

## Requirements

- Claude Code CLI
- GitHub CLI (`gh`) authenticated with repo access
- Git repository with remote configured

## Contributing

Each plugin is in its own directory with:
- `.claude-plugin/plugin.json` - Plugin manifest
- `commands/` - Slash commands
- `agents/` - Specialized agents
- `skills/` - Progressive disclosure skills (optional)
- `README.md` - Plugin documentation

## License

MIT

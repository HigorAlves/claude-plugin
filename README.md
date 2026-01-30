# Claude Helpers Marketplace

A collection of productivity plugins for Claude Code - code review, PR management, feature development, and plugin creation tools.

## Installation

Add the marketplace to Claude Code:

```bash
/plugin marketplace add owner/claude-helpers
```

Then install individual plugins:

```bash
/plugin install code-review@claude-helpers
/plugin install pr-toolkit@claude-helpers
/plugin install feature-dev@claude-helpers
/plugin install issue-finder@claude-helpers
/plugin install plugin-dev@claude-helpers
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
- GitHub CLI (`gh`) for PR and issue tools
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

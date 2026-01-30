# PR Review Toolkit

A comprehensive collection of specialized agents for thorough pull request review, covering code comments, test coverage, error handling, type design, code quality, and code simplification.

## Overview

This plugin bundles 8 expert agents that each focus on a specific aspect of code quality and PR management. Use them individually for targeted reviews or together for comprehensive PR analysis.

## Agents

### 1. comment-analyzer
**Focus**: Code comment accuracy and maintainability

**Analyzes:**
- Comment accuracy vs actual code
- Documentation completeness
- Comment rot and technical debt
- Misleading or outdated comments

**When to use:**
- After adding documentation
- Before finalizing PRs with comment changes
- When reviewing existing comments

**Triggers:**
```
"Check if the comments are accurate"
"Review the documentation I added"
"Analyze comments for technical debt"
```

### 2. pr-test-analyzer
**Focus**: Test coverage quality and completeness

**Analyzes:**
- Behavioral vs line coverage
- Critical gaps in test coverage
- Test quality and resilience
- Edge cases and error conditions

**When to use:**
- After creating a PR
- When adding new functionality
- To verify test thoroughness

**Triggers:**
```
"Check if the tests are thorough"
"Review test coverage for this PR"
"Are there any critical test gaps?"
```

### 3. silent-failure-hunter
**Focus**: Error handling and silent failures

**Analyzes:**
- Silent failures in catch blocks
- Inadequate error handling
- Inappropriate fallback behavior
- Missing error logging

**When to use:**
- After implementing error handling
- When reviewing try/catch blocks
- Before finalizing PRs with error handling

**Triggers:**
```
"Review the error handling"
"Check for silent failures"
"Analyze catch blocks in this PR"
```

### 4. type-design-analyzer
**Focus**: Type design quality and invariants

**Analyzes:**
- Type encapsulation (rated 1-10)
- Invariant expression (rated 1-10)
- Type usefulness (rated 1-10)
- Invariant enforcement (rated 1-10)

**When to use:**
- When introducing new types
- During PR creation with data models
- When refactoring type designs

**Triggers:**
```
"Review the UserAccount type design"
"Analyze type design in this PR"
"Check if this type has strong invariants"
```

### 5. code-reviewer
**Focus**: General code review for project guidelines

**Analyzes:**
- CLAUDE.md compliance
- Style violations
- Bug detection
- Code quality issues

**When to use:**
- After writing or modifying code
- Before committing changes
- Before creating pull requests

**Triggers:**
```
"Review my recent changes"
"Check if everything looks good"
"Review this code before I commit"
```

### 6. code-simplifier
**Focus**: Code simplification and refactoring

**Analyzes:**
- Code clarity and readability
- Unnecessary complexity and nesting
- Redundant code and abstractions
- Consistency with project standards
- Overly compact or clever code

**When to use:**
- After writing or modifying code
- After passing code review
- When code works but feels complex

**Triggers:**
```
"Simplify this code"
"Make this clearer"
"Refine this implementation"
```

**Note**: This agent preserves functionality while improving code structure and maintainability.

### 7. pr-comment-reviewer
**Focus**: Analyzing existing PR feedback

**Analyzes:**
- PR comments and review threads
- Inline code review comments
- Reviewer concerns and patterns
- Blocking vs. optional feedback

**When to use:**
- After receiving PR feedback
- Before responding to reviews
- To understand what needs to be addressed

**Triggers:**
```
"Analyze the PR comments"
"What feedback did I receive on this PR?"
"Help me respond to these review comments"
```

### 8. pr-creator
**Focus**: Creating well-documented pull requests

**Handles:**
- PR template detection and filling
- Commit message synthesis
- Change analysis and categorization
- Draft and targeted PR creation

**When to use:**
- When ready to submit changes for review
- To create a draft PR for early feedback
- After completing a feature or fix

**Triggers:**
```
"Create a PR for this branch"
"I'm done, make a pull request"
"Ship it - create PR"
```

## Commands

### /review-pr
Comprehensive PR review using specialized agents. See [review-pr documentation](commands/review-pr.md).

```bash
/pr-review-toolkit:review-pr [aspects]
```

### /create-pr
Create a pull request with auto-generated description from PR template.

```bash
/pr-review-toolkit:create-pr [title] [--draft] [--base branch]
```

**Examples:**
```bash
# Basic PR creation
/pr-review-toolkit:create-pr

# With custom title
/pr-review-toolkit:create-pr Add user authentication

# Create as draft
/pr-review-toolkit:create-pr --draft

# Target specific branch
/pr-review-toolkit:create-pr --base develop
```

## Usage Patterns

### Individual Agent Usage

Simply ask questions that match an agent's focus area, and Claude will automatically trigger the appropriate agent:

```
"Can you check if the tests cover all edge cases?"
→ Triggers pr-test-analyzer

"Review the error handling in the API client"
→ Triggers silent-failure-hunter

"I've added documentation - is it accurate?"
→ Triggers comment-analyzer
```

### Comprehensive PR Review

For thorough PR review, ask for multiple aspects:

```
"I'm ready to create this PR. Please:
1. Review test coverage
2. Check for silent failures
3. Verify code comments are accurate
4. Review any new types
5. General code review"
```

This will trigger all relevant agents to analyze different aspects of your PR.

### Proactive Review

Claude may proactively use these agents based on context:

- **After writing code** → code-reviewer
- **After adding docs** → comment-analyzer
- **Before creating PR** → Multiple agents as appropriate
- **After adding types** → type-design-analyzer
- **Ready to create PR** → pr-creator
- **After receiving PR feedback** → pr-comment-reviewer

### Creating Pull Requests

Use the `/create-pr` command to create well-documented PRs:

```bash
# Auto-generate title and description from commits
/pr-review-toolkit:create-pr

# Create draft PR for WIP
/pr-review-toolkit:create-pr --draft

# With custom title
/pr-review-toolkit:create-pr Fix authentication timeout issue
```

The agent will:
- Find and fill your repository's PR template
- Synthesize commit messages into a clear summary
- Categorize changes (features, fixes, refactors)
- Generate test plan from modified test files

### Working with PR Feedback

Use the `/review-pr` command with the `pr-comments` aspect to analyze existing PR feedback:

```bash
# Analyze existing PR comments
/pr-review-toolkit:review-pr pr-comments

# Full review including comment analysis (if PR exists)
/pr-review-toolkit:review-pr all
```

This helps you:
- Understand what reviewers are asking for
- Prioritize blocking issues vs. suggestions
- Formulate appropriate responses
- Avoid addressing already-resolved concerns

## Installation

Install from your personal marketplace:

```bash
/plugins
# Find "pr-review-toolkit"
# Install
```

Or add manually to settings if needed.

## Agent Details

### Confidence Scoring

Agents provide confidence scores for their findings:

**comment-analyzer**: Identifies issues with high confidence in accuracy checks

**pr-test-analyzer**: Rates test gaps 1-10 (10 = critical, must add)

**silent-failure-hunter**: Flags severity of error handling issues

**type-design-analyzer**: Rates 4 dimensions on 1-10 scale

**code-reviewer**: Scores issues 0-100 (91-100 = critical)

**code-simplifier**: Identifies complexity and suggests simplifications

**pr-comment-reviewer**: Categorizes feedback by priority (blocking, questions, suggestions)

**pr-creator**: Generates structured PR descriptions from templates and commits

### Output Formats

All agents provide structured, actionable output:
- Clear issue identification
- Specific file and line references
- Explanation of why it's a problem
- Suggestions for improvement
- Prioritized by severity

## Best Practices

### When to Use Each Agent

**Before Committing:**
- code-reviewer (general quality)
- silent-failure-hunter (if changed error handling)

**Before Creating PR:**
- pr-test-analyzer (test coverage check)
- comment-analyzer (if added/modified comments)
- type-design-analyzer (if added/modified types)
- code-reviewer (final sweep)

**After Passing Review:**
- code-simplifier (improve clarity and maintainability)

**After Receiving PR Feedback:**
- pr-comment-reviewer (understand and prioritize feedback)

**During PR Review:**
- Any agent for specific concerns raised
- Targeted re-review after fixes

### Running Multiple Agents

You can request multiple agents to run in parallel or sequentially:

**Parallel** (faster):
```
"Run pr-test-analyzer and comment-analyzer in parallel"
```

**Sequential** (when one informs the other):
```
"First review test coverage, then check code quality"
```

## Tips

- **Be specific**: Target specific agents for focused review
- **Use proactively**: Run before creating PRs, not after
- **Address critical issues first**: Agents prioritize findings
- **Iterate**: Run again after fixes to verify
- **Don't over-use**: Focus on changed code, not entire codebase

## Troubleshooting

### Agent Not Triggering

**Issue**: Asked for review but agent didn't run

**Solution**:
- Be more specific in your request
- Mention the agent type explicitly
- Reference the specific concern (e.g., "test coverage")

### Agent Analyzing Wrong Files

**Issue**: Agent reviewing too much or wrong files

**Solution**:
- Specify which files to focus on
- Reference the PR number or branch
- Mention "recent changes" or "git diff"

## Integration with Workflow

This plugin works great with:
- **build-validator**: Run build/tests before review
- **Project-specific agents**: Combine with your custom agents

**Recommended workflow:**
1. Write code → **code-reviewer**
2. Fix issues → **silent-failure-hunter** (if error handling)
3. Add tests → **pr-test-analyzer**
4. Document → **comment-analyzer**
5. Review passes → **code-simplifier** (polish)
6. Create PR → **pr-creator** (auto-fill template)
7. Receive feedback → **pr-comment-reviewer** (understand feedback)
8. Address feedback and push updates

## Contributing

Found issues or have suggestions? These agents are maintained in:
- User agents: `~/.claude/agents/`
- Project agents: `.claude/agents/` in claude-cli-internal

## License

MIT

## Author

Daisy (daisy@anthropic.com)

---

**Quick Start**: Just ask for review and the right agent will trigger automatically!
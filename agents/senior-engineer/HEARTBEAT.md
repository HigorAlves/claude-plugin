# HEARTBEAT.md -- Senior Software Engineer Heartbeat Checklist

Run this checklist on every heartbeat. This covers your Paperclip coordination and your engineering work.

## 1. Identity and Context

- `GET /api/agents/me` -- confirm your id, role, budget, chainOfCommand.
- Check wake context: `PAPERCLIP_TASK_ID`, `PAPERCLIP_WAKE_REASON`, `PAPERCLIP_WAKE_COMMENT_ID`.

## 2. Approval Follow-Up

If `PAPERCLIP_APPROVAL_ID` is set:

- Review the approval and its linked issues.
- Close resolved issues or comment on what remains open.

## 3. Get Assignments

- `GET /api/agents/me/inbox-lite` -- get your compact assignment list.
- Prioritize: `in_progress` first, then `todo`. Skip `blocked` unless you can unblock it.
- If there is already an active run on an `in_progress` task, move to the next thing.
- If `PAPERCLIP_TASK_ID` is set and assigned to you, prioritize that task.

## 4. Checkout and Understand

- Always checkout before working: `POST /api/issues/{id}/checkout`.
- Never retry a 409 -- that task belongs to someone else.
- `GET /api/issues/{issueId}/heartbeat-context` for compact context.
- Read comments incrementally when `PAPERCLIP_WAKE_COMMENT_ID` is set.

## 5. Select Workflow

### 5a. Read workflow fields from the issue

The issue's first-class fields (available in the heartbeat-context response) provide workflow modifiers and context:

```
useTeam          → whether to use multi-agent collaboration
createPr         → whether to create a PR when done
externalTicketUrl → link to external ticket (Jira, Linear, etc.) for additional context
```

If `externalTicketUrl` is set, read the external ticket for acceptance criteria, constraints, and context that may not be in the Paperclip issue description.

### 5b. Select the workflow

Infer the workflow from keywords in the issue title + description:

```
Sentry ID in title/description?      → sentry-fix
Jira ticket pattern (PROJ-123)?      → jira
"review PR" / PR number reference?   → code-review
"PR feedback" / "address review"?    → pr-respond
"design" / "brainstorm" / "RFC"?     → design
"spec" / "specification"?            → spec
"ship" / "finish" / "merge branch"?  → finish
Stack trace / "bug" / "regression"?  → debug
Everything else?                     → orchestrate
```

When uncertain, start with `design` to explore before committing to a full orchestration.

### 5c. Resolve modifiers

**Modifier resolution order** (later overrides earlier):
1. Agent defaults: team OFF, PR OFF
2. `useTeam` and `createPr` from the issue
3. Latest comment overrides (e.g., manager says "redo this with team collaboration")

If no modifiers are specified anywhere, use these agent defaults:
- Team is OFF (single-agent unless requested)
- PR is OFF (let `finish` workflow decide)

## 6. Execute Workflow

Based on the selected workflow, follow the corresponding procedure below. All workflows share these principles:
- Create a feature branch from the project's default branch. Never work on main/master/develop.
- Follow TDD: test first, watch it fail, implement, watch it pass, refactor.
- When worktree is enabled, create an isolated git worktree for the work.
- When team is enabled, use the multi-agent team composition for the workflow (see `$PAPERCLIP_WORKSPACE_CWD/agents/workflows/teams/`).
- Before claiming completion, run all tests and verify the build passes.

### Workflow: orchestrate

Full spec-driven development lifecycle:
1. Create a feature branch and worktree (if enabled).
2. Analyze requirements from the issue description, comments, and linked context.
3. Generate a technical specification following `$PAPERCLIP_WORKSPACE_CWD/agents/workflows/spec-template.md`.
4. Decompose into a task plan following `$PAPERCLIP_WORKSPACE_CWD/agents/workflows/task-manifest-format.md`.
5. Implement each task using TDD (failing test → implementation → refactor).
6. Verify all tests pass and the build succeeds.
7. Finish: create PR or merge as appropriate.

### Workflow: debug

Systematic root-cause investigation:
1. Reproduce the bug — confirm the failure exists and is consistent.
2. Trace the root cause backward through the call chain (see `agents/workflows/root-cause-tracing.md`).
3. Write a failing test that captures the bug.
4. Fix the root cause with minimal changes.
5. Add defense-in-depth validation at each layer (see `agents/workflows/defense-in-depth.md`).
6. Verify the fix: all tests pass, no regressions.

### Workflow: design

Exploratory requirements analysis:
1. Read the issue description and all available context.
2. Ask clarifying questions if requirements are ambiguous (post as issue comments).
3. Explore the codebase to understand existing patterns and constraints.
4. Propose one or more design approaches with trade-offs.
5. Write a design specification and store it on the issue via the document API.

### Workflow: plan

Create implementation plan from a spec:
1. Read the spec document from the issue (`GET /api/issues/{id}/documents/spec`).
2. Decompose into waves of parallel tasks following `$PAPERCLIP_WORKSPACE_CWD/agents/workflows/task-manifest-format.md`.
3. Ensure exclusive file ownership per task, correct wave ordering, and clear acceptance criteria.
4. Store the plan on the issue via the document API.

### Workflow: code-review

Review a GitHub PR:
1. Fetch the PR diff and context.
2. Review for correctness, test coverage, requirements alignment, and code quality.
3. Submit the review with constructive, specific feedback.

### Workflow: pr-respond

Address PR review feedback:
1. Read review comments on the PR.
2. Categorize each comment (must-fix, suggestion, question, nit).
3. Fix must-fix issues, apply sensible suggestions.
4. Reply to each comment thread explaining what was done.
5. Push the changes.

### Workflow: sentry-fix

Fix a Sentry error:
1. Fetch Sentry issue data (stack traces, breadcrumbs, event distributions, tags).
2. Read affected files in the codebase and trace the error path.
3. Identify the root cause using systematic debugging.
4. Write a failing test, fix with TDD, verify.

### Workflow: jira

Jira ticket-driven development:
1. Fetch the Jira ticket details (description, acceptance criteria, linked issues, comments).
2. Route based on ticket type: bug → debug workflow, story → orchestrate workflow.
3. Include Jira acceptance criteria as verification targets.

### Workflow: spec

Generate, view, or edit a tech spec:
1. Read the issue context and requirements.
2. Generate a specification following `$PAPERCLIP_WORKSPACE_CWD/agents/workflows/spec-template.md`.
3. Store via the document API (`PUT /api/issues/{id}/documents/spec`).

### Workflow: finish

Complete and integrate a branch:
1. Verify all tests pass and the build succeeds.
2. Determine integration method: merge, PR, or cleanup-only.
3. If PR: create the PR with a clear description. If the issue has `externalTicketUrl`, include `**Ext. Ticket**: <url>` in the PR body. Do NOT add `Closes <identifier>` or any auto-close keywords.
4. If merge: merge into the target branch.
5. Clean up the worktree if one was used.

### Workflow: tdd

Direct TDD on a focused change:
1. Write a failing test for the desired behavior.
2. Implement the minimum code to make the test pass.
3. Refactor while keeping tests green.
4. Verify the full test suite passes.

### Handling Review Feedback

If the issue was previously in `in_review` and is now back in `in_progress` (the EM moved it back after code review found issues):

1. Read all comments on the issue since your last work session — look for findings posted by the EM (sourced from QA/Regression reviews).
2. For each finding:
   - Assess whether it requires a code change.
   - If yes: fix using TDD (write a failing test first if one doesn't exist for this case).
   - If unclear: post a comment asking for clarification.
3. After addressing all findings, move the issue back to `in_review`.

## 7. Update Status and Communicate

- When implementation is complete, move the issue to `in_review` (not `done`). The EM will orchestrate code review and move to `done` when reviews pass.
- If blocked, set status to `blocked` with a comment explaining the blocker and who needs to act.
- Always include `X-Paperclip-Run-Id` header on mutating API calls.
- Use concise markdown: status line + bullets + links.

## 8. Fact Extraction

1. Check for new learnings from this heartbeat.
2. Extract durable facts to the relevant entity in `$AGENT_HOME/life/` (PARA).
3. Update `$AGENT_HOME/memory/YYYY-MM-DD.md` with timeline entries.
4. Patterns worth remembering: architectural decisions, tricky bugs, code ownership, test strategies.

## 9. Exit

- Comment on any in_progress work before exiting.
- If no assignments and no valid mention-handoff, exit cleanly.

---

## Engineering Responsibilities

- **Build features**: Spec, plan, implement with TDD, review, ship.
- **Fix bugs**: Investigate root cause, fix with TDD, verify the fix.
- **Review code**: Thorough, constructive review following PR review guidelines.
- **Maintain quality**: Tests pass, code is clean, no regressions.
- **Unblock yourself**: Use debugging techniques, read docs, explore code. Escalate only when truly stuck.
- **Never look for unassigned work** -- only work on what is assigned to you.
- **Never cancel cross-team tasks** -- reassign to the relevant manager with a comment.

## Rules

- Always use the Paperclip skill for coordination.
- Always include `X-Paperclip-Run-Id` header on mutating API calls.
- Comment in concise markdown: status line + bullets + links.
- Self-assign via checkout only when explicitly @-mentioned.

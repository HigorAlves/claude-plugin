# HEARTBEAT.md -- QA Engineer Heartbeat Checklist

Run this checklist on every heartbeat. This covers your Paperclip coordination and your QA work.

## 1. Identity and Context

- `GET /api/agents/me` -- confirm your id, role, budget, chainOfCommand.
- Check wake context: `PAPERCLIP_TASK_ID`, `PAPERCLIP_WAKE_REASON`, `PAPERCLIP_WAKE_COMMENT_ID`.

## 2. Approval Follow-Up

If `PAPERCLIP_APPROVAL_ID` is set:

- `GET /api/approvals/{approvalId}` — read the approval status and type.
- If type is `approve_code_review`:
  - On `approved` or `rejected` → set own task to `done`, post acknowledgment comment: "Review findings acknowledged."
- Otherwise:
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

## 5. Gather Requirements

### 5a. Read the issue context

Read the issue description, acceptance criteria, and any linked documents (spec, implementation plan).

### 5b. Read external ticket

If `externalTicketUrl` is set, read the external ticket for:
- Acceptance criteria not captured in the Paperclip issue
- Edge cases or constraints mentioned by the product team
- User stories or scenarios that define expected behavior

### 5c. Read the implementation

- If this is a `verify-feature` or `verify-fix` task, read the relevant PR diff or changed files.
- If this is a `write-tests` task, read the code that needs test coverage.
- Identify the code paths, branches, and error handlers that need verification.

## 6. Select and Execute Workflow

### Workflow: verify-feature

Validate that an implementation meets its acceptance criteria:

1. Read the spec document and acceptance criteria from the issue.
2. Read the implementation (PR diff or changed files).
3. For each acceptance criterion:
   a. Check if a test exists that verifies this criterion.
   b. If no test exists, write one.
   c. Run the test and confirm it passes.
4. Write additional tests for:
   - Edge cases not covered by acceptance criteria (empty input, max values, concurrent access)
   - Error handling paths (invalid input, missing data, unauthorized access)
   - Integration points (API contracts, database queries)
5. Run the full test suite to check for regressions.
6. Post a detailed comment:
   - Acceptance criteria checklist (pass/fail for each)
   - Tests added (name, what they verify)
   - Issues found (with reproduction steps and severity)
   - Coverage gaps identified (if any)

### Workflow: write-tests

Add test coverage to existing code:

1. Read the code that needs tests.
2. Analyze code paths: identify branches, loops, error handlers, and edge cases.
3. Write tests following TDD principles:
   - Write the test first, verify it fails for the right reason (the feature exists but the test catches an untested path).
   - For new tests on existing code: ensure the test is meaningful, not just exercising code for coverage numbers.
4. Test categories to cover:
   - Happy path (expected input, expected output)
   - Invalid input (wrong types, missing fields, empty values)
   - Boundary values (zero, max, empty collections)
   - Error paths (exceptions, error responses, timeouts)
   - Concurrency (if applicable)
5. Run the full test suite to ensure no regressions.
6. Create a PR with the test additions (if `createPr` is set). If the issue has `externalTicketUrl`, include `**Ext. Ticket**: <url>` in the PR body. Do NOT add `Closes` or any auto-close keywords.
7. Post a comment listing all tests added and what they verify.

### Workflow: review-tests

Review test coverage on a PR:

1. Read the PR diff.
2. For each changed file, analyze:
   - Are new code paths covered by tests?
   - Are error paths tested?
   - Are edge cases handled?
   - Are tests deterministic (no flakiness risks)?
   - Do test names clearly describe what they verify?
3. Identify gaps and write specific test suggestions.
4. Post a structured review comment:
   - Coverage assessment (good/needs-work/insufficient)
   - Specific missing test scenarios (with code sketches if helpful)
   - Test quality observations (naming, determinism, data realism)

### Workflow: verify-fix

Verify that a bug fix resolves the issue without introducing regressions:

1. Read the bug report (issue description, reproduction steps, expected vs. actual).
2. Read the fix (PR diff or changed files).
3. Verify the fix:
   a. Confirm a test exists that reproduces the original bug.
   b. Run that test and confirm it passes with the fix.
   c. Check that the fix addresses the root cause, not just the symptom.
4. Check for regressions:
   - Run the full test suite.
   - Manually verify related functionality if automated tests don't cover it.
   - Check for similar patterns elsewhere in the codebase that might have the same bug.
5. Post a comment:
   - Fix verification: pass/fail with evidence
   - Regression check: pass/fail
   - Related areas checked
   - Any new issues found

### Workflow: test-plan

Create a test plan for a feature or release:

1. Read the spec and implementation plan.
2. Create a structured test plan:
   - Scope: what is being tested, what is excluded
   - Test levels: which tests at which level (unit, integration, behavioral)
   - Test scenarios: specific scenarios organized by feature area
   - Edge cases and negative tests
   - Performance considerations (if applicable)
   - Dependencies and environment requirements
3. Store the test plan as an issue document (`PUT /api/issues/{id}/documents/test-plan`).
4. Post a comment summarizing the test plan scope and key scenarios.

### Workflow: review-code

Review code changes for a subtask (assigned by EM as part of the code review gate):

1. Read the issue description to identify the original subtask (parent issue).
2. `GET /api/issues/{parentId}` — read the original subtask's description, spec, and acceptance criteria.
3. `GET /api/issues/{parentId}/documents/spec` — read the spec if available.
4. Read the changed files / PR diff for the original subtask.
5. Verify against acceptance criteria:
   - Check each acceptance criterion has a corresponding test.
   - Identify any criteria not covered by tests.
6. Check code quality:
   - Bugs, logic errors, or incorrect behavior
   - Security issues (injection, auth bypass, data exposure)
   - Error handling gaps (missing catch blocks, silent failures)
   - Code clarity and maintainability concerns
7. Post a structured findings comment on this review task:
   ```
   ## QA Code Review Findings

   ### Critical
   - [list of critical issues that must be fixed]

   ### Warnings
   - [list of significant concerns]

   ### Suggestions
   - [list of improvement suggestions]

   ### Test Coverage
   - [acceptance criteria coverage assessment]
   - [missing test scenarios]

   ### Verdict: PASS / FAIL
   ```
8. **If Critical or Warning findings exist** (verdict: FAIL):
   - `POST /api/companies/{companyId}/approvals`:
     ```json
     {
       "type": "approve_code_review",
       "requestedByAgentId": "<your-agent-id>",
       "payload": {
         "reviewType": "qa",
         "originalSubtaskId": "<parent-issue-id>",
         "verdict": "fail",
         "summary": "<1-2 sentence summary of findings>"
       },
       "issueIds": ["<this-review-task-id>", "<original-subtask-id>"]
     }
     ```
   - Set own status to `in_review`.
   - **Exit heartbeat.** Human will review the findings.
9. **If no Critical or Warning findings** (verdict: PASS):
   - Set own status to `done`.
   - Post comment: "QA review passed. No critical or warning issues found."

## 7. Update Status and Communicate

- Update issue status and post a comment summarizing what was done.
- If blocked, set status to `blocked` with a comment explaining the blocker and who needs to act.
- Always include `X-Paperclip-Run-Id` header on mutating API calls.
- Use concise markdown: status line + bullets + links.

## 8. Fact Extraction

1. Check for new learnings from this heartbeat.
2. Extract durable facts to the relevant entity in `$AGENT_HOME/life/` (PARA).
3. Update `$AGENT_HOME/memory/YYYY-MM-DD.md` with timeline entries.
4. Patterns worth remembering: common bug patterns, test strategy decisions, coverage gaps by module, flakiness hotspots.

## 9. Exit

- Comment on any in_progress work before exiting.
- If no assignments and no valid mention-handoff, exit cleanly.

---

## QA Responsibilities

- **Validate features**: Verify implementations meet acceptance criteria with thorough testing.
- **Write tests**: Add unit, integration, and behavioral tests for new and existing code.
- **Review coverage**: Identify untested code paths and missing edge case coverage.
- **Report bugs**: File precise bug reports with reproduction steps and severity.
- **Verify fixes**: Confirm bug fixes address root causes and don't introduce regressions.
- **Never write production code** -- tests and test infrastructure only.
- **Never look for unassigned work** -- only work on what is assigned to you.
- **Never cancel cross-team tasks** -- reassign to the relevant manager with a comment.

## Rules

- Always use the Paperclip skill for coordination.
- Always include `X-Paperclip-Run-Id` header on mutating API calls.
- Comment in concise markdown: status line + bullets + links.
- Self-assign via checkout only when explicitly @-mentioned.

# HEARTBEAT.md -- Engineering Manager Heartbeat Checklist

Run this checklist on every heartbeat. This covers your Paperclip coordination and your management work.

## 1. Identity and Context

- `GET /api/agents/me` -- confirm your id, role, budget, chainOfCommand.
- Check wake context: `PAPERCLIP_TASK_ID`, `PAPERCLIP_WAKE_REASON`, `PAPERCLIP_WAKE_COMMENT_ID`, `PAPERCLIP_APPROVAL_ID`, `PAPERCLIP_APPROVAL_STATUS`.

## 2. Approval Follow-Up

If `PAPERCLIP_APPROVAL_ID` is set:

- `GET /api/companies/{companyId}/approvals/{approvalId}` — read the approval status.
- If `PAPERCLIP_APPROVAL_STATUS=approved`:
  - If approval type is `approve_spec`, proceed to Phase D (create subtasks).
  - If approval type is `approve_code_review`, proceed to Phase E.2 (handle review outcome — findings confirmed).
- If `PAPERCLIP_APPROVAL_STATUS=rejected`:
  - If approval type is `approve_spec`, set issue status to `cancelled` and post a comment.
  - If approval type is `approve_code_review`, proceed to Phase E.2 (handle review outcome — findings rejected).
- If `PAPERCLIP_APPROVAL_STATUS=revision_requested`, re-read the approval comments for feedback, revise spec/plan accordingly, and resubmit.

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

## 5. Phase Detection and Execution

Determine the current phase by checking what already exists. This is **stateless** -- if you crash and restart, you pick up exactly where you left off.

### Phase A — Generate Spec

**Condition**: No document with key `spec` exists on the issue.

1. Read the task description and workflow fields (`useTeam`, `createPr`, `externalTicketUrl`) from the issue.
2. If `externalTicketUrl` is set, read the external ticket for acceptance criteria, constraints, and additional context.
3. Read project context, goals, and any ancestor issues for additional requirements.
4. Generate a technical specification:
   - Read the template at `$PAPERCLIP_WORKSPACE_CWD/agents/workflows/spec-template.md`.
   - Fill all 12 sections with implementation-specific detail.
   - Include file ownership map, interface contracts, and acceptance criteria.
   - See `$PAPERCLIP_WORKSPACE_CWD/agents/workflows/sample-spec.md` for a complete example.
5. `PUT /api/issues/{id}/documents/spec` with the generated spec:
   - `format: "markdown"`
   - `title: "Technical Specification"`
   - `body: <spec content>`
6. Post a **detailed comment** summarizing the spec:
   - Scope: what this spec covers and what it deliberately excludes
   - Key technical decisions and trade-offs made
   - Critical files that will be modified
   - Any open questions or assumptions that need validation
   - If an external ticket exists, reference it: "Requirements sourced from [external ticket](<url>)"
7. Continue to Phase B in the same heartbeat if budget allows.

### Phase B — Generate Plan

**Condition**: Has `spec` document, no `implementation-plan` document.

1. `GET /api/issues/{id}/documents/spec` — read the full spec.
2. Generate a TDD implementation plan:
   - Read the format at `$PAPERCLIP_WORKSPACE_CWD/agents/workflows/task-manifest-format.md`.
   - Organize into waves for parallel execution.
   - Ensure exclusive file ownership per task.
   - Validate: every file in the spec's ownership map appears in exactly one task, all dependencies point to earlier waves, acceptance criteria are testable.
3. `PUT /api/issues/{id}/documents/implementation-plan` with the generated plan:
   - `format: "markdown"`
   - `title: "Implementation Plan"`
   - `body: <plan content>`
4. Post a **detailed comment** summarizing the implementation plan:
   - Number of waves and total task count
   - Task breakdown by wave: title, assigned files, complexity estimate
   - Dependencies between waves
   - Estimated scope (files touched, tests to write)
   - TDD approach: which tests come first, integration test strategy
5. Continue to Phase C in the same heartbeat.

### Phase C — Request Approval (MANDATORY GATE)

**Condition**: Has both `spec` and `implementation-plan` documents, no linked approval.

**This is a hard stop.** You must not create subtasks or begin any execution without explicit human approval. The approval exists so the human can review the spec and plan, suggest changes, or approve the approach.

Check for existing approvals first: `GET /api/companies/{companyId}/approvals?issueId={id}`. If one already exists and is pending, skip to exit.

1. `POST /api/companies/{companyId}/approvals`:
   ```json
   {
     "type": "approve_spec",
     "requestedByAgentId": "<your-agent-id>",
     "payload": {
       "specKey": "spec",
       "planKey": "implementation-plan",
       "summary": "<2-3 sentence summary of what was spec'd>"
     },
     "issueIds": ["<current-issue-id>"]
   }
   ```
2. `POST /api/issues/{id}/approvals/{approvalId}/link` — link the approval to the issue.
3. `PATCH /api/issues/{id}` — set status to `in_review`.
4. Post comment summarizing what is ready for review:
   - "Spec and implementation plan are ready for your review."
   - Link to both documents on the issue
   - Highlight any decisions that need human judgement
   - If `externalTicketUrl` is set, include: "External ticket: [link](<url>)"
   - "Please approve to proceed with subtask creation, or request revisions with feedback."
5. **Exit heartbeat.** You will be woken when the approval is resolved.

**On revision request**: When woken with `PAPERCLIP_APPROVAL_STATUS=revision_requested`:
- Read all approval comments for specific feedback
- Revise the spec and/or plan documents based on the feedback
- Post a comment explaining what was changed and why
- Resubmit for approval (return to Phase C)

### Phase D — Create Subtasks

**Condition**: Woken by approval callback (`PAPERCLIP_APPROVAL_ID` set, status `approved`), or approval exists and is approved but no subtasks yet.

1. `GET /api/issues/{id}/documents/implementation-plan` — read the plan.
2. Parse the plan's task sections into a structured list. Each task should have:
   - Title
   - Description with acceptance criteria
   - Wave number (for ordering)
3. `GET /api/companies/{companyId}/agents` — get available agents (filter by status `active` or `idle`). Consider all roles:
   - **Engineers** (`engineer` role): implementation, bug fixes, feature work
   - **QA Engineers** (`qa_engineer` role): test coverage, feature verification, test plans
   - **Regression Analysts** (`regression_analyst` role): regression investigation, bisect, regression testing
4. **For each subtask, determine the right workflow settings:**

   **Conveying workflow intent** — use a clear subtask title that signals the nature of the work to the engineer. The engineer uses keyword heuristics on the title/description to select the appropriate workflow:

   | Subtask nature | Title pattern (triggers heuristic) | Assign to |
   |---------------|-----------------------------------|-----------|
   | Bug fix, error investigation | "Debug: ..." or include "bug" in description | Engineer |
   | New feature touching 3+ files | Descriptive feature title (defaults to `orchestrate`) | Engineer |
   | Small, localized change (1-2 files) | Focused title (engineer decides `tdd` vs `orchestrate`) | Engineer |
   | Architecture/design exploration | "Design: ..." or include "RFC"/"brainstorm" | Engineer |
   | Sentry error with a known issue ID | Include Sentry issue ID in title/description | Engineer |
   | Jira ticket reference | Include Jira ticket ID (PROJ-123) in title/description | Engineer |
   | Code review of an existing PR | "Review PR #..." | Engineer |
   | Responding to PR feedback | "Address review feedback on PR #..." | Engineer |
   | Tech spec writing | "Spec: ..." | Engineer |
   | Shipping/merging a completed branch | "Finish: ..." or "Ship: ..." | Engineer |
   | Feature verification against acceptance criteria | "QA: verify ..." or "Validate: ..." | QA Engineer |
   | Test coverage for a module or feature | "QA: add test coverage for ..." | QA Engineer |
   | Test plan creation | "QA: create test plan for ..." | QA Engineer |
   | Regression investigation | "Regression: ... used to work" or include "regression" | Regression Analyst |
   | Regression test coverage | "Regression: add regression tests for ..." | Regression Analyst |

   **Setting modifiers:**
   - `useTeam`: set to `true` for complex subtasks that benefit from multi-agent collaboration (e.g., large features, cross-cutting concerns). Default `false` for focused tasks.
   - `createPr`: set to `true` when the subtask should produce a PR on completion. Typically `true` for most implementation work; `false` for investigation-only tasks.

   Inherit `useTeam` and `createPr` from the parent issue as defaults, but override per-subtask when the plan indicates a different need.

5. **Assign engineers** — distribute subtasks across available engineers. Consider:
   - Round-robin or balanced assignment (no single engineer gets all wave-1 tasks)
   - If the plan specifies an engineer by name/role, respect that
   - Prefer assigning related subtasks (same module/area) to the same engineer for context continuity

6. For each task, `POST /api/companies/{companyId}/issues`:
   ```json
   {
     "parentId": "<current-issue-id>",
     "projectId": "<inherited-from-parent>",
     "goalId": "<inherited-from-parent>",
     "title": "<task-title>",
     "description": "<task-description-with-acceptance-criteria>",
     "status": "todo",
     "priority": "<inherited-from-parent>",
     "assigneeAgentId": "<engineer-id>",
     "useTeam": false,
     "createPr": true,
     "externalTicketUrl": "<inherited-from-parent-if-set>"
   }
   ```
   - Wave 1 tasks get status `todo`, later waves get `backlog`.
   - Propagate `externalTicketUrl` from the parent issue so engineers have the external context link.
7. Post a **detailed comment** listing all created subtasks:
   - Table format: wave | identifier | title | assigned engineer | workflow intent
   - Total task count and wave count
   - Which engineers received which assignments
   - Any notable decisions about task decomposition or assignment
8. `PATCH /api/issues/{id}` — set status to `in_progress` (monitoring mode).

### Phase E — Monitor Progress

**Condition**: Subtasks exist (issue has children).

1. `GET /api/companies/{companyId}/issues?parentId={id}` — list subtasks.
2. Check status of each subtask:
   - **All done** → set own status to `done`, post summary comment.
   - **Current wave complete** → promote next wave from `backlog` to `todo`.
   - **Any blocked** → investigate by reading the blocked subtask's comments. If actionable, post guidance. If external blocker, escalate with a comment.
   - **Any failed/cancelled** → assess if the failure is recoverable. If so, create a replacement subtask. If not, post a comment and set own status to `blocked`.

### Phase E.1 — Create Review Tasks

**Condition**: A subtask has status `in_review` and has no active review children (no children with titles starting with "Review:").

When listing subtasks, check for `in_review` status:

1. For each child in `in_review`: `GET /api/companies/{companyId}/issues?parentId={child.id}` — fetch its children.
2. If no review children exist (no children whose titles start with "Review:"), create two review subtasks:
   - `POST /api/companies/{companyId}/issues`:
     ```json
     {
       "parentId": "<in-review-subtask-id>",
       "projectId": "<inherited>",
       "title": "Review: QA — <subtask-title>",
       "description": "Code review task: verify acceptance criteria, test coverage, code quality, and security for the parent subtask.",
       "status": "todo",
       "priority": "<inherited>",
       "assigneeAgentId": "<qa-engineer-agent-id>"
     }
     ```
   - `POST /api/companies/{companyId}/issues`:
     ```json
     {
       "parentId": "<in-review-subtask-id>",
       "projectId": "<inherited>",
       "title": "Review: Regression — <subtask-title>",
       "description": "Regression review task: check for regression risks, run the test suite, and analyze for regression-prone patterns in the parent subtask.",
       "status": "todo",
       "priority": "<inherited>",
       "assigneeAgentId": "<regression-analyst-agent-id>"
     }
     ```
3. Post a comment on the original subtask: "Code review initiated. QA and Regression review tasks created."
4. If review children already exist and are all `done`, and the subtask is back in `in_review` (re-review round), create fresh review tasks.

### Phase E.2 — Handle Review Outcomes

**Condition**: Woken with `PAPERCLIP_APPROVAL_ID` and approval type `approve_code_review`.

Read the approval to determine the outcome:

1. `GET /api/approvals/{approvalId}` — read approval status and payload.
2. `GET /api/approvals/{approvalId}/issues` — get linked issues to find the review task and original subtask.
3. Read the approval payload for `reviewType` ("qa" or "regression") and `originalSubtaskId`.

**If approved** (human confirms findings ARE real problems):
1. Read the review task's comments for specific findings.
2. Post each finding as a comment on the original subtask.
3. `PATCH /api/issues/{originalSubtaskId}` — set status to `in_progress`.
4. Post comment on original subtask: "Code review found issues. See comments above."
5. `PATCH /api/issues/{reviewTaskId}` — set review task status to `done`.

**If rejected** (human determines findings are NOT real problems):
1. `PATCH /api/issues/{reviewTaskId}` — set review task status to `done`.
2. Check if ALL review tasks for this subtask are resolved:
   - `GET /api/companies/{companyId}/issues?parentId={originalSubtaskId}` — list review children.
   - If all review children with "Review:" titles are `done` and none had confirmed findings → `PATCH /api/issues/{originalSubtaskId}` — set status to `done`.
   - If some are still pending → wait (do nothing with the original subtask).

## 6. Update Status and Communicate

- Update issue status and post a comment summarizing what was done.
- If blocked, set status to `blocked` with a comment explaining the blocker and who needs to act.
- Always include `X-Paperclip-Run-Id` header on mutating API calls.
- Use concise markdown: status line + bullets + links.

## 7. Fact Extraction

1. Check for new learnings from this heartbeat.
2. Extract durable facts to the relevant entity in `$AGENT_HOME/life/` (PARA).
3. Update `$AGENT_HOME/memory/YYYY-MM-DD.md` with timeline entries.
4. Patterns worth remembering: architectural decisions, subtask decomposition strategies, engineer capabilities, blockers encountered.

## 8. Exit

- Comment on any in_progress work before exiting.
- If no assignments and no valid mention-handoff, exit cleanly.

---

## Management Responsibilities

- **Decompose work**: Take ambiguous requirements and produce clear, testable specs.
- **Plan execution**: Create implementation plans with waves and dependencies.
- **Delegate effectively**: Assign subtasks to engineers with clear context and acceptance criteria.
- **Monitor progress**: Track subtask completion, unblock engineers, promote waves.
- **Quality gate**: Specs and plans must be approved by a human before execution begins.
- **Never write production code** -- that's what engineers are for.
- **Never look for unassigned work** -- only work on what is assigned to you.
- **Never cancel cross-team tasks** -- reassign to the relevant manager with a comment.

## Rules

- Always use the Paperclip skill for coordination.
- Always include `X-Paperclip-Run-Id` header on mutating API calls.
- Comment in concise markdown: status line + bullets + links.
- Self-assign via checkout only when explicitly @-mentioned.

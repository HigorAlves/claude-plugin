# Tools

## Paperclip API

Your primary coordination tool. Use the `paperclip` skill for all API interactions. Key endpoints:

| Action | Endpoint |
|--------|----------|
| My identity | `GET /api/agents/me` |
| My inbox | `GET /api/agents/me/inbox-lite` |
| Checkout task | `POST /api/issues/{issueId}/checkout` |
| Heartbeat context | `GET /api/issues/{issueId}/heartbeat-context` |
| Update task | `PATCH /api/issues/{issueId}` |
| Add comment | `POST /api/issues/{issueId}/comments` |
| Create subtask | `POST /api/companies/{companyId}/issues` |

Always include `X-Paperclip-Run-Id` header on mutating calls.

## Workflow Reference Documents

Engineering reference documents at `$PAPERCLIP_WORKSPACE_CWD/agents/workflows/`. Read these when executing the corresponding workflow.

| Document | Purpose |
|----------|---------|
| `agents/workflows/spec-template.md` | Template for generating technical specifications (12 sections) |
| `agents/workflows/task-manifest-format.md` | Format for decomposing specs into parallel task waves |
| `agents/workflows/sample-spec.md` | Complete example of a filled-in spec |
| `agents/workflows/tdd-anti-patterns.md` | Common testing mistakes and how to avoid them |
| `agents/workflows/root-cause-tracing.md` | Technique for tracing bugs backward to their source |
| `agents/workflows/defense-in-depth.md` | Multi-layer validation pattern for preventing bug recurrence |

### Team Composition References

When the `team` modifier is enabled, read the relevant team document for multi-agent coordination patterns:

| Document | When |
|----------|------|
| `agents/workflows/teams/debugging-team.md` | Debug workflow with team |
| `agents/workflows/teams/design-team.md` | Design workflow with team |
| `agents/workflows/teams/implementation-team.md` | Orchestrate workflow, execution phase with team |
| `agents/workflows/teams/spec-review-team.md` | Orchestrate workflow, spec phase with team |
| `agents/workflows/teams/decomposition-review-team.md` | Orchestrate workflow, planning phase with team |
| `agents/workflows/teams/sentry-team.md` | Sentry-fix workflow with team |
| `agents/workflows/teams/jira-bug-team.md` | Jira bug workflow with team |
| `agents/workflows/teams/jira-story-team.md` | Jira story workflow with team |

## Plugin Tools (when paperclip-plugin-compozy is installed)

The Compozy Paperclip plugin provides tracking tools that persist orchestration state:

| Tool | Purpose |
|------|---------|
| `compozy-orchestrate` | Track orchestration in Paperclip (creates entity + issue) |
| `compozy-status` | Query orchestration state from plugin entities |
| `compozy-resume` | Resume tracked orchestration |

These tools provide the Paperclip-side tracking. The actual development work is done by the workflows described above.

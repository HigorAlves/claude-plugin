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
| List subtasks | `GET /api/companies/{companyId}/issues?parentId={issueId}` |
| List agents | `GET /api/companies/{companyId}/agents` |

### Document API

| Action | Endpoint |
|--------|----------|
| Upsert document | `PUT /api/issues/{issueId}/documents/{key}` |
| Read document | `GET /api/issues/{issueId}/documents/{key}` |
| List documents | `GET /api/issues/{issueId}/documents` |

Document body format:
```json
{
  "format": "markdown",
  "title": "Document Title",
  "body": "# Markdown content...",
  "changeSummary": "Optional change description"
}
```

### Approval API

| Action | Endpoint |
|--------|----------|
| Create approval | `POST /api/companies/{companyId}/approvals` |
| Link to issue | `POST /api/issues/{issueId}/approvals/{approvalId}/link` |
| Read approval | `GET /api/companies/{companyId}/approvals/{approvalId}` |
| List approvals | `GET /api/companies/{companyId}/approvals` |

Approval creation body:
```json
{
  "type": "approve_spec",
  "requestedByAgentId": "<your-agent-id>",
  "payload": {
    "specKey": "spec",
    "planKey": "implementation-plan",
    "summary": "Brief summary of what was spec'd and planned"
  },
  "issueIds": ["<issue-id>"]
}
```

When the human approves, your heartbeat is triggered with `PAPERCLIP_APPROVAL_ID` and `PAPERCLIP_APPROVAL_STATUS=approved`.

Always include `X-Paperclip-Run-Id` header on mutating calls.

## Workflow Reference Documents

Engineering reference documents at `$PAPERCLIP_WORKSPACE_CWD/agents/workflows/`. Read these when generating specs and plans.

| Document | Purpose |
|----------|---------|
| `agents/workflows/spec-template.md` | Template for generating technical specifications (12 sections) |
| `agents/workflows/task-manifest-format.md` | Format for decomposing specs into parallel task waves |
| `agents/workflows/sample-spec.md` | Complete example of a filled-in spec |
| `agents/workflows/tdd-anti-patterns.md` | Common testing mistakes — use when reviewing subtask approaches |

## Plugin Tools (when paperclip-plugin-compozy is installed)

The Compozy Paperclip plugin provides tracking tools that persist orchestration state:

| Tool | Purpose |
|------|---------|
| `compozy-orchestrate` | Track orchestration in Paperclip |
| `compozy-status` | Query orchestration state from plugin entities |

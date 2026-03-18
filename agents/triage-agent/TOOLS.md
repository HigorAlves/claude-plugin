# Tools

## Paperclip API

Your primary coordination tool. Use the `paperclip` skill for all API interactions. Key endpoints:

| Action | Endpoint |
|--------|----------|
| My identity | `GET /api/agents/me` |
| My inbox | `GET /api/agents/me/inbox-lite` |
| Read issue | `GET /api/issues/{issueId}` |
| Update issue | `PATCH /api/issues/{issueId}` |
| Heartbeat context | `GET /api/issues/{issueId}/heartbeat-context` |
| Add comment | `POST /api/issues/{issueId}/comments` |
| Read document | `GET /api/issues/{issueId}/documents/{key}` |
| Write document | `PUT /api/issues/{issueId}/documents/{key}` |
| List agents | `GET /api/companies/{companyId}/agents` |
| Create approval | `POST /api/companies/{companyId}/approvals` |
| Link approval | `POST /api/issues/{issueId}/approvals/{approvalId}` |
| Read approval | `GET /api/approvals/{approvalId}` |
| List labels | `GET /api/companies/{companyId}/labels` |
| Create label | `POST /api/companies/{companyId}/labels` |
| Add label to issue | `POST /api/issues/{issueId}/labels` |

Always include `X-Paperclip-Run-Id` header on mutating calls.

**Important:** You do NOT have checkout permissions. Never call `POST /api/issues/{issueId}/checkout`. Triage agents evaluate issues without taking ownership.

## Workflow Reference Documents

Engineering reference documents at `$PAPERCLIP_WORKSPACE_CWD/agents/workflows/`. Relevant documents:

| Document | Purpose |
|----------|---------|
| `agents/workflows/spec-template.md` | Spec template -- understand what a well-specified issue looks like |

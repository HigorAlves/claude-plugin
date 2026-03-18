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
| Read document | `GET /api/issues/{issueId}/documents/{key}` |
| Write document | `PUT /api/issues/{issueId}/documents/{key}` |

Always include `X-Paperclip-Run-Id` header on mutating calls.

## Testing Tools

Use the project's test runner (typically `vitest` or `jest`) to execute tests:

| Action | Command |
|--------|---------|
| Run all tests | `pnpm test` |
| Run specific test file | `pnpm test -- path/to/test.ts` |
| Run tests with coverage | `pnpm test -- --coverage` |
| Typecheck | `pnpm typecheck` |

## Workflow Reference Documents

Engineering reference documents at `$PAPERCLIP_WORKSPACE_CWD/agents/workflows/`. Relevant documents:

| Document | Purpose |
|----------|---------|
| `agents/workflows/tdd-anti-patterns.md` | Common testing mistakes and how to avoid them |
| `agents/workflows/defense-in-depth.md` | Multi-layer validation pattern for preventing bug recurrence |
| `agents/workflows/spec-template.md` | Spec template — read the acceptance criteria section for test targets |

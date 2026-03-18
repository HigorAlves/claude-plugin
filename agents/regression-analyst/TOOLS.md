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
| Read document | `GET /api/issues/{issueId}/documents/{key}` |
| Write document | `PUT /api/issues/{issueId}/documents/{key}` |

Always include `X-Paperclip-Run-Id` header on mutating calls.

## Git Investigation Tools

Your primary analysis tools for tracing regressions:

| Action | Command |
|--------|---------|
| Bisect start | `git bisect start <bad-commit> <good-commit>` |
| Bisect with test | `git bisect run <test-script>` |
| Bisect reset | `git bisect reset` |
| Blame file | `git blame <file>` |
| Recent changes to file | `git log --oneline -20 -- <file>` |
| Diff between commits | `git diff <commit-a>..<commit-b> -- <file>` |
| Search commit messages | `git log --all --grep="<keyword>"` |
| Show commit details | `git show <commit>` |
| Find commits touching file | `git log --follow -- <file>` |

## Testing Tools

| Action | Command |
|--------|---------|
| Run all tests | `pnpm test` |
| Run specific test file | `pnpm test -- path/to/test.ts` |
| Run tests matching pattern | `pnpm test -- -t "pattern"` |
| Typecheck | `pnpm typecheck` |

## Workflow Reference Documents

Engineering reference documents at `$PAPERCLIP_WORKSPACE_CWD/agents/workflows/`:

| Document | Purpose |
|----------|---------|
| `agents/workflows/root-cause-tracing.md` | Technique for tracing bugs backward to their source |
| `agents/workflows/defense-in-depth.md` | Multi-layer validation pattern for preventing bug recurrence |
| `agents/workflows/tdd-anti-patterns.md` | Common testing mistakes — useful for analyzing why tests missed regressions |

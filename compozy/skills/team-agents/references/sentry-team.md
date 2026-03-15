# Sentry Investigation Team (sentry-fix --team)

Used during Phase 2 (Deep Sentry Analysis). Multiple agents investigate the Sentry issue from different angles simultaneously.

**Roles:**
1. **Sentry Data Analyst** — Gathers all Sentry data: stack traces, breadcrumbs, event distributions, tag breakdowns, traces, and Seer AI analysis
2. **Codebase Investigator** — Reads stack trace files in the local codebase, traces data flow through the call chain, checks `git blame`/`git log` for recent changes to affected files
3. **Impact Assessor** — Analyzes tag distributions (browser, OS, environment, release), finds related Sentry issues, estimates blast radius and user impact

**Flow:**
```
Phase 2 (parallel investigation):
  1. Dispatch all 3 agents simultaneously with the Sentry issue ID and initial details
  2. Sentry Data Analyst (tools: mcp__plugin_sentry_sentry__*):
     "Gather ALL available Sentry data for this issue:
      - Full stack trace with source context
      - Breadcrumbs leading to the error
      - Event distribution across time, environment, release
      - Tag value distributions (browser, OS, transaction)
      - Trace spans if available
      - Seer AI analysis
      Return: structured analysis report."
  3. Codebase Investigator (tools: Read, Glob, Grep, Bash(git *)):
     "Read the files referenced in this stack trace: [stack trace files].
      - Trace the data flow backward from the crash point
      - Check git log and git blame for recent changes to these files
      - Find similar working code paths in the codebase
      Return: local code context and suspicious recent changes."
  4. Impact Assessor (tools: mcp__plugin_sentry_sentry__*):
     "Analyze the impact scope of this issue:
      - Get tag distributions (browser, OS, environment, release, transaction)
      - Search for related issues with similar error types
      - Determine if this is a regression (started with a specific release)
      Return: impact report with blast radius estimate."

Phase 2 (synthesis):
  5. Read all 3 reports
  6. Synthesize findings — where do the investigations converge?
  7. Cross-reference: Sentry data + local code + impact scope = root cause hypothesis
  8. Proceed to Phase 3 with consolidated evidence
```

**Why this helps:**
- Sentry data + local code + impact analysis cover all investigative angles simultaneously
- Convergence = high confidence (if data analyst and codebase investigator point to same cause, it's likely right)
- Impact assessor prevents tunnel vision — the fix must address ALL affected environments, not just the first one found

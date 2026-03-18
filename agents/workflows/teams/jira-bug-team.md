# Jira Bug Investigation Team (jira --team, Phase 2, `$FLOW = bug`)

Used during Phase 2 (Deep Ticket Analysis) when the ticket is a Bug/Defect. Multiple agents investigate the Jira bug from different angles simultaneously.

**Roles:**
1. **Ticket Context Analyst** — Gathers all Jira data: description, acceptance criteria, linked issues, subtasks, comments, sprint/epic context
2. **Codebase Investigator** — Reads files referenced in the ticket, traces data flow, checks `git blame`/`git log` for recent changes to affected areas
3. **Impact Assessor** — Analyzes related bugs in the same sprint/epic, examines linked issues, estimates scope of the fix

**Flow:**
```
Phase 2 (parallel investigation):
  1. Dispatch all 3 agents simultaneously with the Jira ticket key and initial details
  2. Ticket Context Analyst (tools: mcp__jira_*):
     "Gather ALL available Jira data for this bug ticket:
      - Full description with reproduction steps
      - Acceptance criteria / definition of done
      - Linked issues (especially 'blocks' and 'is blocked by')
      - Subtasks and their status
      - Comments with decisions and clarifications
      - Sprint goal and epic context
      Return: structured ticket analysis report."
  3. Codebase Investigator (tools: Read, Glob, Grep, Bash(git *)):
     "Investigate the codebase based on this bug ticket: [description summary].
      - Read files likely related to the reported behavior
      - Trace data flow through the affected code paths
      - Check git log and git blame for recent changes
      - Find similar working code paths
      Return: local code context and suspicious recent changes."
  4. Impact Assessor (tools: mcp__jira_*):
     "Analyze the impact scope of this bug:
      - Search for related bugs in the same sprint/epic/component
      - Check linked issues for dependencies and duplicates
      - Estimate fix scope (single file vs multi-component)
      Return: impact report with related tickets and scope estimate."

Phase 2 (synthesis):
  5. Read all 3 reports
  6. Synthesize findings — where do the investigations converge?
  7. Cross-reference: ticket context + local code + impact = root cause hypothesis
  8. Proceed to Phase 3 with consolidated evidence
```

**Why this helps:**
- Ticket data + local code + impact analysis cover all investigative angles simultaneously
- Convergence = high confidence (if analyst and investigator point to same cause, it's likely right)
- Impact assessor prevents tunnel vision — the fix must address ALL related issues, not just the immediate ticket

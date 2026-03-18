# Jira Story Planning Team (jira --team, Phase 2, `$FLOW = story`)

Used during Phase 2 (Deep Ticket Analysis) when the ticket is a Story/Task/Improvement. Multiple agents analyze the ticket and codebase to prepare for spec generation.

**Roles:**
1. **Ticket Context Analyst** — Gathers all Jira data: description, acceptance criteria, linked issues, subtasks, comments, sprint/epic context
2. **Codebase Explorer** — Explores architecture, similar features, existing patterns relevant to the story
3. **Requirements Analyst** — Extracts structured requirements from the ticket and linked issues, identifies gaps and ambiguities

**Flow:**
```
Phase 2 (parallel investigation):
  1. Dispatch all 3 agents simultaneously with the Jira ticket key and initial details
  2. Ticket Context Analyst (tools: mcp__jira_*):
     "Gather ALL available Jira data for this story/task:
      - Full description with user value statement
      - Acceptance criteria / definition of done
      - Linked issues (especially related stories and epics)
      - Subtasks and their status
      - Comments with decisions and clarifications
      - Sprint goal and epic context
      Return: structured ticket analysis report."
  3. Codebase Explorer (tools: Read, Glob, Grep):
     "Explore the codebase for context relevant to this story: [description summary].
      - Find similar features already implemented
      - Identify architectural patterns to follow
      - Map affected modules and components
      - Note conventions for testing, naming, structure
      Return: codebase context with patterns and conventions."
  4. Requirements Analyst (tools: mcp__jira_*, Read):
     "Extract structured requirements from this ticket and its linked issues:
      - Convert acceptance criteria into testable requirements
      - Identify implicit requirements from the description
      - Check linked issues for additional requirements or constraints
      - Flag gaps, ambiguities, or conflicting requirements
      Return: structured requirements list with gaps flagged."

Phase 2 (synthesis):
  5. Read all 3 reports
  6. Synthesize findings — requirements + codebase context + ticket data
  7. Produce consolidated input for spec generation
  8. Proceed to Phase 3 with full context
```

**Why this helps:**
- Requirements analyst catches implicit requirements and gaps before spec generation
- Codebase explorer ensures the spec follows existing patterns
- Ticket analyst provides full stakeholder context (comments, linked issues, epic goals)

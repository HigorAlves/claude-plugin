# Debugging Team (debug --team)

Used during Phase 1 (Root Cause Investigation). Multiple agents investigate simultaneously from different angles.

**Roles:**
1. **Data Flow Tracer** — Traces the bug backward through call chains (root-cause-tracing technique)
2. **Change Analyst** — Examines recent git changes, diffs, and commit history for likely culprits
3. **Pattern Scout** — Finds similar working code in the codebase and identifies what's different

**Flow:**
```
Phase 1 (parallel investigation):
  1. Dispatch all 3 agents simultaneously with the bug description
  2. Data Flow Tracer: "Trace the error backward through the call chain.
     Where does the bad value originate? Follow it up to the source.
     Return: the trace chain and suspected root cause."
  3. Change Analyst: "Check git log, git diff, recent commits.
     What changed that could cause this? Check dependencies, config.
     Return: list of suspicious changes with file paths and reasoning."
  4. Pattern Scout: "Find similar working code in this codebase.
     What's different between working and broken? Compare patterns.
     Return: differences found and what the working version does right."

Phase 1 (synthesis):
  5. Read all 3 reports
  6. Synthesize findings — where do the investigations converge?
  7. Present consolidated root cause hypothesis to user
  8. Proceed to Phase 2-4 as normal
```

**Why this helps:**
- Three perspectives on the same bug surface different evidence
- Convergence = high confidence (if all 3 point to same cause, it's likely right)
- Divergence = the bug is more complex than it appears (investigate further)

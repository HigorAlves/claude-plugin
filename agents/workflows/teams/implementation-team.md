# Implementation Team (orchestrate --team, Phase 5)

Used during Phase 5 (Task Execution). Each wave dispatches a team instead of solo implementers.

**Roles:**
1. **Implementer** — Writes the code following TDD discipline
2. **Reviewer** — Reviews each implementer's output before the wave completes
3. **Architect** — Monitors cross-cutting concerns across waves (shared types, API consistency, naming)

**Flow:**
```
Wave N:
  1. Dispatch implementer agents (parallel, one per task — same as solo mode)
  2. Collect results
  3. Dispatch reviewer agent with ALL wave outputs:
     "Review these implementations for:
      - Correctness against spec
      - Cross-task consistency (naming, patterns, interfaces)
      - Test quality (real behavior tested, not mocks)
      - Edge cases missed
      Report issues by severity."
  4. If critical issues: re-dispatch implementers with review feedback
  5. If clean: proceed to next wave

After all waves:
  6. Dispatch architect agent with full implementation:
     "Review the complete implementation for:
      - Architectural coherence across all waves
      - Interface consistency between components
      - Missing integration points
      - Patterns that diverged from codebase conventions
      Report structural issues."
  7. Fix any architectural issues before Phase 6
```

**Why this helps:**
- Reviewer catches bugs implementers miss (fresh eyes on each wave)
- Architect catches cross-wave drift (naming divergence, inconsistent patterns)
- Issues caught per-wave, not at the end (cheaper to fix early)

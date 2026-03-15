# Design Team (design --team)

Used during approach exploration. Multiple agents propose designs independently.

**Roles:**
1. **Approach Explorer A** — Designs solution favoring simplicity and minimal changes
2. **Approach Explorer B** — Designs solution favoring extensibility and future-proofing
3. **Devil's Advocate** — Reviews both approaches for weaknesses, edge cases, and overlooked requirements

**Flow:**
```
  1. After clarifying questions are answered:
     Dispatch Explorer A and Explorer B with same context
  2. Collect both approaches
  3. Dispatch Devil's Advocate with both approaches:
     "Review both designs. For each:
      - What breaks under load/scale?
      - What edge cases are missed?
      - What's the maintenance burden in 6 months?
      - Which is easier to test?
      Report strengths and weaknesses of each."
  4. Present all findings to user with recommendation
```

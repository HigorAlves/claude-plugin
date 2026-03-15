# Spec Review Team (orchestrate --team, Phase 3)

Used during Phase 3 (Tech Spec Generation). After the spec-generator produces the spec, two reviewers validate it before the user sees it.

**Roles:**
1. **Spec Critic** — Reviews for gaps, weaknesses, and over-engineering
2. **Testability Reviewer** — Ensures every requirement is verifiable

**Flow:**
```
Phase 3 (after spec generation):
  1. Dispatch both reviewers in parallel with the generated spec + codebase context
  2. Spec Critic: "Review this tech spec for:
      - Missing edge cases or error scenarios
      - Unclear or ambiguous interfaces
      - Over-engineering (YAGNI violations)
      - Inconsistencies with existing codebase patterns
      - Missing non-functional requirements (performance, security)
      Report issues by severity."
  3. Testability Reviewer: "Review this tech spec for:
      - Acceptance criteria that can't be tested (vague, subjective)
      - Interfaces that can't be mocked or stubbed
      - Missing test scenarios for each component
      - Dependencies that make testing hard
      Report untestable items and suggest how to make them testable."
  4. Synthesize findings
  5. If critical issues: re-run spec-generator with feedback, then re-review
  6. If clean: present spec to user for approval
```

**Why this helps:**
- Catches spec gaps BEFORE implementation (10x cheaper than fixing code)
- Testability review prevents "we can't test this" surprises in Phase 5
- Two perspectives: one on design quality, one on verifiability

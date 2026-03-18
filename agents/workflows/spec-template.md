# Tech Spec Template

Use this template when generating technical specifications. Fill in all sections. Remove placeholder text. If a section is genuinely not applicable, write "N/A — [reason]" rather than omitting it.

---

## 1. Header

| Field | Value |
|-------|-------|
| **Title** | [Feature/change name] |
| **Status** | Draft / Approved / Implemented |
| **Author** | [Name or "Auto-generated"] |
| **Date** | [YYYY-MM-DD] |
| **PRD Source** | [Link, issue number, or "inline"] |
| **Version** | 1.0 |

---

## 2. Overview

[2-3 paragraphs explaining what is being built and why. Include:]
- The user problem or business need being addressed
- The high-level approach and key design choices
- How this fits into the existing system

---

## 3. Requirements Summary

### Functional Requirements

| ID | Requirement | Priority | Source |
|----|-------------|----------|--------|
| FR-1 | [Specific, testable requirement] | Must | [PRD section/line] |
| FR-2 | [Specific, testable requirement] | Should | [PRD section/line] |
| FR-3 | [Specific, testable requirement] | Could | [PRD section/line] |

### Non-Functional Requirements

| ID | Requirement | Priority | Source |
|----|-------------|----------|--------|
| NFR-1 | [Performance, security, scalability, etc.] | Must | [PRD section/line] |
| NFR-2 | [Observability, maintainability, etc.] | Should | [PRD section/line] |

---

## 4. Architecture

### Design Overview

[Describe the architectural approach. Include:]
- Component relationships and data flow
- Integration points with existing systems
- Key abstractions and patterns used

### Component Diagram

```
[ASCII diagram showing component relationships]

┌──────────┐     ┌──────────┐     ┌──────────┐
│ Component│────▶│ Component│────▶│ Component│
│    A     │     │    B     │     │    C     │
└──────────┘     └──────────┘     └──────────┘
       │                                ▲
       └────────────────────────────────┘
```

### Architecture Decisions

| Decision | Choice | Alternatives Considered | Rationale |
|----------|--------|------------------------|-----------|
| [What was decided] | [What was chosen] | [What else was considered] | [Why this choice] |

---

## 5. Component Specifications

### Component: [Name]

**Responsibility**: [One-sentence description of what this component does]

**Location**: `path/to/component/`

**Public API**:

```
[Function signatures, class interfaces, or endpoint definitions]

function doSomething(input: InputType): Promise<OutputType>
```

**Internal Structure**:
- [Key internal functions/methods and their roles]
- [State management approach]
- [Caching strategy if applicable]

**Dependencies**:
- `path/to/dependency` — [What it provides]
- `external-package` — [What it's used for]

**Error Handling**:
- [Input validation]: [How handled]
- [External service failure]: [How handled]
- [Unexpected state]: [How handled]

[Repeat for each component]

---

## 6. Data Models

### [Model Name]

```
[Type definition, schema, or table structure]

type User = {
  id: string;          // UUID v4
  email: string;       // Unique, lowercase
  createdAt: Date;     // Auto-set on creation
  role: "admin" | "member";  // Default: "member"
}
```

**Constraints**:
- [Uniqueness constraints]
- [Validation rules]
- [Default values]

**Indexes**:
- [Index definitions if database model]

[Repeat for each model]

---

## 7. File Ownership Map

Each file is assigned to exactly one task. No file appears in more than one task.

| File Path | Action | Task ID | Wave |
|-----------|--------|---------|------|
| `src/types/new-types.ts` | Create | T-1 | 1 |
| `src/services/feature.ts` | Create | T-2 | 2 |
| `src/routes/feature.ts` | Create | T-3 | 2 |
| `src/services/existing.ts` | Modify | T-4 | 2 |
| `src/tests/feature.test.ts` | Create | T-5 | 3 |

---

## 8. API/Interface Contracts

### [Interface Name]

**Between**: [Component A] → [Component B]

**Contract**:

```
[Request/response format, function signature, or event payload]

// Request
POST /api/resource
{
  "name": string,       // Required, 1-100 chars
  "type": "a" | "b"     // Required
}

// Response 200
{
  "id": string,
  "name": string,
  "type": "a" | "b",
  "createdAt": string    // ISO 8601
}

// Response 400
{
  "error": "validation_error",
  "details": [{ "field": string, "message": string }]
}
```

[Repeat for each interface]

---

## 9. Error Handling Strategy

### Error Categories

| Category | HTTP Status | Response Format | Logging | Recovery |
|----------|-------------|-----------------|---------|----------|
| Validation | 400 | `{ error, details[] }` | Warn | Return to client |
| Auth | 401/403 | `{ error }` | Info | Return to client |
| Not Found | 404 | `{ error }` | Debug | Return to client |
| Internal | 500 | `{ error: "internal_error" }` | Error + stack | Alert on threshold |

### Error Propagation

[Describe how errors flow through the system: which layer catches, which rethrows, which logs]

---

## 10. Acceptance Criteria

| # | Criterion | Requirement | Verification |
|---|-----------|-------------|-------------|
| AC-1 | [Specific, testable condition] | FR-1 | [How to verify: unit test, integration test, manual] |
| AC-2 | [Specific, testable condition] | FR-2 | [How to verify] |
| AC-3 | [Specific, testable condition] | NFR-1 | [How to verify] |

---

## 11. Out of Scope

- [Feature/behavior explicitly NOT included in this spec]
- [Related improvement deferred to future work]
- [Edge case acknowledged but not addressed]

---

## 12. Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| [What could go wrong] | Low/Med/High | [Consequence] | [Prevention/response strategy] |

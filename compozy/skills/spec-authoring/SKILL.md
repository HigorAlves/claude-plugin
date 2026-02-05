---
name: Spec Authoring
description: This skill should be used when generating technical specifications from product requirements, writing tech specs, creating task manifests for parallel execution, decomposing features into implementation tasks, structuring PRD analysis, authoring architecture documents, or when the user asks to "write a spec", "create a tech spec", "generate a specification", "break down a feature", "decompose into tasks", or needs guidance on spec structure, task wave planning, file ownership maps, or acceptance criteria formatting.
version: 1.0.0
---

# Spec Authoring for Development Orchestration

## Overview

Technical specifications bridge the gap between product requirements and implementation. A well-written spec enables parallel execution by multiple agents, each working on independent tasks without conflicts. This skill provides the knowledge and templates needed to author specs that are precise enough for automated implementation.

**Key concepts:**
- Specs must be unambiguous — an agent reading the spec should never need to ask clarifying questions
- File ownership maps prevent merge conflicts during parallel execution
- Task waves define execution order based on dependencies
- Acceptance criteria must be testable, not subjective
- Component specifications must include interface contracts for cross-component integration

## Spec Quality Principles

### 1. Completeness Over Brevity

Every section of the spec template exists for a reason. Skipping sections creates ambiguity that surfaces as bugs during implementation. When in doubt, be explicit.

### 2. Implementation-Ready Detail

A spec is ready when someone unfamiliar with the codebase can implement it by following the spec alone. This means:
- Exact file paths (not "somewhere in the auth module")
- Function signatures with parameter types and return types
- Error handling behavior for each failure mode
- Import statements and dependency references

### 3. Parallel-Safe Design

The spec must enable multiple agents to work simultaneously without conflicts:
- Each file is owned by exactly one task
- Shared interfaces are defined in the spec, not discovered during implementation
- Integration points are explicitly documented with expected types/contracts
- New shared utilities are created in dedicated tasks that run in earlier waves

### 4. Testable Acceptance Criteria

Every requirement maps to at least one acceptance criterion. Criteria use concrete, verifiable language:
- "Response time under 200ms for 95th percentile" (testable)
- "System should be fast" (not testable)
- "Returns 404 with body `{\"error\": \"not_found\"}` when user ID doesn't exist" (testable)
- "Handles missing users gracefully" (not testable)

## Spec Sections Guide

### Header
Metadata: title, author, date, status (draft/approved/implemented), PRD source reference, and version.

### Overview
2-3 paragraphs explaining what is being built and why. Written for someone with no context. Include the user problem being solved and the high-level approach.

### Requirements Summary
Two tables — Functional Requirements (FR) and Non-Functional Requirements (NFR). Each row has an ID (FR-1, NFR-1), description, priority (must/should/could), and source (which part of the PRD).

### Architecture
Design decisions with rationale. Component diagram showing how pieces interact. ADR-style entries for significant choices: "We chose X over Y because Z."

### Component Specifications
Per-component detail: responsibility, public API, internal structure, dependencies. This is the largest section and should be exhaustive.

### Data Models
Schema definitions, type definitions, database migrations. Include field types, constraints, defaults, and indexes.

### File Ownership Map
Critical for parallelization. A table mapping every file to be created or modified to exactly one task. No file appears in more than one task. Shared code goes in earlier waves.

### API/Interface Contracts
Request/response schemas, function signatures, event payloads. These contracts are the "handshake" between components built by different tasks.

### Error Handling Strategy
How each error type is handled: validation errors, network failures, auth failures, unexpected exceptions. Include error response formats and logging requirements.

### Acceptance Criteria
Numbered list of testable conditions that must pass for the spec to be considered implemented. Map back to requirements IDs.

### Out of Scope
Explicitly list what this spec does NOT cover. Prevents scope creep during implementation and review.

### Risks and Mitigations
Table of risks with likelihood, impact, and mitigation strategy. Include both technical risks (performance, compatibility) and process risks (timeline, dependencies).

## Task Manifest Principles

### Wave Structure

Tasks are grouped into waves. All tasks in a wave can execute in parallel. Waves execute sequentially — wave N+1 starts only after all tasks in wave N complete.

**Wave ordering rules:**
- Wave 1: Shared types, interfaces, utilities, configuration
- Wave 2-N: Feature implementation tasks (parallel within each wave)
- Final wave: Integration glue, cleanup, documentation

### File Exclusivity

The most important constraint for parallel execution: **each file is owned by exactly one task**. If two tasks need to modify the same file, either:
1. Split the file into separate files owned by different tasks
2. Move the shared modification to an earlier wave
3. Combine the tasks into one

### Task Granularity

Tasks should be large enough to be meaningful (not "add one import") but small enough to be independent (not "implement the entire feature"). A good task typically:
- Creates or modifies 2-5 files
- Takes 5-15 minutes of focused coding
- Has a clear, testable outcome
- Can be described in 3-5 sentences

## Common Pitfalls

1. **Vague component specs**: "The auth module handles authentication" tells an implementer nothing. Specify endpoints, middleware, token formats, storage, and error responses.

2. **Missing interface contracts**: Two components that need to communicate must have their interface defined in the spec. Otherwise, each task's agent will guess differently.

3. **Circular dependencies between tasks**: If Task A needs output from Task B and Task B needs output from Task A, they can't run in parallel. Restructure to break the cycle.

4. **Forgetting existing code**: Specs for modifications must reference the current state of the code. Include file paths and relevant function names.

5. **Over-decomposition**: 20 tiny tasks with complex dependencies are harder to manage than 6 substantial tasks with simple wave ordering.

---

For templates and examples, see files in `references/` and `examples/` directories.

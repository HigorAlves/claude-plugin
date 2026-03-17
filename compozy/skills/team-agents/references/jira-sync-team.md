# Jira Sync Validation Team (orchestrate --team --jira-sync, Phase 4.5)

Used during Phase 4.5 (Jira Sync) when both `--team` and `--jira-sync` flags are set. After the Ticket Creator creates all subtasks, two validation agents run in parallel to verify correctness.

**Roles:**
1. **Ticket Creator** (sonnet) — Creates the parent Story (if needed) and all subtasks in Jira from the task manifest. Writes the jira-sync.json mapping file.
2. **Mapping Validator** (haiku) — Cross-checks the task manifest against created Jira tickets. Verifies no tasks are missing, parent links are correct, labels match wave numbers, and descriptions contain acceptance criteria.
3. **Dependency Linker** (haiku) — Creates "blocks/is-blocked-by" issue links between subtasks based on task dependencies in the manifest. Verifies all dependency relationships from the manifest are represented as Jira issue links.

**Flow:**
```
Phase 4.5 (sequential → parallel):
  1. Dispatch Ticket Creator (sonnet, subagent_type: compozy:jira-sync, mode: create):
     "Create Jira tickets from the task manifest:
      - Parent ticket: [project key or existing ticket]
      - Task manifest: [path]
      - Tech spec title: [title]
      - $COMPOZY_DIR: [path]
      Create parent Story (if project key), create all subtasks,
      write jira-sync.json mapping file.
      Return: summary of created tickets."

  2. After Creator completes, dispatch Validator and Linker in parallel:

     Mapping Validator (haiku, tools: Read, Glob, Grep, mcp__plugin_atlassian_atlassian__*):
     "Validate the Jira sync mapping:
      - Read task manifest at [path]
      - Read jira-sync.json at [path]
      - For each task in the manifest, verify a matching Jira subtask exists
      - Verify parent ticket key matches
      - Verify each subtask has: correct summary format [T-{ID}], wave-N label,
        compozy label, acceptance criteria in description
      - Flag: missing tasks, wrong parent links, missing labels, empty descriptions
      Return: validation report with pass/fail per check."

     Dependency Linker (haiku, tools: Read, Glob, Grep, mcp__plugin_atlassian_atlassian__*):
     "Verify and create dependency links:
      - Read task manifest at [path] — extract all task dependencies
      - Read jira-sync.json at [path] — get Jira key mappings
      - For each dependency (e.g., T-3 depends on T-1):
        check if a 'blocks/is-blocked-by' link exists between their Jira subtasks
      - Create any missing links
      - Flag any dependency in the manifest that couldn't be linked
      Return: dependency link report with created/verified/failed counts."

Phase 4.5 (synthesis):
  3. Read both validation reports
  4. If Validator found issues: fix them (update subtask descriptions, add missing labels)
  5. If Linker found unresolvable issues: log warnings
  6. Produce consolidated Jira sync summary for the user
```

**Why this helps:**
- Ticket Creator focuses on throughput — creating all tickets quickly
- Mapping Validator catches structural issues (missing tasks, wrong labels) that Creator might miss when processing many tasks
- Dependency Linker handles the cross-referencing complexity of issue links separately, reducing Creator's scope and error surface

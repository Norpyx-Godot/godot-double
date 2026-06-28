# AGENTS.md

## Workplans

### What this is
This repo uses **workplans** (Markdown files) to plan and execute changes. A workplan is the source of truth for:
- what we’re building,
- why we’re building it,
- how we’ll build it (steps),
- how we’ll verify it (tests/docs/coverage),
- what decisions we made along the way.

### The rule
**No code changes without a workplan in `ready` (or already `in_progress`).**

### Roles (same agent, different hats)
#### Planning Mode (PO/BA/PM)
- Clarify goal, scope, and success criteria.
- Review the relevant code (`src/` and related areas) and write down key context.
- Produce a small, linear step plan with verification per step.
- Track unknowns as Open Questions, and record Decisions when choices are made.

A workplan is `ready` when:
- scope/non-goals are clear,
- acceptance criteria are testable,
- steps are atomic and have verification,
- docs + coverage plan is defined.

#### Execution Mode (Engineer)
- Execute **one step at a time** from the workplan.
- If a new decision/concern appears: update the workplan first.
- Don’t push through ambiguity—convert it into an Open Question or Decision.

### Stop conditions (pause execution, refine the workplan)
Stop and update the workplan if:
- requirements are unclear or conflicting,
- new dependencies change scope,
- you find a convention conflict,
- verification fails beyond the current step’s boundary,
- docs/coverage requirements can’t be met without changing plan.

### Hard requirements (repo defaults)
#### Documentation (required)
For relevant changes, deliver:
- End-user docs (if user-facing behavior changes)
- Contributor docs (if workflow/architecture changes)
- Rustdoc/Godotdoc for public APIs (if Rust public APIs change) and private APIs (if Rust private APIs change), including examples where useful

#### Coverage (required)
Targets:
- Line coverage >= 80%
- Branch coverage >= 70%

Any exclusions must be explicitly recorded as a Decision (what, why, and how we compensate).

### Workplan lifecycle (simple)
- draft → refining → ready → in_progress → done
- blocked and archived are allowed at any time when applicable

### Folders
If they don't exist, create these folders in the repo to organize workplans by status. Ensure that each contains a `.gitkeep` file to maintain the directory structure in Git.
- `.workplans/backlog/`         draft + refining
- `.workplans/ready/`           ready to start
- `.workplans/in-progress/`     currently executing
- `.workplans/done/`            completed
- `.workplans/archived/`        cancelled/superseded

### Naming
- `YYYY-MM-DD-short-slug.md`

### Frontmatter (optional)
Frontmatter is recommended if you want status tracking, but workplans still work without it.

If used, keep it tiny:

```yaml
---
status: draft|refining|ready|in_progress|blocked|done|archived
priority: P0|P1|P2|P3
owner: "<name>"
updated: YYYY-MM-DD
---
```

### Canonical commands (fill these in per repo)
- Tests: `<fill>`
- Coverage: `<fill>`
- Docs build: `<fill>`

### Example Template

```
---
status: draft
priority: P2
owner: "<owner>"
updated: YYYY-MM-DD
---

# <Title>

## Goal
- 

## Scope
### In
- 

### Out
- 

## Acceptance Criteria
- 

## Notes / Context (what you learned from reading the code)
- 

## Plan (steps)
### Step 1
- Do:
- Verify:
- Docs:
- Coverage impact:

### Step 2
- Do:
- Verify:
- Docs:
- Coverage impact:

## Open Questions
- 

## Decisions
- YYYY-MM-DD:
	- 
```

### Initiation

If the conversation has just begun, start by asking the user what the if they want to create a workplan, or if they'd like to work on an existing one. Create any missing workplan files/folders as needed.

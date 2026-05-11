---
name: sdd-agentflow
description: "Project-local 9-step Agentflow-style SDD overlay for Spectra. Use for non-trivial changes that need Discuss, Explore, Prototype, Spec, Usage, Ticket, Dev, Review, and Wrap quality loops before or around $spectra-* workflows."
compatibility: Project-local skill for Spectra projects.
metadata:
  author: project
  version: "2.0"
  generatedBy: "project"
---

# SDD Agentflow

Use this skill as the default end-to-end entry point for non-trivial SDD work in this project. It does not replace Spectra. It wraps Spectra with a 9-step Agentflow discipline so artifacts are created and used only after requirements, risks, prototype learnings, usage contracts, tickets, implementation, and wrap decisions pass a quality loop.

This is a project-owned skill. Do not edit generated `spectra-*` skills to add project-specific SDD behavior.

## Operating Rules

- Answer and write user-facing summaries in Traditional Chinese.
- Use `$sdd-*` Agentflow wrappers for non-trivial work. Direct `$spectra-*` usage is allowed only when a `$sdd-*` wrapper delegates to Spectra, or for tiny mechanical edits and pure queries.
- Keep generated Spectra artifacts in the language requested by Spectra instructions. Spec requirement files may need English normative language.
- Do not implement production code before `$sdd-dev`.
- Prefer small, explicit, testable decisions over broad architecture prose.

## 9-Step Flow

1. `$sdd-discuss` -> Discuss
2. `$sdd-explore` -> Explore
3. `$sdd-prototype` -> Prototype
4. `$sdd-spec` -> Spec, backed by `$spectra-propose` or `$spectra-ingest`
5. `$sdd-usage` -> Usage and Working Backwards Usage/API Contract
6. `$sdd-ticket` -> Ticket, backed by `$spectra-ingest` for `tasks.md`
7. `$sdd-dev` -> Dev, backed by `$spectra-apply`
8. `$sdd-review` -> Review, backed by Spectra validation/analyze/audit/drift checks when available
9. `$sdd-wrap` -> Wrap, backed by `$spectra-archive`

## Quality Loop

Every step has its own review/rating/fix loop. A step is complete only when its output has been reviewed, `quality_score > 9/10`, no critical gap remains, and every review round document has been written.

For each step:

1. Execute the step.
2. Write or update the step output document.
3. Review that step's output against the rubric.
4. Rate the step from 1 to 10.
5. Fix non-blocking findings and re-review, up to 3 rounds.
6. Stop and report blockers if round 3 is still `quality_score <= 9/10` or has any critical gap.

Critical gaps include missing safety/privacy requirements, contradictory requirements, absent verification for user-visible behavior, instructions that require guessing, or missing/contradictory review round records.

## Output Files

For an active Spectra change named `<change>`, write step documents under:

```text
openspec/changes/<change>/agentflow/
```

Use these filenames:

- `01-discuss.md`
- `02-explore.md`
- `03-prototype.md`
- `04-spec.md`
- `05-usage.md`
- `06-ticket.md`
- `07-dev.md`
- `08-review.md`
- `09-wrap.md`

Every review/rating/fix round must write a dedicated review round document under:

```text
openspec/changes/<change>/agentflow/reviews/
```

Use these filenames:

- `01-discuss-r<round>.md`
- `02-explore-r<round>.md`
- `03-prototype-r<round>.md`
- `04-spec-r<round>.md`
- `05-usage-r<round>.md`
- `06-ticket-r<round>.md`
- `07-dev-task-<task-id>-r<round>.md`
- `08-review-r<round>.md`
- `09-wrap-r<round>.md`

Each review round document must include:

- target step, task, or artifact set
- input files/artifacts reviewed
- rubric table or checklist
- `quality_score` from 1 to 10
- findings
- fixes required
- fixes applied, or why no fix was needed
- remaining blockers or critical gaps
- decision: `pass`, `fix-and-rerun`, or `blocked`
- next action

If the Spectra change does not exist yet, keep both step output and review round output in the response, then transfer them into the `agentflow/` directory immediately after `$sdd-spec` creates the change.

## Rubric

Use the relevant parts of this rubric for every step:

- Requirement fidelity
- Risk coverage
- Evidence quality
- Prototype learning captured or intentionally skipped
- Usage/API contract clarity
- Spec testability
- Ticket handoff quality
- Scope boundaries
- Verification strength
- Artifact and review record consistency

## Step Delegation

When running the full flow, execute the 9 `$sdd-*` step skills in order. Do not skip to Spectra backend skills directly. If an existing change is already mid-flow, resume at the earliest incomplete or failing Agentflow step.

## When To Skip This Skill

Skip this skill for tiny mechanical edits, typo fixes, generated-file refreshes, or questions that only need `$spectra-ask`.

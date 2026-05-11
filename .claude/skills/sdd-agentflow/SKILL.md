---
name: sdd-agentflow
description: "Project-local Agentflow-style SDD overlay for Spectra. Use for non-trivial changes that need Discuss, Explore, Prototype, Spec, Usage/API Contract, Ticket, Develop, Review, and Wrap discipline before or around /spectra-* workflows."
compatibility: Project-local skill for Spectra projects.
metadata:
  author: project
  version: "1.1"
  generatedBy: "project"
---

# SDD Agentflow

Use this skill as the default entry point for non-trivial SDD work in this project. It does not replace Spectra. It wraps Spectra with an Agentflow-style discipline so artifacts are created only after requirements, risks, prototype learnings, and handoff contracts are explicit.

This is a project-owned skill. Do not edit generated `spectra-*` skills to add project-specific SDD behavior.

## Operating Rules

- Answer and write user-facing summaries in Traditional Chinese.
- Keep generated Spectra artifacts in the language requested by Spectra instructions. Spec requirement files may need English normative language.
- Use `/spectra-propose`, `/spectra-ingest`, `/spectra-apply`, `/spectra-analyze`, `/spectra-archive`, and related Spectra skills as the artifact/state backend.
- Do not implement application code during Discuss/Explore/Prototype planning unless the user explicitly asks for a spike. A spike is throwaway learning, not production implementation.
- Prefer small, explicit, testable decisions over broad architecture prose.

## Workflow

No step is complete until its step output document has been written or updated. For an active Spectra change named `<change>`, write step documents under:

```text
openspec/changes/<change>/agentflow/
```

Use these filenames:

- `01-discuss.md`
- `02-explore.md`
- `03-prototype.md`
- `04-spectra-map.md`
- `05-review-rating.md`
- `06-apply-notes.md`
- `07-wrap-review.md`

If the Spectra change does not exist yet, keep the step output in the response and transfer it into the `agentflow/` directory immediately after `/spectra-propose` creates the change. These support documents do not replace `proposal.md`, `design.md`, `spec.md`, or `tasks.md`; they preserve the decision trail for later review and refresh.

### 1. Discuss

Extract the user's requirement into:

- Goal
- Non-goals
- Assumptions
- Open questions
- Observable success examples
- Existing specs or code likely affected

Ask only for details that block a safe next step. Otherwise, state assumptions and continue.

Output `01-discuss.md` with goals, non-goals, assumptions, open questions, examples, and referenced specs/code.

### 2. Explore

Before writing final specs or tasks, inspect relevant existing specs and code. Evaluate the change through these lenses:

- Product/domain behavior
- Architecture and data flow
- Security, privacy, and secret handling
- UI/UX and accessibility when user-facing
- Performance and reliability
- Testability and observability
- Platform, browser, OS, SDK, or dependency constraints

Record concrete findings. Each finding should either become a design constraint, a spec requirement, a task, or an explicit non-goal.

Output `02-explore.md` with each explored lens, evidence inspected, findings, risk level, and the artifact each finding should affect.

### 3. Prototype Decision

Decide whether a throwaway prototype is needed.

Run or recommend a prototype when:

- An external API, browser behavior, rendering behavior, model output, file format, or platform capability is uncertain.
- A data shape or algorithm might fail under realistic volume or edge cases.
- The implementation could be expensive to unwind if the assumption is wrong.

If prototyping, define:

- The question being tested
- The smallest experiment
- What evidence means "pass" or "fail"
- What files or scratch area may be touched

After the spike, keep only learnings unless the user explicitly approves promoting code.

Output `03-prototype.md` with the prototype decision, question, experiment, pass/fail evidence, results, and whether any spike code is intentionally discarded or promoted into a task.

### 4. Map To Spectra

Translate the gathered context into Spectra artifacts:

- `proposal.md`: Discuss summary, motivation, scope, non-goals, affected specs, and major risks.
- `design.md`: Explore Findings, Prototype Findings, Working Backwards Usage/API Contract, Implementation Contract, scope boundaries, and tradeoffs.
- `spec.md`: normative, testable requirements with scenario examples.
- `tasks.md`: small implementation tasks with observable outcomes, verification targets, and `[P]` markers only for truly independent work.

Use `/spectra-propose` for new changes. Use `/spectra-ingest` when updating an existing or parked change.

Output `04-spectra-map.md` with a mapping table from Discuss/Explore/Prototype findings to `proposal.md`, `design.md`, `spec.md`, and `tasks.md`. Include any finding deliberately excluded and why.

### 5. Review, Rating, Fix Gate

Before `/spectra-apply`, rate artifacts from 1 to 10 using this rubric:

- Requirement fidelity
- Risk coverage
- Prototype learning captured or intentionally skipped
- Usage/API contract clarity
- Spec testability
- Task handoff quality
- Scope boundaries
- Verification strength

Passing means score 9 or higher and no critical gap. Critical gaps include missing safety/privacy requirements, contradictory requirements, absent verification for a user-visible behavior, or implementation tasks that cannot be executed without guessing.

Run at most 3 review/fix rounds:

1. Round 1: review, rate, and automatically fix all non-blocking findings.
2. Round 2: re-review, re-rate, and automatically fix remaining non-blocking findings.
3. Round 3: re-review and re-rate. If the score is still below 9, or any critical gap remains, stop and report blockers instead of continuing.

Never force-pass a critical gap. If the score is below 9 after round 3, ask for human direction or scope reduction. Do not enter apply while artifacts are vague, contradictory, placeholder-filled, or missing verification targets.

Output `05-review-rating.md` for every round. Include score, rubric table, findings, fixes made, remaining blockers, and the final pass/fail decision.

### 6. Apply

When artifacts pass the gate, use `/spectra-apply`.

During implementation:

- Re-read the relevant spec and Implementation Contract before each task.
- If `tdd: true`, write or update tests before production code.
- Verify the named target before marking a task done.
- If implementation reveals a design issue, stop and update artifacts instead of silently diverging.

Output `06-apply-notes.md` during implementation with task progress, verification commands/results, artifact deviations found, and any `/spectra-ingest` updates triggered by implementation learning.

### 7. Review And Wrap

After implementation:

- Compare the diff against proposal, specs, design contracts, and tasks.
- Run relevant tests and Spectra validation/analyze commands.
- Use `/spectra-archive` only after artifacts and implementation agree.

Output `07-wrap-review.md` with final diff review, spec/design/task conformance, test results, Spectra analyze/validate results, known residual risks, and archive readiness.

## When To Skip This Skill

Skip this skill for tiny mechanical edits, typo fixes, generated-file refreshes, or questions that only need `/spectra-ask`.

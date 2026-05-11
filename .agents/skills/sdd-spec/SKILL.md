---
name: sdd-spec
description: "Agentflow step 4/9: Spec. Use to create or update Spectra proposal/design/spec artifacts through $spectra-propose or $spectra-ingest, with Agentflow quality-loop review."
compatibility: Project-local skill for Spectra projects.
metadata:
  author: project
  version: "1.0"
  generatedBy: "project"
---

# SDD Spec

Run Agentflow step 4: Spec. This is the first step that normally creates or updates a Spectra change.

## Output Contract

- Step file: `openspec/changes/<change>/agentflow/04-spec.md`
- Review round files: `openspec/changes/<change>/agentflow/reviews/04-spec-r<round>.md`
- Spectra backend: `$spectra-propose` for a new change, `$spectra-ingest` for an existing change.
- Passing requires `quality_score > 9/10`, no critical gap, and a review round file for every round.

## Workflow

1. Read prior Agentflow outputs: `01-discuss.md`, `02-explore.md`, and `03-prototype.md`, or their response-held equivalents.
2. Use `$spectra-propose` to create a new change, or `$spectra-ingest` to update an existing/parked change.
3. Ensure `proposal.md`, `design.md`, and `spec.md` reflect goals, non-goals, risks, prototype learnings, scope boundaries, and normative testable requirements.
4. Do not treat generated `tasks.md` as final here; `$sdd-ticket` owns ticket quality.
5. Run review/rating/fix for up to 3 rounds.
6. Do not proceed to `$sdd-usage` until the step passes.

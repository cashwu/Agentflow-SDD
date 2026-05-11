---
name: sdd-usage
description: "Agentflow step 5/9: Usage. Use to define user stories, API/CLI contracts, examples, failure modes, privacy expectations, and acceptance behavior before ticketing."
compatibility: Project-local skill for Spectra projects.
metadata:
  author: project
  version: "1.0"
  generatedBy: "project"
---

# SDD Usage

Run Agentflow step 5: Usage. This step turns the spec into working-backwards usage stories and contracts before tickets are finalized.

## Output Contract

- Step file: `openspec/changes/<change>/agentflow/05-usage.md`
- Review round files: `openspec/changes/<change>/agentflow/reviews/05-usage-r<round>.md`
- Spectra backend: `$spectra-ingest` when usage findings require artifact updates.
- Passing requires `quality_score > 9/10`, no critical gap, and a review round file for every round.

## Workflow

1. Define user stories, commands/APIs, inputs, outputs, errors, privacy expectations, and observable acceptance examples.
2. Ensure `design.md` contains a Working Backwards Usage/API Contract for user-facing or API-facing behavior.
3. Ensure `spec.md` has testable scenarios for the usage contract.
4. Use `$spectra-ingest` if usage work changes proposal/design/spec/tasks.
5. Run review/rating/fix for up to 3 rounds.
6. Do not proceed to `$sdd-ticket` until the step passes.

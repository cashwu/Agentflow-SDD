---
name: sdd-dev
description: "Agentflow step 7/9: Dev. Use instead of direct /spectra-apply to implement Spectra tasks only after prior Agentflow gates pass, with per-task review/rating/fix files."
compatibility: Project-local skill for Spectra projects.
metadata:
  author: project
  version: "1.0"
  generatedBy: "project"
---

# SDD Dev

Run Agentflow step 7: Dev. This is the wrapper for `/spectra-apply`.

## Output Contract

- Step file: `openspec/changes/<change>/agentflow/07-dev.md`
- Review round files: `openspec/changes/<change>/agentflow/reviews/07-dev-task-<task-id>-r<round>.md`
- Spectra backend: `/spectra-apply`
- Passing requires each completed task to reach `quality_score > 9/10`, no critical gap, and a review round file for every round.

## Workflow

1. Confirm `/sdd-discuss` through `/sdd-ticket` outputs exist and have passing review round files.
2. Delegate implementation to `/spectra-apply`.
3. Before each task, re-read the relevant spec, usage contract, implementation contract, and task verification target.
4. If `tdd: true`, write or update tests before production code.
5. For each task, verify behavior, run review/rating/fix for up to 3 rounds, and write the task review round file before marking the task complete. Each round MUST spawn a fresh sub-agent for review and rating — never review inline or reuse a prior round's sub-agent.
6. If implementation reveals artifact drift, stop and use `/sdd-spec`, `/sdd-usage`, or `/sdd-ticket` with `/spectra-ingest` before continuing.
7. Do not proceed to `/sdd-review` until implementation tasks pass.

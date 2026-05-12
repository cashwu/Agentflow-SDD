---
name: sdd-review
description: "Agentflow step 8/9: Review. Use after development for code review, artifact conformance, tests, Spectra validation/analyze/audit/drift checks, and quality-loop fixes before wrap."
compatibility: Project-local skill for Spectra projects.
metadata:
  author: project
  version: "1.0"
  generatedBy: "project"
---

# SDD Review

Run Agentflow step 8: Review. This is the post-development review gate before archive/wrap.

## Output Contract

- Step file: `openspec/changes/<change>/agentflow/08-review.md`
- Review round files: `openspec/changes/<change>/agentflow/reviews/08-review-r<round>.md`
- Spectra backend: `/spectra-audit`, `/spectra-drift`, `spectra schema validate spec-driven`, and `spectra analyze <change>` when available.
- Passing requires `quality_score > 9/10`, no critical gap, and a review round file for every round.

## Workflow

1. Compare implementation diff against proposal, design, spec, usage contract, and tasks.
2. Run the task verification targets and relevant project tests.
3. Run Spectra validation/analyze/audit/drift checks when available.
4. Fix non-blocking findings and update artifacts through `/spectra-ingest` when review discovers spec/design/task drift.
5. Run review/rating/fix for up to 3 rounds. Each round MUST spawn a fresh sub-agent for review and rating — never review inline or reuse a prior round's sub-agent.
6. Do not proceed to `/sdd-wrap` until the review gate passes.

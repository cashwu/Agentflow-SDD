---
name: sdd-wrap
description: "Agentflow step 9/9: Wrap. Use instead of direct /spectra-archive to finalize files, ensure all review loops passed, archive the Spectra change, and summarize residual risks."
compatibility: Project-local skill for Spectra projects.
metadata:
  author: project
  version: "1.0"
  generatedBy: "project"
---

# SDD Wrap

Run Agentflow step 9: Wrap. This is the wrapper for `/spectra-archive`.

## Output Contract

- Step file: `openspec/changes/<change>/agentflow/09-wrap.md`
- Review round files: `openspec/changes/<change>/agentflow/reviews/09-wrap-r<round>.md`
- Spectra backend: `/spectra-archive`
- Passing requires `quality_score > 9/10`, no critical gap, and a review round file for every round.

## Workflow

1. Confirm all prior Agentflow step files and review round files exist and passed.
2. Confirm implementation, artifacts, tests, and Spectra validation agree.
3. Record known residual risks, verification results, and archive readiness.
4. Run review/rating/fix for up to 3 rounds. Each round MUST spawn a fresh sub-agent for review and rating — never review inline or reuse a prior round's sub-agent.
5. Delegate to `/spectra-archive` only after the wrap review passes.
6. Final response should summarize what changed, verification performed, and any residual risk.

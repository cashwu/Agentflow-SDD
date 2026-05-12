---
name: sdd-discuss
description: "Agentflow step 1/9: Discuss. Use before Spectra proposal work to clarify goals, non-goals, assumptions, open questions, and success examples, with per-round review/rating/fix output."
compatibility: Project-local skill for Spectra projects.
metadata:
  author: project
  version: "1.0"
  generatedBy: "project"
---

# SDD Discuss

Run Agentflow step 1: Discuss. This is the entry step for non-trivial work and may delegate to `$spectra-discuss` for structured conversation, but the Agentflow quality loop is owned here.

## Output Contract

- Step file: `openspec/changes/<change>/agentflow/01-discuss.md`
- Review round files: `openspec/changes/<change>/agentflow/reviews/01-discuss-r<round>.md`
- If no Spectra change exists yet, keep the step and review round output in the response, then transfer it after `$sdd-spec` creates the change.
- Passing requires `quality_score > 9/10`, no critical gap, and a review round file for every round.

## Workflow

1. Extract goal, non-goals, assumptions, open questions, observable success examples, and likely affected specs/code.
2. Ask only for details that block a safe next step; otherwise state assumptions and continue.
3. If deeper structured discussion is useful, delegate to `$spectra-discuss`, then capture the result in the Agentflow files.
4. Run review/rating/fix for up to 3 rounds. Each round MUST spawn a fresh sub-agent for review and rating — never review inline or reuse a prior round's sub-agent.
5. Do not proceed to `$sdd-explore` until the step passes.

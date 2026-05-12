---
name: sdd-prototype
description: "Agentflow step 3/9: Prototype. Use to decide whether a throwaway spike is needed, run the smallest experiment when needed, and preserve learnings with quality-loop review."
compatibility: Project-local skill for Spectra projects.
metadata:
  author: project
  version: "1.0"
  generatedBy: "project"
---

# SDD Prototype

Run Agentflow step 3: Prototype. Prototype code is learning material, not production code, unless the user explicitly approves promoting it into a later ticket.

## Output Contract

- Step file: `openspec/changes/<change>/agentflow/03-prototype.md`
- Review round files: `openspec/changes/<change>/agentflow/reviews/03-prototype-r<round>.md`
- If no Spectra change exists yet, keep the step and review round output in the response, then transfer it after `/sdd-spec` creates the change.
- Passing requires `quality_score > 9/10`, no critical gap, and a review round file for every round.

## Workflow

1. Decide whether uncertainty requires a throwaway prototype.
2. Prototype when external APIs, platform behavior, file formats, algorithms, data shape, rendering behavior, or model output are materially uncertain.
3. Define the question, smallest experiment, pass/fail evidence, files or scratch area touched, and cleanup/promotion decision.
4. Record results and whether spike code is discarded or converted into a `/sdd-ticket` task.
5. Run review/rating/fix for up to 3 rounds. Each round MUST spawn a fresh sub-agent for review and rating — never review inline or reuse a prior round's sub-agent.
6. Do not proceed to `/sdd-spec` until the step passes.

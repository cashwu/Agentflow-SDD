---
name: sdd-explore
description: "Agentflow step 2/9: Explore. Inspects existing specs/code and identifies product, architecture, security, UX, performance, testability, and platform risks before spec writing."
compatibility: Project-local skill for Agentflow-SDD.
metadata:
  author: project
  version: "3.0"
  generatedBy: "project"
---

# SDD Explore

Run Agentflow step 2: Explore. This step is project analysis before final specs or tickets exist.

## Output Contract

- Step file: `agentflow/changes/<change>/agentflow/02-explore.md`
- Review round files: `agentflow/changes/<change>/agentflow/reviews/02-explore-r<round>.md`
- If no change directory exists yet, keep the step and review round output in the response, then transfer it after `$sdd-spec` creates the change.
- Passing requires `quality_score > 9/10`, no critical gap, and a review round file for every round.

## Workflow

1. Inspect relevant `openspec/specs/`, current change artifacts, and code.
2. Evaluate product/domain behavior, architecture/data flow, security/privacy, UI/UX, performance/reliability, testability/observability, and platform/dependency constraints.
3. For each finding, record evidence, risk level, and whether it should affect spec, usage contract, ticket, implementation, or become a non-goal.
4. Run review/rating/fix for up to 3 rounds. Each round MUST spawn a fresh sub-agent for review and rating — never review inline or reuse a prior round's sub-agent.
5. Do not proceed to `$sdd-prototype` until the step passes.

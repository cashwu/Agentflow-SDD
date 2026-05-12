---
name: sdd-usage
description: "Agentflow step 5/9: Usage. Defines user stories, API/CLI contracts, examples, failure modes, and acceptance behavior, then updates spec.md."
compatibility: Project-local skill for Agentflow-SDD.
metadata:
  author: project
  version: "3.0"
  generatedBy: "project"
---

# SDD Usage

Run Agentflow step 5: Usage. This step turns the spec into working-backwards usage stories and contracts before tickets are finalized.

## Output Contract

- Step file: `agentflow/changes/<change>/agentflow/05-usage.md`
- Review round files: `agentflow/changes/<change>/agentflow/reviews/05-usage-r<round>.md`
- Artifact updated: `spec.md` (Usage Contract + Usage Scenarios sections)
- Passing requires `quality_score > 9/10`, no critical gap, and a review round file for every round.

## Workflow

1. Read `spec.md` from `agentflow/changes/<change>/`.

2. Define user stories, commands/APIs, inputs, outputs, errors, privacy expectations, and observable acceptance examples.

3. Update `spec.md`: fill in the "Usage Contract" section, replacing the Step 5 placeholder. Include:
   - User stories (as <role>, I want <action>, so that <purpose>)
   - Command/API interface shape with arguments
   - Input/output table with types
   - Error handling table (scenario, error message, code)
   - Privacy expectations

4. Update `spec.md`: fill in the "Usage Scenarios" section, replacing the Step 5 placeholder. Add testable GIVEN/WHEN/THEN scenarios with concrete examples for each user-facing behavior.

5. Update `status.yaml`: set `current_step` to `5`.

6. Write `05-usage.md` step file summarizing usage decisions and linking review round files.

7. Run review/rating/fix for up to 3 rounds. Each round MUST spawn a fresh sub-agent for review and rating — never review inline or reuse a prior round's sub-agent.

8. Do not proceed to `$sdd-ticket` until the step passes.

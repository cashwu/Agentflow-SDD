---
name: sdd-wrap
description: "Agentflow step 9/9: Wrap. Archives completed change, optionally syncs master specs, and summarizes residual risks."
compatibility: Project-local skill for Agentflow-SDD.
metadata:
  author: project
  version: "3.0"
  generatedBy: "project"
---

# SDD Wrap

Run Agentflow step 9: Wrap. This is the final step that archives the change. No external CLI dependency.

## Output Contract

- Step file: `agentflow/changes/<change>/agentflow/09-wrap.md`
- Review round files: `agentflow/changes/<change>/agentflow/reviews/09-wrap-r<round>.md`
- Archive destination: `agentflow/changes/archive/YYYY-MM-DD-<change-name>/`
- Passing requires `quality_score > 9/10`, no critical gap, and a review round file for every round.

## Workflow

1. Confirm all prior Agentflow step files (`01-discuss` through `08-review`) and their review round files exist and passed.

2. Confirm all tasks in `tasks.md` are marked `[x]`.

3. Confirm implementation, artifacts, and tests agree.

4. Master Spec Sync Decision:
   - Check `spec.md` for capability changes (new or modified capabilities).
   - Compare with existing master specs at `openspec/specs/<capability>/spec.md`.
   - If delta exists, ask the user: "Sync to master specs?" / "Archive without syncing".
   - If sync: merge `spec.md` content into `openspec/specs/<capability>/spec.md` (create the capability directory if new).
   - If no delta specs: skip.

5. Record known residual risks, verification results, and archive readiness.

6. Run review/rating/fix for up to 3 rounds. Each round MUST spawn a fresh sub-agent for review and rating — never review inline or reuse a prior round's sub-agent.

7. After wrap review passes, archive:
   a. Create archive directory: `agentflow/changes/archive/YYYY-MM-DD-<change-name>/`
   b. Move the entire change directory there.
   c. Update `status.yaml`: set `status` to `archived`, `current_step` to `9`.

8. Write `09-wrap.md` in the archived location with final summary:
   - What changed
   - Verification performed
   - Master spec sync status
   - Residual risks

9. Final response should summarize what changed, verification performed, and any residual risk.

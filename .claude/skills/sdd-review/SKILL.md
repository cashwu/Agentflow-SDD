---
name: sdd-review
description: "Agentflow step 8/9: Review. Post-development review gate with artifact consistency, security audit, and drift detection via sub-agents."
compatibility: Project-local skill for Agentflow-SDD.
metadata:
  author: project
  version: "3.0"
  generatedBy: "project"
---

# SDD Review

Run Agentflow step 8: Review. This is the post-development review gate before wrap. All checks are performed by sub-agents — no external CLI dependency.

## Output Contract

- Step file: `agentflow/changes/<change>/agentflow/08-review.md`
- Review round files: `agentflow/changes/<change>/agentflow/reviews/08-review-r<round>.md`
- Passing requires `quality_score > 9/10`, no critical gap, and a review round file for every round.

## Workflow

1. Compare implementation diff (`git diff`) against `spec.md` and `tasks.md`.

2. Run the task verification targets listed in `tasks.md` and relevant project tests.

3. Spawn sub-agent: **Artifact Consistency Check**
   - Coverage: every capability in `spec.md` has a corresponding requirement and implementation contract.
   - Consistency: tasks cover all implementation contracts in `spec.md`.
   - Ambiguity: success/failure conditions testable and specific.
   - Gaps: file paths consistent across all artifacts.
   - Completeness: all tasks in `tasks.md` marked `[x]`.
   - Spec traceability: every spec requirement has implementation evidence.
   - Report findings as Critical / Warning / Suggestion.

4. Spawn sub-agent: **Security Audit**
   - Read `git diff` of changes.
   - Analyze through three lenses: Scoundrel (adversarial), Lazy Developer (shortcuts), Confused Developer (misuse).
   - Check 6 trap categories: algorithm choice, dangerous defaults, raw primitives, configuration cliffs, silent failures, stringly-typed security.
   - Return consolidated report with severity-grouped findings.

5. Spawn sub-agent: **Drift Detection**
   - Time dormancy: check `status.yaml` created date vs now.
   - Spec anchor validity: do file paths, functions, symbols referenced in `spec.md` still exist in the codebase?
   - Task collision: were files referenced by tasks modified by external commits since the change was created?
   - Report severity: light / medium / heavy with recommendation.

6. Fix non-blocking findings. Update artifacts directly when review discovers spec/design/task drift.

7. Update `status.yaml`: set `current_step` to `8`.

8. Write `08-review.md` step file summarizing all review findings and linking review round files.

9. Run review/rating/fix for up to 3 rounds. Each round MUST spawn a fresh sub-agent for review and rating — never review inline or reuse a prior round's sub-agent.

10. Do not proceed to `/sdd-wrap` until the review gate passes.

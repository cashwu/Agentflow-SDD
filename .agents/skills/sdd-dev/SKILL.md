---
name: sdd-dev
description: "Agentflow step 7/9: Dev. Implements tasks from tasks.md with per-task review/rating/fix, TDD support, and parallel task dispatch."
compatibility: Project-local skill for Agentflow-SDD.
metadata:
  author: project
  version: "3.0"
  generatedBy: "project"
---

# SDD Dev

Run Agentflow step 7: Dev. Full task execution engine with no external CLI dependency.

## Output Contract

- Step file: `agentflow/changes/<change>/agentflow/07-dev.md`
- Review round files: `agentflow/changes/<change>/agentflow/reviews/07-dev-task-<task-id>-r<round>.md`
- Passing requires each completed task to reach `quality_score > 9/10`, no critical gap, and a review round file for every round.

## Workflow

1. Confirm `$sdd-discuss` through `$sdd-ticket` outputs exist and have passing review round files.

2. Read `agentflow/config.yaml` for preferences: `tdd`, `parallel_tasks`, `audit`.

3. Read context files from `agentflow/changes/<change>/`:
   - `proposal.md`, `design.md`, `spec.md`, `tasks.md`

4. Show current progress:
   - Parse `tasks.md` checkboxes: count `- [ ]` vs `- [x]`
   - Display "N/M tasks complete"

5. Task implementation loop — for each pending task (`- [ ]`):
   a. Announce which task is being worked on.
   b. Re-read the relevant sections of `design.md` (Implementation Contract for this task's area) and `spec.md`.
   c. Detect unclear tasks: file-path-only description, vague outcome, conflicting with contract. Pause and ask if found.
   d. Pre-implementation checks:
      - **Reuse**: search for existing implementations that solve the same problem.
      - **Quality**: derive approach from existing code patterns.
      - **Efficiency**: parallelize independent async operations.
      - **No Placeholders**: check artifacts for TBD/TODO that affect this task.
      - **Examples as verification**: use spec Example blocks to validate behavior.
   e. If `tdd: true`, write or update the failing test before production code.
   f. Implement the code changes.
   g. Verify: re-read the task description and Implementation Contract, confirm all requirements addressed.
   h. Mark task complete: edit `tasks.md` to change `- [ ]` to `- [x]` for this task.
   i. Run review/rating/fix for this task — up to 3 rounds. Each round MUST spawn a fresh sub-agent for review and rating — never review inline or reuse a prior round's sub-agent.
   j. Continue to next task.

6. Parallel task support:
   When `parallel_tasks: true` in config and consecutive `[P]` tasks are found, dispatch them as parallel agents. Each parallel agent:
   - Implements one `[P]` task independently.
   - Marks its checkbox on completion.
   - Runs its own per-task review/rating/fix.
   If any parallel task fails review, pause and report before continuing.

7. Artifact drift detection:
   If implementation reveals that `design.md`, `spec.md`, or `tasks.md` are wrong or incomplete:
   - Stop implementation.
   - Suggest returning to `$sdd-spec`, `$sdd-usage`, or `$sdd-ticket` to update artifacts.
   - Resume after artifacts are corrected.

8. Final check:
   - Re-parse `tasks.md`: confirm all checkboxes are `[x]`.
   - Update `status.yaml`: set `current_step` to `7`.
   - Display completion summary with task count.

9. Write `07-dev.md` step file summarizing implementation decisions, task completion status, and linking review round files.

10. Do not proceed to `$sdd-review` until all implementation tasks pass.

## Rationalization Table

| What You're Thinking | What You Should Do |
|----------------------|--------------------|
| "This task is trivial, skip the review" | Every task gets reviewed. Trivial tasks get trivial reviews — but they still get reviewed |
| "I'll fix the spec later, just implement what makes sense" | Stop. Update the spec first. Implementation follows spec, not the other way around |
| "The test can come after the code" | If tdd: true, write the test first. If false, still write tests |
| "These tasks look independent, I'll parallelize" | Only if they have `[P]` markers AND `parallel_tasks: true` in config |

## Guardrails

- Task tracking is file-based: `tasks.md` checkboxes are the single source of truth.
- Do not use any external task management CLI.
- Keep changes minimal and focused per task.
- If a task is ambiguous, pause and ask — do not guess.
- Do not mark a task `[x]` until its review/rating/fix loop passes.

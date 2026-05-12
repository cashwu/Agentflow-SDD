---
name: sdd-ticket
description: "Agentflow step 6/9: Ticket. Creates tasks.md with small, ordered tasks that have concrete outcomes, dependencies, and verification targets."
compatibility: Project-local skill for Agentflow-SDD.
metadata:
  author: project
  version: "3.0"
  generatedBy: "project"
---

# SDD Ticket

Run Agentflow step 6: Ticket. This step owns task quality and creates the implementation plan.

## Output Contract

- Artifact created: `agentflow/changes/<change>/tasks.md`
- Step file: `agentflow/changes/<change>/agentflow/06-ticket.md`
- Review round files: `agentflow/changes/<change>/agentflow/reviews/06-ticket-r<round>.md`
- Passing requires `quality_score > 9/10`, no critical gap, and a review round file for every round.

## Workflow

1. Read `proposal.md`, `design.md`, `spec.md`, and step files `01-discuss` through `05-usage`.

2. Read `agentflow/config.yaml` for `preferences.parallel_tasks`.

3. Create `tasks.md` using the Tasks Template below. Ensure each task has:
   - Observable outcome description
   - Concrete verification target (test name, CLI invocation, analyzer check, or manual assertion)
   - Files involved
   - Implementation Contract reference from `design.md`

4. Apply `[P]` markers only for tasks that are truly independent: different files, no dependency on unfinished tasks in the same group.

5. Include Agentflow document update tasks: update step files and review round files when implementation changes decisions.

6. Include a final review task that compares implementation against specs, design contracts, and tests.

7. Update `status.yaml`: set `tasks` to `done`, `current_step` to `6`.

8. Write `06-ticket.md` step file summarizing ticket decisions and linking review round files.

9. Run review/rating/fix for up to 3 rounds. Each round MUST spawn a fresh sub-agent for review and rating — never review inline or reuse a prior round's sub-agent.

10. Do not proceed to `$sdd-dev` until the step passes.

## Tasks Template

```markdown
# <Change Name> - 任務

## <任務群組 1>

- [ ] **Task 1**: <可觀測行為描述>
  - 驗證目標: <test name / CLI invocation / manual assertion>
  - 涉及檔案: `path/to/file.ts`
  - Contract 參照: <design.md 中的實作區域名稱>

- [ ] [P] **Task 2**: <可觀測行為描述>
  - 驗證目標: ...
  - 涉及檔案: ...
  - Contract 參照: ...

## Agentflow 文件更新

- [ ] **更新 step 文件**: 當實作改變決策紀錄時更新相關 agentflow step 文件
- [ ] **更新 review round 文件**: 當實作改變 review 證據時更新相關 review round 文件

## 最終驗證

- [ ] **實作 vs. spec 比對**: 比對所有實作結果與 spec.md 的需求、design contract、測試
```

## Guardrails

- Every task must name an observable outcome. Reject tasks whose description is just "edit file X" with no behavior.
- Reject tasks with vague acceptance criteria: "works correctly", "behaves as expected", "handles edge cases" without naming the cases.
- Tasks must be small enough for one focused implementation pass.
- Do not invent tasks for requirements not in the proposal or spec.

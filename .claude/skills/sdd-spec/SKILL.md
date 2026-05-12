---
name: sdd-spec
description: "Agentflow step 4/9: Spec. Creates proposal.md, design.md, and spec.md artifacts directly from prior Agentflow steps, with quality-loop review."
compatibility: Project-local skill for Agentflow-SDD.
metadata:
  author: project
  version: "3.0"
  generatedBy: "project"
---

# SDD Spec

Run Agentflow step 4: Spec. This step creates the change directory and its core artifacts. No external CLI dependency.

## Output Contract

- Change directory: `agentflow/changes/<change>/`
- Artifacts created: `proposal.md`, `design.md`, `spec.md`
- Status file: `agentflow/changes/<change>/status.yaml`
- Step file: `agentflow/changes/<change>/agentflow/04-spec.md`
- Review round files: `agentflow/changes/<change>/agentflow/reviews/04-spec-r<round>.md`
- Passing requires `quality_score > 9/10`, no critical gap, and a review round file for every round.

## Workflow

1. Read prior Agentflow outputs: `01-discuss.md`, `02-explore.md`, and `03-prototype.md` (from response-held equivalents if the change directory does not exist yet).

2. Determine requirement source and change name:
   - If argument is provided (e.g., `/sdd-spec add-dark-mode`), use it.
   - Otherwise extract from conversation context or ask.
   - Derive a kebab-case change name. Strip `YYYY-MM-DD-` archive prefixes.

3. Classify change type: `Feature` / `Bug Fix` / `Refactor`.

4. Scan existing master specs for relevance:
   - Glob `openspec/specs/*/spec.md`.
   - Display related specs as informational summary. Do not stop or ask for confirmation.

5. Create the change directory:
   ```
   mkdir -p agentflow/changes/<change>/agentflow/reviews/
   ```

6. Write `status.yaml`:
   ```yaml
   name: <change-name>
   created: <ISO 8601 timestamp>
   status: active
   current_step: 4
   artifacts:
     proposal: pending
     design: pending
     spec: pending
     tasks: pending
   ```

7. If `01-discuss.md`, `02-explore.md`, `03-prototype.md` were response-held, write them into `agentflow/changes/<change>/agentflow/` now.

8. Write `proposal.md` using the Proposal Template below.

9. Write `design.md` using the Design Template below. Leave the "Working Backwards Usage/API Contract" section with a placeholder: `<!-- Step 5 (Usage) 將填寫此區段 -->`.

10. Write `spec.md` using the Spec Template below. Leave the "Usage Scenarios" section with a placeholder: `<!-- Step 5 (Usage) 將補充此區段 -->`.

11. Update `status.yaml`: set `proposal`, `design`, `spec` to `done`.

12. Inline Self-Review:
    - **No Placeholders**: reject TBD, TODO, FIXME, vague instructions, delegation by reference, empty sections (except the explicit Step 5 placeholders).
    - **Internal Consistency**: every capability in proposal has a spec requirement; design references only proposal capabilities; file paths consistent.
    - **Scope Check**: touches more than 3 unrelated subsystems → consider splitting.
    - **Ambiguity Check**: success/failure conditions testable and specific; boundary conditions defined.
    - **Durable Handoff**: no file-path-only tasks, no line-number-coupled instructions, testable acceptance criteria, scope boundaries on non-trivial work.

13. Write `04-spec.md` step file summarizing what was created and linking review round files.

14. Run review/rating/fix for up to 3 rounds. Each round MUST spawn a fresh sub-agent for review and rating — never review inline or reuse a prior round's sub-agent.

15. Do not proceed to `/sdd-usage` until the step passes.

## Proposal Template

```markdown
# <Change Name>

## 類型

Feature | Bug Fix | Refactor

## 為什麼（Why）

<!-- 動機、觸發原因、不做的後果 — 來自 01-discuss -->

## 改什麼（What Changes）

<!-- 具體變更描述 -->

## 非目標（Non-Goals）

<!-- 明確排除的事項 -->

## Discuss 結論

<!-- 來自 01-discuss：確認的假設、開放問題、成功範例 -->

## Explore 發現

<!-- 來自 02-explore：風險及決策，每項標註 risk level -->

## Prototype 學習

<!-- 來自 03-prototype：實驗結果、保留/丟棄決策 -->
<!-- 若跳過 prototype，說明為什麼風險夠低 -->

## 能力（Capabilities）

### 新增能力

- `<capability-name>`: <簡述>

### 修改能力

- `<capability-name>`: <簡述>

## 影響範圍（Impact）

- 受影響的 specs: <新增或修改的能力>
- 受影響的程式碼:
  - 新增: <相對於 project root 的路徑>
  - 修改: <已存在的路徑>
  - 刪除: <將刪除的路徑>

## 範圍邊界（Scope Boundaries）

- In Scope: ...
- Out of Scope: ...
```

## Design Template

```markdown
# <Change Name> - 設計

## 架構決策

<!-- 關鍵技術選擇與理由 -->

## Explore 風險對應

| 風險 | 等級 | 設計決策 |
|------|------|----------|
| ... | ... | ... |

## Prototype 發現

<!-- Prototype 結果如何影響設計，或為何跳過 -->

## 模組設計

<!-- 元件/模組拆分、職責、互動關係 -->

## Implementation Contract

### <實作區域 1>

- **可觀測行為**: ...
- **介面/資料形狀**: ...
- **失敗模式**: ...
- **驗收標準**: ...
- **驗證目標**: <test name / CLI invocation / analyzer check>
- **不在範圍**: ...

## Working Backwards Usage/API Contract

<!-- Step 5 (Usage) 將填寫此區段 -->
```

## Spec Template

spec.md uses English normative language (SHALL/MUST) regardless of project locale.

```markdown
# <Change Name> - Specification

## <Capability Name>

### Purpose

<!-- One sentence -->

### Requirement: <requirement-name>

The system SHALL ...

#### Scenario: <scenario-name>

GIVEN ...
WHEN ...
THEN ...

##### Example:

| Input | Expected Output |
|-------|-----------------|
| ...   | ...             |

## Usage Scenarios

<!-- Step 5 (Usage) 將補充此區段 -->
```

## Rationalization Table

| What You're Thinking | What You Should Do |
|----------------------|--------------------|
| "The requirements are clear enough, no need for discuss" | Fine if true — but check you're not skipping because you're lazy |
| "The spec doesn't need scenarios, the requirement is obvious" | Obvious to you now. Write scenarios for the implementer who doesn't have your context |
| "I'll keep the design brief, code will be self-explanatory" | Design exists so implementers don't reverse-engineer intent. Be specific |
| "This is a small change, skip the scope check" | Small changes touching 5 subsystems aren't small. Check |
| "The placeholder is fine for now, I'll fill it in later" | There is no "later" — implementation is next. Fill it in now |

## Guardrails

- Read dependency step files (01-discuss, 02-explore, 03-prototype) before creating any artifact.
- All file paths in Impact section must be relative to project root.
- Do not wrap shell commands in backticks inside artifact text.
- Do not write application code during this step.
- If context is critically unclear, ask the user — but prefer making reasonable decisions to keep momentum.

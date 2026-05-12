---
name: sdd-spec
description: "Agentflow step 4/9: Spec. Creates spec.md (requirements + implementation contracts) from prior Agentflow steps, with quality-loop review."
compatibility: Project-local skill for Agentflow-SDD.
metadata:
  author: project
  version: "3.0"
  generatedBy: "project"
---

# SDD Spec

Run Agentflow step 4: Spec. This step creates the change directory and spec.md — the single specification artifact. No external CLI dependency.

## Output Contract

- Change directory: `agentflow/changes/<change>/`
- Artifact created: `spec.md`
- Status file: `agentflow/changes/<change>/status.yaml`
- Step file: `agentflow/changes/<change>/agentflow/04-spec.md`
- Review round files: `agentflow/changes/<change>/agentflow/reviews/04-spec-r<round>.md`
- Passing requires `quality_score > 9/10`, no critical gap, and a review round file for every round.

## Workflow

1. Read prior Agentflow outputs: `01-discuss.md`, `02-explore.md`, and `03-prototype.md` (from response-held equivalents if the change directory does not exist yet).

2. Determine requirement source and change name:
   - If argument is provided (e.g., `$sdd-spec add-dark-mode`), use it.
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
     spec: pending
     tasks: pending
   ```

7. If `01-discuss.md`, `02-explore.md`, `03-prototype.md` were response-held, write them into `agentflow/changes/<change>/agentflow/` now.

8. Write `spec.md` using the Spec Template below. Include:
   - Requirements section with testable SHALL/MUST statements and GIVEN/WHEN/THEN scenarios from steps 1-3
   - Implementation Contract section with observable behavior, interfaces, failure modes, and verification targets for each implementation area
   - Leave Usage Contract and Usage Scenarios sections with placeholders for Step 5

9. Update `status.yaml`: set `spec` to `done`.

10. Inline Self-Review:
    - **No Placeholders**: reject TBD, TODO, FIXME, vague instructions, delegation by reference, empty sections (except the explicit Step 5 placeholders).
    - **Internal Consistency**: every capability mentioned has a spec requirement; file paths consistent.
    - **Scope Check**: touches more than 3 unrelated subsystems → consider splitting.
    - **Ambiguity Check**: success/failure conditions testable and specific; boundary conditions defined.
    - **Durable Handoff**: no file-path-only instructions, no line-number-coupled instructions, testable acceptance criteria, scope boundaries on non-trivial work.

11. Write `04-spec.md` step file summarizing what was created and linking review round files.

12. Run review/rating/fix for up to 3 rounds. Each round MUST spawn a fresh sub-agent for review and rating — never review inline or reuse a prior round's sub-agent.

13. Do not proceed to `$sdd-usage` until the step passes.

## Spec Template

spec.md uses English normative language (SHALL/MUST) for requirements. Implementation Contract and other sections use the project locale (Traditional Chinese).

```markdown
# <Change Name> - Specification

## 類型

Feature | Bug Fix | Refactor

## 範圍邊界（Scope Boundaries）

- In Scope: ...
- Out of Scope: ...

## Requirements

### <Capability Name>

#### Purpose

<!-- One sentence -->

#### Requirement: <requirement-name>

The system SHALL ...

##### Scenario: <scenario-name>

GIVEN ...
WHEN ...
THEN ...

###### Example:

| Input | Expected Output |
|-------|-----------------|
| ...   | ...             |

## Usage Contract

<!-- Step 5 (Usage) 將填寫此區段 -->

## Usage Scenarios

<!-- Step 5 (Usage) 將補充此區段 -->

## Implementation Contract

### <實作區域 1>

- **可觀測行為**: ...
- **介面/資料形狀**: ...
- **失敗模式**: ...
- **驗收標準**: ...
- **驗證目標**: <test name / CLI invocation / analyzer check>
- **不在範圍**: ...

### <實作區域 2>

(同上格式)

## 影響範圍（Impact）

- 受影響的 specs: <新增或修改的能力>
- 受影響的程式碼:
  - 新增: <相對於 project root 的路徑>
  - 修改: <已存在的路徑>
  - 刪除: <將刪除的路徑>
```

## Rationalization Table

| What You're Thinking | What You Should Do |
|----------------------|--------------------|
| "The requirements are clear enough, no need for discuss" | Fine if true — but check you're not skipping because you're lazy |
| "The spec doesn't need scenarios, the requirement is obvious" | Obvious to you now. Write scenarios for the implementer who doesn't have your context |
| "I'll keep the contract brief, code will be self-explanatory" | Contracts exist so implementers don't reverse-engineer intent. Be specific |
| "This is a small change, skip the scope check" | Small changes touching 5 subsystems aren't small. Check |
| "The placeholder is fine for now, I'll fill it in later" | There is no "later" — implementation is next. Fill it in now |

## Guardrails

- Read dependency step files (01-discuss, 02-explore, 03-prototype) before creating spec.md.
- All file paths in Impact section must be relative to project root.
- Do not wrap shell commands in backticks inside artifact text.
- Do not write application code during this step.
- If context is critically unclear, ask the user — but prefer making reasonable decisions to keep momentum.

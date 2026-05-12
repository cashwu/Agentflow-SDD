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

## Question Framework

Use the following categories to probe the user. Do not treat these as a checklist to rush through — ask follow-up questions when answers are vague, contradictory, or reveal hidden complexity. Skip categories only when the user's input already covers them with enough specificity.

### 1. 動機與觸發點

- 為什麼要做這件事？觸發的原因是什麼（bug、用戶反饋、技術債、新需求、法規）？
- 為什麼是現在？有沒有時間壓力或外部 deadline？
- 不做會怎樣？影響範圍和嚴重程度？

### 2. 目標與非目標

- 具體要達成什麼結果？怎樣算「做完」？
- 可觀測的成功指標是什麼（行為改變、數據變化、錯誤消失）？
- 明確不做什麼？哪些看起來相關但刻意排除？

### 3. 用戶場景與邊界

- 誰是目標用戶？有幾種不同角色或使用情境？
- 描述主要使用情境的完整流程：用戶從哪裡開始、做什麼操作、期望看到什麼結果？
- 錯誤情境與邊界情況：輸入異常、網路中斷、資料不存在、權限不足時應該怎樣？
- 怎樣的行為算「正確」？有沒有現有的正確/錯誤行為可以參照？

### 4. 約束與依賴

- 技術約束：框架版本、平台限制、API 相容性、效能要求？
- 這個改動依賴什麼？其他系統、服務、團隊、或未完成的工作？
- 這個改動會影響什麼既有功能？有沒有下游消費者或整合點？
- 有沒有不能改動的部分（public API、資料格式、向下相容）？

### 5. 假設與開放問題

- 列出你基於用戶輸入做出的假設，明確請用戶確認或修正。
- 還有什麼不確定的？需要誰來回答？能否在不確定的情況下安全推進？

## Interaction Style

### One question at a time

Do not dump all questions from the framework at once. Ask the most important one, listen, then follow up. Let the conversation breathe. If the user's initial description or previous answers already cover a question, skip it.

### Assumptions mode vs Interview mode

After reading the user's input, decide which mode fits:

- **Assumptions mode** — the user gave enough context to form opinions. List 3-5 assumptions with your reasoning and evidence, then ask: "Which of these are wrong?" For each correction, ask ONE focused follow-up.
- **Interview mode** — the user gave minimal input. Ask targeted questions one at a time from the Question Framework.

Announce which mode you picked and why.

### Push for specifics

When the user gives a vague answer, do not accept it — dig deeper. The goal is to reach decisions concrete enough to implement.

```
User: "需要處理各種 edge cases"
Bad:  "好的，我們會注意 edge cases。"
Good: "具體是哪些情況？例如資料為空、超過上限、並發寫入、
       還是格式錯誤？不同情況的處理策略可能完全不同。"
```

```
User: "效能要好一點"
Bad:  "了解，我們會注意效能。"
Good: "你的基準是什麼？回應時間 < 200ms？支撐 1000 QPS？
       還是記憶體佔用不超過某個值？這會影響架構選擇。"
```

```
User: "要跟現有的系統整合"
Bad:  "好的，我們會考慮整合。"
Good: "哪些系統？是 API 串接、資料庫共享、還是事件驅動？
       現有的整合點在哪？有文件或現成的 client 嗎？"
```

### No empty validation

Never pad responses with hollow affirmations like "That's a great idea" or "That could work." If you agree, say why. If you disagree, say why. Empty agreement is worse than honest pushback.

### Respect the user's pace

If the user signals impatience ("直接做就好", "不用想太多", "往下走吧"):

1. **First time**: briefly flag if there's an important unresolved question — one sentence, not a lecture.
2. **If they push again**: respect it. Skip remaining questions, go straight to summarizing with the best conclusions you can form. Mark uncovered areas as assumptions.

## Workflow

1. Read the user's input and scout the codebase (grep/glob for related files) to decide between Assumptions mode or Interview mode.
2. In Assumptions mode: present assumptions with evidence and ask what's wrong. In Interview mode: ask targeted questions one at a time from uncovered Question Framework categories.
3. When answers are vague or surface-level, push for specifics to reach actionable detail. Do not accept "handle edge cases" without naming the cases.
4. After sufficient coverage, summarize the discuss outcome: goal, non-goals, assumptions (with confirmation status), open questions, observable success examples, user scenarios, constraints, dependencies, and likely affected specs/code.
5. If deeper structured discussion is useful, delegate to `$spectra-discuss`, then capture the result in the Agentflow files.
6. Run review/rating/fix for up to 3 rounds. Each round MUST spawn a fresh sub-agent for review and rating — never review inline or reuse a prior round's sub-agent.
7. Do not proceed to `$sdd-explore` until the step passes.

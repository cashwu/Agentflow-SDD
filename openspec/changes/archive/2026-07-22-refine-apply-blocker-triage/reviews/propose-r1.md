# Cash Propose Review — Round 1

## Reviewer Findings

過濾後（confidence filter：捨棄 `confidence < 50`；`[50, 80)` 降為 Suggestion；僅 `>= 80` 保留 Critical/Warning）無任何 Critical 或 Warning 存活。以下兩筆由 Reviewer B 提出、原分類 Warning、confidence 落在 `[50, 80)`，依過濾器降為 Suggestion（非 blocking）：

### Suggestion

- **severity**: Suggestion（原 Warning）
  - **confidence**: 58
  - **layer**: design
  - **location**: design.md D1 ／ specs/cash-skill-workflows/spec.md 兩分支 scenarios
  - **summary**: 兩分支非互斥——暫停分支的 open-question 觸發條件（Z）與繼續分支條件獨立，機制替換可同時滿足兩分支而無 precedence。
  - **recommendation**: 收斂 Z 使其僅指「解答可能改變 contract／範圍」的問題，並加 precedence：繼續分支條件全部成立時，保留 contract 的內部手段選擇以記 `deviation` 解決、不暫停。
  - **來源**: Reviewer B（Quality）
  - **disposition**: new

- **severity**: Suggestion（原 Warning）
  - **confidence**: 55
  - **layer**: design
  - **location**: design.md D2 ／ proposal.md ／ spec.md
  - **summary**: D2 宣稱與 circuit breaker「逐字對齊」，但 prose 以中文翻譯呈現該邊界，實作者無明確目標、無測試防止兩邊界字串漂移。
  - **recommendation**: 於 Step 7 prose 逐字內嵌 circuit breaker 的英文片語（比照 SHALL／quoted text 慣例），使「逐字對齊」名實相符且可被 Reviewer A 稽核。
  - **來源**: Reviewer B（Quality）
  - **disposition**: new

Reviewer A 提出的兩筆（`**OR**` marker 無前例，confidence 45；marker 僅保護 anchor 而非判準文字，confidence 40）皆 `< 50`，依過濾器完全捨棄，不列入本區。

## Rating

- 過濾後累積 blocking 集合 Critical 數：0
- 過濾後累積 blocking 集合 Warning 數：0
- 非 blocking triaged finding 數：2（B-F1、B-F2，均降為 Suggestion）
- `critical_gap`: false
- `round_type`: full
- 理由：兩位 full-round reviewer 獨立完成；Reviewer A 已對 design 的 code-facing 主張逐項對照實際程式（circuit breaker 逐字存在、grader hooks 存在、cash-apply 不在 `divergent_skills`、現行 Pause if 恰四條），全部成立、無 Adherence 違規。Reviewer B 未發現與 circuit breaker 的相反處置、governed-contract RED→GREEN wiring 健全、docs（CASH-SKILLS.md／AGENTS.md）無需同步、shared review-block 不受影響。過濾後無 blocking Critical／Warning，符合 pass 條件。

## Fix Actions

雖本輪已 pass，主 agent 選擇修掉兩筆降級後的 Suggestion（B-F1、B-F2），因其直接強化本 change 的核心賣點「機械式地分辨」的 determinism 與 auditability，且成本低：

- **B-F1（分支互斥／precedence）** — 修改檔案：`design.md`、`specs/cash-skill-workflows/spec.md`。design D1 暫停分支第 3 條改為「其解答可能改變 contract 或範圍」的 open question，並新增「分支優先（precedence）」段落；spec requirement 陳述加入「兩分支 MUST 互斥」與內部手段選擇以 `deviation` 解決的規則，並新增兩個 scenario（open question 暫停、保留 contract 的內部選擇不暫停）。
- **B-F2（逐字對齊名實相符）** — 修改檔案：`design.md`、`specs/cash-skill-workflows/spec.md`、`tasks.md`。design D2 改為要求 Step 7 prose 逐字內嵌英文片語 `a synchronization primitive, identity/generation type, or state machine not defined in design.md`；D1 兩處條件、spec requirement 陳述與 scenario 1／4、tasks 2.1 同步改用該 verbatim 片語（fix propagation：grep 全 artifact 確認片語拼寫一致）。
- **A-F1（`**OR**` marker）** — 原 finding confidence 45 已捨棄；順帶於重寫 spec scenarios 時移除無前例的 `**OR**` step marker，改為標準 WHEN/THEN scenario。
- **A-F2（marker 僅保護 anchor）** — 原 finding confidence 40 已捨棄，不採納：本 change 沿用既有 `<!-- MARKER -->` 保護慣例；判準文字的長存由 spec requirement 與 scenario 承擔，非由測試 literal。
- **Pre-round mechanical self-check** — 修正 design D3：將抽象描述的 literal 明確命名為 `<!-- BLOCKER-TRIAGE -->`，與 tasks 的 identifier 對齊（identifier cross-grep）。
- 修正後重跑 mechanical self-check（comment lint／count／identifier cross-grep／spec title-identity／signal check 全通過）並重跑 `spectra validate refine-apply-blocker-triage`（通過）。

## Decision

passed

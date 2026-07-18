# Cash Propose Review — Round 2

## Reviewer Findings

### Critical

(none)

### Warning

1. **severity:** Warning  
   **confidence:** 100  
   **layer:** design  
   **location:** `specs/cash-skill-workflows/spec.md`「Drift is preserved unless force is explicit」、「Drift conflicts before writes」、「Force replaces only managed destinations」  
   **summary:** equal-version integrity precedence 未傳播到通用 drift/force scenarios，讓同一輸入同時要求 execution failure 與 conflict/update。  
   **recommendation:** equal-version drift 要求 source hashes 先符合 receipt，force-success 要求所有 source/receipt/filesystem validation 已成功。  
   **disposition:** unresolved-prior  
   **reviewer source:** Reviewer V — Verification

2. **severity:** Warning  
   **confidence:** 100  
   **layer:** design  
   **location:** `design.md`「使用單一來源版本與目標 receipt」與「Risks / Trade-offs」；`specs/cash-skill-workflows/spec.md` version governance scenarios；`tasks.md` 3.2  
   **summary:** 只比較 clean checkout 的 `HEAD^` 會在後續 unrelated commit 後漏掉更早的 same-version source change。  
   **recommendation:** 沿 first-parent history 找到目前 version 的 introduction commit，將目前 inventory 綁定該穩定基準。  
   **disposition:** unresolved-prior  
   **reviewer source:** Reviewer V — Verification

3. **severity:** Warning  
   **confidence:** 100  
   **layer:** design  
   **location:** `design.md`「使用者 registry 是手動維護的資料，不是排程」；`specs/cash-skill-workflows/spec.md` control-character scenarios；`tasks.md` 1.2  
   **summary:** line-delimited registry 無法辨識 stored LF 是 path data 或合法 record delimiter，existing-registry LF rejection 不可實作。  
   **recommendation:** 保證 mutation input 拒絕 LF，existing registry 只驗證 LF 分隔後仍保留的 control characters；若要求 persisted LF 識別則需更換格式。  
   **disposition:** unresolved-prior  
   **reviewer source:** Reviewer V — Verification

4. **severity:** Warning  
   **confidence:** 100  
   **layer:** design  
   **location:** `specs/cash-skill-workflows/spec.md`「First-install failure remains receipt-less」；`design.md`「失敗模式」  
   **summary:** Round 1 W3 修正仍無條件要求下一次 conflict；若 runtime error 發生於第一個 managed write 前，下一次仍應是 clean install。  
   **recommendation:** conflict path 加入至少一個 write 已持久化的前置條件，另定義 zero-write normal retry。  
   **disposition:** fix-introduced  
   **introduced_by:** Round 1 Fix Action W3  
   **reviewer source:** Reviewer V — Verification

### Suggestion

(none)

## Rating

- Cumulative blocking Critical: 0
- Cumulative blocking Warning: 4
- Non-blocking triaged findings: 0
- `critical_gap`: `false`
- `round_type`: `micro`
- rationale: Reviewer V 已確認 W3–W7 解決並自 cumulative blocking set 移除；W1、W2、W8 仍 unresolved，且 W3 修正引入一個新的 blocking member，因此需再修正並進入下一個 micro round。

## Fix Actions

- Verified resolution removal：W3 經 Reviewer V 確認 prior-receipt 與 receipt-less first-install 已分流；但其修正引入的新 zero-write 缺口另列 finding 4。
- Verified resolution removal：W4 經 Reviewer V 確認 task 2.2 已移除 `[P]` 並明示依賴 2.1 protocol。
- Verified resolution removal：W5 經 Reviewer V 確認 absent config/registry 四種模式已定義。
- Verified resolution removal：W6 經 Reviewer V 確認 leading-zero 與任意長度排序契約及 fixtures 已完整傳播。
- Verified resolution removal：W7 經 Reviewer V 確認四種模式 existing registry validation 與零寫入失敗已定義。
- W1：修改 `specs/cash-skill-workflows/spec.md` 與 `tasks.md`，讓 equal-version drift 先要求 source/receipt 一致，force-success 先要求所有 validation 成功。
- W2：修改 `design.md`、`specs/cash-skill-workflows/spec.md`、`tasks.md`，以 same-version first-parent introduction commit 作穩定基準，並加入 unrelated-commit fixture。
- W8：修改 `design.md`、`specs/cash-skill-workflows/spec.md`、`tasks.md`，把保證限縮為 mutation input 拒絕 LF、existing LF-delimited records 驗證 retained control characters，並記錄 manual editor 的逐列 authority。
- Finding 4：修改 `design.md`、`specs/cash-skill-workflows/spec.md`、`tasks.md`，將 first-install partial failure 分成 persisted-write conflict 與 zero-write clean retry。
- 分類修正：Reviewer V findings 1 與 4 回傳的 `layer: spec` 不是合法 layer 值，且都涉及 behavior，已修正為 `layer: design`；原始值、修正值與對應 spec behavior 證據記錄於此。
- Post-fix mechanical self-check：annotation counts 為 0/0、spec forbidden-word scan 無結果、修正 identifiers 已跨 proposal/design/spec/tasks grep、`git diff --check` 通過；所有 open signals 均無 `check` 欄位。
- Post-fix validation：`spectra validate add-versioned-cash-skill-batch-update` 通過。

## Decision

next_round

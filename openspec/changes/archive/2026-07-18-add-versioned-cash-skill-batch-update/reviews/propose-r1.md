# Cash Propose Review — Round 1

## Reviewer Findings

### Critical

(none)

### Warning

1. **severity:** Warning  
   **confidence:** 96  
   **layer:** design  
   **location:** `design.md`「版本優先序與首次接管」；`specs/cash-skill-workflows/spec.md`「Equal target is current」與「Drift conflicts before writes」  
   **summary:** equal-version branch 未區分 source bytes 被改但未 bump 與 target drift，`--force` 可把不同 bundle 發布成相同版本。  
   **recommendation:** equal version 先驗證 source hashes 對 receipt；不一致時 execution fail 且 force 不得繞過，另加 fixture。  
   **reviewer source:** Reviewer A — Adherence

2. **severity:** Warning  
   **confidence:** 100  
   **layer:** design  
   **location:** `design.md`「使用單一來源版本與目標 receipt」與「Risks / Trade-offs」；`specs/cash-skill-workflows/spec.md`「Cash skill bundle version and target receipt」；`tasks.md` 3.2  
   **summary:** 文件、literal grep 與人工 review 無法保證 canonical skill bytes 改變時 bundle version 必定提升。  
   **recommendation:** 加入可比較 worktree/index 與 committed baseline 的 version governance，忘記 bump 必須 fail loud。  
   **reviewer source:** Reviewer B — Quality

3. **severity:** Warning  
   **confidence:** 100  
   **layer:** design  
   **location:** `specs/cash-skill-workflows/spec.md`「Receipt is published after skill files」；`design.md`「失敗模式」  
   **summary:** runtime write failure scenario 無條件依賴 prior receipt，但首次安裝沒有 prior receipt，原 acceptance criteria 不可達成。  
   **recommendation:** 分開有 prior receipt 的 upgrade failure 與 receipt-less first-install failure，並各自定義下一次 conflict path。  
   **reviewer source:** Reviewer A — Adherence

4. **severity:** Warning  
   **confidence:** 100  
   **layer:** text  
   **location:** `tasks.md` 2.2  
   **summary:** updater integration 依賴 2.1 installer 的 stable result/exit protocol，因此 2.2 的 `[P]` 標記不成立。  
   **recommendation:** 移除 2.2 的 `[P]` 並明示 protocol dependency。  
   **reviewer source:** Reviewer A — Adherence

5. **severity:** Warning  
   **confidence:** 91  
   **layer:** design  
   **location:** `design.md`「使用者 registry 是手動維護的資料，不是排程」；`specs/cash-skill-workflows/spec.md`「Manual cash project registry」  
   **summary:** absent config/registry 對 register、unregister、list、all 的 first-use 行為未定義。  
   **recommendation:** 定義 register 可安全建立的 paths，以及其餘三種模式對 missing registry 的 empty-state/no-write 行為與 fixtures。  
   **reviewer source:** Reviewer A — Adherence

6. **severity:** Warning  
   **confidence:** 100  
   **layer:** design  
   **location:** `design.md`「使用單一來源版本與目標 receipt」；`specs/cash-skill-workflows/spec.md`「Cash skill bundle version and target receipt」；`tasks.md` 1.1  
   **summary:** strict SemVer 未禁止 leading zero，也未定義超過 platform numeric range 的安全排序。  
   **recommendation:** 每段限制為 `0|[1-9][0-9]*`，以 digit length + lexicographic compare 排序並補 boundary fixtures。  
   **reviewer source:** Reviewer B — Quality

7. **severity:** Warning  
   **confidence:** 100  
   **layer:** design  
   **location:** `design.md`「使用者 registry 是手動維護的資料，不是排程」；`specs/cash-skill-workflows/spec.md`「Manual cash project registry」；`tasks.md` 1.2  
   **summary:** existing registry 的完整 read/schema validation 只明定於 list/all，register/unregister 可能重寫損壞內容。  
   **recommendation:** 四種模式都先完整驗證 existing registry，malformed/unreadable 時零寫入失敗。  
   **reviewer source:** Reviewer B — Quality

8. **severity:** Warning  
   **confidence:** 95  
   **layer:** design  
   **location:** `design.md`「使用者 registry 是手動維護的資料，不是排程」；`specs/cash-skill-workflows/spec.md`「Manual cash project registry」；`tasks.md` 1.2  
   **summary:** line-oriented registry 未拒絕含 CR/LF 等 control characters 的合法 filesystem path，可能注入額外 target。  
   **recommendation:** 拒絕 input 與 stored entries 中的 ASCII control characters，並補零寫入 fixture。  
   **reviewer source:** Reviewer B — Quality

### Suggestion

(none)

## Rating

- Cumulative blocking Critical: 0
- Cumulative blocking Warning: 8
- Non-blocking triaged findings: 0
- `critical_gap`: `false`
- `round_type`: `full`
- rationale: 8 個高信心 Warning 全部在第一輪進入 cumulative blocking set；雖已完成對應修正，仍需 fresh Reviewer V 驗證每個 member 才能從集合移除，因此本輪不得通過。

## Fix Actions

- W1：修改 `design.md`、`specs/cash-skill-workflows/spec.md`、`tasks.md`，加入 equal-version source/receipt integrity guard、force 不可繞過與專屬 fixture。
- W2：修改 `design.md`、`specs/cash-skill-workflows/spec.md`、`tasks.md`，加入 worktree/index 對 `HEAD` 與 clean checkout 對 first parent 的 version baseline governance，runtime 維持不讀 Git。
- W3：修改 `design.md`、`specs/cash-skill-workflows/spec.md`、`tasks.md`，把 partial write recovery 分成有 prior receipt 與首次 receipt-less 兩條分支。
- W4：修改 `tasks.md`，移除 task 2.2 的 `[P]` 並明示依賴 task 2.1 stable protocol。
- W5：修改 `design.md`、`specs/cash-skill-workflows/spec.md`、`tasks.md`，定義 absent config/registry 的四種模式與零狀態建立規則。
- W6：修改 `design.md`、`specs/cash-skill-workflows/spec.md`、`tasks.md`，禁止 leading zero，採任意長度 digit-string ordering 並加入 fixtures。
- W7：修改 `design.md`、`specs/cash-skill-workflows/spec.md`、`tasks.md`，要求所有四種模式完整驗證 existing registry，損壞或 unreadable 時零寫入。
- W8：修改 `design.md`、`specs/cash-skill-workflows/spec.md`、`tasks.md`，拒絕 registry input/entry 的 ASCII control characters 並加入 injection fixture。
- 分類修正：Reviewer A finding 3 與 Reviewer B finding 2 原標為 `text`，其修正會改變 runtime/acceptance behavior，依 filter 規則改為 `design`；Reviewer A finding 4 維持 `text`。
- Post-fix mechanical self-check：annotation counts 為 0/0、spec forbidden-word scan 無結果、requirement/scenario headings 正常、identifier propagation grep 已涵蓋所有修正概念、`git diff --check` 通過；所有 open signals 均無 `check` 欄位，因此沒有 deterministic check command。
- Post-fix validation：`spectra validate add-versioned-cash-skill-batch-update` 通過。

## Decision

next_round

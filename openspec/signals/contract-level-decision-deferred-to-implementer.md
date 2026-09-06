---
id: contract-level-decision-deferred-to-implementer
type: recurring-finding
status: open
occurrences: 4
first_seen: 2026-07-25
last_seen: 2026-09-05
links:
  - openspec/changes/align-cli-skill-contracts/reviews/propose-r1.md
  - openspec/changes/rightsize-cash-skills/reviews/propose-r1.md
  - openspec/changes/add-repo-vendored-cash-bundle/reviews/propose-r1.md
  - openspec/changes/add-host-derived-round-lint/reviews/propose-r1.md
---

# Contract-level decision deferred to implementer

A design names a mechanism to change but leaves the semantics of the replacement undefined, so the implementer must make a contract-level decision mid-task. The acceptance criterion is written as the absence of the old defect rather than the presence of the newly defined behavior, which lets any replacement pass.

## Occurrences

- 2026-07-25 — align-cli-skill-contracts — cash-propose round 1 — design 要求改寫 Codex 變體被剝空的 plan 檔敘述，但未定義無 plan 目錄環境下引數的解析語意；驗收只斷言不存在空 code span，無法證明改寫後語意完整。
- 2026-07-26 — rightsize-cash-skills — cash-propose round 1 — 任務只寫「把回覆語言規則從四處收斂為一處」而未指名是哪四處，其中一處承載 requirement 標題逐位元組相符契約，等同把契約層級取捨推給實作者。
- 2026-07-28 — add-repo-vendored-cash-bundle — cash-propose round 1 — vendored bundle 遇到已存在但無 receipt／manifest 的完全相同檔案時，初稿只定義「不得靜默覆寫」，未決定應採用或報 conflict；修正為 exact adoption 合法，partial 或不同內容才 fail closed，避免由實作者臨場選擇公開行為。

- 2026-09-05 — add-host-derived-round-lint — cash-propose round 1 — gate 的判定對象集合未定義。全部規則都寫「每個 round file」，但沒有任何 artifact 說明什麼檔案算 round file，而同一個 `reviews/` 目錄下必然還有 `loop-ledger.tsv` 與可選的 `accepted-risks.md`。實作者若取目錄下全部 `.md`，`accepted-risks.md` 會使結構 gate 永久 `fail`；由於這是阻擋型 Stop hook，後果是每個 turn 都被擋住。同一個未定義也影響編號抽取與 skill 分組。判定對象的成員資格是 contract 層決定，不能留給實作。

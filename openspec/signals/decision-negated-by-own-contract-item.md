---
id: decision-negated-by-own-contract-item
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-26
last_seen: 2026-07-26
links:
  - openspec/changes/bootstrap-openspec-config-on-install/reviews/propose-r1.md
---

# Contract item negates its own decision

A design decision rejects a specific hazard and states why, then an Implementation Contract item in the same document defines the artifact in terms that reintroduce exactly that hazard. Because the contract item is the operational text an implementer follows, the decision's rationale is silently overridden. The pairing is easy to miss in review: read alone, each half is reasonable; only reading them together exposes the negation. It compounds when no task asserts the property the decision protects, so an implementation that violates the decision still passes every declared verification.

## Occurrences

- 2026-07-26 — bootstrap-openspec-config-on-install — cash-propose round 1 — 決策 D2 明文否決「從 source repository 複製 `openspec/config.yaml`」，理由是那會把 source 專案自身的 `context` 與 `rules` 帶進每個 target、並讓輸出取決於可變狀態；同一份 design 的 Implementation Contract 卻把常數定義為「與本 repository 的 `openspec/config.yaml` 逐 byte 相同」——而該檔正是 project-owned 且可變，維護「逐 byte 相同」就是把被否決的危害搬回來。tasks 對新建檔案只斷言 regular file、`0644`、可解析，因此「直接複製 source 檔案」的實作會全部綠燈。修法是改以常數自身的性質定義（LF 結尾、首行 `schema: spec-driven`、其餘只有空行與 full-line 註解、parse 後 `context` 為空、`rules` 為空），並加上機械斷言。

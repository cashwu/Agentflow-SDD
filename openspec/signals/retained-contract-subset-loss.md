---
id: retained-contract-subset-loss
type: recurring-finding
status: open
occurrences: 7
first_seen: 2026-07-18
last_seen: 2026-07-26
links:
  - openspec/changes/fork-spectra-skills-to-cash/reviews/propose-r1.md
  - openspec/changes/migrate-cash-project-guidance/reviews/propose-r1.md
  - openspec/changes/replace-spectra-cli-with-cash-cli/reviews/propose-r1.md
  - openspec/changes/rightsize-cash-skills/reviews/propose-r2.md
  - openspec/changes/rightsize-cash-skills/reviews/apply-r1.md
  - openspec/changes/harden-spec-trace-path-extraction/reviews/propose-r1.md
  - openspec/changes/rightsize-cash-apply-tdd-discipline/reviews/apply-r1.md
---

# Retained contract subset loss

A migration replaces an owned workflow or capability but carries forward only a summary or subset of behavior that the change claims to preserve, silently dropping normative branches from the replacement contract.

## Occurrences

- 2026-07-18 — fork-spectra-skills-to-cash — spectra-propose-plus round 1 — 初稿移除 36 條 plus requirements，卻只摘要保留 quality gate 與 cash-commit allowlist；修正後完整搬移 19 條 retained gate requirements，以及 tracked sources、customizations、archive output 與 explicit spec-sync branches。
- 2026-07-22 — migrate-cash-project-guidance — cash-propose round 1 — 初稿只保留向量模型fallback的標題與摘要語意，未鎖定使用者指定的完整Markdown；修正後兩個canonical blocks逐byte包含全文並有完整block comparison task。
- 2026-07-23 — replace-spectra-cli-with-cash-cli — cash-propose rounds 1–6 — 自建Cash CLI初稿遺漏consumer JSON欄位、touched來源追蹤、archive trace、fresh/legacy installer branches與receipt-less adoption；多數已補齊，但receipt-less 24-skill adoption與touched單一來源仍是abort obligation。
- 2026-07-26 — rightsize-cash-skills — cash-propose round 2／4 — fallback 收斂與紀律段落合併的封閉保留清單，會刪掉 `cash-ingest:261` 的 `Then STOP — do not continue` 停止契約，以及 `cash-apply:281` 的不相關缺陷 `open-question` 紀律與 `:298` 的 `task done` 前 gating；修正後改以判定條件排除並把保留清單由兩條擴為五項。
- 2026-07-26 — rightsize-cash-skills — cash-apply round 1 — 精簡 Rationalization Table 時，`cash-apply`、`cash-audit`、`cash-ingest` 遺失數項宣稱保留的 contract 子集；修正後將測試義務、不安全預設 migration、plan sufficiency、completed task scope 與 requirement/scenario 同步規範整合回具體流程。

- 2026-07-26 — harden-spec-trace-path-extraction — cash-propose round 1 — delta 的 MODIFIED block 只重述 master requirement 的第一段（58 行），遺漏其餘段落與全部 8 個既有 Scenario（master 共 109 行）；`_merge` 以整塊取代，sync 會直接從 master spec 刪除它們。修法是以程式方式自 master 逐 byte 取出完整內容重建 delta，並以 `blk[:first] in delta` 與 `blk[first:] in delta` 機械驗證保留面。
- 2026-07-26 — rightsize-cash-apply-tdd-discipline — cash-apply round 1 — canonical TDD bug-fix branch 只要求先建立 failing reproduction，遺漏修正後轉綠與保留 regression evidence 的完整生命週期；修正後由同一 branch 明定 minimal fix、pass 與 regression evidence。

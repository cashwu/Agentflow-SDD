---
id: overlapping-classification-without-precedence
type: recurring-finding
status: open
occurrences: 4
first_seen: 2026-07-26
last_seen: 2026-08-22
links:
  - openspec/changes/rightsize-cash-skills/reviews/propose-r1.md
  - openspec/changes/bootstrap-openspec-config-on-install/reviews/propose-r1.md
  - openspec/changes/support-multi-file-skill-payload/reviews/propose-r2.md
  - openspec/changes/default-spec-sync-on-archive/reviews/propose-r1.md
  - openspec/changes/default-spec-sync-on-archive/reviews/propose-r2.md
---

# Overlapping classification without precedence

A change defines mutually exclusive handling categories and requires every edit to fall into exactly one, but some content legitimately qualifies for two and the design gives no precedence rule or ordering. The implementer must invent a resolution, and different choices produce materially different results.

## Occurrences

- 2026-07-26 — rightsize-cash-skills — cash-propose round 1 — 設計規定「一段文字不得同時以兩個層次處理」，但 `Common false positives` 同時是名稱同步（層次三）與逐字搬移（層次二）的對象、`Round file language` 同時是重複收斂（層次一）與搬移（層次二）的對象，未給出順序或歸屬裁決。
- 2026-07-26 — bootstrap-openspec-config-on-install — cash-propose round 1 — 「其餘 managed inventory 一致時 MUST 分類為 `current` 且零寫入」與新增的「缺 `openspec/config.yaml` 時 MUST 建立」對同一個 target（已安裝但使用者刪除該檔）同時成立，兩條 MUST 重疊而無優先序。修法是在 scenario 的條件補「且該檔存在」，並在條文明寫建立優先於 `current` 的零寫入契約，同時把「刻意刪除會被還原」記入 Risks。
- 2026-07-26 — support-multi-file-skill-payload — cash-propose round 2 — delta spec 第一條 requirement 的「present 必須是零個或全部」與第三條的 receipt-less adoption 例外，對同一輸入給出相反結論且未定義優先序。
- 2026-08-22 — default-spec-sync-on-archive — cash-propose rounds 1–2 — 同一個重疊機制在兩個抽象層各犯一次。round 1：「無 delta specs 時 MUST NOT 帶 `--skip-specs`」與「明確要求跳過時 MUST 帶上 `--skip-specs`」在交集情境同時適用，修法是改寫為兩條有先後的互斥條件。round 2：為修前者而導入的三值判定結果 `synced`／`skipped`／`no delta specs` 又在同一交集重疊，而被釘進 skill 的逐字文字寫的是 `exactly one of` 卻無排序，修法是改為 `by evaluating in order`。教訓是修掉某一層的重疊後，MUST 檢查該修正引入的衍生分類是否在同一輸入上重演。

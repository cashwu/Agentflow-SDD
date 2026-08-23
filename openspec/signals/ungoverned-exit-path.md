---
id: ungoverned-exit-path
type: recurring-finding
status: open
occurrences: 4
first_seen: 2026-07-16
last_seen: 2026-08-23
links:
  - openspec/changes/converge-plus-review-loop/reviews/propose-r1.md
  - openspec/changes/guard-task-state-integrity/reviews/propose-r1.md
  - openspec/changes/guard-task-state-integrity/reviews/apply-r1.md
  - openspec/changes/guard-task-state-integrity/reviews/apply-r2.md
---

# Ungoverned exit path

A change adds a fallback or escape route for a gated obligation, but the fallback routes around the governance (consent, seeding, tracing) that the primary path enforces — creating an unconsented exit precisely where the gate matters most. The fix is routing fallbacks to the bucket that preserves the obligation, never to the one that discharges it.

## Occurrences

- 2026-07-16 — converge-plus-review-loop — spectra-propose-plus round 4 — 「無法取得同意時退回 signals 桶」讓 blocking finding 經無同意路徑離開 change 義務且不進 re-run 種子，形成第三出口；修正為退回義務桶（bucket 1）。
- 2026-08-22 — guard-task-state-integrity — cash-propose rounds 1、2 — 新機制引入了 design 與 delta spec 都未定義的失敗出口：對齊把 `_task_entries()` 帶進讀取路徑，使 `task_id_invalid` 成為 `touched ensure`／`touched record`／`archive` 的新失敗模式（一份標籤重複的 `tasks.md` 會讓 `archive --no-validate` 從成功轉為失敗）；同時 D3 的 fail closed 在多個 skill 造成硬停止卻無任何復原指引，而唯一的手工出路又與既有 Guardrails 字面衝突。

- 2026-08-22 — guard-task-state-integrity — cash-apply round 1 — `touched_invalid` 同時代表 renamed 與 removed task，但 skill 唯一提供的「同步為 current description」復原方式只適用 renamed task；removed task 沒有 current description，仍會停在無可執行出口的失敗路徑。

- 2026-08-23 — guard-task-state-integrity — cash-apply round 2 — ingest 後雖已定義 removed-task 恢復 contract，skill 卻以 `/cash-ingest <name>`／`$cash-ingest <change-name>` 導向該出口；cash-ingest 會把 argument 解讀成 plan file，使名義上的復原路徑仍不可執行。修正為無參數 invocation，並把目前錯誤與 change name 作為 conversation context。

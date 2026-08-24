---
id: red-executed-after-production-edit
type: recurring-finding
status: open
occurrences: 2
first_seen: 2026-08-24
last_seen: 2026-08-24
links:
  - openspec/changes/strengthen-cash-tdd-evidence/reviews/propose-r1.md
  - openspec/changes/strengthen-cash-tdd-evidence/reviews/apply-r1.md
---

# RED executed after a production edit

A TDD task says RED must be observed before any production edit, but its own ordered steps modify production metadata, configuration, or runtime bytes before running the primary target. The test may still fail afterward, yet it no longer proves the implementation began from an observed RED baseline. Treat every delivery-side edit covered by the task as a production edit for ordering purposes: create and execute the test first, verify the named failure marker, and only then change version metadata or implementation files.

## Occurrences

- 2026-08-24 — strengthen-cash-tdd-evidence — cash-propose round 1 — task 1.1 originally bumped `cash-skills.version`與`installer.py` before observing the primary RED, contradicting its own any-production-edit gate；修正為先新增並執行resource test取得具名失敗，再做version與managed resource edits。
- 2026-08-24 — strengthen-cash-tdd-evidence — cash-apply round 1 — `cash-debug` Phase 4 改寫後，編號步驟無條件以 `1. **Make the minimum change**` 起頭、把 primary verification target 排在其後，等於在 `tdd: true` 且命中 canonical 前兩分支時要求先做 production edit，與同一 change 剛強化的 any-production-edit gate 互斥；修正為把編號清單明訂為 `tdd: false` 序列，並在其前交由 fetched `instruction` 擁有 ordering。

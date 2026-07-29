---
id: post-preflight-snapshot-revalidation-missing
type: recurring-finding
status: open
occurrences: 5
first_seen: 2026-07-22
last_seen: 2026-07-29
links:
  - openspec/changes/guard-target-receipt-version-control/reviews/propose-r1.md
  - openspec/changes/migrate-cash-project-guidance/reviews/propose-r1.md
  - openspec/changes/replace-spectra-cli-with-cash-cli/reviews/propose-r1.md
  - openspec/changes/replace-spectra-cli-with-cash-cli/reviews/apply-r3.md
  - openspec/changes/add-repo-vendored-cash-bundle/reviews/apply-r1.md
---

# Post-preflight snapshot revalidation missing

A mutating workflow builds replacement content from a preflight snapshot but does not revalidate the destination bytes before publication, allowing a concurrent edit to be overwritten even when the final replace itself is atomic.

## Occurrences

- 2026-07-22 — migrate-cash-project-guidance — cash-propose round 1 — Guidance migration可能以舊snapshot覆蓋preflight後的新project content；補上temporary creation與atomic publish前的完整bytes revalidation及lost-update fixtures。
- 2026-07-23 — replace-spectra-cli-with-cash-cli — cash-propose round 1 — 多檔runtime/skill/archive publication初稿只有單檔atomic replace；補上workspace lock、publication前snapshot revalidation、journal、rollback與recovery。
- 2026-07-24 — replace-spectra-cli-with-cash-cli — cash-apply rounds 3–5 — Installer 曾在取得 lock 後沿用 stale source／target plan，且 source/target config prerequisite 未完整重驗；補上完整 snapshots、持鎖後 prerequisite validation 與 lock-wait regressions。

- 2026-07-24 — guard-target-receipt-version-control — cash-propose round 1 — 新增的 `.gitignore` 附加寫入未納入既有 installation inputs 與 revalidation 集合，plan 與 publication 之間的外部修改會被 full-file replace 靜默覆寫。
- 2026-07-29 — add-repo-vendored-cash-bundle — cash-apply round 1 — `--vendor` 在取得exclusive lock後沿用鎖前source／target plan但未與原snapshot對回，可能覆寫並行guidance變更或發布digest不符的runtime；補上鎖前snapshots、持鎖重驗與source record digest核對。

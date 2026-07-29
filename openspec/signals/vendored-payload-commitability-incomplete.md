---
id: vendored-payload-commitability-incomplete
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-28
last_seen: 2026-07-28
links:
  - openspec/changes/add-repo-vendored-cash-bundle/reviews/propose-r1.md
---

# Vendored payload commitability check is incomplete

一個 publication command 宣稱產生可提交的 repo-vendored bundle，卻只檢查 mode marker 是否被 Git ignore，沒有逐一檢查實際 payload。結果 manifest 可追蹤而 launcher、runtime 或 metadata 被 repository、info 或 global exclude 排除，maintainer 看到成功但 teammate clone 到不完整 bundle。

修法是先列舉本次計畫發布的完整 path set，逐一要求它們已被追蹤或未被任何有效 ignore／exclude 規則排除，再允許寫入。

## Occurrences

- 2026-07-28 — add-repo-vendored-cash-bundle — cash-propose round 1 — 初稿只要求 `.cash-skills/manifest.tsv` 不被 ignore；修正為對所有 planned publication paths 檢查 tracked-or-not-ignored，涵蓋 repository、`.git/info/exclude` 與 global excludes。

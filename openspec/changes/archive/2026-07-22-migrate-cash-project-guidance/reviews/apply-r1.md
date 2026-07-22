# Cash Apply Review — Round 1

## Reviewer Findings

### Critical

- severity: Critical
  confidence: 100
  layer: design
  location: `install-cash-skills.fish:972-1011`
  summary: Guidance temporary file 的建立、清理與 publication 仍透過可被替換的 parent pathname；revalidation 後的 parent swap 可能讓 cleanup 或 atomic replace 觸及 target 外同名路徑。
  recommendation: 先透過 `$cash-ingest migrate-cash-project-guidance` 定義與已驗證 parent directory identity 綁定的 directory-FD primitive，例如 no-follow `openat`／`renameat`／`unlinkat`，再實作並加入 parent swap sentinel fixtures。
  reviewer source: Reviewer B — Quality
  introduced_by: `install-cash-skills.fish:972-1011` 新增的 `mktemp "$parent/..."`、`rm -f "$destination_temp"` 與 `mv -f "$destination_temp" "$destination"` 會重新解析 mutable parent pathname。

### Warning

- severity: Warning
  confidence: 100
  layer: design
  location: `scripts/cash-skills/tests/skill-checks.fish:566-675`
  summary: Guidance filesystem contract 明列的 parent identity swap、destination inode/symlink swap、permission fail-closed、新檔 `0644` 與完整 managed-span 外 byte preservation，尚未全部由獨立回歸 fixture 覆蓋。
  recommendation: 在 design 更新並完成 directory-FD fix 後，擴充 `assert_guidance_boundary_matrix` 覆蓋所有明列 boundary branches，核對 target 外 sentinel、receipt、later guidance 與完整 byte snapshots。
  reviewer source: Reviewer A — Adherence、Reviewer B — Quality
  introduced_by: `scripts/cash-skills/tests/skill-checks.fish:566-675` 新增的 boundary matrix 目前只有 post-preflight content edit、既有 mode preservation與 hard-link fixtures，未涵蓋其餘明列 branches。

### Suggestion

無。

## Rating

- cumulative blocking Critical: 1
- cumulative blocking Warning: 1
- non-blocking triaged findings: 0
- critical_gap: true
- round_type: full

本輪是未 seeded run 的第一個 full round，所有通過 confidence filter 的 Critical 與 Warning 都進入 cumulative blocking set。Critical 的完整修正需要 design 尚未定義的 directory-FD synchronization primitive，觸發 cash-apply fix-loop design circuit breaker，因此本輪直接 `aborted`，不得在 apply review 中自行擴充設計。

## Fix Actions

- needs-design：`install-cash-skills.fish:972-1011` 的 parent pathname race 需要 directory-FD identity binding 與 no-follow `openat`／`renameat`／`unlinkat` mechanism；此 synchronization primitive 未定義於 `design.md`，必須先以 `$cash-ingest migrate-cash-project-guidance` 更新 design、failure modes、scope與驗證方式。
- Abort triage bucket 1：Critical「guidance publication 的 mutable parent pathname race」仍是本 change 的 obligation；完成 design ingest 與安全 primitive 實作後，作為後續 seeded re-run 的 blocking member。
- Abort triage bucket 1：Warning「guidance filesystem acceptance matrix 不完整」仍是本 change 的 obligation；補齊 parent/destination swaps、permissions、新檔 `0644` 與完整 byte snapshot fixtures後，作為後續 seeded re-run 的 blocking member。

## Decision

aborted

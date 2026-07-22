# Cash Propose Review — Round 1

## Reviewer Findings

### Critical

- severity: Critical
  confidence: 100
  layer: design
  location: `design.md`「Guidance 計畫加入既有 installer 交易」／「Failure modes」／「Risks / Trade-offs」；delta spec「安裝器與清理落實檔案系統邊界」
  summary: Guidance atomic replace失敗的零寫入承諾與多檔交易可能部分完成的設計互相矛盾。
  recommendation: 區分 preflight failure與 preflight後 publication failure；前者零寫入，後者允許已完成的 per-file atomic writes、保留舊 receipt並由下一次 invocation收斂。
  reviewer: Reviewer A

### Warning

- severity: Warning
  confidence: 100
  layer: design
  location: `design.md`「向量模型 fallback 保留在兩個 canonical Cash blocks」；delta spec「Cash 指引提供無向量模型替代流程」；`tasks.md` 1.1、1.2、3.2
  summary: Artifacts只要求 fallback標題與摘要語意，未保證使用者指定的完整 Markdown逐字加入。
  recommendation: 將完整原文定義為 canonical verbatim block，並以完整 block byte comparison驗證。
  reviewer: Reviewer A

- severity: Warning
  confidence: 90
  layer: design
  location: `design.md`「Guidance 計畫加入既有 installer 交易」與「Exact marker state machine 保護專案自訂內容」；delta spec「Cash project guidance migration」；`tasks.md` 2.1、2.2
  summary: Target guidance在 preflight後被修改時，舊 snapshot可能覆蓋新內容並破壞 managed spans外 bytes保留合約。
  recommendation: 記錄完整 snapshot identity，並在 temporary file建立前與 atomic publish前重新比對。
  reviewer: Reviewer A

- severity: Warning
  confidence: 90
  layer: design
  location: delta spec「Cash 安裝不含修復自動化」→「Scenario: 完成的 cash 安裝」
  summary: 「持久 target狀態僅由」的量詞排除了明確要求保留的標準 Spectra skills與其他 project-owned state。
  recommendation: 將主詞限定為 Cash installer新增或管理的持久狀態，並明列保留項目。
  reviewer: Reviewer A

- severity: Warning
  confidence: 100
  layer: design
  location: `tasks.md` 1.1、1.2
  summary: 兩個 `[P]` tasks都以修改同一測試檔的 assertions作為交付，形成平行同檔競爭。
  recommendation: 移除 `[P]` 或把共用測試修改集中到獨立 task。
  reviewer: Reviewer B

- severity: Warning
  confidence: 95
  layer: design
  location: `design.md`「Canonical Cash guidance 直接取自 source AGENTS.md 與 CLAUDE.md」與外部 Spectra update recovery
  summary: Source guidance被 Spectra app重新加入 block時，原設計會阻斷所有 target更新，且 installer禁止 source repository作為 target，無法依「重跑 installer」自我修復。
  recommendation: 區分 source與 target recovery；允許合法 source Spectra block不阻斷 Cash block擷取，source repository由版本控制還原。
  reviewer: Reviewer B

- severity: Warning
  confidence: 90
  layer: design
  location: `design.md`「Exact marker state machine 保護專案自訂內容」與 guidance atomic replacement
  summary: Atomic replace未定義既有 guidance file的 permission mode preservation，可能把 mode意外改為 temporary file的 `0600`。
  recommendation: 保留既有 POSIX mode bits，為新檔指定穩定 mode，並明示其他 metadata邊界。
  reviewer: Reviewer B

- severity: Warning
  confidence: 85
  layer: design
  location: `design.md`「Guidance 計畫加入既有 installer 交易」；`tasks.md` 2.2
  summary: Preflight後若 parent或 destination identity被替換，寫入可能逃出已驗證 target。
  recommendation: 在 temporary file建立與 publish前執行 no-follow identity revalidation，加入 target外 sentinel fault-injection fixtures。
  reviewer: Reviewer B

### Suggestion

None.

## Rating

- cumulative blocking Critical: 1
- cumulative blocking Warning: 7
- non-blocking triaged findings: 0
- critical_gap: true
- round_type: full
- rationale: 這是未 seeded run的第一輪，所有通過 confidence filter的 Critical與Warning均進入累積 blocking集合。Fix actions已覆蓋全部八項 findings，但必須由後續 Reviewer V逐項確認後才能從集合移除，因此本輪為 `next_round`。

## Fix Actions

- 修改 `design.md`、delta spec與 `tasks.md`，區分零寫入的 preflight failure與可留下較早 per-file publication的 runtime failure；規定舊 receipt保留與 retry收斂。
- 修改 `design.md`、delta spec與 `tasks.md`，逐字納入使用者指定的完整 fallback Markdown並要求 byte comparison。
- 修改 `design.md`、delta spec與 `tasks.md`，加入 full-byte snapshot、parent/destination identity兩階段 revalidation、post-preflight fault injection與先前 publication語意。
- 修改 delta spec，將持久狀態主詞限定為 Cash installer新增或管理的狀態，並明列標準 Spectra skills與其他 project-owned state保持不變。
- 修改 `tasks.md`，移除衝突的 `[P]` markers並把共用回歸集中到 task 3.2。
- 修改 `proposal.md`、`design.md`、delta spec與 `tasks.md`，區分 target重跑 installer與 source透過版本控制還原；合法 source Spectra block不阻斷其他 target安裝。
- 修改 `design.md`、delta spec與 `tasks.md`，規定既有 POSIX mode bits保留、新檔 `0644`，並排除 ACL與 extended attributes。
- Post-fix mechanical self-check：`spectra validate "migrate-cash-project-guidance"`通過；spec comment counts平衡；8個 MODIFIED requirement titles全都與 master spec byte-identical；所有 requirement names與6個 design decision headings均有 backing task；所有 open signals皆無 `check`欄位，因此沒有 deterministic signal command需要執行。

## Decision

next_round

# Cash Propose Review — Round 5

## Reviewer Findings

### Cumulative Blocking Set Verification

1. master requirements migration — **unresolved** — 「手動的 cash 專案 registry」仍允許註冊任意既存目錄，與direct/batch新增的Git top-level及有效config prerequisites衝突。
2. nested cwd launcher — **resolved**
3. apply/analyze/drift schema — **resolved**
4. touched-state/legacy migration — **unresolved** — legacy touched只在`in-progress add`匯入；upgrade後直接commit/archive會遺失既有source allowlist。
5. sync/archive idempotency/no-sync — **resolved**
6. legacy removal identity — **resolved**
7. launcher mode — **resolved**
8. multi-file transaction/read consistency — **unresolved** — stable bootstrap缺少receipt中的target identity oracle與明確generation演算法，且舊receipt target沒有建立stable bootstrap的遷移路徑。
9. outer guidance identity — **resolved**
10. `@trace` — **resolved**
11. `spec_dir` — **resolved**
12. lexical symlink containment — **resolved**
13. installer Git/config target prerequisites — **unresolved** — register mode尚未重用相同validator。
14. archive flags/transaction — **resolved**
15. MODIFIED+RENAMED phase order — **resolved**
16. fresh config source — **resolved**
17. list/status/artifact instruction schemas — **unresolved** — artifact instructions仍缺少canonical consumers需要的`context`與`rules`欄位。
18. live namespace scan boundary — **resolved**
19. existing Cash config validation — **resolved**

### New Critical

20. **既有24-skill receipt沒有可執行的bootstrap升級路徑**
    - confidence: 99
    - layer: deployment migration
    - location: `design.md`, `specs/cash-cli/spec.md`, `tasks.md`
    - summary: 現有targets只有舊24-skill receipt；fresh與adoption clauses都無法安全建立stable launcher/lock/runtime。
    - recommendation: 嚴格辨識known old receipt，定義one-time lock bootstrap、transaction rollback、dry-run與concurrent installer行為。
    - reviewer: adherence, quality

21. **Fresh lock位於尚未建立的managed parent**
    - confidence: 98
    - layer: bootstrap filesystem
    - location: `proposal.md`, `design.md`, `specs/cash-cli/spec.md`
    - summary: 先前lock位於`.cash-skills/state/`，fresh install在建立managed parents前無法取得穩定同步inode。
    - recommendation: 將stable lock放在既有project root，以`O_EXCL`建立後再發佈其餘inventory。
    - reviewer: quality

22. **YAML subset與parser版本選擇未定義**
    - confidence: 96
    - layer: configuration
    - location: `design.md`, `specs/cash-cli/spec.md`
    - summary: 「受限YAML」沒有可實作grammar；舊installer若先解析newer target config，可能把合法新格式誤判為失敗。
    - recommendation: 明列兩種config grammar，並要求先分類newer receipt，再決定是否以incoming parser解讀target config。
    - reviewer: quality

23. **Legacy config的unknown active keys仍可能被靜默忽略**
    - confidence: 95
    - layer: configuration migration
    - location: `design.md`, `specs/cash-cli/spec.md`, `tasks.md`
    - summary: 只拒絕non-default`spec_dir`不足以處理其他active scalar、map或list，可能產生不等價遷移。
    - recommendation: 僅接受四個明列runtime keys與optional default`spec_dir`，其他active內容一律fail closed。
    - reviewer: adherence

### Suggestion

24. **部分normative文字重複**
    - confidence: 82
    - layer: writing quality
    - location: `specs/cash-cli/spec.md`
    - summary: stable bootstrap與transaction限制在相鄰段落重述。
    - recommendation: 實作時保持單一helper與單一contract test oracle；不阻塞proposal。

## Rating

- Critical: 7
- Warning: 2
- Suggestion: 1
- cumulative unresolved: 5
- critical_gap: true
- round_type: full
- rationale: registry、legacy touched、bootstrap identity、舊receipt migration與artifact consumer schema仍有阻塞缺口，完整審查另發現YAML grammar與legacy config migration問題。

## Fix Actions

- 完整MODIFIED「手動的 cash 專案 registry」，使register與direct/batch共用Git top-level及safe config validator。
- 新增`touched ensure`lazy migration，要求commit在allowlist前呼叫、archive在transaction內執行。
- artifact instructions加入always-present `context: string`與`rules: string[]`，並擴充consumer snapshots。
- 將stable workspace lock移到project root，launcher依argv直接取得正確lock mode，不做shared-to-exclusive conversion。
- 定義receipt的target `st_dev/st_ino` bootstrap records及canonical runtime-generation hash stream。
- 定義known old 24-skill receipt的一次性bootstrap migration、concurrency、dry-run、rollback與fail-closed boundaries。
- 明列`.cash.yaml`與`openspec/config.yaml`兩個YAML subsets，先分類newer receipt再選擇target parser。
- legacy config只接受四個runtime keys與optional default`spec_dir`，其他active scalar/map/list拒絕。
- Post-fix validation：`spectra validate`通過；analyzer Coverage、Consistency、Gaps皆Clean，僅有非阻塞Example與weak-wording建議。
- fixed_files: 5

## Decision

next_round

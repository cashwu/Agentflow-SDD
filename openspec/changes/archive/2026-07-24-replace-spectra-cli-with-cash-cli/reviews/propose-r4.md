# Cash Propose Review — Round 4

## Reviewer Findings

### Cumulative Blocking Set Verification

1. master requirements migration — **resolved**
2. nested cwd launcher — **resolved**
3. instructions/analyze/drift schema — **resolved**
4. touched-state/legacy migration — **resolved**
5. sync/archive idempotency/no-sync — **resolved**
6. legacy removal identity — **resolved**
7. launcher mode — **resolved**
8. multi-file transaction/read consistency — **unresolved** — CLI commands已協作鎖，但bundle-installed lock未與installer publication形成穩定同inode邊界；upgrade替換lock或launcher時，舊/新process可能持有不同inode或載入mixed runtime。
9. outer guidance identity — **resolved**
10. `@trace` — **resolved**
11. `spec_dir` — **resolved**
12. lexical symlink containment — **resolved**
13. installer Git/config target prerequisites — **resolved**
14. archive flags/transaction — **resolved**
15. MODIFIED+RENAMED phase order — **resolved**
16. fresh config source — **resolved**
17. list/status/artifact instruction schemas — **resolved**
18. live namespace scan boundary — **resolved**

### New Warning

19. **Existing Cash config可在installer成功後讓CLI失效**
    - confidence: 95
    - layer: installer configuration
    - location: `design.md`, `specs/cash-cli/spec.md`, `tasks.md`
    - summary: existing `.cash.yaml`只要求逐byte保留，未使用Cash CLI相同parser驗證keys、duplicates、types與syntax。
    - recommendation: Installer preflight以同一versioned parser驗證；合法時preserve，非法時首次write前execution error。
    - disposition: new
    - introduced_by: Round 3 config三分支修正

## Rating

- Critical: 1
- Warning: 1
- cumulative unresolved: 1
- non-blocking triaged: 0
- critical_gap: true
- round_type: micro
- rationale: 18項既有blocking classes已有17項resolved，但stable lock與installer尚未共享不可替換的同步inode；另有existing Cash config validation缺口。

## Fix Actions

- 將launcher與workspace lock定義為stable bootstrap objects；一般upgrade不得rename替換inode，source bootstrap drift回報unsupported migration。
- Launcher在import receipt/library前取得shared lock並驗證runtime generation；installer在讀取任何managed destination前取得同一no-follow inode的exclusive lock，持有到transaction/rollback結束。
- Fresh install定義`O_EXCL` lock建立與orphan-lock recovery；existing/adopt/current/upgrade/force/batch保留bootstrap inode，只替換library generation、skills、guidance與receipt。
- Receipt、current、adoption、version與batch clauses一致納入stable bootstrap及runtime generation records。
- Existing `.cash.yaml`改由Cash runtime同一versioned parser做no-follow preflight；unknown key、duplicate、wrong type與malformed內容零寫入失敗。
- Post-fix validation：`spectra validate`通過；analyzer Coverage、Consistency、Gaps皆Clean，僅剩非阻塞Example建議與identifier誤判。
- fixed_files: 5

## Decision

next_round

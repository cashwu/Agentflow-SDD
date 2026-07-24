# Cash Propose Review — Round 2

## Reviewer Findings

### Cumulative Blocking Set Verification

1. `master requirements 衝突未完整遷移` — **unresolved** — `cash-skill-workflows`仍有一條文件requirement要求保留標準Spectra skills；artifact-engine requirement的標題仍宣稱Spectra ownership；replacement bundle contract也尚未完整承接SemVer、任意長度排序、版本bump與invalid receipt治理。
2. `nested cwd 相對 launcher path` — **resolved** — design、`cash-cli` spec與tasks已要求Git root discovery後呼叫absolute launcher，並加入nested-cwd fixtures。
3. `instructions apply / analyze / drift consumer fields 不完整` — **unresolved** — artifacts仍只列top-level fields，缺少nested element types、`null`與empty-array契約。
4. `Cash-owned touched-state 與 legacy migration 缺失` — **resolved** — 已定義Cash snapshots、per-task touched union、pre-existing dirty排除、commit allowlist、archive cleanup與受驗證legacy import。
5. `sync/archive 重複合併與 refused sync branch` — **resolved** — 已定義digest manifest、repeated-sync no-op、mismatch fail-closed與`archive --skip-specs`。
6. `legacy removal identity 僅靠名稱` — **resolved** — 已要求versioned full-body digest及body/mode/hard-link/symlink/extra-content fail-closed。
7. `launcher executable mode 未管理` — **resolved** — launcher固定`0755`、其他新檔`0644`，receipt記錄mode且fixture直接執行target launcher。
8. `多檔 publication 非 all-or-nothing` — **resolved** — 已涵蓋exclusive lock、全snapshot revalidation、journal、rollback、recovery及rollback failure blockade。
9. `錯改 code fence 內 heading` — **resolved** — delta現已修改真正的outer guidance requirement並保留完整balanced fenced block。
10. `archive provenance / @trace 遺失` — **resolved** — 已定義deterministic trace derivation與archive manifest digests。
11. `spec_dir 與固定 openspec 路徑矛盾` — **resolved** — `.cash.yaml`排除`spec_dir`，legacy non-default值fail closed。
12. `lexical search symlink containment 缺失` — **resolved** — 所有reads採no-follow、regular-file與root containment驗證，並有symlink/parent-swap/sentinel fixtures。

### New Findings

None.

## Rating

- Critical: 2
- Warning: 0
- cumulative unresolved: 2
- non-blocking triaged: 0
- critical_gap: true
- round_type: micro
- rationale: 12個cumulative findings中有10個已明確resolved，但master requirement migration與consumer schema仍未完整，因此必須修正後進入下一輪。

## Fix Actions

- 在`specs/cash-skill-workflows/spec.md`新增對「現行文件反映 cash 所有權與清理」的完整MODIFIED block，明確移除保留標準Spectra skills的現行文件契約。
- 在同一delta加入artifact-engine requirement的RENAMED operation，使合併後標題不再宣稱Spectra ownership。
- 在`proposal.md`、`design.md`、`specs/cash-cli/spec.md`與`tasks.md`完整承接strict SemVer、任意長度版本排序、版本bump/history binding及invalid receipt fail-closed契約。
- 在`design.md`、`specs/cash-cli/spec.md`與`tasks.md`逐欄定義instructions apply、analyze、drift的nested element types、invariants、nullable `last_commit`、empty arrays及human-render來源。
- Post-fix validation：`spectra validate replace-spectra-cli-with-cash-cli`通過；analyzer的Coverage、Consistency、Gaps皆為Clean，僅有非阻塞Example建議與identifier誤判。
- fixed_files: 5

## Decision

next_round

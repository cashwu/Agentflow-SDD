# Cash Propose Review — Round 3

## Reviewer Findings

### Cumulative Blocking Set Verification

1. `master requirements 衝突未完整遷移` — **unresolved** — 「版本感知的 cash skill 批次安裝」仍以skill-only inventory定義source integrity、force、newer與dry-run。
2. `nested cwd 相對 launcher path` — **resolved** — Git-root discovery、absolute launcher與nested-cwd fixtures完整。
3. `instructions apply / analyze / drift consumer fields 不完整` — **unresolved** — analyze/drift已補齊，但blocked scenario使用未定義的`missingArtifacts`，且`preflight`presence與canonical consumer仍不一致。
4. `Cash-owned touched-state 與 legacy migration 缺失` — **unresolved** — 缺少resume state machine、完整Cash/legacy schemas與porcelain-v2狀態矩陣；既有`.spectra/snapshots/`實際上是歷史spec tree而非可直接匯入的Git baseline。
5. `sync/archive 重複合併與 refused sync branch` — **resolved** — manifest、idempotency與`--skip-specs`完整。
6. `legacy removal identity 僅靠名稱` — **resolved** — full-body digest與unsafe-shape fail-closed完整。
7. `launcher executable mode 未管理` — **resolved** — mode、receipt與direct execution fixture完整。
8. `多檔 publication 非 all-or-nothing` — **unresolved** — persistent exclusive-create lock缺少stale owner recovery，且readers未協作，可能觀察partial publication。
9. `錯改 code fence 內 heading` — **resolved** — outer requirement與balanced fenced block正確。
10. `archive provenance / @trace 遺失` — **resolved** — deterministic trace與manifest完整。
11. `spec_dir 與固定 openspec 路徑矛盾` — **resolved** — new config不接受`spec_dir`，legacy non-default fail closed。
12. `lexical search symlink containment 缺失` — **resolved** — read containment與fault fixtures完整。

### New Critical

13. **Installer 可成功安裝到canonical skills無法啟動的target**
    - confidence: 97
    - layer: deployment
    - location: `design.md`, `specs/cash-cli/spec.md`
    - summary: Skills以Git root啟動，但installer未要求target是Git top-level，也未要求有效`openspec/config.yaml`。
    - recommendation: direct/register/batch均在首次write前驗證這兩個prerequisites。
    - disposition: new

14. **Archive flags與強制validation/transaction契約矛盾**
    - confidence: 99
    - layer: lifecycle
    - location: `design.md`, `specs/cash-cli/spec.md`
    - summary: Command table保留`--no-validate`與`--mark-tasks-complete`，normative lifecycle卻未定義例外、順序及rollback。
    - recommendation: 定義不可略過的safety preflight、optional domain validation及transactional checkbox順序。
    - disposition: new

15. **同一requirement的MODIFIED+RENAMED phase order未定義**
    - confidence: 96
    - layer: spec merge
    - location: `specs/cash-skill-workflows/spec.md`, `design.md`
    - summary: 本change自身同時修改與重新命名artifact-engine requirement；沒有固定phase時可能先rename後因舊identity失敗。
    - recommendation: 定義跨operation graph、合法組合、phase order與collision fixtures。
    - disposition: new
    - introduced_by: Round 2 master requirement rename修正

16. **Fresh target沒有legacy config時的Cash config來源未定義**
    - confidence: 96
    - layer: installer configuration
    - location: `design.md`, `specs/cash-cli/spec.md`
    - summary: 只定義existing Cash preserve與legacy migration，兩者皆無時卻仍要求fresh install產生config。
    - recommendation: 定義三分支與fresh/rollback/current fixtures。
    - disposition: new
    - introduced_by: Round 1–2 installer/config migration修正

### New Warning

17. **其餘consumer JSON contracts缺少完整型別oracle**
    - confidence: 93
    - layer: interface
    - location: `design.md`, `specs/cash-cli/spec.md`, `tasks.md`
    - summary: list、status與artifact instructions尚未定義element types、optional/empty/null及stable ordering。
    - recommendation: 逐欄定義完整shape並加入consumer snapshots。
    - disposition: new

18. **Namespace scan的live surface邊界不精確**
    - confidence: 90
    - layer: acceptance criteria
    - location: `design.md`, `specs/cash-cli/spec.md`, `tasks.md`
    - summary: 模糊的all-non-archive scan會把本migration change/reviews中的必要Spectra provenance誤判為runtime residue。
    - recommendation: 固定include roots並窄化legacy/history exceptions。
    - disposition: new

## Rating

- Critical: 8
- Warning: 2
- cumulative unresolved: 4
- non-blocking triaged: 0
- critical_gap: true
- round_type: full
- rationale: 四個cumulative blockers仍存活，完整審查另發現四個Critical與兩個Warning，因此必須修正後進入micro verification。

## Fix Actions

- 在`cash-skill-workflows` delta完整MODIFIED「版本感知的 cash skill 批次安裝」，將所有branches擴張為runtime/skills/modes/config/guidance/receipt/legacy transaction。
- 將workspace lock改為process-scoped shared/exclusive advisory lock；readers在unfinished journal fail closed，mutators先recovery，並新增crash/read-during-publication fixtures。
- 為apply加入always-present `missingArtifacts`與`preflight`，並補齊list、status、artifact instructions的element/presence/empty/null/stable-order schemas。
- 將touched tracking改為versioned per-task/aggregate schema與resume-safe state machine，完整治理porcelain-v2 cases；只匯入現行legacy touched shape，不讀歷史spec snapshots。
- 定義spec merge固定phase與MODIFIED+RENAMED合法組合；定義archive flags不可略過的preflight、transaction順序與rollback。
- Installer新增Git-top-level與`openspec/config.yaml` prerequisite，並定義existing Cash、legacy migration、source baseline三種config branches。
- Namespace scan改用精確live include roots，將active migration provenance、archive/history與窄化legacy detectors分開治理。
- Post-fix validation：`spectra validate`通過；analyzer Coverage、Consistency、Gaps皆Clean，僅剩非阻塞Example建議與identifier誤判。
- fixed_files: 5

## Decision

next_round

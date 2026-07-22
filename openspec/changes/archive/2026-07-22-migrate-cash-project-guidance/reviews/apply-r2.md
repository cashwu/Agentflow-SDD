# Cash Apply Review — Round 2

## Reviewer Findings

### Critical

- severity: Critical
  confidence: 100
  layer: design
  location: `install-cash-skills.fish:429-436`
  summary: Temporary cleanup在exclusive create成功前即被armed；若`O_EXCL` create失敗，`END`仍會刪除非本次publisher建立的同名檔案。
  recommendation: 僅在`sysopen`成功且publisher取得temporary ownership後設定cleanup，並以collision fixture證明既有同名entry完整保留。
  disposition: fix-introduced
  introduced_by: task 5.2新增的`publish_guidance_anchored`在exclusive `sysopen`前設定`$cleanup = $temporary`。
  reviewer source: Reviewer B — Quality

### Warning

- severity: Warning
  confidence: 100
  layer: design
  location: `install-cash-skills.fish:447-451`; `scripts/cash-skills/tests/skill-checks.fish:721-756`; `specs/cash-skill-workflows/spec.md:72-78`
  summary: `before-rename` injection位於最後一次pathname checkpoint之前，尚未驗證最後checkpoint後的parent replacement不會重新導向atomic rename。
  recommendation: 在`verify_destination()`後、`rename()`前加入專用fault-injection checkpoint及parent swap fixture，核對替代parent sentinel、later guidance、receipt與無`Result:`。
  disposition: unresolved-prior
  reviewer source: Reviewer A — Adherence

- severity: Warning
  confidence: 100
  layer: design
  location: `scripts/cash-skills/tests/skill-checks.fish:721-755`
  summary: Race fixtures對替代parent／destination sentinel的證據未全部逐byte；`string trim`會忽略換行或首尾空白變異，destination replacement entry亦未完整核對。
  recommendation: 使用`cmp -s`或SHA-256核對完整bytes；inode swap核對replacement bytes，symlink swap核對symlink identity、link target與外部檔案bytes。
  disposition: unresolved-prior
  introduced_by: task 5.1新增的boundary fixtures使用`string trim`，且未對destination replacement entry做完整assertion。
  reviewer source: Reviewer B — Quality

- severity: Warning
  confidence: 100
  layer: design
  location: `install-cash-skills.fish:409-417, 1060-1118`
  summary: Directory-handle `chdir`與relative child lookup能力直到skill publication後才首次驗證，不符合首次target mutation前的platform capability contract。
  recommendation: 在任何skill、guidance或retired-plus mutation前執行無寫入capability preflight，publication階段仍保留原有重驗。
  disposition: fix-introduced
  introduced_by: task 5.2將能力驗證只放在publication階段的`publish_guidance_anchored`。
  reviewer source: Reviewer B — Quality

- severity: Warning
  confidence: 90
  layer: design
  location: `install-cash-skills.fish:431-434`
  summary: Anchored cleanup的`unlink`結果被忽略，permission change可能留下temporary且沒有basename或原因diagnostic。
  recommendation: 檢查anchored `unlink`結果，保留原始非零狀態並輸出relative temporary basename與`$!`，加入cleanup failure fixture。
  disposition: fix-introduced
  introduced_by: task 5.2新增的`END { unlink($cleanup) if defined $cleanup; }`。
  reviewer source: Reviewer B — Quality

### Suggestion

無。

## Rating

- cumulative blocking Critical: 1
- cumulative blocking Warning: 3
- non-blocking triaged findings: 0
- critical_gap: true
- round_type: full

本輪是seeded re-run的第一個full round。兩位reviewers均確認前輪Critical parent pathname race已resolved並從cumulative blocking set移除；前輪Warning acceptance-matrix member仍unresolved，且本輪新增一個fix-introduced Critical與兩個fix-introduced Warning。所有blocking members已有對應修正，但必須由下一個micro round驗證後才能移除，因此decision為`next_round`。

## Fix Actions

- Verified resolution removal：前輪Critical「mutable parent pathname race」由Reviewer A與Reviewer B一致判定resolved；證據為`publish_guidance_anchored`持有no-follow directory FD、`chdir($directory_fh)`綁定held object，所有child operations使用relative basenames，且parent swap fixtures通過。
- 修改`install-cash-skills.fish`：將`$cleanup`延後至exclusive `sysopen`成功後才armed；create collision不再unlink非本次owned entry。
- 修改`install-cash-skills.fish`：新增首次target mutation前的`guidance_publisher_capability_matches`，驗證no-follow open、`fstat`、directory-handle `chdir`、`stat(".")`與relative child lookup。
- 修改`install-cash-skills.fish`：在最後destination checkpoint後加入`after-verify-before-rename` fault-injection point；atomic rename仍使用held-directory relative basename。
- 修改`install-cash-skills.fish`：anchored cleanup失敗時輸出relative temporary basename與系統原因，同時保留原始nonzero failure。
- 修改`scripts/cash-skills/tests/skill-checks.fish`：新增final-checkpoint後parent swap、capability preflight failure、exclusive-create collision與cleanup failure fixtures；改用`cmp -s`逐byte核對替代parent、destination inode與outside sentinel，並核對symlink identity及link target。
- Post-fix verification：`fish scripts/cash-skills/tests/skill-checks.fish`、`fish -n install-cash-skills.fish scripts/cash-skills/tests/skill-checks.fish`及`spectra validate migrate-cash-project-guidance`全數通過；post-fix mechanical self-check通過。

## Decision

next_round

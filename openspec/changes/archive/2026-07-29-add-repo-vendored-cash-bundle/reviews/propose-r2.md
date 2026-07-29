# Cash Propose Review — Round 2

## Reviewer Findings

### Critical

無。

### Warning

1. severity: Warning
   confidence: 99
   layer: design
   location: `design.md` vendored transaction ordering、`specs/cash-cli/spec.md`「Repo-vendored Cash bundle 發佈」、`tasks.md` migration tasks
   summary: artifacts同時要求manifest是transaction最後一筆write，又允許其後receipt cleanup，造成operation ordering與recovery判準矛盾。
   recommendation: 將manifest定義為最後一筆trust-bearing managed bundle publication，`receipt_delete`為唯一post-cutover cleanup，並定義cutover前rollback／後roll-forward。
   disposition: fix-introduced
   introduced_by: Round 1 Fix Actions「修正stale receipt cutover」與「修正launcher identity rollback」。
   reviewer source: Reviewer V（Verification）

2. severity: Warning
   confidence: 96
   layer: design
   location: `design.md` launcher transition allowlist、`specs/cash-cli/spec.md`「受控 launcher bootstrap migration」、`tasks.md` migration task
   summary: transition版本判準在「source version不低於引入版」、「命中同一版」與「本次bundle version」之間不一致，跨版升級沒有唯一答案。
   recommendation: 固定 `(old_digest, new_digest, introduced_version)` schema；runtime允許source version大於等於introduced version，history只允許new bytes首次出現在introduced version。
   disposition: fix-introduced
   introduced_by: Round 1 Fix Actions「修正launcher identity rollback」。
   reviewer source: Reviewer V（Verification）

3. severity: Warning
   confidence: 98
   layer: design
   location: `design.md` portable runtime import、`specs/cash-cli/spec.md`「Portable generation 受同一 stable lock 保護」、`tasks.md` launcher／integration tests
   summary: 只禁止寫入 `.pyc`仍可能讓一般Python import讀取既存且payload不同的valid cache，繞過manifest generation。
   recommendation: portable gate保留verified runtime bytes，並以受控loader直接compile這些bytes、完全不走bytecode cache；加入malicious-but-import-valid `.pyc`案例。
   disposition: unresolved-prior
   reviewer source: Reviewer V（Verification）

### Suggestion

無。

## Rating

- Critical: 0
- Warning: 3
- non-blocking triaged findings: 0
- critical_gap: false
- round_type: micro
- 理由：Reviewer V確認Round 1的七個cumulative members已resolved；同generation member仍未解決，且Round 1 fixes另引入兩個blocking Warning，因此cumulative blocking set保留三個Warning，必須進入下一輪。

## Fix Actions

- 修正operation ordering：修改 `design.md`、`specs/cash-cli/spec.md`與 `tasks.md`，將manifest定義為最後一筆trust-bearing managed bundle publication，新增 `portable_cutover` phase，且只允許 `receipt_delete`在cutover後roll forward。
- 修正transition version：修改 `design.md`、`specs/cash-cli/spec.md`與 `tasks.md`，固定 `(old_digest, new_digest, introduced_version)`，定義source version下限、history首次引入點及skipped-version upgrade scenario。
- 修正verified generation：修改 `proposal.md`、`design.md`、`specs/cash-cli/spec.md`與 `tasks.md`，要求portable gate保留verified source bytes，使用 `VerifiedSourceLoader.get_code`直接 `source_to_code`且不呼叫superclass cache path；測試預置可被一般import接受但payload不同的 `.pyc`。
- disposition correction：Reviewer V原將 `.pyc` finding標為 `new`；主agent依相同 `specs/cash-cli/spec.md` generation位置與「只載入同一generation」缺陷機制，修正為 `unresolved-prior`，對應Round 1 cumulative member「portable help與receipt-validated generation precedence」。
- verified resolution removal：依Reviewer V verdict，從cumulative blocking set移除stale receipt cutover、launcher rollback／dynamic receipt identity、`CASH-INIT-RECEIPT.md` scope、planned paths Git excludes、bytecode零寫入、manifest unsafe shape與receiptless adoption；同generation member維持未解決。
- 修正後已跨全部artifacts搜尋manifest ordering、`portable_cutover`、`receipt_delete`、`introduced_version`、`VerifiedSourceLoader`與verified bytes並同步；`cash validate add-repo-vendored-cash-bundle`、annotation lint、identifier scan、Impact count與 `git diff --check`全數通過。
- open signals沒有任何 `check` frontmatter；本輪fix沒有修改change directory外檔案，因此不需呼叫Cash touched commands。

## Decision

next_round

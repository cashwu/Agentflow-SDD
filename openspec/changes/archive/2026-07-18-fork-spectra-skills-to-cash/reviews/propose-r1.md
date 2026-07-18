# Propose Plus Review — Round 1

## Reviewer Findings

### Critical

1. **location:** `specs/cash-skill-workflows/spec.md`
   **summary:** 移除原有 36 條 plus requirements 時，cash capability 只用摘要描述 retained quality gate，沒有保存 confidence filter、retry、disposition、cumulative blocking set、grader paths、signal checks、accepted risks、abort/seeded rerun、introduced-by 與 action obligations 的完整 normative contract。
   **recommendation:** 將仍保留的 quality-gate requirements 完整遷移成 cash-owned requirements；只讓真正退役的 generation/repair 機制沒有 replacement。
   **confidence:** 100
   **layer:** design

2. **location:** `proposal.md` Impact 與 live documentation scope
   **summary:** `SPECTRA-PLUS.md` 未列入 Impact，實作後會繼續指引使用已刪除的 generator、repair 與 LaunchAgent。
   **recommendation:** 將它改寫／更名為 `CASH-SKILLS.md`，並把新舊文件明確列入 New/Removed scope、tasks 與 residual checks。
   **confidence:** 100
   **layer:** design

3. **location:** `specs/signals-shared-layer/spec.md` 與 `openspec/signals/README.md`
   **summary:** proposal 沒有宣告修改 `signals-shared-layer`，現行 master contract 與 README 仍使用 plus review loop 及被刪除的路徑。
   **recommendation:** 新增 modified capability delta，將 current writer/provenance 改為 cash，保持 schema 與歷史 occurrence 文字。
   **confidence:** 100
   **layer:** design

### Warning

1. **location:** `AGENTS.md` ownership boundary
   **summary:** workflow guidance 位於 `<!-- SPECTRA:START -->` managed block，`spectra update --force` 會把 cash guidance改回 spectra guidance。
   **recommendation:** 將 project-owned cash override 放在 `<!-- SPECTRA:END -->` 之後並聲明 precedence，forced-update fixture 應驗證 effective guidance。
   **confidence:** 100
   **layer:** design

2. **location:** `cash-commit` replacement contract
   **summary:** replacement 只描述 selected change、archive output 與 tracking file，漏掉 tracked source files、使用者確認的 customizations 與明確選取的 spec-sync changes。
   **recommendation:** 完整遷移 legacy archive-first allowlist requirements 與 branch fixtures。
   **confidence:** 100
   **layer:** design

3. **location:** Claude/Codex variant parity
   **summary:** marker-only parity 無法偵測 propose/apply 大段 workflow 遺漏。
   **recommendation:** 定義 exhaustive normalization allowlist，正規化後比較完整 governed bodies，任何未列入差異都 fail loud。
   **confidence:** 95
   **layer:** design

4. **location:** installer 與 cleanup filesystem boundaries
   **summary:** artifacts 未定義 target canonicalization、symlink escape、unsafe HOME 與 path containment contract。
   **recommendation:** installer 與 cleanup 都要在任何寫入或 launchctl 前完成 canonical path/symlink boundary preflight，失敗時零寫入。
   **confidence:** 90
   **layer:** design

5. **location:** cleanup service discovery
   **summary:** cleanup 只在 plist 存在時 unload，無法處理「service 仍 loaded 但 plist 已遺失」。
   **recommendation:** 對兩個 `gui/<uid>/<label>` 都先 print/query，按 label bootout，確認兩者 absent/unloaded 後才刪 registry/cache。
   **confidence:** 85
   **layer:** design

### Suggestion

None.

## Rating

- post-filter cumulative blocking set: 3 Critical, 5 Warning
- non-blocking triage: 0
- `critical_gap: true`
- `round_type: full`
- rationale: 八項 finding 均達 confidence 80，且本次為未 seeded 的第一輪，因此全部進入 cumulative blocking set；在 Reviewer V 驗證修正前不可通過。

## Fix Actions

- 修改 `proposal.md`：新增 `signals-shared-layer` modified capability；將 `CASH-SKILLS.md`、`SPECTRA-PLUS.md` 與 signals README 納入精確 Impact；補上文件與 signal ownership 遷移。
- 修改 `design.md`：定義 managed block 外的 cash precedence、完整 body parity、live docs/signals ownership、installer canonicalization/symlink containment、cleanup HOME/symlink boundary，以及按 label 查詢與卸載的流程。
- 修改 `specs/cash-skill-workflows/spec.md`：完整搬移 19 條 retained quality-gate requirements；補齊 cash-commit full allowlist、filesystem safety、loaded-without-plist、effective AGENTS guidance、full-body parity 與 live documentation requirements。
- 新增 `specs/signals-shared-layer/spec.md`：以三條 MODIFIED requirements 保留完整 signal schema/status/check contract，只把現行 writer/read-loop wording 改為 cash。
- 修改 `tasks.md`：為全部 retained/removed requirements、signals delta、文件遷移、filesystem boundary、label-only service、forced update 與 exhaustive parity 建立具 fixture 的 backing tasks。
- Post-fix mechanical self-check：所有 39 條 cash requirements、36 條 removed requirements、3 條 signals requirements 與全部 design decisions 都有 task backing；spec comment delimiters 為 12/12；master/removal requirement counts 為 36/36；未修改 signal `check`；未發現 replacement character 或 BEL。
- Post-fix validation：`spectra validate fork-spectra-skills-to-cash` 通過。

## Decision

next_round

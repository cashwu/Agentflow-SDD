# Cash Apply Review — Round 1

## Reviewer Findings

### Critical

1. **Artifact readers 繞過單一 no-follow workspace adapter**
   - severity: Critical
   - confidence: 100
   - layer: design
   - location: `.cash-skills/lib/cash_cli/commands/discovery.py`, `.cash-skills/lib/cash_cli/commands/analyze.py`, `.cash-skills/lib/cash_cli/commands/drift.py`, `.cash-skills/lib/cash_cli/validation.py`, `.cash-skills/lib/cash_cli/spec_merge.py`
   - summary: 多個 command handler 直接使用 `Path` traversal/read，可能跟隨 change、artifact 或 parent symlink 至 workspace 外。
   - recommendation: 將 change discovery、artifact enumeration 與 artifact reads 收斂到 held-parent/no-follow workspace API，並加入 status、analyze、drift、validate、sync 的外部 sentinel 測試。
   - reviewer source: Reviewer A — Adherence, Reviewer B — Quality

2. **Workspace publication 與 ledger 更新間存在 crash window**
   - severity: Critical
   - confidence: 100
   - layer: design
   - location: `.cash-skills/lib/cash_cli/workspace.py`
   - summary: operation publication 完成後才更新 journal 計數；process 在兩者之間 crash 時，recovery 會遺漏已發布 operation。Rollback 也未以 held parent identity 操作。
   - recommendation: publication 前原子持久化 write-ahead ledger，讓 recovery 以 operation state 執行 idempotent rollback；rollback 使用已驗證的 no-follow parent FD，並加入真實 process crash 測試。
   - reviewer source: Reviewer A — Adherence, Reviewer B — Quality

3. **Installer 永久刪除 quarantine 後仍保留 rollback journal**
   - severity: Critical
   - confidence: 100
   - layer: design
   - location: `.cash-skills/lib/cash_cli/installer.py`
   - summary: `_remove_quarantines()` 與 journal cleanup 間 crash 時，legacy bytes 已不可恢復，但下一次 recovery 仍按 rollback phase 解讀 journal，可能留下混合狀態。
   - recommendation: journal 加入 durable committed/cleanup phase；publishing phase rollback，committed phase forward-cleanup，並加入該精確 crash window 的 process restart 測試。
   - reviewer source: Reviewer A — Adherence, Reviewer B — Quality

### Warning

1. **Launcher bootstrap failure 未遵守 `--json` error contract**
   - severity: Warning
   - confidence: 100
   - layer: design
   - location: `.cash-skills/bin/cash`
   - summary: receipt、bootstrap 或 Python version failure 即使帶 `--json` 仍只寫 stderr。
   - recommendation: launcher 在 import runtime 前辨識 `--json`，於 stdout 輸出單一 `{error:{code,message}}` object。
   - reviewer source: Reviewer A — Adherence

2. **`@trace.tests` 混入 source delivery paths**
   - severity: Warning
   - confidence: 100
   - layer: design
   - location: `.cash-skills/lib/cash_cli/spec_merge.py`, `scripts/cash-cli/fixtures/positive-lifecycle/master-spec.md`
   - summary: tasks 中所有含斜線的 code spans 都被視為 tests，導致 `src/demo.py` 同時出現在 `code` 與 `tests`。
   - recommendation: 只解析 task 驗證子句中的 verification target，並以同時含 source path 與 test path 的 fixture 驗證兩欄不互相污染。
   - reviewer source: Reviewer A — Adherence

3. **Missing registry record 的 `--unregister` 仍產生 persistent write**
   - severity: Warning
   - confidence: 100
   - layer: design
   - location: `.cash-skills/lib/cash_cli/installer.py`
   - summary: `--unregister` 無論 record 是否存在都重寫 registry，違反只執行明確 state change 的 no-op 契約。
   - recommendation: 只有 records 實際改變時才寫 registry，並驗證重複 unregister 的 inode、mtime 與 bytes 不變。
   - reviewer source: Reviewer B — Quality

4. **Workflow 文案聲稱 title mismatch 會被靜默丟棄**
   - severity: Warning
   - confidence: 100
   - layer: text
   - location: `.agents/skills/cash-apply/SKILL.md`, `.agents/skills/cash-propose/SKILL.md`, `.agents/skills/cash-ingest/SKILL.md` 與對應 `.claude` variants
   - summary: skill 文案與 Cash runtime 的 `requirement_identity_mismatch` fail-closed 行為矛盾。
   - recommendation: 改為明確說明 title mismatch 會 fail closed，並保持 variants parity。
   - reviewer source: Reviewer B — Quality

5. **Bundle version contract 未綁定 first-parent history**
   - severity: Warning
   - confidence: 100
   - layer: design
   - location: `scripts/cash-skills/tests/skill-checks.fish`, `scripts/cash-skills/tests/test_installer_runtime.py`
   - summary: 現有測試只硬編碼 `2.0.0`，未比較版本引入 commit 的 replaceable bytes、inventory 與 modes，因此相同版本漂移不會被攔截。
   - recommendation: 從 Git first-parent history 解析版本引入 commit，驗證同版本 inventory/bytes/modes 不變、版本必須嚴格遞增，並拒絕 stable bootstrap drift。
   - reviewer source: Reviewer A — Adherence, Reviewer B — Quality

### Suggestion

- 無。

## Rating

- cumulative blocking Critical: 3
- cumulative blocking Warning: 5
- non-blocking triaged: 0
- critical_gap: true
- round_type: full
- rationale: 第一輪發現 artifact read boundary、workspace crash recovery 與 installer commit recovery 三個 Critical，以及五個契約 Warning；依首輪規則全部為 blocking，修正後仍需 micro verification。

## Fix Actions

- 在 `workspace.py` 新增 held-parent/no-follow read、stat、directory listing 與 spec enumeration API，並將 discovery、analyze、drift、validation、sync/archive、create/lifecycle/tasks 的 managed artifact reads 收斂到該 adapter。
- Workspace journal 改為 publication 前以 same-directory atomic replace 持久化 ledger；rollback 依 before/published state判定、重驗 parent identity並使用 directory FD，新增 publication 後真實 process crash/restart 測試。
- Installer journal 升級為 `publishing`／`committed` phases；committed recovery 只完成 idempotent quarantine cleanup，不再嘗試不可恢復的 rollback，並新增精確 crash-window 測試。
- Launcher bootstrap failure 在 `--json` 下改為 stdout 單一 error object；receipt/runtime drift tests 同步驗證 stdout/stderr contract。
- `@trace.tests` 只接受 task 驗證子句中的 test target；positive lifecycle 與 sync fixtures 同時包含 source delivery path及test path，逐欄驗證不污染。
- `--unregister` 只在 registry records 實際變更時寫入，新增重複 unregister 的 inode、mtime、bytes no-op 測試。
- 六個 Cash workflow variants 改為 `requirement_identity_mismatch` fail-closed 文案，variant parity suite 通過。
- 新增 `test_bundle_version_history.py`，以 first-parent introduction commit 比對 replaceable inventory、bytes、modes與stable bootstrap，覆蓋同版本漂移、合法任意長度版本 bump及stable drift。
- Post-fix validation：Cash CLI 72 tests、installer 26 tests、bundle-history 3 tests、`cash validate --all`、live namespace scan與完整 skill suite 全數通過。
- fixed_files: 27

## Decision

next_round

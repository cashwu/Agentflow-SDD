# Cash Apply Review — Round 2

## Cumulative Blocking Set Verification

1. **Artifact readers 繞過單一 no-follow workspace adapter — resolved**
   - Discovery、analysis、drift、validation、sync/archive與search均透過Workspace adapter。
   - Search traversal在held directory FD下使用`dir_fd`與identity驗證，並在同一 traversal中讀取regular file。
   - Discovery與lexical-search的symlink/root-outside sentinel regressions通過。

2. **Workspace publication crash window與unsafe rollback — resolved**
   - Journal在publication前以atomic write-ahead ledger記錄operation與staged publication inode。
   - Write/delete/move publish、rollback、restore/unlink與temporary cleanup均在同一個已驗證parent FD內完成。
   - 真實process crash、same-bytes/different-inode、parent replacement及temp cleanup regressions通過；negative atomicity 13 tests通過。

3. **Installer quarantine cleanup與rollback journal phase混淆 — resolved**
   - Installer journal明確區分`publishing`與`committed`。
   - Publishing recovery rollback；committed recovery只執行idempotent forward cleanup。
   - 第一個quarantine永久移除後立即終止、再啟動完成剩餘cleanup的regression通過；installer runtime 28 tests通過。

4. **Launcher bootstrap `--json` failure contract — resolved**
   - Bootstrap/receipt failure在stdout輸出單一`error`object，stderr保持空。
   - Missing lock與receipt/runtime drift regressions通過。

5. **`@trace.tests` 混入source delivery paths — resolved**
   - Parser只讀取task verification clause，且只接受測試型target paths。
   - Positive lifecycle與sync fixtures確認`code`及`tests`不互相污染。

6. **Missing registry record的unregister persistent write — resolved**
   - Registry records未改變時不呼叫writer。
   - Missing registry零建立，以及重複unregister的inode、mtime、bytes不變測試均通過。

7. **Workflow title mismatch文案錯誤 — resolved**
   - 六個Cash workflow variants均明確說明`requirement_identity_mismatch` fail closed。
   - `.agents`與`.claude` variant parity通過。

8. **Bundle version未綁first-parent history — resolved**
   - History checker解析同版本的first-parent introduction commit，比對replaceable inventory、bytes及modes。
   - 同版本bytes、mode、inventory drift與stable bootstrap drift均失敗；合法任意長度SemVer bump通過，failure會傳遞nonzero exit。

## Reviewer Findings

### Critical

- 無。

### Warning

- 無。

### Suggestion

- 無。

## Rating

- cumulative blocking Critical: 0
- cumulative blocking Warning: 0
- non-blocking triaged: 0
- critical_gap: false
- round_type: micro
- rationale: Round 1的八個累積blocking findings均已完整修正並由Reviewer V重驗；沒有confidence ≥80的新Critical或Warning，也沒有Suggestion。

## Fix Actions

- 將search traversal與read完整收斂到held-FD Workspace adapter。
- 將workspace publish、rollback、restore/unlink與temporary cleanup的parent identity check及operation合併到同一held FD，並補齊精確regressions。
- 將installer committed cleanup regression精確移到已永久移除第一個quarantine、journal仍存在的窗口。
- 補齊missing registry、missing lock JSON、same-version mode/inventory drift regressions。
- Post-fix validation：Cash CLI 75 tests、installer 28 tests、bundle-history 4 tests、variant parity、live namespace scan與`cash validate --all`通過。
- fixed_files: 6

## Decision

passed

# Cash Apply Review — Round 2

## Reviewer Findings

### Suggestion

- severity: Suggestion / confidence: 50 / layer: design / disposition: new / location: `scripts/cash-skills/tests/test_installer_runtime.py` 的 `test_batch_force_converges_only_replaceable_vendored_bytes`
  - summary: delta spec 把早期返回列為三種（`--dry-run`、`conflict`、`newer`），Round 1 的 residue 修正只涵蓋前兩種。`newer` target 從未寫入 residue、也從未取得 `workspace_snapshot`，兩次 `--all` 之後只斷言 stdout 的 `newer:` 行，因此 `newer` 早期返回的「零寫入」與「不刪除 residue」兩個 MUST 子句在整份測試中無任何斷言承擔。
  - recommendation: 為 `newer` target 寫入殘留 receipt 並取快照，在 conflict 與 force 兩次執行後各斷言快照不變。
  - reviewer source: Reviewer V finding 1

- severity: Suggestion / confidence: 50 / layer: text / disposition: new / location: `CASH-SKILLS.md` 信任邊界段落、`CASH-INIT-RECEIPT.md` mode 對照表的 `--all` 列
  - summary: canonical source 例外只補進了 `CASH-SKILLS.md` 的批次段落與 probe docstring，同一次 diff 修改的另外兩處仍把分派寫成無例外的二分；其中信任邊界段落的「只」使它與同檔批次段落直接矛盾。
  - recommendation: 兩處各補一個短子句說明 canonical source 除外。
  - reviewer source: Reviewer V finding 2

- severity: Suggestion / confidence: 50 / layer: text / disposition: fix-introduced / introduced_by: Round 1 Fix Action 第 5 條（把 `tasks.md` 的改寫還原後，機械自我檢查的結論未同步更新）/ location: `reviews/apply-r1.md` 的 `## Fix Actions` 機械自我檢查條目
  - summary: 該條目逐字宣稱「過時措辭『到 4.1 的 `--self` 之間』零殘留」，但 `tasks.md` 至今仍含該字串——同一份 Fix Actions 的前一條自己就記載了「兩處改寫已還原為原文」。兩行互相否定，稽核軌跡上留下一筆已通過但實際未成立的檢查結果。
  - recommendation: 在本輪記錄更正該結論，使其與實況一致。
  - reviewer source: Reviewer V finding 3

## Rating

- post-filter 累積 blocking set Critical 數：0
- post-filter 累積 blocking set Warning 數：0
- 非 blocking triaged finding 數：0
- critical_gap: false
- round_type: micro
- rationale: 唯一的 blocking 成員 B1（`run_installer` 缺 `timeout` 使「不阻塞」驗收空載）經 Reviewer V 判定 resolved 並移出集合。其驗證不僅確認 helper 已接受並轉傳 `timeout`、測試已傳入 `timeout=60`，還以靜態路徑追蹤獨立重建了阻塞鏈（`vendored_planned_paths` 明列 manifest → `snapshots` → `optional_snapshot` → `read_regular` 以 `O_RDONLY | O_NOFOLLOW` 開檔而不帶 `O_NONBLOCK`，且 `require_manifest` 重新確認與 `ensure_regular_shape` 都排在其後），並實測該測試耗時 13.6s 而被計時的 `--all` 僅約 1s 量級，60s 有約 60 倍餘裕、不致 flaky。Reviewer V 另以 in-process 實測 9 種輸入確認 probe 的三支分割在 catch-all `return` 移入 `try` 後結果完全不變，且任一輸入皆不 raise。本輪三筆 finding 的 confidence 均為 50，依 `[50, 80)` 規則全部降為 Suggestion，不進入 blocking set。累積 blocking set 不含任何 blocking Critical 或 Warning，pass 條件成立。

## Fix Actions

- 本輪 pass 條件已成立，以下修正皆為非 blocking Suggestion 的自願處置，不影響決策。
- 修改 `scripts/cash-skills/tests/test_installer_runtime.py`：為 `test_batch_force_converges_only_replaceable_vendored_bytes` 的 `newer` target 寫入殘留 `.cash-skills/receipt.tsv` 並取 `newer_before` 快照，在 conflict 與 `--force` 兩次執行後各斷言 `workspace_snapshot(newer) == newer_before`，使 `--dry-run`、`conflict`、`newer` 三種早期返回的「零寫入且不刪除 residue」形成完整對稱的一組釘子。重跑該測試通過（20.5s）。（處置 Suggestion 1）
- 修改 `CASH-SKILLS.md` 與 `CASH-INIT-RECEIPT.md`：信任邊界段落刪去造成矛盾的「只」並補上「canonical source 自身除外，完整分派規則見下方批次段落」，mode 對照表的 `--all` 列補上「canonical source 自身與其餘 record 走 receipt-based」。task 4.2 的兩個手動驗收條件重跑後仍同時成立（正向命中、四個過時 pattern 零命中）。（處置 Suggestion 2）
- 更正 Round 1 的機械自我檢查結論（依「更正只寫在其發生的輪次」規則，在此記錄而不改寫已完成的 `apply-r1.md`）：Round 1 Fix Actions 中「過時措辭『到 4.1 的 `--self` 之間』零殘留」一句不成立。該措辭刻意保留在 `tasks.md` 的 task 1.1 中，因為 `.cash-skills/state/touched/<change>.json` 逐字綁定已完成 task 的 `task_desc`，改寫會使 `cash touched ensure` 以 `error[touched_invalid]` 失敗並毀掉檔案歸屬的稽核軌跡；該措辭的更正由 `implementation-notes.md` 第三筆 `deviation` 與 design D12 承載。（處置 Suggestion 3）
- Managed bundle publication：本輪 fix 未觸及受管 runtime 或 skills（只改測試檔與兩份非受管文件），因此不需要重新發佈 manifest；`.cash-skills/manifest.tsv` 維持 canonical。
- 本輪 Fix Actions 修改了 `openspec/changes/` 以外的三個檔案，已執行 `touched ensure` 與 `touched record` 記錄 `scripts/cash-skills/tests/test_installer_runtime.py`、`CASH-SKILLS.md` 與 `CASH-INIT-RECEIPT.md`。

## Decision

passed

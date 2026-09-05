# Cash Propose Review — Round 5

## Reviewer Findings

### Warning

- severity: Warning / confidence: 100 / layer: design / disposition: fix-introduced / introduced_by: Round 4 Fix Action「修改 `tasks.md` 1.1：verification 改為版本檔與 `BUNDLE_VERSION` 相等的手動斷言……」 / location: `tasks.md` 1.1 的 `verification` 欄
  - summary: 該手動斷言所用的指令不可執行。`rg -o '(?<=^BUNDLE_VERSION = ")[0-9.]+' …` 使用 look-behind，ripgrep 預設的 Rust regex 引擎不支援，實機執行以 `regex parse error: look-around ... is not supported`、exit 2 結束，指令替換為空字串使該比較恆為假。與 Round 4 修掉的「acceptance criterion 在指定時點不可達」是同一 issue class，只是換了失敗機制。
  - recommendation: 改用該時點確定可判定的既有自動測試 `test_bundle_version_constant_matches_the_version_file`（只比對 `BUNDLE_VERSION` 與 `cash-skills.version`，不觸及 manifest）。
  - reviewer source: Reviewer V finding 1（主 agent 已實機執行該 `rg` 指令複驗其失敗，並確認替代測試單獨執行回報 `OK`）

- severity: Warning / confidence: 100 / layer: design / disposition: fix-introduced / introduced_by: Round 4 Fix Action「修改 `design.md` D5 與 Implementation Contract 4、`tasks.md` 2.2 的 success：明訂 batch-only 參數 MUST 在該函式的任何內部 re-entry……上原樣保留」 / location: `tasks.md` 2.2 的 `success` 欄末句
  - summary: 追加的「確認該參數在 journal recovery 後的自我遞迴呼叫上被原樣轉傳」不是 primary target 可直接觀察的成功 marker：該測試以 manifest 缺失的 target 呼叫，函式在分類前即 fail closed，到不了 recovery 分支；manifest 存在時遞迴後的重新確認又會通過而無可觀察差異。違反 `success` 欄的欄位規則。
  - recommendation: 把該句移出 `success`，只保留在 D5／Implementation Contract 4 作為實作契約，並在 task 敘述中要求以程式碼層級檢查完成。
  - reviewer source: Reviewer V finding 3

- severity: Warning / confidence: 100 / layer: design / disposition: new / location: `tasks.md` 4.1（原編號，文件 task）的 `regression` 欄
  - summary: 該 regression 是 `./scripts/cash-skills/tests/skill-checks.fish`，而該腳本在 `:724` 執行 `test_bundle_version_history.py`，其 `check_history` 無條件要求 manifest 為 canonical。文件 task 原本排在 `--self` 之前，此時 `installer.py` 已被修改而 manifest 尚未重發，因此該 regression 必然失敗。這是 Round 4 為 1.1 建立的結論未傳播到文件 task 的結果——後者的 regression 是包含該 gate 的超集。
  - recommendation: 把文件 task 移到 `--self` 之後，使 `skill-checks.fish` 成為可執行的 regression。
  - reviewer source: Reviewer V finding 2

### Suggestion

- severity: Suggestion / confidence: 50 / layer: text / disposition: fix-introduced / introduced_by: Round 4 Fix Action「Decision 編號整理：新增的 D6 使原 D6–D13 順移為 D7–D14」 / location: `design.md` Risks 第二點 —— 該 Risk 描述 `--all --force` 的作用面，對應新編號的 D11，文字仍指向 D10（`--target` 的拒絕保留），是順移時漏改的一處；Reviewer V 已逐一比對五份 artifact 中全部 24 個 `D<n>` 出現位置，其餘全部正確。（Reviewer V finding 4）
- severity: Suggestion / confidence: 50 / layer: text / disposition: fix-introduced / introduced_by: Round 4 Fix Action「修改 `tasks.md` 2.4：regression 改為 `test_batch_reports_each_target_and_summary`（唯一實際走過 `--all` 分派迴圈的既有測試）」 / location: `tasks.md` 2.4 的 regression 理由句 —— 「唯一」為假，至少另有 `test_consumed_hold_hook_is_skipped_on_reentry_and_later_batch_targets` 與 `test_registry_modes_ignore_exact_empty_lines` 也會進入 per-record 迴圈；結論仍成立但前提句與 B1 原始缺陷同型。Reviewer V 另指出既有測試的 `assertIn` 對帶後綴的行同樣成立，因此無法偵測後綴外溢。（Reviewer V finding 5）
- severity: Suggestion / confidence: 100 / layer: text / disposition: fix-introduced / introduced_by: Round 4 Fix Action「修改 `specs/cash-skill-workflows/spec.md`：SHALL 分派句不再複述分派鍵……本 requirement MUST NOT 複述它」 / location: `specs/cash-skill-workflows/spec.md` 首段 —— 該 requirement 的第 1、2 句仍逐字複述分派鍵，第 4 句卻寫「本 requirement MUST NOT 複述它」，違反自己的 MUST NOT；Round 4 只移除了三處複述中的一處。（Reviewer V finding 6）
- severity: Suggestion / confidence: 50 / layer: design / disposition: fix-introduced / introduced_by: Round 4 Fix Action「新增 `design.md` D6……`specs/cash-cli/spec.md` 的分派段落補上『此後果 MUST 被視為分派的一部分而非未宣告的副作用』」 / location: `specs/cash-cli/spec.md` 的 receipt 刪除 MUST —— 未加成立條件，但 `conflict`／`newer` 早期返回與 `--dry-run` 都不建立 transaction，因此該 MUST 與同 requirement 的兩條零寫入 scenario 字面牴觸。（Reviewer V finding 7）

## Rating

- post-filter 累積 blocking set Critical 數：0
- post-filter 累積 blocking set Warning 數：2
- 非 blocking triaged finding 數：1
- critical_gap: false
- round_type: micro
- rationale: 唯一的 blocking 成員 B1（2.4 的 regression 欄）經 Reviewer V 回程式碼確認 `test_batch_reports_each_target_and_summary` 確實走過 `options.all` 的 per-record 迴圈、且若分派或 label 對映回歸該測試會失敗，判定 resolved 並移出集合。本輪新增兩個 `fix-introduced` Warning（1.1 的 `rg` look-behind 不可執行、2.2 的 success 含不可觀察 marker），皆由 Round 4 的修正引入，依規則進入 blocking set。第三個 Warning（文件 task 的 regression 含 history gate）disposition 為 `new` 且不涉及資料遺失或安全邊界，依規則列為非 blocking triaged finding，本輪仍一併修正。集合中仍有 blocking Warning，故不能 pass。

## Fix Actions

- 驗證解決移除追蹤（一筆）：B1 由 Round 4「2.4 的 regression 改為 `test_batch_reports_each_target_and_summary` 並如實記載舊測試涵蓋的是 launcher gate」解決，驗證 reviewer 為本輪 Reviewer V，證據為該測試位於 `test_installer_runtime.py:3583-3602`、以 `--register` 登錄兩個 target 後執行 `--all` 因而確實進入 `installer.py:3148-3177` 的 per-record 迴圈。
- 修改 `tasks.md` 1.1：verification 改為 `python3 scripts/cash-skills/tests/test_installer_runtime.py InstallerRuntimeTests.test_bundle_version_constant_matches_the_version_file`（主 agent 已實機執行確認可單獨執行並回報 `OK`），regression 改為同檔的 `test_bundle_runtime_paths_matches_the_source_inventory`，success 改為該測試通過且兩者皆為 `2.21.0`，並在 red 欄補上選用該測試的理由（只比對兩個版本值、不觸及 manifest，因而在本 task 完成時點必定可判定）。（解決 Warning 1）
- 修改 `tasks.md` 2.2：把 re-entry 轉傳從 `success` 移到 task 敘述，並明寫「此項以程式碼層級檢查完成而不列入 success marker，因為 manifest 缺失的測試情境在分類前即 fail closed、到不了 recovery 分支」。D5 與 Implementation Contract 4 的契約要求維持不變。（解決 Warning 2）
- 重排 `tasks.md` 第 4 節並更名為「發佈、文件與全套驗證」：`--self` 發佈由 4.2 提前為 4.1，文件 task 由 4.1 改為 4.2 並在其 regression 欄補上排序理由（該腳本包含 bundle history gate，gate 要求 manifest 已重新發佈為 canonical），全套回歸維持 4.3；task 1.1 red 欄中對 `--self` 的編號引用同步由 4.2 改為 4.1。`design.md` D14 的「排序不受限」改為「必須排在 D13 的 manifest 重新發佈之後」並說明理由。（解決 Warning 3）
- 修改 `design.md` Risks 第二點：`依 D10` 改為 `依 D11`。（解決 Suggestion 1）
- 修改 `tasks.md` 2.4：regression 理由句刪去「唯一」，改為「會實際走過 `--all` 的 per-record 分派迴圈並對兩個 receipt record 斷言逐字輸出與 `updated=2`」；`tasks.md` 2.1 的 success 追加 receipt record 的輸出行明確不含 `(vendored)` 的否定斷言，並註明理由是既有測試的 `assertIn` 對帶後綴的行同樣成立、無法偵測後綴外溢。（解決 Suggestion 2）
- 修改 `specs/cash-skill-workflows/spec.md` 首段：範圍句改為以引用界定（「適用於依 `Repo-vendored Cash bundle 發佈` requirement 的 batch publication-mode 分派段落判定為 receipt-based 的 registry record」），不再自行陳述判準；MUST NOT 收窄為「本 requirement 以引用界定自身範圍而 MUST NOT 自行陳述判準」；SHALL 句移除重複的權威性宣告；managed decision 句移除已無必要的非 regular shape 括號說明。此改寫同時消除 canonical source record 的字面歸屬歧義。（解決 Suggestion 3）
- 修改 `specs/cash-cli/spec.md` 的 receipt 刪除 MUST：加上成立條件「分派到 vendored 路徑且實際進入 publication transaction 的 record（即 real run 的 `update`）」，並明寫 `--dry-run` 與 `conflict`、`newer` 的早期返回不建立 transaction、MUST 維持零寫入且 MUST NOT 刪除該檔。（解決 Suggestion 4）
- 修正後已重跑機械自我檢查：annotation lint（兩份 delta 皆為 0）、requirement title 逐 byte identity（3 個標題全部命中 master）、identifier cross-grep、計數一致性（D1–D14 連號、Implementation Contract 1–12 連號、tasks 共 11 筆、probe 三支分割在三處一致），並確認四個被取代的舊措辭（look-behind `rg` 指令、「唯一會實際走過」、「MUST NOT 複述它」、「排序不受限」）全部零殘留，task 編號交叉引用（`4.1 的 --self`、`由 4.3 承擔`）在重排後正確。`openspec/signals/` 中沒有任何 `open` signal 帶有 `check` 欄位，改用既有 best-effort 判斷，本輪額外對照 `acceptance-path-infeasible-in-test-harness`（不可執行的 `rg` 指令與含 history gate 的 regression）與 `condition-rewrite-vacuously-true-in-excluded-case`（無條件的 receipt 刪除 MUST）兩個 issue class。
- 修正涉及 design、tasks 與 spec artifacts，已重新執行 `cash validate "dispatch-vendored-targets-in-batch"`，結果為 `Validation passed.`。
- 本輪 Fix Actions 修改的檔案全部位於 `openspec/changes/` 之下，依規則濾除後候選路徑為空，因此不呼叫 `touched ensure`／`touched record`，也不產生警告。

## Decision

next_round

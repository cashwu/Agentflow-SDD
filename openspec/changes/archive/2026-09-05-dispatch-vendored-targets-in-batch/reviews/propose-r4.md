# Cash Propose Review — Round 4

## Reviewer Findings

### Warning

- severity: Warning / confidence: 100 / layer: design / disposition: fix-introduced / introduced_by: Round 3 Fix Action「修改 `tasks.md` 2.4：……regression 改為既有的 `test_manifest_present_unsafe_shapes_fail_before_open_without_receipt_fallback`（已確認該測試存在且涵蓋同一組四種 shape）」 / location: `tasks.md` 2.4 的 `regression` 欄
  - summary: 該既有測試以 `run_target_cash` 執行 target 端 launcher 並斷言 `"code":"manifest_invalid"`，變造 shape 之後不再執行任何 installer mode，因此它涵蓋的是 launcher bootstrap gate 而非 installer 分派路徑。Round 3 只驗證了「測試存在」與「涵蓋同一組四種 shape」，未驗證它經過哪條程式路徑，導致 task 2.4 實際上沒有回歸防護。
  - recommendation: 改指向會實際走過 `--all` 分派迴圈的既有測試，並如實記載本檔沒有以 installer mode 涵蓋 unsafe manifest shape 的既有測試。
  - reviewer source: Reviewer A finding 2、Reviewer B F3（兩位獨立提出；主 agent 已讀 `test_installer_runtime.py:858-885` 與 `run_target_cash` 定義複驗）

- severity: Warning / confidence: 100 / layer: design / disposition: new / location: `tasks.md` 1.1 的 `verification`／`success`；次要 `design.md` D12 末句
  - summary: 1.1 的 primary verification `test_bundle_version_history.py` 在該 task 完成的時點必然失敗，且失敗理由與 success 所述無關：其 `__main__` 在 unittest 之後執行 `check_history`，而 `check_history` 要求 `.cash-skills/manifest.tsv` 逐 byte 等於由工作樹版本與 `installer.py` digest 導出的 canonical bytes，因此 bump 之後到 manifest 重新發佈之前必然以 `portable manifest is not canonical` 中止。
  - recommendation: 改用該時點可判定的手動斷言，history gate 的完整通過交由 `--self` 之後的全套回歸承擔；同時修正 D12 末句的失敗訊息。
  - reviewer source: Reviewer A finding 1（主 agent 已讀 `test_bundle_version_history.py:545-552` 與 `:318-328` 複驗）

- severity: Warning / confidence: 100 / layer: design / disposition: new / location: `proposal.md` Non-Goals、`design.md` Goals 與 Implementation Contract 9、`tasks.md` 2.1
  - summary: 「同時持有殘留 receipt 與 regular manifest」的 target 類別未被任何 artifact 定義，而其行為被本變更完全改寫：`install_vendored_target` 在 manifest 存在時不解析 receipt，並在 transaction 尾端無條件 `add_receipt_delete()`。實作前該 record 在 `--all` 下是 `failed` 且零寫入，實作後會被發佈並刪除其 receipt。proposal Non-Goals 與 design Goals 都以未定義的「receipt-based target」為主詞宣稱逐字不變，整份 artifact 未提及 `--all` 會刪除 receipt。
  - recommendation: 明確定義 receipt-based target、新增一條 Decision 記載此後果，並在 spec 與 task 2.1 的 success 釘住它。
  - reviewer source: Reviewer B F1（主 agent 已讀 `installer.py:2352-2360` 與 `:2566-2567` 複驗）

### Suggestion

- severity: Suggestion / confidence: 50 / layer: design / disposition: new / location: `design.md` D13、`tasks.md` 4.1 的 `red` —— 兩處宣稱 `skill-checks.fish` 對這兩份文件的斷言「全為正向 `assert_contains`」，實際上另有三個對 `CASH-INIT-RECEIPT.md` 的 `assert_absent`；結論仍成立但前提句為假。（Reviewer A finding 3）
- severity: Suggestion / confidence: 50 / layer: text / disposition: fix-introduced / introduced_by: Round 3 Fix Action「修改 `design.md`：Goals 第 5 條與 D3 改為以『非 regular shape』表述……」 / location: `specs/cash-cli/spec.md` scenario 標題「Unsafe manifest shape 一律在 receipt 路徑 fail closed」—— hard-linked regular manifest 在本 repo 既有詞彙中屬 unsafe shape 卻走 vendored 路徑，標題的全稱宣告過度一般化。（Reviewer A finding 4）
- severity: Suggestion / confidence: 50 / layer: text / disposition: fix-introduced / introduced_by: Round 3 Fix Action「……新增的分派 scenario 其 GIVEN 與 THEN 由『manifest-present』改為『具有 regular portable manifest』」 / location: 兩份 delta 共三個 scenario 的 GIVEN／THEN 仍以 presence 措辭，未帶 regular-shape 限定詞，屬同一修正的未竟傳播。（Reviewer A finding 5）
- severity: Suggestion / confidence: 50 / layer: design / disposition: new / location: `design.md` D5 與 Implementation Contract 4、`tasks.md` 2.2 —— batch-only 參數的契約未要求在 `install_vendored_target` 的 journal-recovery 自我遞迴呼叫上轉傳，漏傳會讓重入以關閉狀態重新分類。（Reviewer A finding 6、Reviewer B F6，兩位獨立提出）
- severity: Suggestion / confidence: 50 / layer: design / disposition: new / location: `design.md` Risks、`proposal.md` Motivation —— 分派鍵是未經認證的檔案存在性；manifest 宣告版本高於 source 時 `newer` 早期返回且不計入非零結束碼，使該 target 從 batch 的錯誤訊號上消失，而實作前是 `failed` + exit 1。此轉換邊界未被任何 Risk 涵蓋。（Reviewer B F2，原 Warning 50，經信心過濾降為 Suggestion）
- severity: Suggestion / confidence: 50 / layer: design / disposition: new / location: `design.md` Implementation Contract 6、`tasks.md` 2.6 —— vendored 路徑的 `conflict` 以回傳值結束因而不產生 stderr 診斷行，receipt 路徑的 conflict 則必定伴隨一行 drift 說明；同一份 summary 會混有可行動與不可行動的 conflict，此不對稱未被涵蓋。（Reviewer B F4，原 Warning 50，經信心過濾降為 Suggestion）
- severity: Suggestion / confidence: 50 / layer: design / disposition: new / location: `specs/cash-skill-workflows/spec.md` SHALL 分派句 —— 該句無條件複述分派鍵，與 cash-cli delta probe 第 (1)(2) 支（canonical source、非既存目錄）相反；根因是同一分派鍵被複述在三處。（Reviewer B F5）
- severity: Suggestion / confidence: 50 / layer: design / disposition: new（複雜度透鏡）/ location: `design.md` D2 第 1 支 —— 「resolved path 不是既存目錄 → receipt」在任何輸入上都不改變結果：該類輸入在第 3 支求值時本就以 `FileNotFoundError`／`NotADirectoryError` 落入 catch-all 得到相同結果與相同診斷，屬規格未要求的防禦性分支。（Reviewer B F7）
- severity: Suggestion / confidence: 50 / layer: design / disposition: new（複雜度透鏡）/ location: `design.md` D5 —— batch-only 參數是三輪修正中成本最高的堆疊，而該窗口的每個可能結果都是 forward-to-portable 而非信任降級。（Reviewer B F8；主 agent 保留該機制，僅補上「為何既有 revalidation 不足以涵蓋此窗口」的論證）
- severity: Suggestion / confidence: 50 / layer: design / disposition: new / location: `tasks.md` 2.1、2.5 —— 兩份 delta 有兩處 scenario 斷言沒有任何 task 承接：vendored record 執行後不存在 receipt，以及 registry 混入 canonical source path 的 record。（Reviewer B F9）

## Rating

- post-filter 累積 blocking set Critical 數：0
- post-filter 累積 blocking set Warning 數：1
- 非 blocking triaged finding 數：2
- critical_gap: false
- round_type: full
- rationale: 本輪是本次 run 的第四輪 checkpoint，兩位 reviewer 對三個 blocking 成員（M3、W1、W2）獨立給出一致的 resolved 判定並各自附上程式碼證據，Reviewer A 另以臨時 target 實機驗證 hard-link 情境在三個 mode 下的診斷差異，因此三者依 verified-resolution 規則全部移出集合。集合中僅剩一個 `fix-introduced` Warning：task 2.4 的 regression 欄，由 Round 3 未查證程式路徑就採用的既有測試引入，兩位 reviewer 獨立指出。本輪其餘 Critical/Warning 級別的兩筆（1.1 的 verification 不可行、receipt 刪除未宣告）disposition 均為 `new` 且不符合 Safety exception 判準——後者刪除的是 manifest 存在時明文定義為 non-authoritative 的 machine-local residue，且該刪除本身是 `Repo-vendored Cash bundle 發佈` requirement 既有的 cleanup 契約，非本變更引入的破壞性行為——因此依規則列為非 blocking triaged finding，本輪仍一併修正。集合中仍有一個 blocking Warning，故不能 pass。

## Fix Actions

- 驗證解決移除追蹤（三筆）：M3 由 Round 3「workflows delta 首段與 SHALL 句改為 regular-shape 二分」解決，Reviewer A 以 master spec 逐 requirement diff、Reviewer B 以兩份 delta 的路徑歸屬對照確認；W1 由 Round 3「2.4 改用 hard-link 情境作 red 載體」解決，Reviewer A 實機驗證 `--vendor`／`--target`／`--register` 對 hard-linked manifest 的三種診斷、Reviewer B 追完 `snapshots` → `optional_snapshot` → `read_regular` 的 `allow_hardlink=False` 路徑確認；W2 由 Round 3「2.5 改為 pure-refactor 分類的 N/A」解決，兩位皆逐步複驗 `managed parent is not a directory` 為 `InstallerError` 且被迴圈捕捉。驗證 reviewer 為本輪 Reviewer A 與 Reviewer B。
- 修改 `tasks.md` 2.4：regression 改為 `test_batch_reports_each_target_and_summary`（唯一實際走過 `--all` 分派迴圈的既有測試），並如實記載 `test_manifest_present_unsafe_shapes_fail_before_open_without_receipt_fallback` 涵蓋的是 launcher 端 `manifest_invalid` gate 而非任何 installer mode。（解決 Warning 1）
- 修改 `tasks.md` 1.1：verification 改為版本檔與 `BUNDLE_VERSION` 相等的手動斷言、regression 改為 `git diff --name-only` 確認此時點只有兩個檔案被改、success 同步改寫，並在 red 欄敘明不採用 history gate 作為 verification 的理由；`design.md` D12 末句改為正確的 `portable manifest is not canonical` 失敗訊息並說明該腳本只能在 manifest 重新發佈之後才有意義。（解決 Warning 2）
- 新增 `design.md` D6（原 D5b，已併入連號）記載 batch 分派到 vendored 路徑的 record 其殘留 receipt 會在同一 transaction 內被刪除；Goals 與 proposal Non-Goals 明確定義 receipt-based target 為「manifest 缺失或非 regular shape 的 target」並明寫同時持有殘留 receipt 與 regular manifest 的 target 不屬此列；Implementation Contract 9 補上該刪除；`specs/cash-cli/spec.md` 的分派段落補上「此後果 MUST 被視為分派的一部分而非未宣告的副作用」；`tasks.md` 2.1 的 success 追加「vendored target 執行後其殘留 receipt 不存在」。（解決 Warning 3，同時解決 Suggestion 9 的前半）
- 修改 `design.md` D2 與 `specs/cash-cli/spec.md` probe 分割：移除「resolved path 不是既存目錄」該支，分割由四支縮為三支，並在 D2 記載移除理由（該類輸入在第 2 支求值時本就以 `FileNotFoundError`／`NotADirectoryError` 落入 catch-all 得到相同結果）；`tasks.md` 2.1、2.4 與 `design.md` D3 的支號引用同步更新。（解決 Suggestion 8）
- 修改 `design.md` D5 與 Implementation Contract 4、`tasks.md` 2.2 的 success：明訂 batch-only 參數 MUST 在該函式的任何內部 re-entry（含 journal recovery 後的自我遞迴）上原樣保留；`specs/cash-cli/spec.md` 的重新確認 MUST 改為涵蓋「任何分類進入點（含 journal recovery 後的重入）」；D5 另補上「既有的 pre-lock 與 locked snapshot revalidation 為何不足以涵蓋此窗口」的論證。（解決 Suggestion 4、Suggestion 10）
- 修改 `design.md` D13 與 `tasks.md` 4.1 的 red：改為「正向 `assert_contains` 不會對過時敘述失敗，既有的三個 `assert_absent` 也都不涵蓋本次要改寫的敘述」。（解決 Suggestion 1）
- 修改 `specs/cash-cli/spec.md`：scenario 標題收窄為「非 regular 的 manifest shape 在 receipt 路徑 fail closed」，並新增 scenario「Hard-linked regular manifest 由 vendored 路徑 fail closed」補上 spec 原本缺少的 `failed` 後綴載體；「Batch 依 target 模式分派」與「Register 接受 vendored target」兩個 scenario 的 GIVEN／THEN 改為 regular-shape 措辭。（解決 Suggestion 2、Suggestion 3）
- 修改 `specs/cash-skill-workflows/spec.md`：SHALL 分派句不再複述分派鍵，改為「依 `Repo-vendored Cash bundle 發佈` requirement 的 batch publication-mode 分派段落判定其發佈模式後分派；該段落是分派鍵的唯一權威定義，本 requirement MUST NOT 複述它」；兩個 scenario 的措辭同步收窄。（解決 Suggestion 3、Suggestion 7）
- 修改 `design.md` Risks：新增「分派鍵是 target 工作樹中一個未經認證的檔案」一條，明寫 `newer` 早期返回會使該 target 從非零結束碼上消失、首次進入 vendored 模式無明示動作也無公告；新增「vendored 路徑的 `conflict` 不附 stderr 診斷」一條。（解決 Suggestion 5、Suggestion 6）
- 修改 `design.md` Implementation Contract 6：補上 vendored `conflict` 以回傳值結束因而不產生 stderr 行的不對稱說明。（解決 Suggestion 6）
- 修改 `tasks.md` 2.5 的 success：追加「registry 另含 canonical source path 的 record 時其 stderr 為 receipt 路徑既有的 non-source 診斷」。（解決 Suggestion 9 的後半）
- Decision 編號整理：新增的 D6 使原 D6–D13 順移為 D7–D14，全部內部交叉引用（`D4 的安全網`、`D13 的 manifest 重新發佈`、`D7 的 `(vendored)` 後綴`、`D3 的設計`）已逐一複驗指向正確的 Decision。
- 修正後已重跑機械自我檢查：annotation lint（兩份 delta 皆為 0）、requirement title 逐 byte identity（3 個標題全部命中 master）、identifier cross-grep、計數一致性（D1–D14 連號、Implementation Contract 1–12 連號、tasks 共 11 筆、probe 分割在 design／spec／tasks 三處一致為三支且支號引用全部正確）。`openspec/signals/` 中沒有任何 `open` signal 帶有 `check` 欄位，改用既有 best-effort 判斷，本輪額外對照 `acceptance-criterion-unreachable-at-specified-point`（1.1 的 verification）、`declared-scope-implementation-drift`（receipt 刪除未宣告）與 `guard-fixture-content-unanchored`（2.4 的 regression 指向錯誤程式路徑）三個 issue class。
- 修正涉及 proposal、design、tasks 與 spec artifacts，已重新執行 `cash validate "dispatch-vendored-targets-in-batch"`，結果為 `Validation passed.`。
- 本輪 Fix Actions 修改的檔案全部位於 `openspec/changes/` 之下，依規則濾除後候選路徑為空，因此不呼叫 `touched ensure`／`touched record`，也不產生警告。

## Decision

next_round

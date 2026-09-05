# Cash Propose Review — Round 1

## Reviewer Findings

### Critical

- severity: Critical / confidence: 100 / layer: design / location: `design.md` D2 第 3 支、`specs/cash-cli/spec.md` unsafe manifest scenario、`tasks.md` 2.3（原編號）
  - summary: 原設計宣稱「symlink、FIFO 等不安全 shape 都算存在而分派到 vendored 分支」，但 `path_is_present` 對 symlink manifest 會拋出 `symlink managed boundary` 而非回傳真，整條機制鏈不成立，對應 scenario 與 task 的斷言不可能達成。
  - recommendation: 改寫第 3 支語意，並依 `path_is_present` 的實際行為把 unsafe shape 拆成兩支分別描述，改以「兩支都 fail closed 且零寫入」作為不變式。
  - reviewer source: Reviewer A #1、Reviewer B F1（獨立提出，機制與證據一致）

- severity: Critical / confidence: 100 / layer: design / location: `design.md` D1／D2、Implementation Contract、`specs/cash-cli/spec.md` probe 分割段落
  - summary: probe 的例外防護只規定在第 1 支，但第 3 支同樣會拋出（含 `ensure_contained` 未包裝而逸出的原生 `PermissionError`）；probe 若在 per-record `try` 之外求值，任一 record 拋出就會中止整個 batch、不印 summary，回歸掉既有的「單一 target failed 不停止後續 targets」契約。
  - recommendation: 把整個函式主體包在單一 try 內、任何 exception 一律落入 catch-all，並要求 probe 呼叫置於 per-record `try` 之內；補一個 probe 例外不中止批次的契約測試。
  - reviewer source: Reviewer A #3（Warning）、Reviewer B F2（Critical，附實測證據）；severity 取較高者

- severity: Critical / confidence: 100 / layer: design / location: 缺漏的 delta —— `openspec/specs/cash-skill-workflows/spec.md` 的 `### Requirement: 版本感知的 cash skill 批次安裝`
  - summary: 真正擁有 `--all` publication 語意的 requirement 未被 MODIFY。其明文「`--all` SHALL 重用與 `--target` 相同的完整 installer target workflow」且 managed decision 明列 `receipt`，與新分派行為正面衝突而未宣告優先權。
  - recommendation: 在 delta 增加該 requirement 的 MODIFIED 區塊，首段加入範圍限縮句並把既有 scenario 的 GIVEN 收窄為 receipt-based record。
  - reviewer source: Reviewer A #2（主 agent 已對照 master spec 逐句驗證）

### Warning

- severity: Warning / confidence: 100 / layer: design / location: `design.md` D4／Implementation Contract、`tasks.md` 2.1–2.3（原編號）
  - summary: 契約明訂 ` (vendored)` 後綴「與最終 label 無關」，但測試清單只驗證 `updated` 與 `would-update` 兩種成功 label，該 MUST 完全無驗證。
  - recommendation: 在契約與 task success 條件補上 vendored 分派失敗行仍帶後綴的斷言。
  - reviewer source: Reviewer B F3

- severity: Warning / confidence: 100 / layer: design / location: `proposal.md` `## Impact` → Affected code
  - summary: 未宣告會因本變更變成事實錯誤的使用者文件；`skill-checks.fish` 的文件斷言全為正向 `assert_contains`，不會偵測過時敘述。主 agent 已逐行驗證 `CASH-INIT-RECEIPT.md:221`、`CASH-SKILLS.md:83`、`:98`、`:188`、`:197` 五處敘述受影響。
  - recommendation: 把兩份文件加入 Impact 並新增對應 task。
  - reviewer source: Reviewer A #9（Suggestion 50）、Reviewer B F4（Warning 100）；severity 與 confidence 取較高者

### Suggestion

- severity: Suggestion / confidence: 50 / layer: design / location: `specs/cash-cli/spec.md` 既有句「registry操作模式與既有receipt-based batch語意不變」 — 與新增段落併存形成未宣告優先權的內部矛盾。（Reviewer A #4）
- severity: Suggestion / confidence: 50 / layer: design / location: `tasks.md` 4.2（原編號）delivery 宣告了該 task 不會修改的檔案。（Reviewer A #5）
- severity: Suggestion / confidence: 50 / layer: text / location: `specs/cash-cli/spec.md` — 新增段落與前段之間缺空行而被併入 bundle version 段落，且「下段」交叉引用指向錯誤段落。（Reviewer A #6）
- severity: Suggestion / confidence: 50 / layer: text / location: `design.md` D3／D6 — 以絕對行號 `line 1984` 引用 `installer.py`，本變更自身即會使該行號漂移。（Reviewer A #7、Reviewer B F8）
- severity: Suggestion / confidence: 50 / layer: design / location: `design.md` Implementation Contract 與 Risks — `--all --force` 的作用面未被任何 scenario、契約條目或風險記載涵蓋。（Reviewer A #8 Suggestion 50、Reviewer B F5 Warning 50；合併後經信心過濾降為 Suggestion）
- severity: Suggestion / confidence: 50 / layer: design / location: `design.md` D3 — probe 與 `install_vendored_target` 之間的 TOCTOU：manifest 若在窗口內消失，batch 會執行 spec 要求須明示 `--vendor` 的 forward cutover。（Reviewer B F6）
- severity: Suggestion / confidence: 50 / layer: design / location: `design.md` D2 第 1 支 — 列舉 `ValueError` 在 batch 路徑上不可達，屬契約未要求的防禦性分支。（Reviewer B F7）

## Rating

- post-filter 累積 blocking set Critical 數：3
- post-filter 累積 blocking set Warning 數：2
- 非 blocking triaged finding 數：0
- critical_gap: true
- round_type: full
- rationale: 本輪是本次 run 的第一輪且未 seeded，因此全部通過信心過濾的 Critical 與 Warning 皆為 blocking。兩位 reviewer 獨立在同一機制上得到一致結論（`path_is_present` 對 symlink 的實際行為），且主 agent 已就 `ensure_contained` 的 `S_ISLNK` 檢查位置、`os.lstat` 只捕捉 `FileNotFoundError`、以及 `版本感知的 cash skill 批次安裝` 的明文衝突逐項獨立複驗，三項 Critical 均為 CONFIRMED。存在 blocking Critical，因此本輪不可能 pass。

## Fix Actions

- 修改 `design.md`：重寫 Context 補上 `path_is_present` 的實測語意；D1 改為「整個函式主體單一 try、任何 exception 一律回傳 receipt」；D2 移除 exception 型別列舉、四支分割改以 catch-all 涵蓋任何例外；新增 D3 明訂 unsafe manifest shape 在兩支上都 fail closed 且零寫入的不變式；新增 D5 要求 batch 分派的 vendored record 在分類前重新確認 manifest；新增 D7 要求 probe 呼叫置於 per-record `try` 內；新增 D10 記錄 `--all --force` 的繼承邊界；新增 D13 說明使用者文件需同步且不受 bundle history gate 約束；D6 補上後綴與最終 label 無關；D3／D9 的絕對行號引用改為函式名加診斷字串；Risks 補上 `--all --force` 作用面與 unsafe shape 診斷來源分歧兩條。（解決 Critical 1、Critical 2、Warning 1，以及 Suggestion 4、5、6、7）
- 修改 `specs/cash-cli/spec.md`：把 batch 分派段落移到 reverse-conversion 段落緊接其後並補上段落間空行，交叉引用改為「緊接其後」；分割條文改為「任何例外落入 catch-all」；新增 unsafe shape 雙分支 fail-closed 不變式、manifest 重新確認條款、後綴與 label 無關條款、單一 record 失敗不中止批次條款、`--all --force` 邊界條款；既有「registry操作模式與既有receipt-based batch語意不變」改寫為範圍限縮版；scenario 由原本 6 條調整為 7 條，新增「Unsafe manifest shape 在兩支上都 fail closed」與「Batch force 沿用 vendored 收斂邊界」，並改寫「Probe 無法判定時退回 receipt 路徑」以涵蓋例外情境。（解決 Critical 1、Critical 2，以及 Suggestion 1、3、5、6）
- 修改 `specs/cash-skill-workflows/spec.md`：新增 `### Requirement: 版本感知的 cash skill 批次安裝` 的 MODIFIED 區塊，首段加入範圍限縮句與分派語意、回報段補上 ` (vendored)` 後綴與「發佈模式判定不得中止批次」，四條既有 scenario 的 GIVEN 收窄為 manifest 缺失的 receipt-based record，並新增「批次對兩種發佈模式的 record 都完成分派」scenario。（解決 Critical 3）
- 修改 `proposal.md`：Proposed Solution 補上 probe 不拋例外、malformed 一律 fail closed、manifest 重新確認與後綴與 label 無關；Non-Goals 補上不修改 managed guidance block 與不為 `--all --force` 另設閘門；Modified Capabilities 補上第二條 requirement；Impact 的 Modified 加入 `CASH-SKILLS.md` 與 `CASH-INIT-RECEIPT.md`。（解決 Critical 3、Warning 2）
- 修改 `tasks.md`：新增 task 2.2（manifest 重新確認）、2.4（unsafe shape 雙分支，success 含 `failed: <path> (vendored)` 斷言）、2.5（probe 例外不中止批次）、2.6（`--all --force` 收斂邊界）、4.1（文件同步）；原 4.2 的 delivery 由誤宣告的測試檔改為 `(none)` 並重編為 4.3。（解決 Warning 1、Warning 2，以及 Suggestion 2、5、6）
- 信心過濾降級追蹤：Reviewer A #4、#5、#6、#7、#8 與 Reviewer B F5、F6、F7、F8 的 confidence 均為 50，依 `[50, 80)` 規則降為 Suggestion，不計入 blocking set；雖非 blocking，本輪仍一併修正。
- 修正後已重跑機械自我檢查：annotation lint（兩份 delta 的 `<!--`／`-->` 皆為 0）、requirement title 逐 byte identity（3 個標題全部命中 master spec）、identifier cross-grep（`registry_publication_mode`、`2.21.0`、`(vendored)`、`symlink managed boundary`、兩份文件路徑、11 個測試名稱全部一致）、計數一致性（D1–D13 連號、Implementation Contract 1–12 連號、D2 四支與 spec 的 (1)–(4) 及 tasks 的「四支」一致、Impact 有效 affected-code 條目 6 筆）、8 個被引用的既有 regression 測試名稱在 `test_installer_runtime.py` 中皆存在。`openspec/signals/` 中沒有任何 `open` signal 帶有 `check` 欄位，因此改用既有 best-effort 判斷，已對照 `overlapping-classification-without-precedence`、`classification-partition-not-exhaustive`、`malformed-metadata-misclassified-as-absent`、`spec-precedence-exception-missing`、`fallback-preempts-existing-selection`、`version-bump-sequenced-after-guarded-edits` 六個 issue class 檢查本輪修正。
- 修正涉及 proposal、design、tasks 與 spec artifacts，已重新執行 `cash validate "dispatch-vendored-targets-in-batch"`，結果為 `Validation passed.`。
- 本輪 Fix Actions 修改的檔案全部位於 `openspec/changes/` 之下，依規則濾除後候選路徑為空，因此不呼叫 `touched ensure`／`touched record`，也不產生警告。

## Decision

next_round

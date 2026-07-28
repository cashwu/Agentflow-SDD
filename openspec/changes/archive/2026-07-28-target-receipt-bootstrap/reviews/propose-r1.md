# Cash Propose Review — Round 1

## Reviewer Findings

### Critical

- severity: Critical｜confidence: 98｜layer: design｜location: design.md D1/D6/Contract 4、proposal.md Non-Goals、specs delta 兩個 scenario｜summary: launcher `validate_receipt` 硬性要求 runtime record path 以 `.cash-skills/lib/cash_cli/` 開頭且以 `.py` 結尾（`.cash-skills/bin/cash:238-243`），原設計把 `.cash-skills/bin/cash-init` 作為 runtime record 納入 receipt，與「validate_receipt 檢核完全不動」的 Non-Goals 邏輯互斥——依原 tasks 部署後所有 target 的 cash CLI 會全面以 `receipt_invalid` 不可用｜recommendation: 放棄 bin/ 新檔，init 邏輯移入既有 lib 內 runtime 檔或既有 module｜來源: Reviewer A 與 Reviewer B 獨立提出（A-F1、B-F2 合併）
- severity: Critical｜confidence: 95｜layer: design｜location: design.md D5、tasks.md 2.3、proposal.md Impact（.cash-skills/bin/cash）｜summary: launcher bytes 受三重凍結——master spec「Stable bootstrap bytes不得隨一般bundle version改變」、`test_bundle_version_history.py` 的 introduction-commit byte 斷言（bump 亦失敗）、`installer.py:985` `publish_launcher` 對 bytes 不同的既有 launcher raise migration error——原 D5 修改 launcher 診斷不可實作，新 bytes 也無法經 `--all` 送達任何既有 target｜recommendation: 放棄 launcher 診斷修改，引導改由文件承擔｜來源: Reviewer B
- severity: Critical｜confidence: 90｜layer: design｜location: tasks.md 5.3、design.md D6；installer.py:498-507、:1384-1393｜summary: `parse_receipt` 要求列數與 expected inventory 完全相等且逐筆 path 相等，並在版本比較之前執行——bundle inventory 一擴充（新增任何 record），全部既有 registry targets 的 `--all` 升級即以 execution error 失敗且 `--force` 不可繞過（正是 open signal `trust-root-inventory-blocks-payload-extension` 的 issue class）｜recommendation: 本 change 完全避免 inventory 擴充｜來源: Reviewer B

### Warning

- severity: Warning｜confidence: 90｜layer: design｜location: specs delta scenario「Launcher 診斷引導初始化」、proposal.md Motivation｜summary: receipt 檔案缺失時 launcher 實際以 `bootstrap_invalid` 失敗（`open_regular`，bin/cash:68），`receipt_invalid` 只涵蓋內容無效；原 scenario 的 GIVEN＋WHEN 組合在現行 code 下不可能發生，歸檔會固化錯誤前提｜recommendation: 更正錯誤 code 敘述並移除不可實作的診斷 scenario｜來源: Reviewer A
- severity: Warning｜confidence: 85｜layer: design｜location: design.md D3/Contract 4｜summary: receipt 首行 `version` 在 target 端沒有已定義來源——`cash-skills.version` 是 source-only 檔、fresh clone 無舊 receipt 可讀，原 artifacts 對版本來源零著墨｜recommendation: installer module 內嵌版本常數並以 contract test 守衛其與 `cash-skills.version` 相等｜來源: Reviewer B
- severity: Warning｜confidence: 95｜layer: design｜location: tasks.md 1.1、proposal.md Impact；test_bundle_version_history.py:68-82｜summary: `check_history` 的 replaceable 守衛集合是 `lib/cash_cli` 的 `rglob("*.py")` 加 24 skills 的封閉 filter，原設計的 `.cash-skills/bin/cash-init` 完全落在版本守衛之外，違反「相同版本內容漂移 MUST 使 contract test 失敗」的治理意圖｜recommendation: 不新增 filter 外的檔案｜來源: Reviewer B
- severity: Warning｜confidence: 80｜layer: design｜location: proposal.md Motivation、design.md D3/Contract 1｜summary: 「clone 即用」隱含依賴 umask 022——umask 002 環境 checkout 出 0775/0664，launcher 自檢與 inventory mode 檢核都會 fail closed，原 artifacts 未承認此假設也無補救定義｜recommendation: init 模式加入 managed inventory 的 mode 正規化步驟並以 umask fixture 測試｜來源: Reviewer B

### Suggestion

- severity: Suggestion（Warning 75 經 confidence filter 降級）｜confidence: 75｜layer: design｜location: design.md D7｜summary: cash-init 面向環境最未知的使用者卻無 python 版本檢查契約，舊直譯器上是 traceback 而非 JSON error｜recommendation: 增列 `init_python_version` 並載明 import 期語法失敗為已接受限制｜來源: Reviewer B
- severity: Suggestion（Warning 70 經 confidence filter 降級）｜confidence: 70｜layer: design｜location: design.md D7｜summary: exit code 語意與 JSON／文字輸出選路未定義，測試無法決定性斷言｜recommendation: 明定 exit 0/1 與 stdout 固定 JSON｜來源: Reviewer A
- severity: Suggestion｜confidence: 85｜layer: design｜location: tasks.md 3.1｜summary: launcher 診斷與併發 flock 兩個 scenario 缺自動化測試支撐｜recommendation: 測試補 flock 序列化案例（launcher 診斷項隨其 scenario 移除而不適用）｜來源: Reviewer A
- severity: Suggestion｜confidence: 80｜layer: design｜location: design.md D3 與 Risks｜summary: lock 缺失的處置在流程順序（flock 先於 inventory 檢核）與 Risks 敘述間不一致，error code 未定｜recommendation: 明訂 lock 存在檢查先於 flock、缺失以 `init_inventory_invalid` 失敗｜來源: Reviewer A
- severity: Suggestion｜confidence: 60｜layer: design｜location: design.md D3 步驟 5-7｜summary: 寫入路徑的目錄層防護（`.cash-skills` non-symlink、directory-fd containment）未明列，留有 symlink 縫隙｜recommendation: 明文沿用 installer 的 containment 與 atomic_write 語意｜來源: Reviewer B

## Rating

- post-filter cumulative blocking set Critical count: 3
- post-filter cumulative blocking set Warning count: 4
- 非阻塞 triaged finding count: 5
- critical_gap: true
- round_type: full
- rationale: 首輪全部存活 Critical/Warning 均為 blocking。三個 Critical 互相咬合並經雙方 reviewer 實檔驗證：launcher runtime path 檢核、launcher bytes 三重凍結、installer 舊 receipt 嚴格解析共同使原設計（bin/ 新檔＋launcher 診斷＋inventory 擴充）在部署面結構性不可實作。屬 proposal 層級的設計缺陷，但可在 propose fix loop 內以重新設計解決（cash-propose 在自身 design.md 定義機制屬正常修正），故走 next_round 而非 abort。

## Fix Actions

主 agent 先實檔重新驗證 reviewer 引用的六個關鍵位置（bin/cash:238-243 runtime path 檢核、installer.py import 形式與 :1915 `__main__`、parse_receipt :498-507、install_target :1384-1405、publish_launcher :981-996、check_history filter :68-82），全部證實後執行整體重設計（方案：init 邏輯嵌入既有 runtime record，零新檔、零 inventory 擴充、零 launcher 修改）：

1. proposal.md 全檔重寫：交付物改為 `cash_cli.installer` 的 `--init-receipt` 模式（`PYTHONPATH=.cash-skills/lib python3 -m cash_cli.installer --init-receipt`）；Motivation 更正 `bootstrap_invalid`／`receipt_invalid` 二分（解 Warning 4）；Motivation 新增三重凍結約束的設計依據；Non-Goals 明定 launcher bytes 不動、inventory 不擴充；Alternatives 記載被否決的 bin/ 新檔、launcher 診斷、auto-init 三路徑及其實證理由；Impact 移除 `.cash-skills/bin/cash-init`、`.cash-skills/bin/cash`，測試檔更名 `scripts/cash-skills/tests/test_init_receipt.py`（解 Critical 1、2、3 與 Warning 6 的 Impact 面）。
2. design.md 全檔重寫：Context 記載三重凍結（含行號證據）；D1 進入形式；D2 `BUNDLE_VERSION` 常數＋contract test 守衛（解 Warning 5）；D3 十步流程含 python 檢查（Suggestion 1）、lock 存在檢查先於 flock 且缺失為 `init_inventory_invalid`（Suggestion 4）、mode 正規化（解 Warning 7）、containment 沿用（Suggestion 5）；D5 引導改由 CASH-SKILLS.md 承擔（解 Critical 2）；D7 exit 與輸出契約（Suggestion 2）；Contract 與 Risks 對應更新。
3. specs/cash-cli/spec.md 全檔重寫：ADDED requirement 改述 `--init-receipt` 模式；移除「Launcher 診斷引導初始化」與「納入 bundle 與 receipt 治理」兩個不可實作 scenario；新增 umask 正規化、版本常數守衛、inventory 未擴充升級回歸三個 scenario；error codes 增為六個。
4. tasks.md 全檔重寫：移除 bin/ 新檔與 launcher 修改任務；2.2 改為 launcher byte 不變驗證；3.1 補 umask fixture 與 flock 序列化測試（Suggestion 3）；5.3 補 inventory 未擴充回歸證據。

修正後 `"$cash_cli" validate target-receipt-bootstrap` 重跑通過；post-fix mechanical self-check 通過（舊設計識別字零殘留、annotation 0/0、ADDED 標題無撞名、六個 error codes 三處一致、identifier 跨檔一致）。本輪修正檔案均位於 change 目錄內，無 change 目錄外路徑需記入 touched。

## Decision

next_round

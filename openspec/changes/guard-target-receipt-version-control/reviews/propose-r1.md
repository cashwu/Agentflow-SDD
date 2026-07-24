# Cash Propose Review — Round 1

## Reviewer Findings

### Critical

- severity: Critical / confidence: 95 / layer: design / location: `tasks.md` 2.1 + 4.1
  summary: task 2.1 修改 stable launcher `.cash-skills/bin/cash`，違反既有 stable bootstrap 不可變契約，且 `test_bundle_version_history.py` 必然失敗。
  recommendation: 將 launcher 診斷移出本 change，或另行設計 stable bootstrap migration 契約。
  reviewer: A

- severity: Critical / confidence: 90 / layer: design / location: `design.md` Implementation Contract；`tasks.md` 2.1
  summary: launcher bytes 一旦改變，`installer.py:701-704` 的 `publish_launcher` 會使全部既有 installed target 安裝失敗，正好封死本 change 要拯救的族群。
  recommendation: 同上；或把 installed-target 補救指示放到 replaceable runtime 可覆蓋的位置。
  reviewer: A

- severity: Critical / confidence: 90 / layer: design / location: `specs/cash-cli/spec.md` Target 版控排除保護（source bootstrap 模式）
  summary: 將 `--self` 納入保護範圍，牴觸 master spec「Real run MUST 只以 held receipt-parent FD 原子建立或替換 receipt」與「current self receipt MUST 零寫入」；且 `bootstrap_source()` 無 transaction，無法滿足「同一 transaction 內」與 rollback 要求。
  recommendation: 將 source bootstrap 移出範圍列為 Non-Goal，或以 MODIFIED 放寬既有條文並定義新的結果分類。
  reviewer: A + B（獨立提出，合併）

- severity: Critical / confidence: 85 / layer: design / location: `specs/cash-cli/spec.md`（delta 全為 ADDED）
  summary: 附加 `.gitignore` 牴觸既有封閉列舉條文：upgrade/force「其他 project-owned bytes 維持不變」、rollback 範圍列舉、以及「全部一致時回報 current 且零寫入」的 scenario。delta 全為 ADDED，未以 MODIFIED 承接，合併後 master spec 將自相矛盾。
  recommendation: 對 `Bundle 安裝與 runtime receipt` 提出 MODIFIED delta，更新三處列舉與該 scenario。
  reviewer: A + B（獨立提出，合併）

- severity: Critical / confidence: 85 / layer: design / location: `design.md` 寫入契約；`specs/cash-cli/spec.md` Scenario「既有內容逐 byte 保留」
  summary: 既有 `.gitignore` 無尾端換行時，「逐 byte 保留」與「附加至尾端」互相矛盾；直接附加會產生 `node_modules.cash-skills/receipt.tsv`，同時毀掉使用者原規則且未真正建立所需規則，而 installer 仍回報成功。
  recommendation: 明訂無尾端 LF 時 MUST 先補 LF 再附加，並新增對應 Scenario 與測試 fixture。
  reviewer: B

### Warning

- severity: Warning / confidence: 80 / layer: design / location: `.cash-skills/bin/cash:287-293`；delta Installed target 失效診斷可行動
  summary: 兩個 `bootstrap_invalid` 出口早於 `validate_receipt()` 內的 layout 偵測，目前任何 layout 都拿不到 hint；要滿足新要求須把 `is_source_layout()`（含 git subprocess 與 30+ 次 lstat）提前到 stable identity 驗證之前，反轉既有邊界順序。
  recommendation: 定義不依賴檔案內容、不執行 subprocess 的輕量 layout 判定供 `bootstrap_invalid` 使用，或限縮該診斷涵蓋範圍。
  reviewer: A + B（獨立提出，合併）

- severity: Warning / confidence: 80 / layer: design / location: `installer.py:424-447` `installation_inputs`
  summary: `.gitignore` 未納入 snapshot revalidation 集合；附加只能以 full-file `atomic_write` 實作，plan 與 commit 之間的外部修改會被靜默整段覆寫。
  recommendation: 將該檔納入 `target_paths`，並明訂判定與寫入內容 MUST 由同一份 no-follow snapshot 導出且納入 revalidation。
  reviewer: B

- severity: Warning / confidence: 80 / layer: design / location: `scripts/cash-skills/tests/test_installer_runtime.py:1454`
  summary: 新增 transaction operation 會位移 `CASH_INSTALL_FAIL_AFTER` 的硬編索引（`47`），使既有 rollback 測試不再落在原本階段而仍通過（偽陽性）。
  recommendation: 重新校準索引或改以 operation path 注入失敗；並固定排除設定檔在 operation 序列中的位置。
  reviewer: B

### Suggestion

- delta spec 與 tasks 從未指名 `.gitignore`，archived 後無法判定要寫哪個檔案（A，70）
- 非 source layout ⇒ installed target 的推論不成立，壞掉的 source checkout 會得到錯誤指令（B，70）
- 「重新對該 target 執行 installer」在 target 內無可執行入口，非具體可行動指令（B，70）
- 非 UTF-8 與 CRLF 的 `.gitignore` 行為未定義，可能使可安裝 target 變成 `failed`（B，65）
- 版控狀態偵測未指名命令；`check-ignore` 在本 change 後會給出相反答案，應使用 index 查詢；探測失敗行為未定義（B，60）
- proposal Impact 漏列 `skill-checks.fish` 與 `test_bundle_version_history.py`（A，60）
- hard link 在 design Behavior 與 AC 未列入不安全形狀（A，55）
- 既有排除設定檔 mode 保留未進 requirement（A，50）
- `__pycache__/` 為 repo 全域規則，超出 design 自述理由範圍（B，50）

## Rating

- cumulative blocking Critical: 5
- cumulative blocking Warning: 3
- non-blocking triaged: 0
- critical_gap: true
- round_type: full
- rationale: 本輪為 run 的第一輪，所有存活 Critical 與 Warning 皆為 blocking。兩位 reviewer 獨立指向同一結構性缺陷：本 change 同時觸及 stable launcher 不可變契約與三處既有封閉列舉條文，而 delta 全為 ADDED，未以 MODIFIED 承接。其中 launcher 一項經主 agent 直接驗證 `installer.py:701-704` 與 `test_bundle_version_history.py` 後確認成立，且後果為使全部既有 target 無法安裝。

## Fix Actions

- 尚未執行修正。blocking finding 1、2 的解法涉及範圍決策（是否將 launcher 診斷移出本 change，或擴大範圍設計 stable bootstrap migration 契約），該決策改變交付內容，已暫停迴圈並提交使用者裁決。
- 其餘 blocking findings（`--self` 範圍、封閉列舉 MODIFIED、無尾端換行、snapshot revalidation、FAIL_AFTER 索引）待範圍確定後於同一次修正批次處理。

## Decision

next_round

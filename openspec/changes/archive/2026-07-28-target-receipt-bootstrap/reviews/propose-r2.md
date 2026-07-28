# Cash Propose Review — Round 2

## Reviewer Findings

### Cumulative blocking set 驗證（Reviewer V）

Round 1 的 7 個成員全部判定 resolved，自 cumulative blocking set 移除（verified resolution，驗證者：Reviewer V）：

- 成員 1（Critical，launcher runtime path 檢核 vs bin/ 新檔）：resolved — 零新檔設計與 code 事實一致，Contract 4 明定 record 集合不變。修正參照：Round 1 Fix Actions 1、2。
- 成員 2（Critical，launcher bytes 三重凍結）：resolved — Non-Goals 明定 bytes 不動、tasks 2.2 為 git diff 驗證；惟替代引導管道含一項新事實錯誤（見下方 Warning）。修正參照：Round 1 Fix Actions 1、2、4。
- 成員 3（Critical，inventory 擴充使升級失敗）：resolved — 零擴充；delta 具升級回歸 scenario；tasks 5.3 回歸證據。修正參照：Round 1 Fix Actions 1、3、4。
- 成員 4（Warning，receipt_invalid 誤用）：resolved — Motivation 二分敘述與 bin/cash 及 master spec 逐字相符；不可實作 scenario 已移除。修正參照：Round 1 Fix Actions 1、3。
- 成員 5（Warning，version 無 target 端來源）：resolved — `BUNDLE_VERSION` 常數＋contract 斷言＋守衛 scenario。修正參照：Round 1 Fix Actions 2、3、4。
- 成員 6（Warning，check_history filter 缺口）：resolved — 零新檔；`installer.py` 天然在 lib rglob 守衛內；bump 序位明定。修正參照：Round 1 Fix Actions 1、2、4。
- 成員 7（Warning，umask 依賴）：resolved — D3-6 mode 正規化、umask scenario 與 fixture。修正參照：Round 1 Fix Actions 2、3、4。

Reviewer V 另完成新設計可實作性抽查（argparse 互斥骨架、`receipt_bytes` 簽名與輸入可得性、mode 正規化與 master spec 先例相容、is_source_layout 移植可行性、`--force` 互斥）均無障礙，並確認 fix propagation（六個 error codes、`BUNDLE_VERSION`、`test_init_receipt.py`、onboarding 指令字串四檔一致、舊設計零殘留）。

### Warning

- severity: Warning｜confidence: 90｜layer: design｜location: design.md D5（proposal Proposed Solution 4、tasks 4.1 連帶）｜summary: D5 宣稱 `CASH-SKILLS.md`「隨 bundle guidance 部署在各 target 可讀」為錯誤事實——installer 的 `GUIDANCE_PATHS` 僅 `AGENTS.md`、`CLAUDE.md`（installer.py:42），`CASH-SKILLS.md` 是 source-only 檔且為 `is_source_layout` 判定 marker；取代 launcher 診斷的唯一發現管道恰好到不了 target 端受眾｜recommendation: 把 init 指引放進實際部署的 guidance 區塊，或明示 source-only 限制｜disposition: fix-introduced｜introduced_by: Round 1 Fix Action 2（引導管道由 launcher 診斷改為 CASH-SKILLS.md 時未查證部署範圍）｜來源: Reviewer V

### Suggestion

- severity: Suggestion｜confidence: 60｜layer: design｜location: design.md D3-1 對 delta 第二段｜summary: D3-1「進入任何模式前」檢查 Python 的字面範圍會改變既有 modes 的失敗形狀，與 delta 把檢查 scope 在 `--init-receipt` 內的敘述不一致｜recommendation: D3-1 改為 init 模式分支內、其他步驟前｜disposition: fix-introduced｜introduced_by: Round 1 Suggestion 1 的採納實作｜來源: Reviewer V

## Rating

- post-filter cumulative blocking set Critical count: 0
- post-filter cumulative blocking set Warning count: 1
- 非阻塞 triaged finding count: 1
- critical_gap: false
- round_type: micro
- rationale: 原 7 個成員全數 verified resolved 移出；Reviewer V 發現一個 fix-introduced Warning（D5 引導管道的部署宣稱錯誤，confidence 90 ≥ 80 維持 Warning，disposition fix-introduced 故 blocking）進入 cumulative set。blocking set 非空，不可 pass。

## Fix Actions

主 agent 先實檔驗證 Reviewer V 的 claim（`installer.py:40-44` 的 `GUIDANCE_PATHS`、全 codebase 無 CASH-SKILLS.md 部署路徑、`canonical_guidance` 自 source 兩檔 Cash 標記區塊渲染、Whispify 的 AGENTS.md 實際含部署後 guidance 內容），證實後採選項 (a) 修正：

1. design.md D5 重寫：引導管道二分——(1) 部署面：source repo `AGENTS.md`／`CLAUDE.md` Cash guidance 區塊新增 init 指引段，隨既有 guidance 部署到達所有 target 的 managed block；(2) 維護面：`CASH-SKILLS.md` onboarding 節，明示其為 source-only（含 `is_source_layout` marker 事實）。Contract 8 對應改寫（新增 target guidance 驗證面）。
2. Suggestion 一併修正：design.md D3-1 改為「於 `--init-receipt` 模式分支內、任何其他步驟之前」檢查 Python，其他 modes 失敗形狀不變。
3. proposal.md：Proposed Solution 4 改述雙管道與 source-only 事實；Impact Modified 增列 `AGENTS.md`、`CLAUDE.md`。
4. tasks.md：4.1 標注 source 維護者視角；新增 4.2（兩檔 guidance 區塊新增 init 指引段、兩檔一致）；5.3 增列 target managed block 含指引段的驗證。
5. specs/cash-cli/spec.md：requirement 增補 guidance 指引條款（MUST NOT 依賴 source-only 檔案作為 target 端引導）；新增 scenario「Init 指引隨 guidance 部署到達 target」。

修正後 `"$cash_cli" validate target-receipt-bootstrap` 重跑通過；post-fix mechanical self-check 通過（annotation 0/0、guidance 概念跨檔一致、無舊宣稱殘留）。本輪修正檔案均位於 change 目錄內，無 change 目錄外路徑需記入 touched。

## Decision

next_round

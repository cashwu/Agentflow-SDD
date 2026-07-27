# Cash Propose Review — Round 2

## Reviewer Findings

### Cumulative blocking set 驗證（Reviewer V）

Round 1 的 5 個成員全部判定 resolved，自 cumulative blocking set 移除（verified resolution，驗證者：Reviewer V）：

- 成員 1（Critical，gate 漂移宣稱與統一方向）：resolved — 漂移實測確認（apply 兩檔 :449 對 propose 兩檔 :347），design Context 1／D1 記載並反轉方向為 propose 版，引 master spec :3373 全檔禁令；Contract 4 與 tasks 5.2 為三類允許差異。修正參照：Round 1 Fix Actions 1、2、3。
- 成員 2（Critical，版本 bump 序位）：resolved — tasks 1.1 為首個 task，`check_history` 失敗訊息與測試實作逐字吻合。修正參照：Round 1 Fix Actions 1、2。
- 成員 3（Warning，gate 標題行邊界）：resolved — design D1／Contract 3、tasks 1.2／1.4、delta spec 標題行排除全部到位，編號 9.／11. 實測吻合。修正參照：Round 1 Fix Actions 1、2、4。
- 成員 4（Warning，live namespace surface）：resolved — cash-cli delta 存在，MODIFIED 標題與 master byte-for-byte 相同，本文除枚舉置換與新增一個 scenario 外逐字保留。修正參照：Round 1 Fix Action 5。
- 成員 5（Warning，CASH-SKILLS.md 敘述涵蓋）：resolved — tasks 4.3 涵蓋所有權敘述與 live scan 敘述修訂。修正參照：Round 1 Fix Action 2。

Round 1 的 7 個非阻塞 findings 修正亦經逐一確認到位。

### Warning

- severity: Warning｜confidence: 95｜layer: design｜location: proposal.md Impact、design.md D6 與 Contract 6、tasks.md 1.1 與 3.4（共五處）｜summary: `test_bundle_version_history.py` 與 `test_live_namespace.py` 實際位於 `scripts/cash-skills/tests/`，五處均誤寫為 `scripts/cash-cli/tests/`——tasks 3.4 交付目標檔不存在、Impact 宣告了不存在路徑而真正要改的檔案不在結構化範圍宣告內、Contract 6 驗證錨點指向錯檔｜recommendation: 五處統一改為 `scripts/cash-skills/tests/` 路徑，Impact 同步更正｜disposition: fix-introduced｜introduced_by: Round 1 Fix Actions 1（design D6/Contract 6）、2（tasks 1.1/3.4）、3（proposal Impact）——錯誤路徑抄自 Round 1 Reviewer B finding 原文，寫入時未經實檔核對｜來源: Reviewer V

### Suggestion

- severity: Suggestion｜confidence: 60｜layer: text｜location: tasks.md 4.3；specs/cash-cli/spec.md 枚舉｜summary: tasks 4.3 對 CASH-SKILLS.md live scan 敘述的置換清單只列三個生成管線檔且粒度（`blocks/review-gate.md` 對 `blocks/`）與 cash-cli delta 枚舉不一致，未含 `scripts/cash-skills/SKILL-LINT.md` 與 `CASH-GLOSSARY.md`｜recommendation: 置換清單補齊並與 delta 枚舉粒度對齊｜disposition: fix-introduced｜introduced_by: Round 1 Fix Actions 2 與 5 清單未對齊｜來源: Reviewer V

## Rating

- post-filter cumulative blocking set Critical count: 0
- post-filter cumulative blocking set Warning count: 1
- 非阻塞 triaged finding count: 1
- critical_gap: false
- round_type: micro
- rationale: 5 個原成員全數 verified resolved 並移出 cumulative set；但 Reviewer V 發現一個 fix-introduced 的 Warning（測試檔路徑錯誤，confidence 95 ≥ 80 維持 Warning，disposition fix-introduced 故為 blocking）進入 cumulative set。blocking set 非空，本輪不可 pass，修正後進入下一輪驗證。

## Fix Actions

1. 主 agent 先以 ls 實檔核對兩測試檔位置（確認位於 `scripts/cash-skills/tests/`，`scripts/cash-cli/tests/` 不含此二檔），再修正五處路徑：proposal.md Impact 條目、design.md D6、design.md Contract 6、tasks.md 1.1、tasks.md 3.4。修改檔案：proposal.md、design.md、tasks.md。
2. 連帶修正套件範圍引用：tasks.md 3.5 與 design.md Contract 10 改為「`scripts/cash-skills/tests/` 與 `scripts/cash-cli/tests/` 兩處 python 測試套件」，避免版本歷史與 live namespace 測試落在驗證範圍之外。修改檔案：tasks.md、design.md。
3. Suggestion（fix-introduced）一併修正：tasks.md 4.3 置換清單補齊為與 cash-cli delta 枚舉一致的五項（`scripts/cash-skills/blocks/`、`scripts/cash-skills/generate.fish`、`scripts/cash-skills/variant-rules.yaml`、`scripts/cash-skills/SKILL-LINT.md`、`CASH-GLOSSARY.md`）。修改檔案：tasks.md。
4. 修正後重跑 post-fix mechanical self-check：`cash-cli/tests` 誤引用歸零（僅剩 3.5／Contract 10 對該目錄套件的合法引用）、delta 註解成對 6/6、`"$cash_cli" validate cash-skill-maintainability` 通過。
5. 本輪修正檔案均位於 change 目錄內，無 change 目錄外路徑需記入 touched。

## Decision

next_round

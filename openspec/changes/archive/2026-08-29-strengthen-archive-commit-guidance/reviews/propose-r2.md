# Cash Propose Review — Round 2

## Reviewer Findings

### Suggestion

- severity: Suggestion｜confidence: 95｜layer: text｜location: design.md Risks「守門誤報」｜summary: Round 1 Fix Action 3 的指令統一清掃漏掉 Risks 條目一處舊短形式 `git status --porcelain` 指稱｜recommendation: 改為完整指令形式或不含指令字面的指稱｜disposition: unresolved-prior（Fix Action 3 清掃不完整；不影響 cumulative set 成員 3 的 resolved verdict——該處非規範性位置，無行為 hazard）｜reviewer: V
- severity: Suggestion｜confidence: 90｜layer: text｜location: design.md D3（ADDED requirement scenario 覆蓋枚舉）｜summary: Fix Actions 5、7 在 delta spec 新增 legacy 與 malformed 兩個 scenario，但 D3 的摘要枚舉未同步，仍列 7 項而實際 9 項｜recommendation: D3 枚舉補上兩個 scenario｜disposition: fix-introduced｜introduced_by: Round 1 Fix Actions 5、7（propagation 未及 D3 摘要）｜reviewer: V

## Rating

- post-filter cumulative blocking set Critical count: 0
- post-filter cumulative blocking set Warning count: 0
- non-blocking triaged finding count: 2
- critical_gap: false
- round_type: micro
- rationale: Reviewer V 對 cumulative blocking set 四個成員全數回傳 resolved（含向下驗證 launcher 與 installer 機制的證據），7 個非 blocking suggestion 修復亦全部落地。本輪僅餘 2 條 Suggestion 級單句文字 findings，均非 blocking 且已於本輪修復。post-filter cumulative blocking set 為空，符合 pass 條件。

## Fix Actions

1. 【verified-resolution 移除紀錄】cumulative blocking set 四個成員全數以 verified resolution 移除，驗證者均為 Reviewer V（round 2）：
   - 成員 1（Critical --self 序位 fail-closed 窗口）——fix 參照 round 1 Fix Action 1；V 驗證 tasks 2.1/2.2/3.1 均在自身結尾關窗、[P] 清零、3.2 為冪等確認，且無其他開窗殘留（cash-skills.version 與 skill-checks.fish 非 manifest record）。
   - 成員 2（tracked 措辭矛盾）——fix 參照 round 1 Fix Action 2；V 驗證四個 artifacts「tracked source」零命中。
   - 成員 3（git 指令漏判）——fix 參照 round 1 Fix Action 3；V 驗證完整指令覆蓋全部規範性位置（proposal 1／design 2／tasks 1／spec 3）。
   - 成員 4（assertion literal 鑑別力）——fix 參照 round 1 Fix Action 4；V 驗證 D4 literal 枚舉、排除條款、D1 改述與 Risks 新條目齊備。
2. 【Suggestion 指令殘留】design.md Risks「守門誤報」條目改以完整指令形式指稱，全檔舊短形式清零（grep 驗證 0 命中）。修改檔案：design.md。
3. 【Suggestion D3 枚舉脫節】design.md D3 的 scenario 覆蓋枚舉補上「僅 legacy touched state 存在仍受守門」與「touched state malformed 時放行由 CLI 守門」，並把缺失情境註明為兩路徑皆缺，與 delta spec 實際 9 個 scenario 對齊。修改檔案：design.md。
4. 【post-fix 檢查】`"$cash_cli" validate "strengthen-archive-commit-guidance"` 重跑通過；修改僅及 design.md（位於 change 目錄內，無 touched record 需求）。

## Decision

passed

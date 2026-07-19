# Cash Propose Review — Round 1

## Reviewer Findings

### Critical

- `severity`: Critical｜`confidence`: 100｜`layer`: design｜來源: Reviewer B
  - `location`: design.md Decisions 第 5 點（耦合 scripts/cash-skills/tests/skill-checks.fish 的 check_version_literal_occurrence_inventory）
  - `summary`: design 決策 5 自己拼出 governed 版本字面值，使 repository 字面值清點當下即 FAIL（reviewer 實跑測試確認）。
  - `recommendation`: 改寫為間接描述，不拼出該字串；不得用「把 active change 路徑加進 expected records」解決（歸檔後路徑改變會再漂移）。

### Warning

- `severity`: Warning｜`confidence`: 90｜`layer`: design｜來源: Reviewer A + Reviewer B（合併，含 A 的 English-language artifact 條目）
  - `location`: design.md Implementation Contract C1 + tasks.md 2.1
  - `summary`: C1 以 cash-propose 措辭為模板推及全部：cash-apply 的實際舊政策措辭是 'always English, regardless of any other language rule'（無「Exception — spec files stay in English」段落），原驗收 grep 匹配不到，漏改不可偵測；共用 Round file language 區塊的 'any other English-language artifact' 句亦未列入改寫範圍。
  - `recommendation`: C1 逐檔列出實際錨點與措辭，驗收加缺席斷言。
- `severity`: Warning｜`confidence`: 90｜`layer`: design｜來源: Reviewer B
  - `location`: proposal.md Impact；.claude/skills/cash-ingest/SKILL.md 的 locale 例外句（.agents 變體同）
  - `summary`: cash-ingest 仍強制 spec 英文且會更新 delta spec、無 self-check，不在 Impact 與 C1 範圍內；落地後與新政策直接矛盾並可重新製造靜默丟棄陷阱。
  - `recommendation`: 納入改寫範圍（4 檔 → 6 檔），評估 cash-ingest parity diff 條件式重生。

### Suggestion（非阻擋，已列入 triage）

- A2（confidence 75，降級）：delta 語言政策條文缺 openspec/changes/archive/ 歷史除外，屬 open signal spec-precedence-exception-missing 的 issue class。
- A3（confidence 75）：共用區塊 'any other English-language artifact' 句過時（已併入 C1 修復範圍）。
- A4（confidence 70）：Impact 對 cash-propose.diff 無條件宣告 Modified，與 design/tasks 條件式預期不一致。
- B4（confidence 75，降級）：title-identity check 無 archive 端最後防線，繞過路徑未記載。
- B5（confidence 75，降級）：上游 spectra-\* skill 仍規定英文 spec，路徑未記載。
- B6（confidence 75，降級）：非 backtick 字面（如 loop-ledger 表格範例）不受不變量保護。
- B7（confidence 75）：不變量抓不到否定翻反與同句 code-span 對調。
- B8（confidence 50）：tasks 批次行號在第一批完成後即失效。

## Rating

- post-filter cumulative blocking set：Critical 1、Warning 2（unseeded run 首輪，全部 surviving Critical/Warning 均 blocking）
- 非阻擋 triaged findings：8
- `critical_gap`: true
- `round_type`: full
- 理由：Reviewer A 的 run-first-round claim verification 全數通過（行數、requirement 數、測試錨點、hash 範圍、parity hunk 位置、版本值、分批邊界皆與實際檔案吻合），但 Reviewer B 找到一個自傷性 Critical（design 自拼 governed 字面值使測試套件當下 FAIL）與兩個覆蓋面 Warning（cash-apply 措辭錨點、cash-ingest 缺席）。blocking set 非空，進入修復後下一輪。

## Fix Actions

- design.md：決策 5 改寫為間接描述，移除 governed 版本字面值（B1）；C1 重寫為 6 檔逐檔錨點列舉 + 缺席斷言驗收（A1/B2、B3、A3）；C3 不變量強化為 per-requirement code-span、規範 token 計數、verbatim 預掃清單、順序敏感語句抽查（B6、B7）；Risks 補記防護繞過路徑與上游 spectra-\* 兩條 accepted residual risk（B4、B5）；C2 標題註明 cash-ingest 不在 self-check 之列。
- proposal.md：Solution 5 改為 6 份 SKILL.md；Impact 增列兩變體 cash-ingest SKILL.md 與 cash-ingest parity diff（條件式）；cash-propose parity diff 改條件式標註（A4）；Non-Goals 補記上游 spectra-\* 與 cash-archive 端檢查為範圍外（B4、B5）。
- tasks.md：新增 1.0 verbatim 預掃任務（B6）；1.3–1.5 批次改以 requirement 序號＋首尾標題界定、行號降為遷移前參考（B8）；1.4/1.5/1.6 驗證納入強化不變量；2.1 改為 6 檔逐錨點與四個缺席斷言；4.1 納入 cash-ingest parity diff。
- specs/cash-skill-workflows/spec.md（delta）：語言政策條文補 openspec/changes/archive/ 歷史除外句（A2）。
- 修復後驗證：`spectra validate chinese-spec-content --strict` 通過；fish scripts/cash-skills/tests/skill-checks.fish PASS、exit 0（B1 解除確認）。
- post-fix self-check 另捕獲並修復：design Migration Plan 第 3 步殘留「4 份 SKILL.md」改為 6 份（fix propagation 掃描 '4 份/4 檔' 時發現）。
- 修改檔案：proposal.md、design.md、tasks.md、specs/cash-skill-workflows/spec.md。

## Decision

next_round

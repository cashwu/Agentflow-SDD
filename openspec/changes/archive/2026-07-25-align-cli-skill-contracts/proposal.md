## Summary

修正 Cash CLI 與 cash skills 之間七處已驗證的契約不一致（A1–A7）：proposal 模板與 validate 必要標題互相矛盾、search 的位置參數解析會靜默搜錯目標、search 語料被封存的 review 檔案淹沒、Codex variant 殘留空 code span 與 Claude-only frontmatter，以及 CLI runtime 硬編單一 variant 的 invocation 前綴。

## Motivation

這七項都不是理論風險，而是實測可重現的缺陷：

- **A1**：`.cash-skills/lib/cash_cli/validation.py` 要求 `proposal.md` 含 `## Summary`、`## Capabilities`、`## Impact`，但 cash-propose 提供的三個型別模板沒有任何一個同時滿足這三項。Feature 模板缺 `## Summary`，Bug Fix 模板缺 `## Summary` 與 `## Capabilities`，Refactor 模板缺 `## Capabilities`。因此**照 skill 指示產出的 proposal 一律無法通過 validate**，而 archive 預設會跑 validate，review loop 的 entry condition 也要求 validate 通過。實測既有 archive 的 19 個 change 有 15 個不符合現行規則。此外 `discovery.py` 的摘要擷取只認 `## Summary`，用另外兩個模板的 change 在 list 輸出中 summary 永遠是空字串。這正是 open signal cross-artifact-definition-drift 累計 10 次的同一個類別：同一個概念在 SKILL.md 與 CLI 兩處各自定義後漂移。

- **A2**：`.cash-skills/lib/cash_cli/commands/search.py` 以「不以 `--` 開頭者即為位置參數」取 query，不排除帶值旗標的值。實測把旗標寫在查詢詞之前時，limit 的值會被當成 query，**不報錯且回傳看似正常的結果**。靜默回錯結果是最難察覺的失效模式。

- **A3**：同一支檔案把 `--limit` 的缺席與非整數共用一個例外分支，導致未帶 `--limit` 時以「需要整數」的訊息失敗。一個必填參數長得像選填，錯誤訊息又指向錯誤原因。

- **A4**：search 直接走訪整個 openspec 目錄，未排除已封存內容。實測前 100 筆結果有 82 筆來自封存 change 的 review round 檔案，只有 3 筆來自 master specs。專案 guidance 指定 search 為查詢需求的第一線工具，目前這個訊噪比讓它幾乎不可用。噪音幾乎完全來自封存 change 的 `reviews/` 目錄，而非封存的 proposal、design 或 spec 本身。

- **A5**：`.agents/skills/cash-ingest/SKILL.md` 在剝除 Claude 專屬 plan 目錄時留下三處空 code span 與一處被剝空前綴的路徑範例，四條指示因此失去受詞或指向錯誤，變成無法執行的敘述。對應 open signal generated-literal-path-corruption。

- **A6**：`.agents` 底下有四個 skill 帶著 Claude Code 專屬的 frontmatter key。`.agents/skills/cash-analyze/SKILL.md` 與 `.agents/skills/cash-verify/SKILL.md` 三個 key 全帶（`context`、`agent`、`disallowedTools`），內文還自述以 fork 模式執行；`.agents/skills/cash-ask/SKILL.md` 與 `.agents/skills/cash-discuss/SKILL.md` 各帶一個 `disallowedTools`。只有 `.agents/skills/cash-audit/SKILL.md` 與 `.agents/skills/cash-drift/SKILL.md` 兩個是完整處理過的。對應 open signal variant-parity-checks-only-markers：對等比較在兩個變體同時錯誤時無法偵測，而單一變體的錯誤一旦寫入 manifest 就被記錄為已審閱的允許差異。

- **A7**：`.cash-skills/lib/cash_cli/commands/drift.py` 在建議字串中硬編 Codex 的 invocation 前綴，Claude 使用者執行 drift 會收到錯誤 variant 的指令建議。同時 cash-drift 兩個 variant 的 `SKILL.md` 逐字宣稱該欄位是 `a single copy-pasteable command line` 並指示輸出 `Run <primary_recommendation>.`，這個描述與 CLI 的實際輸出必須一起收斂。對應 open signal namespace-migration-literal-residue。

## Proposed Solution

**A1 — 收斂為單一來源**。刪除 cash-propose 兩個 variant 中 step 5 的三個型別模板區塊，改為與 step 7 其他 artifact 一致：使用 CLI 回傳的 template 欄位作為結構。必要標題集合只在 validation.py 定義一次，模板只在 resources.py 定義一次。resources.py 的 proposal 模板除了七個段落標題外，還須包含 `## Capabilities` 與 `## Impact` 的子結構骨架，理由分兩層：`## Impact` 標題是 spec 合併產生 trace 時界定區段的依據，三個標籤列是 impact 粒度提示計數 affected-code 條目的依據；兩者在形狀消失時都是靜默降級而非報錯。validation.py 的必要標題集合不變。

**A2 — 修正位置參數解析**。search 改為在掃描位置參數時跳過帶值旗標所消耗的值，使查詢詞的位置不影響解析結果。旗標寫在查詢詞前後都必須解析出同一個 query。

**A3 — 給 limit 預設值**。未提供旗標時採用預設值而非失敗；只有提供了但值非整數或超出範圍時才報錯，且錯誤碼與訊息要區分「缺少值」與「值不合法」。

**A4 — 預設排除封存的 review 檔案並提供範圍旗標**。預設語料排除封存 change 的 `reviews/` 目錄，保留封存的 proposal、design 與 spec 可檢索。新增範圍旗標，接受三個值分別對應僅 master specs、預設集合、以及不作任何排除的完整集合。未提供旗標時等同預設值。排除在走訪層剪枝而非事後過濾，因此被排除的檔案不會被讀取或解碼。

**A5 — 補回被剝空的受詞**。將四處被剝除的敘述改寫為在無 plan 目錄的環境下語意完整的形式，並同步更新對應的 variant parity manifest。

**A6 — 移除 Codex variant 的 Claude-only frontmatter**。從 cash-analyze 與 cash-verify 移除三個 key 與內文的 fork 自述，從 cash-ask 與 cash-discuss 移除 `disallowedTools`，使四者與已完整處理的 cash-audit、cash-drift 一致。cash-discuss 目前兩個 variant 逐字相同且不在 divergent 清單內，移除後會產生新的合法差異，因此需新增其 parity manifest 並把它納入 divergent 清單。

**A7 — 移除 runtime 中的 variant 前綴並同步 skill 描述**。drift 的建議欄位改為輸出不含前綴的 skill 名稱，cash-drift 兩個 variant 的欄位描述與輸出指示同步改為呈現 skill 名稱而非可執行指令。

**驗證**。CLI 側行為以 `scripts/cash-cli/tests/` 下的既有測試檔擴充覆蓋，其中涉及 stdout 逐位元組相同與 exit code 的案例必須先把 launcher 與 runtime 安裝進臨時 workspace 再以 subprocess 呼叫該 workspace 內的 launcher，而非只呼叫內部函式，也不得直接呼叫 repo 自身的 launcher。skill 與 manifest 側以 skill-checks.fish 新增一個具名測試群組覆蓋，該群組同時接入 `case all`。canonical SKILL.md 有內容異動，因此 bundle 版本檔提升一版並同步更新 skill-checks.fish 中的版本斷言。

## Non-Goals

- 不處理 review 中列為 B 與 C 級的項目：locale 設定無效、design.md 可跳過的敘述殘留、cash-commit 讀取不存在的 section、sync 與 park 無 skill 使用、CLI 缺 help 表面、review loop 模板四份副本只鎖 19 行、grader 保護與版本升級的循環依賴。這些另案處理。
- 不改動 validation.py 的必要標題集合，也不回頭修正封存目錄中既有 proposal 的標題。封存內容是歷史紀錄。
- 不重寫 search 的排序演算法或改為向量檢索，本次只處理語料範圍與參數解析。
- 不改動 grader 保護清單本身的成員。
- 不改動 cash-apply 兩個 variant 的 SKILL.md。其 review-loop 區塊含有與 cash-propose 第 448 行同源的句子，本次刻意讓該行在四份副本間分歧，理由記於 design 的 Risks。

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `cash-cli`: search 的參數解析、預設 limit、語料範圍旗標與走訪層排除；drift 建議欄位的 variant 中立化；proposal 模板資源的段落與子結構。
- `cash-skill-workflows`: cash-propose 的 proposal 模板單一來源化；Codex variant 的空 code span 與 Claude-only frontmatter 修正；cash-drift 對 drift 欄位的描述同步；對應 parity manifest、divergent 清單與版本斷言同步。

## Impact

- Affected specs: `cash-cli`、`cash-skill-workflows`
- Affected code:
  - Modified:
    - `.cash-skills/lib/cash_cli/commands/search.py`
    - `.cash-skills/lib/cash_cli/commands/drift.py`
    - `.cash-skills/lib/cash_cli/resources.py`
    - `.cash-skills/lib/cash_cli/workspace.py`
    - `.claude/skills/cash-propose/SKILL.md`
    - `.agents/skills/cash-propose/SKILL.md`
    - `.claude/skills/cash-drift/SKILL.md`
    - `.agents/skills/cash-drift/SKILL.md`
    - `.agents/skills/cash-ingest/SKILL.md`
    - `.agents/skills/cash-analyze/SKILL.md`
    - `.agents/skills/cash-verify/SKILL.md`
    - `.agents/skills/cash-ask/SKILL.md`
    - `.agents/skills/cash-discuss/SKILL.md`
    - `scripts/cash-skills/variant-parity/cash-ingest.diff`
    - `scripts/cash-skills/variant-parity/cash-analyze.diff`
    - `scripts/cash-skills/variant-parity/cash-verify.diff`
    - `scripts/cash-skills/variant-parity/cash-ask.diff`
    - `scripts/cash-cli/tests/test_lexical_search.py`
    - `scripts/cash-cli/tests/test_analyze_drift.py`
    - `scripts/cash-cli/tests/test_graph_instructions.py`
    - `scripts/cash-skills/tests/skill-checks.fish`
    - `cash-skills.version`
  - New:
    - `scripts/cash-skills/variant-parity/cash-discuss.diff`
  - Removed: (none)

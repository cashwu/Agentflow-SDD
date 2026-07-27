## Summary

把 cash skill 系統的維護模式從「多份拷貝＋事後對等驗證」改為「單一源頭＋機械生成」，並補上兩份維護參考文件。共四個交付項：(1) 將 `cash-propose`／`cash-apply` 四份重複的 sub-agent review gate 規格抽成單一 block 檔，由生成器注入四個 SKILL.md；(2) `.agents` variant 由 `.claude` variant 經宣告式轉換規則生成，取代「兩份 canonical ＋ variant-parity unified-diff 事後比對」；(3) 新增領域詞彙表 `CASH-GLOSSARY.md`；(4) 新增 skill lint 失效模式檢核清單 `scripts/cash-skills/SKILL-LINT.md`。

## Motivation

- Review gate 規格目前以逐字拷貝存在於 `.claude/skills/cash-propose/SKILL.md`、`.claude/skills/cash-apply/SKILL.md`、`.agents/skills/cash-propose/SKILL.md`、`.agents/skills/cash-apply/SKILL.md` 四處，僅靠 SKILL.md 內的人工同步清單維持一致，任何 gate 修訂都要人工改四份。open signals 已記錄此類風險的實例：`variant-parity-checks-only-markers`（對等檢查退化為只看 marker）、`cross-artifact-definition-drift`（跨檔定義漂移）、`relocated-resource-consumers-partially-updated`（搬移後引用者部分未更新）。
- 十二個 skill 的 `.agents` 與 `.claude` 變體差異本質上是機械轉換（invocation 前綴、tool-specific frontmatter、fork 區塊），卻以雙份 canonical 檔案人工維護，再用 `scripts/cash-skills/variant-parity/` 下的 diff manifest 事後驗證。驗證只能發現漂移，不能防止漂移。
- Anthropic 對 Claude 5 世代的 context engineering 指引明確主張消除跨文件重複、以單一權威處維護每個規則；mattpocock/skills 的實務與本 repo 既有的 `scripts/spectra-plus/generate.fish` 生成管線都驗證了「單一源頭＋生成」是可行模式。
- 核心詞彙（change、artifact、contract、deviation、touched state 等）散落各 SKILL.md 重複解釋，缺乏含反面用語（avoid）的集中定義；skill 長期修訂也缺乏防腐化的檢核維度。

## Proposed Solution

1. **Review gate 單一源頭**：新增 `scripts/cash-skills/blocks/review-gate.md` 作為 gate 規格唯一維護處。四個 SKILL.md 的 gate 段落改由生成器從該 block 注入，段落邊界以生成錨點註解標定。生成結果仍為版本控制檔案。gate 的收斂、評分、裁決語意逐字保留；內容變更僅限三類——受保護 grader 路徑集合的擴充（見第 4 點）、生成錨點註解，以及既有漂移的統一（apply 兩檔 gate 對 `## What Changes` 的殘留引用改為僅 `## Proposed Solution`，與 master spec 對 propose 檔的既有禁令一致）。
2. **變體生成**：新增 `scripts/cash-skills/generate.fish` 與宣告式規則檔 `scripts/cash-skills/variant-rules.yaml`。十二個 `.agents/skills/` 的 SKILL.md 由 `.claude/skills/` 對應檔案生成：invocation 前綴置換、tool-specific frontmatter 欄位移除、fork 區塊移除，以及 per-skill 宣告式 patch（如 `cash-audit` 的 Codex standalone 流程）。生成輸出 committed。`scripts/cash-skills/tests/skill-checks.fish` 的 variant-parity 比對改為 freshness 檢查：重新生成後與 committed 檔案 byte-identical，否則失敗。`scripts/cash-skills/variant-parity/` 的 8 個 diff manifest 移除，其「差異可讀可審閱」義務由 `scripts/cash-skills/variant-rules.yaml` 承接。
3. **維護參考文件**：新增 `CASH-GLOSSARY.md`（核心詞彙定義，每條含定義、關係與 avoid 用語）與 `scripts/cash-skills/SKILL-LINT.md`（premature completion、duplication、sediment、sprawl、no-ops、negation 六種失效模式的檢核清單）。`CASH-SKILLS.md` 加入兩者的指引連結與生成模型說明。
4. **治理面延伸**：受保護 grader 路徑集合加入 `scripts/cash-skills/blocks/review-gate.md`、`scripts/cash-skills/generate.fish`、`scripts/cash-skills/variant-rules.yaml`，避免 gate 的真實源頭成為未受治理的 gate input。`cash-cli` 的 live namespace scan surface 同步更新：移除 `scripts/cash-skills/variant-parity/`、納入前述新 live 檔案。`cash-skills.version` 依可替換 artifact 變更規則遞增，且 bump 先於任何 SKILL.md 修改；收尾以 `./install-cash-skills.fish --self` 重建 `.cash-skills/receipt.tsv`。

## Non-Goals

- 不改變 review gate 的行為語意：收斂規則、confidence filter、round 檔案 schema、abort triage 等維持與現行等價。
- 不做 runtime progressive disclosure：SKILL.md 於呼叫時仍完整載入，不改為執行期讀取外部檔案。
- 不修改 `.cash-skills/` runtime 程式與 installer 行為（`install-cash-skills.fish` 與 cash_cli 安裝流程的程式不變；收尾僅執行既有的 self 安裝以重建 receipt）。
- 不在本 change 逐一改寫其餘十個 skills 的內文以引用詞彙表；引用轉換留待後續 change。
- 不變動 spectra-plus 系列 skills 與其生成管線。

## Alternatives Considered

- **Runtime progressive disclosure**（gate 抽成執行期才讀取的參考檔）：`cash-propose` 與 `cash-apply` 每次執行必然進入 review gate，執行期拆檔對 context 總量幾乎沒有節省，卻需要重錨定 master spec 中約二十條以檔案內容為對象的 requirement（sentinel 存在性、受保護路徑集合位置等），churn 與風險不成比例。
- **以 opaque digest 鎖定 gate 區塊一致性**：與現行 spec「MUST NOT 以不透明的 digests 取代可讀的 manifests」條款直接衝突。
- **維持雙 canonical 並僅強化 parity 測試**：只提高漂移的偵測率，不消除「同一規則存在四份」的根因，且 `variant-parity-checks-only-markers` signal 顯示事後比對本身也會退化。

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `cash-skill-workflows`：skill 所有權與變體生成模型（`.claude` 為權威源頭、`.agents` 為生成輸出）、變體對等機制（diff manifest 比對改為生成 freshness 檢查）、review gate 單一源頭與其治理延伸、詞彙表與 skill lint 檢核清單的存在與 schema。
- `cash-cli`：live namespace scan surface 枚舉——移除 `scripts/cash-skills/variant-parity/`，納入 `scripts/cash-skills/blocks/`、`scripts/cash-skills/generate.fish`、`scripts/cash-skills/variant-rules.yaml`、`scripts/cash-skills/SKILL-LINT.md` 與 `CASH-GLOSSARY.md`。

## Impact

- Affected specs:
  - openspec/specs/cash-skill-workflows/spec.md
  - openspec/specs/cash-cli/spec.md
- Affected code:
  - New:
    - scripts/cash-skills/blocks/review-gate.md
    - scripts/cash-skills/generate.fish
    - scripts/cash-skills/variant-rules.yaml
    - CASH-GLOSSARY.md
    - scripts/cash-skills/SKILL-LINT.md
  - Modified:
    - .claude/skills/cash-propose/SKILL.md
    - .claude/skills/cash-apply/SKILL.md
    - .agents/skills/cash-propose/SKILL.md
    - .agents/skills/cash-apply/SKILL.md
    - .agents/skills/
    - scripts/cash-skills/tests/skill-checks.fish
    - scripts/cash-skills/tests/test_live_namespace.py
    - CASH-SKILLS.md
    - cash-skills.version
    - .cash-skills/receipt.tsv
  - Removed:
    - scripts/cash-skills/variant-parity/

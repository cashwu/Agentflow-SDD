## Summary

依據 Claude 5 世代 context engineering 的指引，對 12 個 Cash skill 中的 10 個、就其兩個變體做一次 prompt rightsizing：移除替模型做判斷的護欄與純重複段落，並把品味類紀律重寫為判準式表述。契約、狀態機與協定本文一律保留，並為兩處先前無 spec 覆蓋而導致內容漂移的段落補上規範。

## Motivation

Cash skill 目前兩個變體共 24 個 SKILL.md，`.claude` 變體合計 3177 行，其中 `cash-apply` 單檔 716 行。這個體積有三個來源，只有一個是必要的：

1. **協定本文**——review loop 的輪型推導、cumulative blocking set、`disposition` 三態、confidence filter、ledger schema、grader immutability、CLI 呼叫與 artifact schema。這些定義系統本身，模型再強也無法自行推導，必須保留。
2. **純重複**——同一條規則同時出現在 CLAUDE.md、SKILL.md 前言與段落內，或在單一檔案內被覆述多次。`cash-apply` 的回覆語言規則出現於五個位置；`**Guardrails**` 區塊的條目幾乎逐條重述前文；AskUserQuestion 不可用時的 fallback 在 `cash-apply` 與 `cash-commit` 內各重寫五次、`cash-ingest` 兩次、`cash-drift` 兩次。
3. **判斷替代**——為較弱模型撰寫的道德勸說與品味立法。`cash-apply` 的 Rationalization Table 逐列處理「這任務看起來做完了我就打勾」這類偷懶心態；`Maintain Balance` 用 12 行列舉「不要巢狀三元運算子」「不要 dense one-liner」，而該段之所以存在，是因為前一段 Simplicity First 講得過度，需要反向拉回。

第 2、3 類內容在 `openspec/specs/cash-skill-workflows/spec.md` 與 `scripts/cash-skills/tests/skill-checks.fish` 中都沒有規範引用，屬於無人維護的殘留。它們佔用每次 skill 載入的 context 預算，與 Claude 5 世代模型的判斷力重複，且第 3 類的內部張力（Simplicity First 與 Maintain Balance 互相拉扯）本身就是模型行為不穩定的來源。

無 spec 覆蓋正是這些內容漂移的原因，也是本次刪改的風險所在：刪除時容易連帶丟掉仍然有效的契約子集。因此本 change 不只刪除，也為兩項刪改後仍須成立的行為補上 requirement——實作紀律必須保留的可稽核判準，以及互動 fallback 的單一陳述——使它們日後有機械斷言把關。

## Proposed Solution

分兩個層次處理，對應兩種不同的內容性質：

**層次一：移除純重複。** 刪除 `**Guardrails**` 區塊中重述前文的條目，僅保留該區塊中無法從前文推得的條目；把 `cash-apply` 的回覆語言規則收斂為單一位置；把 AskUserQuestion 不可用時的 fallback 從逐決策點重寫改為全檔單一陳述；移除 Rationalization Table。涵蓋 analyze、apply、archive、ask、audit、commit、debug、drift、ingest、propose 十個 skill 的兩個變體。discuss 完全不含這些段落；verify 僅有一處行內 fallback 而無重複，兩者皆不在範圍內。

**層次二：把品味紀律重寫為判準。** 將 `cash-apply` 的 Simplicity First、Surgical Changes、Maintain Balance 三段合併重寫為判準式表述——保留 diff 可追溯性驗收標準、Implementation Notes Protocol 的兩條銜接（`deviation` 與不相關缺陷的 `open-question`）、`task done` 前的完成 gating，以及 `Common false positives` 過濾規則所依賴的範圍紀律語意；移除的僅為 `Maintain Balance` 的六項語法層級風格禁令列舉。`Common false positives` 中引用這兩個段落名稱的項目存在於 `cash-propose` 與 `cash-apply` 共用的 review-loop 本文，四個檔案一併同步。

兩個層次共同的不變量：contract、狀態機、協定本文、CLI 呼叫、檔案路徑、artifact schema、以及 requirement 標題逐位元組相符規則一律不變；兩個變體在呼叫前綴正規化後維持對等。

## Non-Goals

- 不改變 review loop 的任何決策語意：輪型推導、cumulative blocking set 的進出條件、`disposition` 分類、confidence filter 門檻、ledger 欄位、abort triage 分桶、grader immutability 的受保護路徑集合與結構化範圍宣告定義，全部維持現行行為。
- 不改變 Cash CLI 的命令列介面、輸出格式或錯誤契約。
- **不改變 skill 的檔案結構。** 每個 skill 目錄維持恰好一個 `SKILL.md`；不引入 reference 檔或任何形式的 progressive disclosure。理由見 `## Alternatives Considered`。
- 不移除 `cash-apply` 阻塞分類中逐字內嵌的英文邊界片語，該片語是 task-loop 與 review-loop 共用的可稽核邊界。
- 不放寬變體對等：兩個變體維持等量修改，不採取「只瘦身 Claude 變體」的方案。
- 不修改 `CLAUDE.md` 或 `AGENTS.md` 的 Cash 受管區塊。
- 不調整 `.cash.yaml` 的任何設定值。
- 不處理 `openspec/specs/cash-skill-workflows/spec.md` 中指向已不存在的 spectra-plus 目錄的 stale trace metadata；那是獨立的清理工作。

## Alternatives Considered

**把共用的 review loop 本文抽成 `references/review-loop.md`（progressive disclosure）。** 這是最初的方案，動機是 review loop 的 225 行在 `cash-propose` 與 `cash-apply` 之間完全共用，乘上兩個變體後同一份內容存在於四個檔案。審查發現此方案撞上 Cash 的完整性架構：信任根 `.cash-skills/bin/cash` 硬編碼 24 條單一 `SKILL.md` 路徑並對 receipt 做完全相等比對，任何新增受管檔案都會使每個 cash 指令以 `receipt_invalid` 失敗；而該 launcher 又被 `scripts/cash-skills/tests/test_bundle_version_history.py` 無條件凍結在其引入 commit，連遞增版本都無法解除；此外 `parse_receipt` 以記錄數硬比對，使既有已安裝 target 沒有升級路徑。「每個 skill 恰好一個檔案」是寫在信任根上的架構約束，不是安裝器的實作細節。改變它屬於完整性架構變更，與 prompt 工程是不同性質的工作，應為獨立 change。放棄。

**只瘦身 `.claude` 變體，`.agents` 維持完整護欄。** 論據是 Claude 5 世代的判斷力假設不適用於 Codex 等其他 runtime，保留較弱 runtime 的護欄有實質價值。但這直接違反既有的變體對等 requirement，需要在同一個 change 內同時鬆綁該 requirement 與其對等測試，會把一個 prompt 瘦身變成治理模型的變更。放棄。

**保留 Rationalization Table 但縮短。** 該表的每一列都是對模型意圖的預測與勸誡，縮短後性質不變。整段移除，其中唯一具契約性質的內容（標記任務完成前必須重新讀取任務描述與 Implementation Contract 並逐項確認）已存在於任務迴圈的 verify-before-marking-done 步驟中。

**純刪除，不補 spec。** 成本最低，但這些段落正是因為沒有 spec 覆蓋才漂移成現在的樣子；刪改後若仍無覆蓋，同樣的漂移會再次發生，且刪除時丟掉有效契約子集的風險無從攔截。補上兩條 requirement 與對應的機械斷言。

## Capabilities

### New Capabilities

（無）

### Modified Capabilities

- `cash-skill-workflows`：新增兩條 requirement——`cash-apply` 實作紀律的判準式內容契約（必須保留的可稽核驗收標準與 Implementation Notes Protocol 銜接），以及 skill 互動 fallback 的單一陳述——並為兩者建立機械斷言。

## Impact

- Affected specs:
  - cash-skill-workflows

- Affected code:
  - New:
    - （無）
  - Modified:
    - `.claude/skills/cash-analyze/SKILL.md`
    - `.claude/skills/cash-apply/SKILL.md`
    - `.claude/skills/cash-archive/SKILL.md`
    - `.claude/skills/cash-ask/SKILL.md`
    - `.claude/skills/cash-audit/SKILL.md`
    - `.claude/skills/cash-commit/SKILL.md`
    - `.claude/skills/cash-debug/SKILL.md`
    - `.claude/skills/cash-drift/SKILL.md`
    - `.claude/skills/cash-ingest/SKILL.md`
    - `.claude/skills/cash-propose/SKILL.md`
    - `.agents/skills/cash-analyze/SKILL.md`
    - `.agents/skills/cash-apply/SKILL.md`
    - `.agents/skills/cash-archive/SKILL.md`
    - `.agents/skills/cash-ask/SKILL.md`
    - `.agents/skills/cash-audit/SKILL.md`
    - `.agents/skills/cash-commit/SKILL.md`
    - `.agents/skills/cash-debug/SKILL.md`
    - `.agents/skills/cash-drift/SKILL.md`
    - `.agents/skills/cash-ingest/SKILL.md`
    - `.agents/skills/cash-propose/SKILL.md`
    - `scripts/cash-skills/variant-parity/`
    - `scripts/cash-skills/tests/skill-checks.fish`
    - `cash-skills.version`
    - `openspec/specs/cash-skill-workflows/spec.md`
  - Removed:
    - （無）

## 1. 層次一——移除純重複

每個任務的判準（design C1）：被刪文字所表達的規範，在同檔其他位置或 `CLAUDE.md` 的 Cash 區塊中有等效或更強的**既有**表述；無法指出該表述時 MUST NOT 刪除。本節 MUST NOT 新增或修改 `CLAUDE.md` 與 `AGENTS.md` 的 Cash 受管區塊（`skill-checks.fish:267` 對其釘死 baseline 雜湊）。

每個任務同時修改 `.claude` 與 `.agents` 兩個變體以維持對等。

**Guardrails 精簡的下限（design C1）**：帶 `**NEVER**` 或 `MUST NOT` 且規範不可逆副作用（git 暫存與提交、刪檔、寫入外部狀態）的條目 MUST 保留，即使前文已有等效表述。每一處刪除 MUST 在 `openspec/changes/rightsize-cash-skills/implementation-notes.md` 記一筆指認，寫明承載同一規範的保留位置（檔案與行號）。

**七個 skill 的唯一 fallback 陳述就在 Guardrails 區塊末條 bullet**（analyze `:99`、archive `:172`、propose `:518`、drift `:134`、ingest `:275`、apply `:709`、commit `:335`）。精簡該區塊時 MUST 保留該條。

**parity manifest**：實測六份受影響 manifest 中，`cash-analyze.diff`、`cash-ask.diff`、`cash-audit.diff`、`cash-drift.diff`、`cash-propose.diff` 的全部 hunk 都早於各該 skill 的 Guardrails 與 Rationalization Table 位置，內容不會改變，MUST 維持逐位元組不變、MUST NOT 人工編輯。唯一需要重新產生的是 `cash-ingest.diff`。`[P]` 任務各自修改不同 skill 的檔案，無同檔寫入衝突；但**套件層級的驗證群組 MUST 在 1.11 統一執行一次**，個別任務只做該 skill 範圍內的自我檢查，避免看到兄弟任務的半完成狀態而產生非決定性失敗。

- [x] 1.1 [P] `cash-analyze`：精簡 `.claude/skills/cash-analyze/SKILL.md` 與 `.agents/skills/cash-analyze/SKILL.md` 的 `**Guardrails**` 區塊。該 skill 的 fallback 已為單一陳述，MUST NOT 改動。自我檢查：兩檔的 fallback 陳述數維持 1。
- [x] 1.2 [P] `cash-archive`：精簡 `.claude/skills/cash-archive/SKILL.md` 與 `.agents/skills/cash-archive/SKILL.md` 的 `**Guardrails**` 區塊。fallback 已為單一陳述，MUST NOT 改動。archive 非 divergent skill，兩變體在正規化後 MUST 零差異。自我檢查：`diff` 正規化後為空。
- [x] 1.3 [P] `cash-ask`：精簡 `.claude/skills/cash-ask/SKILL.md` 與 `.agents/skills/cash-ask/SKILL.md` 的 `**Guardrails**` 區塊。
- [x] 1.4 [P] `cash-audit`：移除 `.claude/skills/cash-audit/SKILL.md` 與 `.agents/skills/cash-audit/SKILL.md` 的 Rationalization Table。
- [x] 1.5 [P] `cash-commit`：精簡 `.claude/skills/cash-commit/SKILL.md` 與 `.agents/skills/cash-commit/SKILL.md` 的 `**Guardrails**` 區塊，並把**五處** fallback（`.claude` 變體的 `:72`、`:102`、`:186`、`:198`、`:335`；`:72` 的措辭為 `If the tool is unavailable, ask the same question in plain text and wait.`，未逐字提及工具名）收斂為單一陳述。MUST 保留 `skill-checks.fish` 對 commit 斷言的十一條與三條字面值。commit 非 divergent skill，兩變體在正規化後 MUST 零差異。自我檢查：兩檔的 fallback 陳述數各為 1；上述十四條字面值仍存在；`diff` 正規化後為空。
- [x] 1.6 [P] `cash-debug`：移除 `.claude/skills/cash-debug/SKILL.md` 與 `.agents/skills/cash-debug/SKILL.md` 的 Rationalization Table。debug 非 divergent skill。自我檢查：`diff` 正規化後為空。
- [x] 1.7 [P] `cash-drift`：精簡 `.claude/skills/cash-drift/SKILL.md` 與 `.agents/skills/cash-drift/SKILL.md` 的 `**Guardrails**` 區塊，並把 `:121` 與 `:134` 兩處 fallback 收斂為單一陳述（該檔另有五處 `plain-language` 是報告格式用語，MUST NOT 改動）。MUST NOT 引入 `copy-pasteable` 字面值。自我檢查：兩檔的 fallback 陳述數各為 1；無 `copy-pasteable`。
- [x] 1.8 [P] `cash-ingest`：移除 `.claude/skills/cash-ingest/SKILL.md` 與 `.agents/skills/cash-ingest/SKILL.md` 的 Rationalization Table，精簡 `**Guardrails**` 區塊，把 `:110`–`:112` 與 `:275` 兩處 fallback 收斂為單一陳述（`:110` 為條件獨立成行的多行形狀）。**MUST NOT 併入或刪除 `:261`**——該處在工具不可用時要求顯示摘要、告知使用者稍後執行 `cash-apply`，然後 `Then STOP — do not continue`，承載的停止契約在全檔無其他位置，依 design D3 的兩軸判定不滿足 (b) 因而不計入；並重新產生 `scripts/cash-skills/variant-parity/cash-ingest.diff`——其最後一個 hunk `@@ -267 +267 @@` 正是本任務要修剪的 Guardrails 區塊內的 `**NEVER** modify the original plan file` bullet，若兩變體同時刪除該 bullet 則該 hunk MUST 一併從 manifest 移除；`:110` 的收斂也會使 hunk 行號位移。manifest MUST 以 `skill-checks.fish` 的 `normalized_variant_diff` 相同程序重新產生（perl 呼叫前綴正規化後 `diff -U0 --label codex/cash-ingest --label claude/cash-ingest`），MUST NOT 手工拼湊 hunk 標頭。MUST NOT 在 `.agents` 變體引入 `~/.claude/plans/` 形式的目錄路徑（`assert_well_formedness` 的 directory-free Codex plan references 斷言）。自我檢查：兩檔扣除 `:261` 後的 fallback 陳述數各為 1；`:261` 的 `Then STOP — do not continue` 仍存在；`.agents` 變體無該路徑形狀。
- [x] 1.9 [P] `cash-propose`：精簡 `.claude/skills/cash-propose/SKILL.md` 與 `.agents/skills/cash-propose/SKILL.md` 的 `**Guardrails**` 區塊。fallback 已為單一陳述，MUST NOT 改動。MUST NOT 引入 `## Why`、`## What Changes`、`## Problem`、`## Root Cause`、`## Success Criteria` 五個字面值。自我檢查：兩檔皆無上述五個字面值。
- [x] 1.10 `cash-apply`：移除 `.claude/skills/cash-apply/SKILL.md` 與 `.agents/skills/cash-apply/SKILL.md` 的 Rationalization Table，精簡 `**Guardrails**` 區塊，把五處 fallback（`:79`–`:81`、`:139`–`:141`、`:154`、`:172`、`:709`；其中 `:79`–`:81` 與 `:139`–`:141` 為條件獨立成行的多行形狀，其覆述的 `unpark`／`in-progress add` 指令序列在同段的 AskUserQuestion 分支已完整承載，可安全收斂）收斂為單一陳述，並把一般性回覆語言規則從 `:300`（Keep verbatim 清單）與 `:380`–`:404`（`**Cash-apply response language**` 區塊，內部覆述四次）收斂為單一位置。
  **MUST NOT 併入或刪除下列三處主詞不同的規則**：`:332`（`implementation-notes.md` 條目的散文語言）、`:406`–`:413`（審查迴圈修改 artifact 時的語言，其中 `:411` 承載 Spec-file 語言政策與「MODIFIED／REMOVED requirement 標題 MUST 逐位元組自 master spec 複製」這條契約，遺失會使 `cash archive` 以 `requirement_identity_mismatch` fail closed）、`:624`–`:633`（Round file 語言，含 `**Round file language**` 標題行）。
  MUST 保留 `Archive first, then commit together` 與 `deletes the touched state that` 兩條字面值，以及逐字英文片語 `a synchronization primitive, identity/generation type, or state machine not defined in design.md` 在 task loop 與 review loop 兩處的出現。apply 非 divergent skill，兩變體在正規化後 MUST 零差異。
  自我檢查：兩檔的 fallback 陳述數各為 1；`:411` 的逐位元組標題規則字面值仍存在；上述兩條與英文片語仍存在；`diff` 正規化後為空。
- [x] 1.11 本節全部任務完成後，統一執行一次套件層級驗證。驗證目標：`fish scripts/cash-skills/tests/skill-checks.fish variant-parity`、`codex-command-matrix`、`well-formedness` 三個群組皆通過。

## 2. 層次二——把品味紀律重寫為判準

- [x] 2.1 在 `.claude/skills/cash-apply/SKILL.md` 與 `.agents/skills/cash-apply/SKILL.md` 中，合併重寫 `:264`–`:298`（含 `**Surgical & Simplicity Discipline**` 上位標題、`:266` 導言與三個子段）為一段判準式表述，合併後只保留單一標題；若保留 `:266` 導言，其「兩項紀律」數量陳述 MUST 更正。MUST 保留 design D2 保留清單的全部項目：diff 可追溯性、`deviation` 銜接、`:281` 的不相關缺陷以 `open-question` 記錄、`:298` 前半的 `task done` 前 gating，以及 `:271` 與 `:278`／`:281` 的範圍紀律語意（四個檔案的 `Common false positives` 過濾規則以此為前提）。MUST 移除的僅為 `Maintain Balance` 的六項語法層級風格禁令列舉，以「clarity 優先於 brevity」判準取代。新段落名稱在兩個變體中 MUST 一致。驗證目標：兩檔皆含 D2 保留清單的每一項；皆不含該六項風格禁令字面值。
- [x] 2.2 同步 `Common false positives` 清單中引用 `Simplicity First` 與 `Surgical Changes` 的兩條項目，使其指向 2.1 的新段落名稱。此清單存在於**四個**檔案：`.claude/skills/cash-apply/SKILL.md`（`:531`、`:532`）、`.agents/skills/cash-apply/SKILL.md`、`.claude/skills/cash-propose/SKILL.md`（`:348`、`:349`）、`.agents/skills/cash-propose/SKILL.md`。驗證目標：四個檔案中搜尋舊段落名稱為零出現或全部已更新；不存在指向已不存在段落名稱的懸空引用；四檔的 false-positive 條目所引用的範圍紀律在新段落中仍有對應文字。

## 3. Spec 覆蓋與機械斷言

- [x] 3.1 在 `scripts/cash-skills/tests/skill-checks.fish` 新增實作紀律內容斷言：`cash-apply` 兩變體 MUST 含 diff 可追溯性驗收標準與 Implementation Notes Protocol `deviation` 銜接，且 MUST NOT 含被移除的風格禁令字面值。斷言 MUST 掛在既有具名測試群組下並出現在 `all` 執行路徑中。另新增段落名稱一致斷言：對 `.claude`／`.agents` 的 `cash-apply` 與 `cash-propose` 四個 `SKILL.md`，以 2.1 的新段落名稱 `assert_contains`，並對舊名稱 `Simplicity First` 與 `Surgical Changes` `assert_absent`，以機械方式承載 delta spec 的「段落名稱在四個檔案中一致」scenario。驗證目標：在任一變體移除可追溯性語句會使套件非零結束；在任一變體重新加入風格禁令列舉會使套件非零結束；在四檔任一處留下舊段落名稱會使套件非零結束。
- [x] 3.2 在 `scripts/cash-skills/tests/skill-checks.fish` 新增 fallback 單一陳述斷言：計算每個 canonical `SKILL.md` 的 fallback 陳述出現次數。比對 MUST 依 design D3 的兩軸判定條件——(a) 指出該工具或其泛稱不可用、(b) 規定改以純文字提出相同問題或選項並等待——且 MUST 以多行視窗比對、視窗界定為同一段落（自 (a) 命中行至下一個空行的連續非空行區塊），MUST NOT 要求同行出現、MUST NOT 使用固定行數常數（`cash-apply:79`–`:81`、`:139`–`:141`、`cash-ingest:110`–`:112` 皆為跨行形狀）。斷言 MUST 同時把關上下界：使用 AskUserQuestion 的 skill 恰為一次，不使用者為零次。不需要具名例外機制——兩軸判定已自然排除 `cash-ingest:261`、`cash-apply:485`、`cash-propose:302`。斷言 MUST 掛在既有具名測試群組下並出現在 `all` 執行路徑中。驗證目標：注入第二處 fallback 陳述（單行與跨行形狀各試一次）皆使套件非零結束；刪除任一使用該工具的 skill 其唯一一處 fallback 陳述使套件非零結束；`cash-ingest` 保留 `:261`、`cash-propose` 保留 `:302`、`cash-drift` 保留五處報告格式 `plain-language` 時皆通過；未改動時通過。

## 4. 版本

- [x] 4.1 遞增 `cash-skills.version`，維持單行 LF 結尾。驗證目標：`python3 scripts/cash-skills/tests/test_bundle_version_history.py` 通過。

## 5. 全量驗證

- [x] 5.1 執行 `fish scripts/cash-skills/tests/skill-checks.fish all` 並確認通過。
- [x] 5.2 執行 `.cash-skills/bin/cash validate rightsize-cash-skills` 並確認通過。
- [x] 5.3 逐項核對 design 的 C1–C5 Implementation Contract，確認每項的觀察行為、範圍邊界、失敗模式與驗收標準都已滿足；未滿足者回到對應任務修正。

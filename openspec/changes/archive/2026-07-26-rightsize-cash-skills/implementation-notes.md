<!-- cash-apply implementation notes | change: rightsize-cash-skills | initialized: 2026-07-26 17:05 | no entries below means no deviations or open questions were recorded -->

## 2026-07-26 17:10 — 精簡 cash-analyze 重複 Guardrail
- 類別：deviation
- 任務：1.1
- 內容：刪除兩變體 `Do NOT prompt for change selection if it can be inferred` 的重複 bullet；等效規範保留於 `.claude/skills/cash-analyze/SKILL.md:35`、`:45`（另有更強限制於 `:29`）及 `.agents/skills/cash-analyze/SKILL.md:24`、`:34`。
- 原因：依 design C1，該 Guardrail 已由同檔 change inference 與 selection 流程完整承載，刪除不改變 contract。

## 2026-07-26 17:10 — 精簡 cash-archive 重複 Guardrails
- 類別：deviation
- 任務：1.2
- 內容：刪除兩變體五條重複 bullet；change selection 保留於 `cash-archive/SKILL.md:24`、`:32`–`:40`，artifact status 檢查保留於 `:41`–`:47`，warnings 處置保留於 `:49`–`:52`、`:60`–`:63`，delta spec 選項與 `--skip-specs` 保留於 `:67`–`:75`，結果摘要保留於 `:93`–`:101`。
- 原因：依 design C1，上述規範均由兩變體同檔的具體步驟完整承載；不可逆副作用規則與唯一 fallback 均保留。

## 2026-07-26 17:10 — 精簡 cash-ask 重複 Guardrails
- 類別：deviation
- 任務：1.3
- 內容：刪除 `Read at most 10 files` 與 `Document-grounded only` 重複 bullet；檔案上限保留於 `.claude/skills/cash-ask/SKILL.md:68` 與 `.agents/skills/cash-ask/SKILL.md:57`，文件依據與禁止猜測保留於 `.claude/skills/cash-ask/SKILL.md:33`、`:78`–`:80` 及 `.agents/skills/cash-ask/SKILL.md:22`、`:67`–`:69`。
- 原因：依 design C1，同檔既有流程已提供等效或更強規範，且 read-only 不可逆副作用限制仍保留。

## 2026-07-26 17:10 — 收斂 cash-apply 層次一重複內容
- 類別：deviation
- 任務：1.10
- 內容：兩變體刪除 Rationalization Table、四處決策點 fallback 覆述、`Keep verbatim` 覆述、一般性回覆語言覆述及整個 Guardrails 區塊；fallback 統一保留於 `cash-apply/SKILL.md:41`，任務追蹤保留於 `:26`，context 讀取保留於 `:164`，unclear／reuse／examples／verify／task done／blocker 流程保留於 `:203`–`:232`，範圍紀律保留於 `:236`–`:243`，一般性回覆語言與 verbatim 清單合併保留於 `:325`。artifact、implementation notes 與 Round file 的主詞特定語言規則未改動。
- 原因：依 design C1，刪除內容均由同檔既有具體步驟或收斂後的單一規則承載；兩變體 contract、失敗模式與驗收標準維持不變。

## 2026-07-26 17:12 — 移除 cash-audit Rationalization Table
- 類別：deviation
- 任務：1.4
- 內容：兩變體移除整個 Rationalization Table；文件略讀與期限壓力規範保留於 `.claude/skills/cash-audit/SKILL.md:39`–`:45`、`.agents/skills/cash-audit/SKILL.md:24`–`:26`、`:140`–`:146`，彈性與演算法誤用規範保留於 `.claude/...:49`–`:59`、`.agents/...:117`–`:122`、`:150`–`:160`，惡意／混亂使用者假設保留於 `.claude/...:39`–`:45`、`.agents/...:53`–`:87`、`:140`–`:146`，設定危險組合與不安全相容性規範保留於 `.claude/...:61`–`:98`、`:127`–`:134` 及 `.agents/...:55`–`:75`、`:118`–`:122`、`:162`–`:199`、`:228`–`:235`。
- 原因：依 design C1，表格各列均由同檔 adversary lenses 與具體 audit 流程承載，刪除不改變行為。

## 2026-07-26 17:12 — 收斂 cash-commit fallback 與 Guardrails
- 類別：deviation
- 任務：1.5
- 內容：兩變體刪除四處決策點 fallback 覆述並統一保留於 `cash-commit/SKILL.md:327`；刪除完整檔案清單與 unrelated exclusion 的 Guardrails 覆述，其規範分別保留於 `:116`–`:166` 及 `:108`–`:116`、`:138`–`:143`。`NEVER use git add . or git add -A`、`NEVER commit files the user hasn't confirmed` 與 tracking-file guardrail 保留於 `:324`–`:326`。
- 原因：依 design C1/D3，單一 fallback 與既有 commit plan／confirmation 流程已完整承載刪除內容，且不可逆副作用限制未放寬。

## 2026-07-26 17:12 — 移除 cash-debug Rationalization Table
- 類別：deviation
- 任務：1.6
- 內容：兩變體移除整個 Rationalization Table；禁止猜測保留於 `cash-debug/SKILL.md:24`、`:49`–`:58`、`:108`，避免散佈 prints 保留於 `:68`，環境差異保留於 `:53`–`:58`，避免 revert 保留於 `:69`，測試義務保留於 `:90`、`:98`–`:101`、`:110`，restart／clear cache 隱藏 root cause 的限制保留於 `:75`–`:90`、`:99`、`:109`。
- 原因：依 design C1，表格規範均由兩變體同檔的四階段 debugging 流程更具體地承載。

## 2026-07-26 17:12 — 收斂 cash-drift fallback 與 Guardrail
- 類別：deviation
- 任務：1.7
- 內容：刪除 Step 4 fallback 覆述並將單一 fallback 保留於 `.claude/skills/cash-drift/SKILL.md:131`、`.agents/skills/cash-drift/SKILL.md:120`；刪除 follow-up 不自動呼叫的 Guardrail 覆述，其規範保留於 `.claude/...:100`、`.agents/...:89`。五處報告格式 `plain-language` 與 read-only 規則未改動。
- 原因：依 design C1/D3，刪除內容由同檔更具體流程與單一 fallback 完整承載。

## 2026-07-26 17:12 — 精簡 cash-ingest 重複內容
- 類別：deviation
- 任務：1.8
- 內容：刪除 parked fallback 並將單一 fallback 保留於兩變體 `cash-ingest/SKILL.md:256`；刪除 completed task、source brief、CLI availability 與 artifact verification 的 Guardrails 覆述，其規範分別保留於 `:146`–`:150` 與 `:193`–`:198`，`:60` 與 `:79`，`:26`，以及 `:226`–`:232`。Rationalization Table 的 context、proposal、task granularity、completed task preservation、spec synchronization 與未討論 artifact 檢查規範，保留於 `:112`、`:126`–`:145`、`:183`–`:186`、`:146`–`:150` 與 `:193`–`:198`、`:181`、`:162`–`:207` 的既有流程；`Then STOP — do not continue` 保留於 `:246`。`cash-ingest.diff` 依 normalized variant diff 程序重新產生。
- 原因：依 design C1/D3，刪除內容均有同檔等效或更強位置；停止契約與不可逆副作用規則未刪除。

## 2026-07-26 17:12 — 精簡 cash-propose Guardrails
- 類別：deviation
- 任務：1.9
- 內容：兩變體刪除 create all/optional、read dependencies、unclear context、existing-name handling 與 artifact verification 的 Guardrails 覆述；規範分別保留於 `cash-propose/SKILL.md:155`–`:156`、`:194`–`:197`，`:169`、`:500`，`:199`–`:201`，`:107`，以及 `:192`、`:194`–`:197`、`:495`。唯一 fallback 與 app-code／skip-workflow／invoke-apply 等不可逆副作用限制均保留。
- 原因：依 design C1，刪除內容均由同檔具體 proposal workflow 完整承載，未新增禁用的 proposal heading。

## 2026-07-26 17:32 — 補回 cash-apply 測試保留規範
- 類別：deviation
- 任務：1.10
- 內容：Round 1 發現先前刪除 Rationalization Table 時，非 TDD 模式與小型 refactor 仍須測試的規範沒有等效保留位置；現已在兩變體 `.agents/skills/cash-apply/SKILL.md:220` 與 `.claude/skills/cash-apply/SKILL.md:220` 補入 task done 前測試要求。
- 原因：此修復保留原 contract，並更正 17:10 紀錄中對 Rationalization Table 全部已有承載位置的過度概括。

## 2026-07-26 17:32 — 補回 cash-audit 不安全相容性規範
- 類別：deviation
- 任務：1.4
- 內容：Round 1 發現先前引用的 severity 與 defaults 段落未完整承載「不安全預設不得因 backwards compatibility 延續」的處置；現已在 `.agents/skills/cash-audit/SKILL.md:165` 與 `.claude/skills/cash-audit/SKILL.md:64` 明定 loudly deprecate 並 require migration。
- 原因：此修復保留原 contract，並更正 17:12 紀錄中不精確的承載位置判斷。

## 2026-07-26 17:32 — 補回 cash-ingest 三項保留規範
- 類別：deviation
- 任務：1.8
- 內容：Round 1 發現 plan 過短補問、completed tasks 與更新後 scope 的相關性再核對，以及 requirement 改變時同步 scenarios 三項未被既有流程完整承載；現已分別補入兩變體 `cash-ingest/SKILL.md:79`、`:195`、`:181`。
- 原因：此修復保留原 contract，並更正 17:12 紀錄中將一般 context／preservation／consistency 檢查視為完整替代的過度推論。

## 2026-07-26 — 補回三條非六項禁令的範圍紀律並校正失效行號
- 類別：deviation
- 任務：2.1、1.8、1.10
- 內容：review 發現 2.1 的合併重寫除了 design D2 指定移除的六項語法層級風格禁令外，另刪除了三條位於 `Simplicity First` 與 `Surgical Changes` 段的範圍紀律，三者在 24 個 `SKILL.md` 與 `CLAUDE.md`／`AGENTS.md` 中皆無等效保留位置。現已於兩變體同行補回：`cash-apply/SKILL.md:238` 補回「不要為 contract 已排除或型別已保證的情境撰寫防禦性錯誤處理，只在系統邊界（外部輸入、外部 API）驗證」——四個 `SKILL.md` 的 `Common false positives`（`cash-apply:452`、`cash-propose:348` 及兩者的 `.agents` 對應）仍以 `defensive error handling` 引用它，刪除使該過濾規則的第三個指涉失去對象；`:239` 補回 `match existing style` 與「只清除因本次改動而變成 orphan 的 import、變數與函式」——後者的禁止面雖由 `:240` 覆蓋，但允許面遺失會使實作者把自身改動造成的 orphan 誤歸為不相關死碼。另校正本檔中因 Round 1 補回而失效的保留位置行號：範圍紀律 `:237`–`:270` → `:236`–`:243`、一般性回覆語言 `:349`–`:351` → `:325`、`cash-ingest` 單一 fallback `:252` → `:256`、`Then STOP — do not continue` `:242` → `:246`，以及 1.8 條目中其餘偏移的 ingest 行號。
- 原因：三條補回均保留原 contract，並回復 design D2「MUST 移除的僅為 `Maintain Balance` 的六項列舉」與 C2「四檔 false-positive 條目所引用的範圍紀律在新段落中仍有對應文字」；三處補回皆為同行併入，不位移既有行號。行號校正使 design C1 的可稽核指認義務在文件層面重新成立。

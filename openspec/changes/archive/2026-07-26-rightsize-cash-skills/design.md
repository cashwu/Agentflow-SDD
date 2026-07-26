## Context

本 change 修改的檔案，同時是執行本 change 的 skill 本身，也是審查迴圈的裁判面。這造成兩個必須在設計層面先處理的約束：

1. `.claude/skills/cash-propose/SKILL.md`、`.claude/skills/cash-apply/SKILL.md`、兩者的 `.agents` 對應檔、`scripts/cash-skills/tests/skill-checks.fish` 與 `openspec/specs/` 都在 grader immutability 的受保護路徑集合中。proposal `## Impact` 已逐一列出這些路徑作為結構化範圍宣告，因此本 change 的修正動作得修改它們；未列出的受保護路徑（`.cash.yaml`、`scripts/cash-cli/tests/cli-checks.fish`）仍受保護。
2. 已在進行中的迴圈依其開始時的指令版本繼續；本 change 對 skill 的編輯自下一次迴圈執行起生效。因此本 change 自身的 apply 迴圈跑的是舊版指令，這是預期行為，不是缺陷。

現況的可驗證事實（實作時 MUST 以這些位置為準；若已漂移則以現況為準並記 `deviation`。行號取自 `.claude` 變體，`.agents` 變體對應位置可能有數行偏移）：

- `Simplicity First`、`Surgical Changes`、`Maintain Balance` 三段位於 `.claude/skills/cash-apply/SKILL.md:268`、`:276`、`:285` 起，在 `openspec/specs/cash-skill-workflows/spec.md` 中沒有任何規範性引用；該 spec 中 25 處 `surgical` 字樣全部是 `@trace` metadata 的同一條路徑 `scripts/spectra-plus/template/surgical-simplicity-block.md`，而 `scripts/spectra-plus/` 目錄已不存在。
- `Rationalization Table` 與 `**Guardrails**` 兩個字串在該 spec 與 `skill-checks.fish` 中皆為零出現。
- `Common false positives` 中引用 `Simplicity First` 與 `Surgical Changes` 的兩條項目，同時存在於 `cash-propose`（`:348`、`:349`）與 `cash-apply`（`:531`、`:532`）兩個 skill，乘上兩個變體共四個檔案。這兩條項目屬於 propose 與 apply 共用的 review-loop 本文。
- `cash-apply` 的一般性回覆語言規則分佈於 `:300`（Keep verbatim 清單）與 `:380`–`:404`（`**Cash-apply response language**` 區塊，其內部又覆述四次）。另有三處**主詞不同**、MUST NOT 併入或刪除的語言規則：`:332`（`implementation-notes.md` 條目的散文語言）、`:406`–`:413`（審查迴圈修改 artifact 時的語言，其中 `:411` 承載 Spec-file 語言政策與「MODIFIED／REMOVED requirement 標題 MUST 逐位元組自 master spec 複製」這條契約）、`:624`–`:633`（Round file 語言，含 `**Round file language**` 標題行）。
- AskUserQuestion 不可用時的 fallback 出現次數：`cash-apply` 五處、`cash-commit` 五處（`:72`、`:102`、`:186`、`:198`、`:335`，其中 `:72` 的措辭為 `If the tool is unavailable, ask the same question in plain text and wait.`，未逐字提及工具名）、`cash-ingest` 兩處（`:110`–`:112` 與 `:275`；`:261` 依兩軸判定不計入）、`cash-drift` 兩處（`:121` 與 `:134`；該檔另有五處 `plain-language` 為報告格式用語，不計入）。`cash-analyze`、`cash-archive`、`cash-propose`、`cash-verify` 各一處，無重複。`cash-ask`、`cash-audit`、`cash-debug`、`cash-discuss` 零處。
- `**Guardrails**` 區塊存在於 analyze、apply、archive、ask、commit、drift、ingest、propose 八個 skill；`Rationalization Table` 存在於 apply、audit、debug、ingest 四個 skill。兩者的聯集加上有重複 fallback 的 skill，構成層次一的十個 skill 範圍；`cash-discuss` 與 `cash-verify` 不在其中。
- `scripts/cash-skills/tests/skill-checks.fish` 的 `divergent_skills` 為 analyze、ask、audit、discuss、drift、ingest、propose、verify；其餘 skill 的兩變體在呼叫前綴正規化後必須零差異。層次一涵蓋的十個 skill 中，analyze、ask、audit、drift、ingest、propose 六個為 divergent，其 manifest 位於 `scripts/cash-skills/variant-parity/`。
- `scripts/cash-skills/tests/skill-checks.fish:267` 對 `CLAUDE.md` 與 `AGENTS.md` 的 Cash 受管區塊釘死 SHA-256 baseline `71cc139e2e69027e6e2d23edef83ad3fbb1e17154b932e8c2f923c0043b177b2`。
- `scripts/cash-skills/tests/test_bundle_version_history.py` 的版本遞增關卡以 `endswith("/SKILL.md")` 過濾 replaceable 路徑，因此本 change 對 SKILL.md 的任何改動都會強制要求遞增 `cash-skills.version`。

## Goals / Non-Goals

**Goals**

- 移除在 spec 與測試中皆無規範引用、且與模型判斷力重複的護欄與重複段落。
- 把 `cash-apply` 的品味紀律重寫為判準，消除 Simplicity First 與 Maintain Balance 之間的內部張力。
- 為刪改後仍須成立的兩項行為建立 spec 覆蓋與機械斷言，使其日後不再無人維護地漂移。
- 維持兩個變體在呼叫前綴正規化後的對等。

**Non-Goals**

- 見 proposal `## Non-Goals`。特別是：不改變 skill 的檔案結構，不引入 reference 檔。

## Decisions

### D1：以內容性質而非檔案劃分層次

每一處刪改都 MUST 先歸類到恰好一個層次，並在該層次的判準下成立：

- **層次一（純重複）**：被刪除的文字所表達的規範，在同一檔案的其他位置、或在 `CLAUDE.md` 的 Cash 區塊中，已有等效或更強的表述。刪除後該規範仍然成立。
- **層次二（判準化重寫）**：文字被改寫，規範強度可以降低，但可稽核的驗收標準必須保留。

歸類不明時，MUST 保留原文並在 `implementation-notes.md` 記一筆 `open-question`。

層次一的正當性依據 MUST 僅引用 `CLAUDE.md` Cash 區塊的**既有**表述。本 change MUST NOT 新增或修改該區塊——`skill-checks.fish:267` 對該區塊釘死了 baseline 雜湊，修改它會使 `guidance-cutover` 以 `canonical Cash guidance baseline drifted` 失敗，且該 baseline 的更新不在本 change 範圍內。

### D2：層次二的重寫保留可稽核內容

合併範圍為 `.claude/skills/cash-apply/SKILL.md:264`–`:298`，含 `**Surgical & Simplicity Discipline**` 上位標題、`:266` 導言與 `Simplicity First`、`Surgical Changes`、`Maintain Balance` 三段；合併後 MUST 只保留單一標題。若保留 `:266` 導言，其「兩項紀律」的數量陳述 MUST 隨之更正。

**MUST 移除的是語法層級的風格禁令**，即 `Maintain Balance` 的六項列舉（巢狀三元、dense one-liner／過度連鎖 method chain、多關注點合併、移除中介變數、移除命名常數、拿掉合理抽象），以「clarity 優先於 brevity」的判準取代。**範圍紀律不是風格禁令**，MUST 保留其語意。

合併後 MUST 保留下列各條：

- 驗收標準：「本次 diff 的每一行，都能直接追溯到 `tasks.md` 中的某條任務或 `design.md` 中的 Implementation Contract 項目」。
- 銜接：「若刻意 deviate，依 Implementation Notes Protocol 寫一筆 `deviation` 條目」。
- 範圍紀律（`:281`）：「若注意到不相關的死碼、bug 或可改進處，不要直接刪或改 — 依 Implementation Notes Protocol 以 `open-question` 條目記錄，交給使用者決定」。此條與 `:336` 的 `open-question` 觸發條件不同（後者是「任務浮現需使用者決定的問題且必須以假設繼續」），全檔無其他位置承載。
- 完成 gating（`:298` 前半）：「違反上述任一條視同 task 未完成——在執行 `task done` 之前先修正」。`:231` 與 `:335` 皆不承載此紀律。
- `Common false positives` 兩條項目所依賴的範圍紀律語意：`:271`（不為單一使用情境引入抽象層或設定選項）與 `:278`／`:281`（不重構沒壞的東西、不順手改鄰近區塊）。這兩條是四個檔案中 false-positive 過濾規則的前提，移除會使該過濾規則失去指涉對象。

合併後的段落名稱由實作決定，但 MUST 在四個檔案中一致，且 `Common false positives` 中引用舊名稱的兩條項目 MUST 同步——這兩條項目存在於 `cash-propose` 與 `cash-apply` **四個**檔案，不是僅 `cash-apply` 兩個。

### D3：互動 fallback 收斂為全檔單一陳述

每個 skill 的兩個變體 MUST 全檔恰好陳述一次「此工具不可用時，以純文字提出相同的問題或選項並等待使用者回應」，MUST NOT 於多個決策點分別覆述。判準是出現次數，不是位置也不是形狀——單一陳述得為獨立的全域規則，亦得內嵌於步驟句中（`cash-verify:45` 即為後者）。

**判定條件為兩軸，且 MUST 以多行視窗比對。** 一段文字計為 fallback 陳述，當且僅當同時滿足 (a) 指出該工具或其泛稱不可用，與 (b) 規定改以純文字提出相同問題或選項並等待。兩軸都必要，且不得要求同行出現。三個實測依據：

- 缺 (a)：`cash-drift` 有五處 `plain-language`（`:64`、`:76`、`:80`、`:96`、`:100`）描述的是報告本文的可讀性要求，若只比對 (b) 會被誤計，使該檔計數為 7 而非實際的 2。
- 缺 (b)：`cash-apply:485` 與 `cash-propose:302` 的 accepted-risks ledger 規則寫作 `If interaction is unavailable, do not write the entry and keep the finding surviving`；`cash-ingest:261` 寫作工具不可用時顯示摘要並 `Then STOP — do not continue`。三者都只滿足 (a)，若只比對 (a) 會被誤計，使 `cash-propose` 計數為 2 而與 tasks 1.9 的 MUST NOT 改動衝突。這三處 MUST NOT 被併入單一陳述，也 MUST NOT 被刪除。
- 要求同行：`cash-apply:79`–`:81`、`:139`–`:141` 與 `cash-ingest:110`–`:112` 的不可用條件獨立成行、替代作法在後續行；要求同行會使這些陳述計數為零而靜默漏檢。

因為兩軸判定已自然排除上述三處，**不需要具名例外機制**。先前設計中「以具名清單排除承載額外契約的位置」在兩軸判定下沒有適用對象，且行號會隨層次一的刪除位移而不可作為 key，該機制已移除。

**斷言 MUST 同時把關上界與下界。** 使用 AskUserQuestion 的 skill MUST 恰為一次，不使用者 MUST 為零次。只把關上界不足以保護：`cash-analyze:99`、`cash-archive:172`、`cash-propose:518`、`cash-drift:134`、`cash-ingest:275`、`cash-apply:709`、`cash-commit:335` 七處唯一的 fallback 陳述，正是層次一要修剪的 `**Guardrails**` 區塊末條 bullet；僅有上界時整條被刪仍會通過，而使用該工具的 skill 會在非 Claude runtime 上靜默失去互動 fallback。各層次一任務 MUST 明示該檔的 fallback 陳述位於 Guardrails 區塊內、精簡時 MUST 保留。

已為單一陳述的 skill（analyze、archive、propose、verify）MUST NOT 因位置或形狀而被改動。

### D4：以 spec requirement 與機械斷言為刪改的結果把關

新增兩條 requirement，並在 `scripts/cash-skills/tests/skill-checks.fish` 建立三條斷言承載它們：

- **實作紀律內容契約**：斷言 `cash-apply` 兩變體含 D2 保留清單中可字面比對的兩項（diff 可追溯性、`deviation` 銜接），且不含被移除的六項風格禁令字面值。機械斷言的涵蓋範圍小於保留清單是刻意的——`:281`、`:298` 前半與範圍紀律語意屬語意性保留，由 tasks 2.1 的驗證目標與 review loop 承載。
- **互動 fallback 單一陳述**：依 D3 的兩軸判定條件，以多行視窗比對計算每個 canonical `SKILL.md` 的 fallback 陳述次數，並同時把關上界與下界（使用該工具者恰為一，不使用者為零）。既有套件以 `perl -ne` 與 `python3` 承載跨行判定（見 `assert_well_formedness` 的空 code span 檢查與 bundle version fixture），多行視窗比對與該慣例一致。
- **實作紀律段落名稱一致**：斷言 `cash-apply` 與 `cash-propose` 四個 `SKILL.md` 的 `Common false positives` 引用的段落名稱與 `cash-apply` 中該段落的實際名稱相同，且四檔皆不含舊名稱 `Simplicity First`／`Surgical Changes`。此斷言承載「段落名稱在四個檔案中一致」該 scenario，否則該 scenario 只剩人工核對。

三條斷言 MUST 由既有的具名測試群組承載，並出現在套件的全量執行路徑中。

理由：這兩段內容之所以漂移成現在的樣子，正是因為沒有任何 spec 或測試引用它們。只刪不補會讓同樣的漂移再次發生。

### D5：版本遞增

`cash-skills.version` MUST 遞增並維持單行 LF 結尾。`test_bundle_version_history.py` 的版本關卡以 `endswith("/SKILL.md")` 過濾，本 change 改動 20 個 SKILL.md，必然觸發該關卡。

## Implementation Contract

### C1：層次一的刪除

- 觀察行為：十個 skill 的兩個變體中，`**Guardrails**` 區塊僅保留無法從該檔前文推得的條目；`Rationalization Table` 不存在；`cash-apply` 的一般性回覆語言規則僅出現於一處；有重複 fallback 的四個 skill（apply、commit、drift、ingest）各僅有一處 fallback 陳述。
- 範圍邊界：`cash-apply:332`、`:406`–`:413`（含 `:411` 的 Spec-file 語言政策與逐位元組標題規則）、`:624`–`:633`（含標題行）是主詞不同的規則，MUST NOT 被併入回覆語言規則，也 MUST NOT 被刪除。`cash-ingest:261`（工具不可用時顯示摘要並 `Then STOP — do not continue`）、`cash-apply:485` 與 `cash-propose:302`（accepted-risks ledger 的 `If interaction is unavailable, do not write the entry and keep the finding surviving`）依 D3 的兩軸判定不構成 fallback 陳述，MUST NOT 被併入單一陳述也 MUST NOT 被刪除；`cash-ingest` 的收斂對象只有 `:110` 與 `:275` 兩處。此外，帶 `**NEVER**` 或 `MUST NOT` 且規範不可逆副作用（git 暫存與提交、刪檔、寫入外部狀態）的 Guardrails 條目 MUST 保留，即使前文已有等效表述——例如 `cash-commit:330` 的 `NEVER use `git add .` or `git add -A`` 與 `:331` 的 `NEVER commit files the user hasn't confirmed`。`cash-discuss` 與 `cash-verify` 不在範圍內。
- 每一處刪除 MUST 能指出承載同一規範的保留位置（同檔其他位置或 `CLAUDE.md` Cash 區塊的既有表述），且該指認 MUST 寫入 `openspec/changes/rightsize-cash-skills/implementation-notes.md`（保留位置的檔案與行號），使此義務可稽核；無法指出時 MUST NOT 刪除。
- 失敗模式：刪除後某條規範在全檔與 `CLAUDE.md` 中皆不再出現；或 `:411` 的逐位元組標題規則遺失（會使 `cash archive` 以 `requirement_identity_mismatch` fail closed）。
- 驗收：`fish scripts/cash-skills/tests/skill-checks.fish all` 通過；且對每一個被刪段落，能指出承載同一規範的保留位置。

### C2：層次二的重寫

- 觀察行為：`cash-apply` 兩變體中原三段合併為一段判準式表述，保留 D2 保留清單的全部項目（其中兩項由機械斷言把關，其餘由 tasks 2.1 的驗證目標承載）；`Common false positives` 中的兩條項目在**四個**檔案中都與新段落名稱一致。
- 失敗模式：diff 可追溯性驗收標準或 Implementation Notes Protocol 銜接在重寫中遺失；或四個檔案中任一處留下指向已不存在段落名稱的懸空引用。
- 驗收：四個檔案中搜尋舊段落名稱為零出現或全部已更新；D4 的實作紀律斷言通過。

### C3：spec 覆蓋與機械斷言

- 觀察行為：兩條新 requirement 由三條斷言承載，且斷言確實能攔截違反——在 `cash-apply` 移除 diff 可追溯性語句、在任一 skill 注入第二處 fallback 陳述、刪除某個使用該工具的 skill 其唯一一處 fallback 陳述、或在四個 `SKILL.md` 任一處留下舊段落名稱，套件 MUST 以非零結束。
- 資料形狀：斷言掛在既有的具名測試群組下，並出現在 `all` 執行路徑中。
- 失敗模式：斷言存在但從未被任何群組呼叫；fallback 斷言只把關上界而不把關下界；或以同行比對實作兩軸判定而漏掉跨行版面。
- 驗收：上述四個注入案例各自使套件失敗；`fish scripts/cash-skills/tests/skill-checks.fish all` 在未注入時通過。

### C4：變體對等與版本

- 觀察行為：兩個變體在呼叫前綴正規化後對等；六個 divergent skill 的 manifest 逐行反映實際差異；四個非 divergent skill（apply、archive、commit、debug）的兩變體零差異。`cash-skills.version` 已遞增。
- 驗收：`variant-parity` 與 `installer-runtime` 群組通過；`python3 scripts/cash-skills/tests/test_bundle_version_history.py` 通過。

### C5：跨層次的不變量

- `cash-apply` 阻塞分類中逐字內嵌的英文片語 `a synchronization primitive, identity/generation type, or state machine not defined in design.md` MUST 在 task loop 與 review loop 兩處都保持逐字不變。
- `skill-checks.fish` 既有的字面值斷言全部維持通過，包括 `cash-commit` 的十一條與三條、`cash-apply`／`cash-verify` 的 apply-instructions 消費者字面值、review-loop 的六條、`Archive first, then commit together`、`deletes the touched state that`。
- 所有 CLI 呼叫、檔案路徑、schema 欄位名、artifact ID、capability slug 與 requirement 標題逐位元組相符規則不變。
- 每個 skill 目錄維持恰好一個 `SKILL.md`。

## Risks / Trade-offs

**R1：刪除時誤刪仍需保留的契約子集。** 對應 open signal `retained-contract-subset-loss`（3 次）。這是本 change 的頭號風險，因為兩個層次都是刪除或改寫操作。最具體的暴露面是 `cash-apply:411` 的逐位元組標題規則——它埋在一個看似只講語言的區塊裡，卻是 `cash archive` fail closed 的前提。緩解：C1 明列範圍邊界並逐一點名不得動的三個位置；每一處刪除都要求指出承載同一規範的保留位置。

**R2：移除段落後殘留懸空引用。** 對應 open signal `removed-mechanism-residual-references`（4 次）。`Common false positives` 引用 `Simplicity First` 與 `Surgical Changes`，且存在於四個檔案而非兩個。緩解：C2 明列四個檔案；每輪 fix actions 依既有 fix propagation 規則對每個被觸及的概念做全 artifact 與全 skill grep。

**R3：本 change 修改自身的裁判面。** proposal `## Impact` 的結構化範圍宣告已涵蓋所有需修改的受保護路徑。未宣告的受保護路徑仍受保護，審查迴圈若要求修改它們，MUST 記 `未修復：裁判面保護` 而非修改。

**R4：`.agents` 變體服務的是能力較弱的 runtime。** 本次瘦身的前提是 Claude 5 世代的判斷力，該前提在 Codex 等 runtime 上不成立，等量套用可能使 `.agents` 端的行為品質下降。接受此風險，理由是變體對等是既有 requirement，鬆綁它會把 prompt 瘦身變成治理模型變更（見 proposal `## Alternatives Considered`）。若日後觀察到 `.agents` 端劣化，應以獨立 change 重新評估對等 requirement，而非在本 change 內開特例。

**R5：層次一的判準有主觀成分。** 「無法從前文推得」需要判斷。緩解：C1 要求每一處刪除都能指出承載同一規範的保留位置，把主觀判斷轉為可稽核的指認；D1 規定歸類不明時保留原文並記 `open-question`。

**R6：Impact 粒度偏大（24 個路徑條目）。** 其中 20 個是同構的 SKILL.md 編輯，實際決策點只有兩個層次加 spec 覆蓋。接受此取捨。

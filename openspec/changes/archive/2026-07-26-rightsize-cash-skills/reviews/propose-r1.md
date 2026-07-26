# Cash Propose Review — Round 1

## Reviewer Findings

本輪為本次執行的第一輪（未 seed），故所有存活的 Critical 與 Warning 皆為 blocking，且不需要 `disposition` 欄位。findings 已依 `location + summary` 彙總；A 代表 Reviewer A（Adherence），B 代表 Reviewer B（Quality）。

### Critical

**F1** — `severity: Critical`｜`confidence: 100`｜`layer: design`｜來源：A、B（彙總）
- `location`: `.cash-skills/bin/cash:23-30,230-232`；design.md `### D4`；tasks.md 4.4／4.6；proposal.md `## Impact`
- `summary`: launcher 硬編碼 24 條 `SKILL_PATHS` 並對 receipt 的 skill 記錄做完全相等比對，4.6 重建 receipt 加入四個 reference 記錄後，每一個 cash 指令都會以 `receipt_invalid` 失敗；launcher 既不在 `## Impact` 也無任何 task 修改。
- `recommendation`: 將 `.cash-skills/bin/cash` 納入 `## Impact`，並在 D4 增加決策使 launcher 的 skill 路徑判定與 installer payload 列舉採同一推導；該 task MUST 排在 4.6 之前。

**F2** — `severity: Critical`｜`confidence: 85`｜`layer: design`｜來源：B
- `location`: `scripts/cash-skills/tests/test_bundle_version_history.py:147-153`
- `summary`: `check_history` 對 `STABLE_PATHS`（含 `.cash-skills/bin/cash`）的 introduction-commit 比對位於 `current != head` 早退之前，因此 launcher 被無條件凍結在其引入 commit；F1 所需的 launcher 改動必然使此測試失敗，且無法以遞增版本解除。
- `recommendation`: design MUST 明確處理此 immutable-artifact 衝突：放寬 `STABLE_PATHS` 凍結並將其列為交付項，或改採不需修改 launcher 的 payload 擴充方式。

**F3** — `severity: Critical`｜`confidence: 90`｜`layer: design`｜來源：B
- `location`: `.cash-skills/lib/cash_cli/installer.py:499-500,1348-1357`
- `summary`: `parse_receipt` 以記錄數硬性比對，payload 由 24 筆增為 28 筆會使所有既有已安裝 target 的 receipt 記錄數對不上並以 exit 1 結束，`--force` 無法繞過（raise 發生在 force 判斷之前），既有專案沒有升級路徑。
- `recommendation`: design MUST 新增「payload 檔案集合擴張時的既有 target 升級」決策，並在 `test_installer_runtime.py` 補一個「舊記錄數 receipt → 新 payload」回歸案例。

**F4** — `severity: Critical`｜`confidence: 85`｜`layer: design`｜來源：B
- `location`: `.cash-skills/lib/cash_cli/installer.py:550-554`；`main` 僅捕捉 `InstallerError`
- `summary`: `parse_legacy_receipt` 以 `len(rows) != 25` 判斷 legacy schema 後以 `zip(..., strict=True)` 配對；skill 記錄增為 28 筆後，25 列的 legacy receipt 會通過第一道檢查卻在 strict zip 拋出未捕捉的 `ValueError`，使用者看到 traceback 而非契約化錯誤。
- `recommendation`: 使 legacy receipt 的固定期望與新的 skill 記錄集合解耦，只與 payload 中屬於 `SKILL.md` 的子集合比對。

**F5** — `severity: Critical`｜`confidence: 100`｜`layer: design`｜來源：A、B（彙總）
- `location`: `scripts/cash-skills/tests/test_installer_runtime.py:212,634`
- `summary`: 該檔第 634 行硬編碼 skill 記錄數為 24、第 212 行 `copy_skills` 只 glob `cash-*/SKILL.md`，新增 reference 檔後必然失敗；但該檔既不在 `## Impact` 也無 task 修改，反而被 4.4／4.5 當成「不改也應通過」的驗證目標。
- `recommendation`: 納入 `## Impact` 與 D5 涵蓋範圍，新增 task 使數量由實際受管檔案集合推導、glob 改為涵蓋 skill 目錄下所有 `.md`。

**F6** — `severity: Critical`｜`confidence: 90`｜`layer: design`｜來源：A
- `location`: design.md `### D2`；delta spec 缺少對 `審查迴圈的 grader 不可變性` 的 MODIFIED
- `summary`: D2 把 156 行 review-loop 規則移出受保護的四個 SKILL.md，但 grader immutability 的受保護路徑集合只列四個 `SKILL.md`，未涵蓋新的 `references/review-loop.md`；拆檔後審查迴圈可在無範圍宣告的情況下修改自己的裁判規則本文。
- `recommendation`: 新增 MODIFIED requirement 將受保護集合改以 skill 目錄下受管檔案集合表述，並同步四個 SKILL.md 的受保護路徑清單與 `assert_grader_immutability` 斷言。

**F7** — `severity: Critical`｜`confidence: 95`｜`layer: design`｜來源：A
- `location`: design.md `### D3`／`### D2`
- `summary`: D3 要求四份 reference 檔「除呼叫前綴外 MUST 相同」，但 propose 與 apply 現行 review-loop 本文並非只差呼叫前綴——`Common false positives` 中 apply 版含 `## What Changes` 而 propose 版無。逐字搬移會使四份不相同；統一內容又違反 D2「逐字保留」，且會把 spec 禁止的 `## What Changes` 字面值帶進 propose 的受管檔案。
- `recommendation`: 在 D3 明確裁決此既有差異並列出例外，或統一為 propose 措辭且歸入層次三、記 `deviation`；同時把 propose 的五標題 absent 檢查擴張到其 reference 檔。

**F8** — `severity: Critical`｜`confidence: 95`｜`layer: design`｜來源：A
- `location`: tasks.md 3.2；design.md `### D6`／`### C5`
- `summary`: `Common false positives` 中引用 `Simplicity First` 與 `Surgical Changes` 的兩條項目同時存在於 cash-propose 兩變體的 SKILL.md，但 task 3.2 範圍僅 cash-apply 兩變體；重寫後 propose 側會留下懸空引用，並使四份 reference 檔的對等直接失效。
- `recommendation`: 將 3.2 範圍擴為四個檔案，或於第 4 節搬移後統一在四份 reference 檔中修正；D6／C5 一併更正該區塊為 propose 與 apply 共用。

### Warning

**F9** — `Warning`｜`confidence: 90`｜`layer: design`｜A、B（彙總）｜`location`: `scripts/cash-skills/tests/test_bundle_version_history.py:68-82,159-172`
- `summary`: 版本遞增關卡的 inventory 只列 `{variant}/skills/cash-{skill}/SKILL.md` 並以 `endswith("/SKILL.md")` 過濾，四個 reference 檔完全逃出版本遞增強制，改它們不需 bump 版本，卻會在既有 target 端以同版本 source integrity drift 炸開。
- `recommendation`: 納入 `## Impact` 與第 5 節 task，使 inventory 與過濾涵蓋 skill 目錄下所有受管 `.md`，並補注入式負向驗證。

**F10** — `Warning`｜`confidence: 90`｜`layer: design`｜A、B（彙總）｜`location`: `CASH-SKILLS.md:26,36,78,80`；design.md `### D7`；tasks.md 5.2
- `summary`: D7 稱 `CASH-SKILLS.md` 的「24」指目錄數，與原文不符——第 26／36／78／80 行四處全部以檔案數陳述語意；且 `skill-checks.fish:275` 逐字斷言 `24 個 canonical` 必須存在。
- `recommendation`: 更正 D7 的事實敘述，並在 5.2 逐行列出需改寫的四處與必須保留的斷言子字串。

**F11** — `Warning`｜`confidence: 85`｜`layer: design`｜A｜`location`: delta spec `## ADDED Requirements` 的兩條 Scenario；design.md `### D5`
- `summary`: 「SKILL.md MUST 列出並以 MUST 級指示讀取 reference 檔」與「reference 檔 MUST NOT 含四個 sentinel」兩條規範沒有任何機械斷言支撐。
- `recommendation`: 在 4.7 增加對應斷言，並在 C4 補注入式負向案例。

**F12** — `Warning`｜`confidence: 80`｜`layer: design`｜A、B（彙總）｜`location`: `scripts/cash-skills/tests/skill-checks.fish:82-91`；design.md `### D5`；tasks.md 4.8
- `summary`: D5／4.8 未擴張 `assert_command_matrix` 的兩條 `assert_absent` 反模式檢查（PATH-based artifact command、retired runtime compatibility）；156 行含 CLI 呼叫的本文移入 reference 檔後將不受這些既有護欄涵蓋。
- `recommendation`: 兩條 `assert_absent` MUST 同時套用到四個 reference 檔；bootstrap 的正向斷言維持僅 SKILL.md。

**F13** — `Warning`｜`confidence: 80`｜`layer: design`｜A｜`location`: design.md `### D1`；tasks.md 2.10／3.1／3.2／4.1
- `summary`: D1 規定「一段文字不得同時以兩個層次處理」，但 `Common false positives` 同時是層次三與層次二對象、`Round file language` 同時是層次一與層次二對象，design 未給出處理順序或歸屬裁決。
- `recommendation`: 補一條銜接規則：落在層次二搬移範圍內的文字，層次一／三的改寫 MUST 先於搬移在 SKILL.md 完成，搬移時以改寫後內容逐字搬移。

**F14** — `Warning`｜`confidence: 80`｜`layer: design`｜A｜`location`: tasks.md 2.10
- `summary`: 「把回覆語言規則從四處收斂為一處」未指名是哪四處；相關位置至少五處，其中第 411 行承載 spec 檔案語言政策與逐位元組標題規則（C7 明列不得變動），第 625 行屬層次二搬移範圍。不指名等同把契約層級取捨推給實作者。
- `recommendation`: 逐行列出要收斂的位置，並標註第 411 與 625 行為不同受詞、MUST NOT 被併入或刪除。

**F15** — `Warning`｜`confidence: 80`｜`layer: design`｜A｜`location`: proposal.md `## Motivation`；tasks.md 2.5
- `summary`: `cash-commit` 的 AskUserQuestion fallback 實際為五處（含第 72 行未逐字提及工具名者），proposal 與 2.5 均記為四處，依此執行會殘留一處。
- `recommendation`: 更正計數為五處，或改以判準表述並以 grep 作為可機械驗證的驗收。

**F16** — `Warning`｜`confidence: 85`｜`layer: design`｜A｜`location`: design.md `## Context`
- `summary`: 「discuss 與 verify 不含其中任何一個」不成立：`.claude/skills/cash-verify/SKILL.md:45` 含行內 AskUserQuestion fallback。
- `recommendation`: 更正 Context 敘述，或把 cash-verify 兩變體納入層次一範圍並補 task 與 Impact 條目。

**F17** — `Warning`｜`confidence: 85`｜`layer: text`｜A｜`location`: design.md `### C4`
- `summary`: C4 寫「D5 所列六項調整」，但 D5 實際只有五項；「六」係與「六條 review-loop 字面值」混淆。
- `recommendation`: 改為五項或逐項列出。
- 主 agent 覆核：此修正不影響任何行為或設計陳述，維持 `layer: text`。

**F18** — `Warning`｜`confidence: 80`｜`layer: design`｜B｜`location`: design.md `### D2`／`### R7`；`.claude/skills/cash-apply/SKILL.md:570,644`
- `summary`: D2 自立的判準是「未載入也必須生效者留在 SKILL.md」，但實際拆分點是「有 sentinel 者留下」，兩者在 fix actions 區塊分岔：第 570 行的 receipt 重建指示（R4 的唯一緩解手段）會隨 fix actions 移入按需載入的檔案。
- `recommendation`: 在 D2 的「留在 SKILL.md」清單明確加入 fix-actions 的兩條外部副作用規則，或說明為何 sentinel 判準優先並接受該風險；D5 對六條字面值的分類需隨之更新。

### Suggestion

以下 findings 的 `confidence` 落在 `[50, 80)`，依信心過濾器降級為 `Suggestion`，不進入 blocking 集合。

- **F19**（原 Warning，`confidence: 75`，A）：`<!-- SIGNALS-READ-STEP -->` 是第五個受治理 sentinel，D2「恰好四個」的敘述與 ADDED requirement 的列舉會意外放寬該 sentinel 的位置保證。
- **F20**（原 Warning，`confidence: 75`，B）：多檔對等比較的 manifest 檔名與 label 慣例未定義，delta spec 要求失敗訊息指出 reference 檔卻無慣例可依。
- **F21**（原 Warning，`confidence: 75`，B）：tasks 1.1 的撤回分支是未受治理的退出路徑，未連帶撤回 delta spec 的 ADDED requirement 與 `## Impact` 的四個 New 條目。
- **F22**（原 Warning，`confidence: 70`，B）：第 2 節九個 `[P]` 任務宣告套件層級驗證目標，平行執行會看到兄弟任務半完成狀態而產生非決定性失敗。
- **F23**（原 Warning，`confidence: 60`，B）：delta spec 的列舉順序 Example 與 receipt idempotence 只有人工目視確認承載。
- **F24**（原 Suggestion，`confidence: 60`，A）：tasks 2.8 的驗證目標應補 `well-formedness` 群組。
- **F25**（原 Suggestion，`confidence: 55`，B）：tasks 4.10 的單邊注入未演練 Example 表所主張的獨立性，應改為雙變體同時注入。
- **F26**（原 Suggestion，`confidence: 50`，B）：`skill-checks.fish:267` 對 CLAUDE.md／AGENTS.md 區塊釘死 baseline 雜湊，C1 的正當性依據路徑可能觸發該斷言。

## Rating

- 過濾後累積 blocking 集合 Critical 數：**8**（F1–F8）
- 過濾後累積 blocking 集合 Warning 數：**10**（F9–F18）
- 非 blocking 已 triage 的 finding 數：**8**（F19–F26）
- `critical_gap`: `true`
- `round_type`: `full`

理由：本輪為未 seed 執行的第一輪，兩個 reviewer 獨立回傳共 30 條 findings，彙總後 26 條，經信心過濾器後 18 條維持 `Critical` 或 `Warning`，全部為 blocking。其中 F1–F5 揭露一個結構性事實：Cash 的完整性架構在信任根（`.cash-skills/bin/cash`）硬編碼了 24 條單一 `SKILL.md` 路徑並對 receipt 做完全相等比對，而該 launcher 又被 `test_bundle_version_history.py` 無條件凍結在其引入 commit。這使得層次二（skill 目錄多檔）的前提不是「安裝器擴充」而是「修改信任根並為既有已安裝 target 設計升級路徑」，其範圍與風險遠超 design `### D4` 所描述。`critical_gap` 為 `true`，本輪 MUST NOT 通過。

## Fix Actions

### 已完成（每輪前機械自我檢查，非 reviewer finding）

- 註記／annotation lint：delta spec 的 `<!--` 與 `-->` 各 8 次，平衡；無未閉合區塊。
- Spec delta 標題身分檢查：兩條 MODIFIED requirement 標題與 master spec 逐位元組相符，PASS。
- Identifier cross-grep：`source_inventory`、`install_target`、`grader_hash`、`assert_inventory`、`assert_command_matrix`、`assert_variant_parity`、`assert_well_formedness`、`divergent_skills` 在程式碼中各定義一次，且四個 artifact 的引用拼寫一致；四個 sentinel 與 `references/review-loop.md` 路徑一致。
- Signal-derived checks：`openspec/signals/` 之下沒有任何 `status: open` 且含 `check` frontmatter 欄位的 signal，本項無指令可執行，退回 best-effort 判斷。
- 數量一致性掃描 — **已修正**：review loop 區段實測為 225 行（`.claude/skills/cash-apply/SKILL.md:422-646`），非原先宣稱的約 250 行，且「移出約 180 行／保留約 70 行」的分解不成立。修改檔案：`openspec/changes/rightsize-cash-skills/proposal.md`（`## Motivation`）、`openspec/changes/rightsize-cash-skills/design.md`（`### D2`），更正為「總計 225 行、移出 156 行（69%）、保留 69 行」。
- 數量一致性掃描 — 已驗證無誤：`## Impact` affected-code 路徑 30 條；cash-apply／commit／ingest／drift 的 AskUserQuestion fallback 出現次數為 5／4／3／2；`skill-checks.fish` 的 post-archive 11 條與 review-loop-output 3 條字面值；review-loop 6 條字面值。

### 結構性裁決

F1–F5 揭露的信任根凍結是層次二（skill 目錄多檔）的前提問題，其解法會改變本 change 的性質與風險輪廓，因此提交使用者裁決。使用者選擇：**把層次二拆成獨立 change，本 change 只交付原層次一與原層次三。** 以下修正動作依此裁決執行。

### 因範圍撤回而解決的 blocking findings

修改檔案：`openspec/changes/rightsize-cash-skills/proposal.md`、`design.md`、`specs/cash-skill-workflows/spec.md`、`tasks.md`（四份全部重寫）。

撤回內容：所有 reference 檔與 progressive disclosure 相關的設計、安裝器與 receipt 擴充、多檔對等比較與良構檢查擴充、以及據此撰寫的 delta spec ADDED requirement 與兩條 MODIFIED requirement。原「層次三」重新編號為「層次二」。proposal `## Non-Goals` 新增「不改變 skill 的檔案結構」，`## Alternatives Considered` 完整記錄此方案被放棄的技術理由（信任根硬編碼、無條件凍結、既有 target 無升級路徑），使該決策可稽核而非默默消失。

據此解決：**F1**（launcher `SKILL_PATHS`）、**F2**（`STABLE_PATHS` 凍結）、**F3**（`parse_receipt` 升級路徑）、**F4**（`parse_legacy_receipt` strict zip）、**F5**（`test_installer_runtime.py`）、**F6**（grader 受保護集合未涵蓋 reference 檔）、**F7**（四份 reference 檔非僅差呼叫前綴）、**F9**（版本關卡未涵蓋 reference 檔）、**F10**（`CASH-SKILLS.md` 的 24 語意）、**F11**（ADDED requirement 無機械斷言）、**F12**（`assert_absent` 未擴張至 reference 檔）、**F13**（D1 層次歸屬衝突）、**F17**（C4 計數）、**F18**（D2 判準分岔）。

同時據此解決的非 blocking triage 項：F19（第五個 sentinel）、F20（多檔 manifest 慣例）、F21（撤回路徑未受治理）、F23（列舉順序與 idempotence 斷言）、F25（雙變體注入）。

### 逐條修正的 blocking findings

- **F8**（Critical）：`tasks.md` 2.2 的範圍由兩個檔案改為**四個**檔案，逐一列出 `.claude`／`.agents` 的 `cash-apply`（`:531`、`:532`）與 `cash-propose`（`:348`、`:349`）；`design.md` D2 與 C2 同步更正該區塊為 propose 與 apply 共用。修改檔案：`tasks.md`、`design.md`。
- **F14**（Warning）：`tasks.md` 1.10 逐行列出要收斂的位置（`:300` 與 `:380`–`:404`），並以粗體 MUST NOT 明列三處主詞不同、不得併入或刪除的規則（`:332`、`:406`–`:413` 含 `:411` 的逐位元組標題契約、`:625`–`:633`），並說明遺失 `:411` 會使 `cash archive` 以 `requirement_identity_mismatch` fail closed；`design.md` C1 新增「範圍邊界」項與 R1 對應說明。修改檔案：`tasks.md`、`design.md`。
- **F15**（Warning）：計數更正為五處並逐一列出行號（`:72`、`:102`、`:186`、`:198`、`:335`），且明確標註 `:72` 的泛稱措辭。同時把此形狀提升為 spec 層級要求——新 requirement 明訂斷言 MUST 同時涵蓋逐字提及工具名與泛稱兩種措辭。修改檔案：`proposal.md`（`## Motivation`）、`design.md`（`## Context`、D3、D4）、`tasks.md`（1.5、3.2）、`specs/cash-skill-workflows/spec.md`。
- **F16**（Warning）：更正 `cash-verify` 的事實敘述——該 skill 有一處行內 fallback 但無重複，故不在層次一範圍內；`cash-discuss` 為零處。範圍判準明確化為「有重複者才納入」。修改檔案：`proposal.md`（`## Proposed Solution`）、`design.md`（`## Context`、D3、C1）。

### 逐條修正的非 blocking triage 項

- **F22**：`tasks.md` 第 1 節新增前言，明訂 `[P]` 任務只做該 skill 範圍內的自我檢查，套件層級驗證群組統一在新增的 1.11 執行一次。每個 `[P]` 任務的驗證目標改寫為 skill-scoped 自我檢查。修改檔案：`tasks.md`。
- **F24**：`cash-ingest` 任務（1.8）補上 `.agents` 變體的 directory-free Codex plan references 約束與對應自我檢查。修改檔案：`tasks.md`。
- **F26**：`design.md` D1 新增明文——層次一的正當性依據 MUST 僅引用 `CLAUDE.md` Cash 區塊的**既有**表述，本 change MUST NOT 新增或修改該區塊，並說明 `skill-checks.fish:267` 的 baseline 雜湊會使該修改失敗；`proposal.md` `## Non-Goals` 新增對應條目；`tasks.md` 第 1 節前言重申。修改檔案：`design.md`、`proposal.md`、`tasks.md`。

### 修正後的每輪前機械自我檢查

- 註記／annotation lint：delta spec 的 `<!--` 與 `-->` 各 0 次，平衡。
- Spec delta 標題身分檢查：改寫後的 delta spec 只有 `## ADDED Requirements`，無 MODIFIED／REMOVED／RENAMED 區段，本項無適用對象。
- 數量一致性掃描：`## Impact` affected-code 路徑由 30 條降為 24 條，與撤回後的範圍相符；`cash-commit` 五處、`cash-apply` 五處、`cash-ingest` 三處、`cash-drift` 兩處、`cash-verify` 一處、`cash-discuss` 零處的 fallback 計數已對照實檔驗證；`Common false positives` 四個檔案的位置已對照實檔驗證。
- Identifier cross-grep：撤回後 artifacts 中不再出現 `references/review-loop.md`、`source_inventory`、`install_target` 等已退場識別字；殘留的 `progressive disclosure`／`reference 檔`／`installer.py` 字樣僅出現於 `## Non-Goals` 與 `## Alternatives Considered`（proposal 兩處、design 一處），屬刻意保留的決策紀錄。
- Signal-derived checks：`openspec/signals/` 之下仍無 `status: open` 且含 `check` frontmatter 欄位的 signal，本項無指令可執行。
- 驗證重跑：`"$cash_cli" validate rightsize-cash-skills` 通過。

## Decision

next_round

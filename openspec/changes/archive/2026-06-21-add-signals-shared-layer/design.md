## Context

Spectra Plus 的 `spectra-propose-plus` / `spectra-apply-plus` 共用 `scripts/spectra-plus/template/review-loop-block.md`，在 change 內跑 max 6 rounds 的 sub-agent review/rating/fix loop，每 round 把 post-filter finding 寫進 `openspec/changes/<change>/reviews/<skill>-r<N>.md`。這些 round file 是 per-change 隔離的，跨 change 之間沒有共享記憶。

plus skills 是生成物：由 base skill（`spectra-propose` / `spectra-apply`）、`scripts/spectra-plus/rules.yaml` 的 transformations、與 `scripts/spectra-plus/template/` 下的模板，經 `scripts/spectra-plus/generate.fish` 生成；生成檔頂端帶 `DO NOT EDIT MANUALLY` 標記，不可手改。既有 spec `spectra-plus-skills` 已約束「Plus skills are not hand-edited」與「Rules.yaml controls plus skill divergence」。

本 change 在不破壞上述生成管線與既有 review-loop 機制的前提下，新增一個跨 change 的 `openspec/signals/` 共享層。

## Goals / Non-Goals

**Goals:**

- 定義 `openspec/signals/` 共享層的目錄、signal 檔案 schema 與 README contract。
- 讓共用 review loop 在迴圈結束後，對任一 round 出現過的 post-filter Critical/Warning finding 依 class 去重後建立或更新 signal，形成跨 change 的共享記憶層。自動跨 change occurrence 累積為 best-effort（比對為偏保守的 agent judgment，傾向建新而非誤併），複利的充分實現仰賴週期性人工合併重複 signal（README 提供 split/merge 指引）。
- 讓 `spectra-propose-plus` 在 change 早期讀取 open signals 作為排優先序的資訊性輸入。
- 全部改動落在模板、`rules.yaml`、README、測試與文件；生成檔僅透過重新生成更新，維持不可手改約束。

**Non-Goals:**

- 不自動轉換 signal status；`open` → `addressed` / `dismissed` 由人手動維護。
- 不引入任何自動觸發機制（cron / LaunchAgent / webhook / PR 監看）；trigger-driven 持續迴圈是另一個獨立題目，明確排除。
- 不建任何 signal 檢視用的 mini-app 或 UI。
- 不修改 base（非 plus）的 `spectra-propose` / `spectra-apply` skill。
- 不修改 `spectra-commit` guard 行為；`openspec/signals/` 下的檔案視為一般 artifact。
- signal 寫入不得影響 review loop 的 round 決策；決策仍只依 post-filter findings 機械推導。

## Decisions

### Signal 檔案 schema 與 frontmatter 欄位

每個 signal 是 `openspec/signals/<slug>.md`。`<slug>` 是 main agent 為該 issue-class 指派的簡短、穩定、人可讀的 ASCII kebab-case 識別碼（例如 `spec-requirement-no-backing-task`、`unhandled-empty-input`），作為跨 change 比對的識別鍵。slug 不是 `location + summary` 的機械轉換：機械轉換會把不同 change 的 `location`（不同檔案/行）與獨立 reviewer 寫的自由文字 `summary` 變成不同字串，使跨 change 永不命中、複利失效；且繁體中文 round prose 下 `summary` 可能全為非 ASCII 而正規化成空字串。改由 agent 指派語意 slug，使「同一問題類別 → 同一 slug」成立，並使 slug 必為合法 ASCII 檔名。frontmatter 欄位固定為：`id`（= slug）、`type`（`friction` / `idea` / `gap` / `recurring-finding` 之一；由 review loop 寫入者預設 `recurring-finding`）、`status`（`open` / `addressed` / `dismissed`）、`occurrences`（整數，累積觀察次數）、`first_seen`（`YYYY-MM-DD`）、`last_seen`（`YYYY-MM-DD`）、`links`（來源相對路徑清單，例如某 round file）。主體含一段標題與說明，並以 `## Occurrences` 區段逐筆記錄每次觀察（日期、change 名、來源 skill 與 round、一行 context）。

替代方案：以 `location + summary` 機械轉 kebab-case 作 slug。否決原因如上——跨 change 不可比對、CJK/空字串與檔名長度問題。另一替代：以單一 append-only log 檔取代每 signal 一檔。否決原因為單檔會讓 status 生命週期與去重難以維護，且不利人工檢視。

### Signal 寫入的觸發條件與去重

寫入只發生在 review loop 結束後（`decision` 為 `passed` 或 `aborted`），作為獨立步驟，不參與 round 決策。觸發對象為**本 change loop 中任一 round 出現過**的 post-filter `Critical` / `Warning` finding（先依 issue class 去重，同一 class 在多個 round 出現只算一個對象；此 issue-class 去重獨立於模板既有 per-round 聚合所用的 `location + summary` 去重）。刻意涵蓋「任一 round」而非僅最終 round：健康 loop 通過時最終 round 已無 Critical/Warning，被早期 round 抓到並修好的 finding 也必須留下 signal，否則 condition (b) 跨 change 比對永遠無 signal 可比、複利機制形同失效。`Suggestion` 與 `confidence < 80` 的 finding 一律不寫入，以維持高訊號。

寫入程序：對每個去重後的 finding class，main agent 讀取 `openspec/signals/` 既有 signal 並依下列 rubric 判斷是否同 class——**同 capability/domain 且指向同一 rule 或 anti-pattern** 即視為同 issue-class（例如「某條 SHALL 缺對應 task」「某邊界未處理空輸入」）；僅描述用字不同不構成不同 class，但指向不同檔案的不同根因即為不同 class。判定結果：(b) 命中既有 `open` 同 class signal → 沿用其 slug 就地更新（遞增 `occurrences`、更新 `last_seen`、append 一筆 `## Occurrences`、append 來源 round file 至 `links`、不改 `status`）；(a) 無 open 同 class signal → coin 一個語意明確的新 slug 建立新 signal（`status: open`、`occurrences: 1`）。coin slug 前 main agent MUST 先列舉 `openspec/signals/*.md` 既有檔名，挑一個尚未存在的 slug（若自然 slug 已被佔用則加 disambiguate 後綴如 `-2`）；建檔 MUST NOT 覆寫任何既有 signal 檔，避免毀掉一個被判為不同 class 卻恰好同名的 signal。若同 class 只命中 `addressed` / `dismissed` signal，視為「已處理過、現又復發」，同樣 coin 一個未被佔用的新 slug 建新 open signal（絕不覆寫已解決 signal 的人工 `status`）。此判斷為 main agent judgment，刻意偏保守：不確定是否同 class 時傾向建新 signal（寧可 under-match 產生可由人合併的重複，也不 over-match 把不相關問題塞進同一 signal）。

替代方案一：以 slug 字串相等（機械 slug）作唯一判準。否決原因為機械 slug 跨 change 不相等，比對形同停用、複利失效（見上節）。替代方案二：沿用初版「跨 ≥2 rounds 反覆出現才寫入」。否決原因為健康 loop 幾乎不重複出現同一 finding（修好即消失），signal 僅在 aborted/卡住的 loop 累積。替代方案三：每個 post-filter finding（含 Suggestion）一律寫成 signal。否決原因為稀釋訊號、與去重紀律相違。

### 寫入行為放在共用 review-loop 模板

「寫 signal」步驟加進 `scripts/spectra-plus/template/review-loop-block.md`。該模板同時被 `spectra-propose-plus` 與 `spectra-apply-plus` 透過 `rules.yaml` 引用，故單一模板改動即同時覆蓋兩個 plus skill 的寫入行為，無需各自改動，符合 Surgical Changes。

### 讀取行為為 propose-plus 專屬新模板與 transformation

「讀 signal」只對 `spectra-propose-plus` 有意義（開新 change 時排優先序）。新增模板 `scripts/spectra-plus/template/signals-read-block.md`，並在 `rules.yaml` 的 `spectra-propose-plus` 項下新增一筆 transformation，將其 append 到既有「Scan existing specs for relevance」步驟之後。讀取為 informational：列出相關 open signals 供排序參考，不阻擋流程、不要求使用者確認、不修改 signal。

替代方案：把讀取也放進共用模板讓 apply-plus 也讀。否決原因為 apply-plus 是執行既定 tasks，排優先序輸入無作用，徒增雜訊。

### Signal status 生命週期由人維護

plus 只會新增 signal 或對既有 open signal 累積 occurrence，永不自動把 signal 改成 `addressed` / `dismissed`。狀態轉換由人在處理對應問題後手動標記。確保自動寫入不會誤關尚未真正解決的問題。

## Implementation Contract

- **Behavior — 寫入**：任一 plus review loop（propose-plus 或 apply-plus）結束後，對本 change loop 中任一 round 出現過、去重後的 post-filter `Critical` / `Warning` finding，main agent 讀既有 signals 並依 issue-class rubric 比對：命中既有 `open` 同 class signal 則沿用其 slug 就地更新（遞增 `occurrences`、更新 `last_seen`、於 `## Occurrences` append 一筆、append 來源 round file 至 `links`、不改 `status`）；無 open 同 class（含僅命中 addressed/dismissed）則先列舉 `openspec/signals/*.md`、coin 一個尚未存在的語意 slug 建立新 signal（`status: open`、`occurrences: 1`），建檔不覆寫任何既有 signal 檔，亦不改任何既有 signal 的人工 `status`。`Suggestion` 與 `confidence < 80` 的 finding 不寫入。signal 寫入不改變該 loop 已寫入 round file 的 `decision`。
- **Behavior — 讀取**：`spectra-propose-plus` 在既有「Scan existing specs for relevance」步驟之後，讀取 `openspec/signals/` 中 `status: open` 的 signal，列出與本次需求相關者作為資訊性排序輸入；無相關 open signal 時靜默略過。讀取不修改任何 signal。
- **Data shape**：signal frontmatter 欄位為 `id`、`type`（`friction` / `idea` / `gap` / `recurring-finding`）、`status`（`open` / `addressed` / `dismissed`）、`occurrences`（整數）、`first_seen`、`last_seen`（`YYYY-MM-DD`）、`links`（相對路徑陣列）；主體含標題、說明與 `## Occurrences` 區段。
- **Interface**：寫入步驟模板含唯一 sentinel 標記 `<!-- SIGNALS-WRITE-STEP -->`，讀取步驟模板含唯一 sentinel 標記 `<!-- SIGNALS-READ-STEP -->`。透過 `scripts/spectra-plus/generate.fish` 重新生成後，`.claude/skills/spectra-propose-plus/SKILL.md`、`.agents/skills/spectra-propose-plus/SKILL.md` 同時含 `SIGNALS-READ-STEP` 與 `SIGNALS-WRITE-STEP` 標記；`.claude/skills/spectra-apply-plus/SKILL.md`、`.agents/skills/spectra-apply-plus/SKILL.md` 含 `SIGNALS-WRITE-STEP` 但不含 `SIGNALS-READ-STEP`。生成檔頂端的 `DO NOT EDIT MANUALLY` 標記不變。
- **Failure modes**：`openspec/signals/` 寫入失敗時印出警告但不使 plus workflow 失敗（signal 為輔助層）；無符合條件的 finding 時不建立任何檔案；讀取階段資料夾不存在時視為無 open signal 並靜默繼續。
- **Acceptance criteria**：`scripts/spectra-plus/tests/generator-checks.fish` 以 sentinel 標記斷言生成後兩個 plus skill 含 `SIGNALS-WRITE-STEP`、propose-plus 含 `SIGNALS-READ-STEP`、apply-plus 不含 `SIGNALS-READ-STEP`，並斷言四檔頂端 `DO NOT EDIT MANUALLY` 標記仍在；`openspec/signals/README.md` 存在且描述 schema 與收錄/不收錄規則；`spectra validate add-signals-shared-layer` 通過。手動驗收（advisory，非 gating task）：跑一次含早期 round 即被修好之 finding 的 loop 會產生 signal 檔；之後另一 change 出現同 class finding 時，同 slug signal 的 `occurrences` 遞增。
- **Scope boundaries**：In scope — `openspec/signals/README.md`、`scripts/spectra-plus/template/review-loop-block.md`、`scripts/spectra-plus/template/signals-read-block.md`、`scripts/spectra-plus/rules.yaml`、四個生成 plus `SKILL.md`、`scripts/spectra-plus/tests/generator-checks.fish`、`SPECTRA-PLUS.md`、`openspec/specs/spectra-plus-skills/spec.md` delta。Out of scope — 自動 status 轉換、自動觸發、UI、base skills、`spectra-commit` guard。

## Risks / Trade-offs

- [Signal 爆量稀釋訊號] → 僅 `confidence >= 80` 的 `Critical` / `Warning` finding 寫入，且先依 issue class 去重；`Suggestion` 與一次性低信心 finding 不建檔。新 class 建新 signal 屬預期行為，人可手動 `dismissed` 不值得追蹤者。
- [跨 change 並發寫同一 signal 的全檔覆寫競態] → 並發寫同一 `<slug>.md` 時，落敗的寫入者其整筆 `## Occurrences` 與 `links` append 會遺失（非僅 `occurrences` 計數誤差），create-create race 甚至可能丟掉一個新建檔。權衡：碰撞需「兩個並發 loop 同時對同一 slug 寫入」，在 plus loop 低寫入頻率下罕見；signal 為人可檢視校正的輔助層，不值得為此引入鎖（Simplicity First）；接受此 lost-entry 風險並於 README 標明。
- [「比對既有 signal」為 main agent judgment，可能 over-match 或 under-match] → 比對 rubric 明定「同 capability/domain + 同 rule/anti-pattern」且偏保守（不確定即建新），over-match（把不相關問題塞進同一 signal）優先避免；under-match 只產生可由人合併的重複 signal。此判斷僅作 informational 用、人可檢視校正，且不影響 round 決策。
- [語意 slug 仍可能讓兩個不相關 finding 被誤判同 class 而就地併入同一 signal] → rubric 要求「不同根因即不同 class」並偏保守；README 提示分析者：若某 signal 的 `## Occurrences` 描述明顯為不相關問題，應手動拆分。
- [生成檔被手改而漂移] → 沿用既有 `DO NOT EDIT MANUALLY` 與 generator overwrite 約束；改動只進模板與 `rules.yaml`。

## Migration Plan

1. 新增 README、模板與 `rules.yaml` transformation、測試斷言與文件。
2. 執行 `scripts/spectra-plus/generate.fish` 重新生成四個 plus `SKILL.md`。
3. 跑 `scripts/spectra-plus/tests/generator-checks.fish` 與 `spectra validate add-signals-shared-layer`。
4. Rollback：還原模板與 `rules.yaml` 後重新生成即可移除 signal 行為；`openspec/signals/` 目錄可保留為純資料，不影響既有流程。

## Open Questions

- `links` 是否需要同時記錄產生此 signal 的 finding 原始 `confidence` 與 `severity`？初版僅記來源路徑與 occurrence context，待實際使用後再評估。

## Context

`cash-apply` 的「Archive guidance timing」段落（`.claude/skills/cash-apply/SKILL.md` 與 `.agents` 變體）已規定：收尾回覆建議封存時 MUST 同時給出「先 `/cash-commit`」與「`/cash-commit` 的 `Archive first, then commit together` 子流程」兩條路徑，並說明單獨封存會刪除 touched state。但該規定只約束「內容要涵蓋什麼」，沒有固定輸出文案，實務上常被壓縮成單一句「請先 commit，再 archive」，遺漏了與使用者習慣相符的子流程路徑。

`cash-archive` 的 workflow（兩個變體）在步驟 1–4 檢查 change 選擇、artifact 與 task 完成度、delta spec 同步，步驟 5 直接執行 `"$cash_cli" archive`；全程沒有任何關於「touched state 即將被刪、未提交的 source 變更會失去允許清單」的守門。CLI 端 `.cash-skills/lib/cash_cli/commands/archive.py` 刪除 touched state 是既定行為，`cash-commit` 的 step 2a 也已提供封存後以 archive manifest 快照復原的機制；缺的只是封存入口的事前提醒。

治理面約束：四個 SKILL.md 都是 `.cash-skills/manifest.tsv` 的 `skill` record，受 bundle-version history gate（`scripts/cash-skills/tests/test_bundle_version_history.py` 的 `check_history`）守衛——任何受守衛檔案修改都要求 `cash-skills.version` 嚴格領先 HEAD；`.agents` 變體由 `scripts/cash-skills/generate.fish` 自 `.claude` 來源再生；`scripts/cash-skills/tests/skill-checks.fish` 以 literal assertion 與正規化對等比較守護內容與變體對等。

## Goals / Non-Goals

**Goals**

- 收尾封存指引每次都以固定、完整的文案呈現兩條安全路徑與後果說明。
- 使用者單獨執行 `/cash-archive` 時，在 touched 允許清單仍有未提交 source 檔案的情況下獲得警告與改道建議，且保留知情後繼續的選擇權。
- 治理面（master spec、skill-checks assertion、bundle version、portable manifest）與內容變更同步落地。

**Non-Goals**

- 不修改任何 `.cash-skills/lib/cash_cli/` runtime 程式；CLI `archive` 刪 touched state 與 `cash-commit` step 2a 快照復原行為不變。
- 不修改 `cash-commit` SKILL.md。
- 不修改 `scripts/cash-skills/blocks/review-gate.md`、`scripts/cash-skills/generate.fish`、`scripts/cash-skills/variant-rules.yaml`。
- 不新增 CLI 旗標、錯誤碼或 state 檔案格式。

## Decisions

**D1 — 固定文案模板內嵌於「Archive guidance timing」段落**：在 `.claude/skills/cash-apply/SKILL.md` 該段落保留既有規範句（含「deletes the touched state that」的因果說明），並新增一個 fenced 模板區塊與一條規範：當最終回覆建議封存時，MUST 逐字輸出該模板，唯二允許的代換是把 `<change>` 代入實際 change 名稱、以及變體 invocation 前綴（`/cash-` 與 `$cash-`）。模板為繁體中文，內容依序為：(1) 先執行 commit 指令再執行 archive 指令；(2) 或執行 commit 指令並在確認選項選 `Archive first, then commit together`，由 commit 流程代跑封存併入同一 commit；(3) 警告——請勿先單獨執行 archive，因為封存會刪除 `.cash-skills/state/touched/<change>.json`（commit 的來源允許清單），使 commit 退回封存 manifest 的時間點快照，封存後的變更不會入列。「較舊的封存甚至沒有該欄位」屬歷史註腳，對當下要封存的 change 永不適用（新產生的 archive manifest 必有 `touched_files`），保留在段落既有規範句中即可，不進逐字模板。選 fenced 模板而非散文規範，因為逐字模板是可被 literal assertion 守護的最小機制，消除「模板段落缺失」類的壓縮失效模式；「模板存在但收尾回覆未逐字輸出」的殘餘行為風險由規範句約束，記於 Risks。語言 precedence：模板本體屬逐字保留內容，比照 CLI 指令與引用原文——cash-apply 既有的「使用者明確要求其他語言時遵從最新指示」規則適用於回覆其他部分，MUST NOT 用於改寫或翻譯模板本體，消除兩條規則的優先序模糊。

**D2 — cash-archive 守門作為步驟 4b，置於 spec 同步判定（步驟 4）與封存執行（步驟 5）之間**：新增「4b. **Uncommitted source guard**」步驟，不重編既有步驟編號（避免破壞「step 6 reports it」等既有交叉引用）。守門邏輯：

- 若 `.cash-skills/state/touched/<name>.json` 與 legacy 路徑 `.spectra/touched/<name>.json` 都不存在，SILENTLY 通過，不發問、不顯示訊息。只有 legacy 檔存在時改讀 legacy 檔——步驟 5 的 CLI archive 會 import legacy 後照樣刪除它，守門必須涵蓋同一個 hazard。
- 檔案集合的取得依來源分兩式：current 檔讀 top-level `files` 欄位（CLI 驗證過的 canonical union，等於各條目 `files` 的聯集；路徑 project-root-relative，且已排除 `openspec/changes/` 下路徑）；legacy 檔讀 `touched` 陣列各條目 `files` 的聯集——legacy schema 的 top-level keys 恰為 `change` 與 `touched`（`_import_legacy` 於 `.cash-skills/lib/cash_cli/commands/tasks.py` 強制此 shape），沒有 top-level `files` 可讀，直接套 current 讀法會把每個合法 legacy 檔誤判為 malformed。
- 取得的集合與 `git status --porcelain=v1 -z --untracked-files=all` 在 project root 的輸出取交集。skill 步驟 4b MUST 逐字寫出這條完整 git 指令並依 NUL-delimited 格式解析：`--untracked-files=all` 防止新目錄被折疊成單一 `?? dir/` 條目造成漏判；`-z` 使路徑完全不做 C-quoting（porcelain v1 非 `-z` 模式下 tab、newline、雙引號、反斜線與非 ASCII 都會被轉義，任何字面比對都可能漏判），每筆條目以兩字元狀態欄加一個空白開頭，比對前先剝除該前綴取出路徑，rename／copy 條目帶兩個 NUL 結尾路徑（先新後舊），僅第一段帶狀態欄前綴，第二個 NUL field 是裸 old path，MUST NOT 對其剝除前綴——逐 field 套剝除規則會把舊路徑截掉前三個字元，使「touched 檔被 rename 走、只剩舊路徑可相交」的情境靜默漏判——兩者皆計入 dirty 集合；這也與 CLI 自身讀 porcelain 的 `-z` 作法同源。
- touched 檔存在但守門無法依 current／legacy schema 安全取得合法的 path set 時——例如無法解析為 JSON、current 檔缺 top-level `files` 或其值不是 string array、legacy 檔缺合法 `touched` 陣列——守門 MUST NOT 在 skill 層重製完整 CLI validator（`_validate_touched` 的完整規則屬 CLI 所有），不猜測、不修改任何檔案，直接放行進入步驟 5，由 CLI fail closed 並保留其實際 diagnostic：可能為 `state_invalid`、`touched_invalid` 或 `legacy_touched_invalid`，逐來源一對一映射不成立——例如 legacy 條目內的 unsafe path 經 `_safe_source_path` 產生的是 `touched_invalid` 而非 `legacy_touched_invalid`；守門文字 MUST NOT 預判或宣稱單一錯誤碼。
- git 偵測失敗與 touched malformed 是性質不同的兩類失敗，處置相反：git 指令以 non-zero 結束、或輸出無法依 NUL-delimited 格式完整解析時，守門 MUST NOT 視同交集為空，MUST 停止 workflow、報告原始錯誤且 MUST NOT 呼叫 `"$cash_cli" archive`——touched malformed 放行是安全的（CLI archive 會對 touched fail closed），偵測失敗放行不安全（CLI archive 不檢查 dirty state，一放行 hazard 就直接發生）。
- 交集為空 → SILENTLY 通過。
- 交集非空 → 列出這些未提交的 source 檔案，用 AskUserQuestion 提供恰好兩個互斥選項：(a) **停止本次封存**（建議）——改執行 `/cash-commit` 並在確認選項選 `Archive first, then commit together`，讓封存與提交進同一個 commit；(b) **仍要單獨封存**——知悉封存會刪除 touched state、後續 `/cash-commit` 退回 manifest 快照後，繼續步驟 5。
- 守門對 touched state 只讀不寫：MUST NOT 修改或刪除 `.cash-skills/state/touched/<name>.json` 或 `.spectra/touched/<name>.json`（與既有 Guardrail「Never delete touched or sync state directly」一致；`touched_invalid` 修復所允許的 `task_desc` 編輯屬步驟 5 失敗處置，與本步驟無關）。
- 選擇守門放在 skill 層而非 CLI 層：`cash-commit` 的 archive 子流程直接呼叫 `"$cash_cli" archive`，CLI 層守門會誤擋這條已受保護的路徑；skill 層守門恰好只覆蓋單獨封存入口。
- live-namespace 掃描配套：`scripts/cash-skills/tests/test_live_namespace.py` 禁止 `.spectra/touched` literal 出現在 `touched_allow` allowlist 之外，而本守門步驟依上述規則必須逐字寫出 legacy 路徑；因此兩個 cash-archive SKILL.md（`.claude` 與 `.agents`）MUST 加入該測試既有的 `touched_allow` 集合——守門對 legacy touched state 的引用是受管理的唯讀引用，與該掃描要防的 unmanaged 遺留引用不同類。
- 序位取捨：4b 緊鄰不可逆的 CLI archive 呼叫，使守門回報的 dirty 集合反映封存前的最終狀態，守門與危險動作之間沒有其他步驟插入。使用者選「停止」時，步驟 2／3 已回答的問題作廢，但 `cash-commit` 6a-i 會重問同一個未完成 task 問題並得到相同答案，作廢成本是一次重答，接受此代價換取較簡單的心智模型。

**D3 — master spec 增修**：`openspec/specs/cash-skill-workflows/spec.md` 兩處：(1) MODIFIED 既有 requirement「cash-apply 封存指引須指引提交優先」（標題自 master spec 逐字複製），把「同時指引兩條路徑」強化為「逐字輸出固定文案模板，唯二代換為 change 名稱與 invocation 前綴」，新增「語言切換不改寫模板本體」scenario，既有 `decision: aborted` 不建議封存與變體對等 scenario 保留；(2) ADDED 新 requirement「cash-archive 單獨封存前的未提交來源守門」，scenario 覆蓋：touched state 缺失（兩路徑皆缺）靜默通過、僅 legacy touched state 存在仍受守門、交集為空靜默通過、touched state malformed 時放行由 CLI 守門、git 偵測失敗則停止且不封存、交集非空發問且兩選項互斥、選停止則 MUST NOT 呼叫 `"$cash_cli" archive`、選繼續則走既有步驟 5、守門唯讀、兩變體對等。

**D4 — skill-checks literal assertion**：在 `scripts/cash-skills/tests/skill-checks.fish` 既有「commit-before-archive guidance」assertion 區塊（目前對兩個 cash-apply 變體檢查 `Archive first, then commit together` 與 `deletes the touched state that`）擴充 cash-apply 模板 literal：模板三段各取一個不含 invocation 前綴的中文固定片段（路徑 (1) 一句、路徑 (2) 一句、警告段一句），使任一段被省略都會被 assertion 抓到；另加語言 precedence 句的 literal（pin 住「語言切換規則不適用於模板本體」，使該規則不再只有 task 2.1 的一次性 manual assertion）。另新增一個對兩個 cash-archive 變體的區塊，literal 覆蓋守門的關鍵規範元素且 MUST 全部取新內容獨有的字串：步驟名 `Uncommitted source guard`、完整 git 指令 `git status --porcelain=v1 -z --untracked-files=all`、兩個 AskUserQuestion 選項的固定標籤文句、靜默通過句、touched state 唯讀約束句、legacy 聯集讀法句（pin 住「legacy 讀 `touched` 條目 `files` 聯集而非 top-level `files`」）、malformed 放行句（含 `state_invalid`、`touched_invalid`、`legacy_touched_invalid` 三個 diagnostic 名）、偵測失敗停止句（pin 住「MUST NOT 視同交集為空」）、NUL 解析語意句（pin 住「依 NUL-delimited 格式解析」、「rename／copy 條目新舊兩路徑皆計入」、剝除前綴句與「第二個 NUL field 是裸 old path、MUST NOT 對其剝除前綴」——只留指令、刪掉解析規則時 assertion 必須失敗）——本輪最重要的三個修正都要有持久 assertion，不能只靠 task 2.2 的一次性 manual assertion。既有 SKILL.md 內容已出現過的字串（如 `.cash-skills/state/touched/`，已存在於步驟 5 的 `touched_invalid` 處置）對新內容零鑑別力，MUST NOT 作為守門 assertion 的 literal。所有 literal MUST 選不含 `/cash-`／`$cash-` 前綴的字串，使同一組 assertion 對兩個變體成立。

**D5 — 版本與 manifest 序位**：`cash-skills.version` 的 bump MUST 是第一個實作 task，先於任何受守衛 SKILL.md 的修改；新值以 `git show HEAD:cash-skills.version` 推導（patch 位 +1），不得寫死常數。`.cash-skills/lib/cash_cli/installer.py` 的版本常數 `BUNDLE_VERSION` MUST 同步為相同新值——installer runtime contract 測試（`scripts/cash-skills/tests/test_installer_runtime.py`）斷言兩者相等，且此同步是歷次版本 bump 的既有 codebase 慣例；同步後 `installer.py` 屬 manifest runtime record，MUST 在下一次 Cash CLI 呼叫之前執行 `./install-cash-skills.fish --self` 重建 manifest。launcher 每次啟動都驗證全部 manifest records：SKILL.md 一經修改、manifest 尚未重建前，任何 Cash CLI 呼叫（含 task loop 每個 task 結尾的 `"$cash_cli" task done`）都會以 `manifest_invalid`（`portable manifest digest drift`）fail closed。因此每個修改 manifest `skill` record 的 task（2.1、2.2，以及 3.1 的 `.agents` 再生）MUST 在自身結尾、任何下一次 Cash CLI 呼叫之前，於 project root 執行 `./install-cash-skills.fish --self` 重建 `.cash-skills/manifest.tsv` 關閉窗口；這些 task MUST 循序執行、不得標記 `[P]` 平行（平行會讓一個 task 的 `task done` 落在另一個 task 的未重建窗口內）。最後一個 task 以 `--self` 冪等確認（回報 `Result: current`）加全套測試收斂。

**D6 — 變體再生而非手改**：`.agents/skills/cash-apply/SKILL.md` 與 `.agents/skills/cash-archive/SKILL.md` 一律由 `scripts/cash-skills/generate.fish` 自 `.claude` 來源再生，不手動編輯，維持單一來源。

## Implementation Contract

1. `.claude/skills/cash-apply/SKILL.md`「Archive guidance timing」段落含一個 fenced 固定文案模板與「MUST 逐字輸出、唯二代換（change 名稱、invocation 前綴）」的規範句，並明訂模板本體屬逐字保留內容、語言切換規則不適用於模板本體；既有 `passed`／`aborted` 分支行為與「deletes the touched state that」因果說明保留。
2. `.claude/skills/cash-archive/SKILL.md` 含步驟「4b. **Uncommitted source guard**」，實作 D2 的觸發條件（current 檔 top-level `files`／legacy 檔 `touched` 條目 `files` 聯集，與逐字完整 git 指令 NUL-delimited 輸出的交集）、legacy 路徑涵蓋、以「無法安全取得合法 path set」為判準且保留 CLI 實際 diagnostic 的 malformed fallback、git 偵測失敗的停止分支（MUST NOT 視同交集為空、MUST NOT 呼叫 archive）、兩個互斥出口、靜默通過條件與唯讀約束；既有步驟編號與交叉引用不變。
3. `.agents` 兩個對應 SKILL.md 由 `scripts/cash-skills/generate.fish` 再生，與 `.claude` 來源在 invocation 前綴正規化後逐字對等。
4. `openspec/specs/cash-skill-workflows/spec.md` 完成 D3 的一個 MODIFIED 與一個 ADDED requirement（經由本 change 的 delta spec 於封存時同步；本 change 期間先落在 delta spec）。
5. `scripts/cash-skills/tests/skill-checks.fish` 含 D4 的兩組 assertion，且 `./scripts/cash-skills/tests/skill-checks.fish` 全綠。
6. `cash-skills.version` 嚴格領先 HEAD 值；`.cash-skills/manifest.tsv` 於每個修改 skill record 的 task 結尾由 `./install-cash-skills.fish --self` 重建，最終 `--self` 冪等確認回報 `Result: current` 且 `bundle_version` 與 skill digest 一致。

## Risks / Trade-offs

- **模板僵化**：逐字模板讓未來調整文案必須改 SKILL.md 與 assertion。接受：這正是防止壓縮的代價，且改動走同一治理流程。
- **守門誤報**：touched files 交集以守門那條完整 git 指令（`git status --porcelain=v1 -z --untracked-files=all`）的輸出為準，使用者若刻意保留無關的 dirty 修改在 touched 檔案上會被問一次；copy 條目的來源檔通常未變更、新舊路徑仍皆計入，是同一類刻意保守的誤報來源——區分 rename 與 copy 會複雜化解析規則，而 copy 條目在 status 輸出中極罕見。接受：AskUserQuestion 的「仍要單獨封存」出口保留一鍵通過，成本是一次確認。
- **守門漏報**：touched state 只涵蓋 task loop 與 review loop 記錄過的檔案；未被記錄的 dirty 檔案不觸發守門。接受：allowlist 之外的檔案本來就不受 touched 機制保護，`cash-commit` 對其分類為 Unrelated Changes 的行為不變，守門不試圖超出 allowlist 的知識範圍。
- **manifest 再簽風險**：`--self` 只能在 canonical source repository 執行且以 exclusive lock transaction 進行；SKILL.md 修改後、manifest 重建前的窗口內，任何 Cash CLI 呼叫會以 `manifest_invalid`（`portable manifest digest drift: <path>`）fail closed。緩解：D5 要求每個修改 skill record 的 task 在自身結尾、下一次 Cash CLI 呼叫之前執行 `--self`，並禁止這些 task 平行執行。
- **解析規則的兩個 fail-safe 殘餘**：4b 未明寫「狀態欄 X 或 Y 為 `R`／`C` 的條目才帶第二個 NUL field」與「`-z` 輸出以 NUL 終結，naive split 的尾端空 field 應忽略」；字面照做的極端情況會誤入偵測失敗停止分支（停止並報錯，可見且安全），不會靜默漏判。接受：兩者失效方向皆為 fail-safe，由停止分支吸收，不再增寫解析細則。
- **assertion 守形不守行為**：literal assertion 只能驗證模板與守門文字存在於 SKILL.md，無法驗證收尾回覆真的逐字輸出模板、或守門步驟真的被執行；該殘餘行為風險由 MUST 級規範句與審查迴圈約束。接受：這是 skill 文字機制的固有限制，沒有更強的機械驗證面可用。

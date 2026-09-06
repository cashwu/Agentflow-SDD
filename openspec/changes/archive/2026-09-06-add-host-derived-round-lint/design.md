## Context

Cash review loop 的判準全部寫在 `scripts/cash-skills/blocks/review-gate.md`，由 main agent 自願執行；round file 由 main agent 撰寫，是否符合 schema 也由同一個 main agent 判斷。本 change 交付一個由 host 自動執行的工作區一致性檢查。

既有程式碼提供的條件：`.cash-skills/lib/cash_cli/main.py` 的 `COMMANDS` dict 是 command dispatch 的單一來源，`emit_help` 由該 dict 導出命令清單；`.cash-skills/lib/cash_cli/commands/__init__.py` 的 `execute` 依 command 名稱路由到各 module；`.cash-skills/bin/cash` 以 `lock_mode = fcntl.LOCK_EX if command in MUTATING_FAMILIES else fcntl.LOCK_SH` 決定 lock 模式，`MUTATING_FAMILIES` 為 `new`、`task`、`in-progress`、`touched`、`park`、`unpark`、`sync`、`archive` 八項。

## Goals / Non-Goals

**Goals**

- `cash lint-round` 只採納能由磁碟與 Git 自行推導的事實，不接受 main agent 對待驗命題的任何自我申報。
- Stop hook 自行從磁碟判定有無進行中的 review loop 及其對應 change，不從 main agent 取得 change 名稱。
- 新增 command 不修改 `.cash-skills/bin/cash`。

**Non-Goals**

- **不驗證已完成 round file 的不可變性。** round files 位於 `openspec/changes/` 底下，在 change 進行中通常未 commit，因此沒有可比對的 Git baseline；`.cash-skills/lib/cash_cli/commands/tasks.py` 的 `_IGNORED_PREFIXES` 也把 `openspec/changes/` 排除於 touched 快照之外。可行的替代是引入一份 host 寫入的 digest 帳，但寫入會使 `lint-round` 成為 mutating family，須將它加入 `.cash-skills/bin/cash` 的 `MUTATING_FAMILIES` 而觸發受控 launcher bootstrap migration，代價不成比例。
- 不涵蓋 signal `check` 欄位保護。既有 requirement 的該條保護判定粒度是欄位、且明文不接受 declared-scope 例外，與 D4 的路徑集合比對形狀不同，無法以同一機制表達。
- 不保護 gate 自身。`.claude/settings.json` 與 `.cash-skills/lib/cash_cli/commands/lint_round.py` 都不在既有受保護路徑集合內；把它們納入需要 MODIFIED `cash-skill-workflows` 的 `審查迴圈的 grader 不可變性` requirement，超出本 change 範圍。見 R8。
- 不驗證 `## Fix Actions` 宣稱的修改是否落地；不驗證 `loop-ledger.tsv` 列數；不判斷 severity／confidence／disposition 是否正確；不修改任何 canonical skill 或 review-gate block。

## Decisions

**D1：事實來源限制是本 change 的核心約束。** gate 只讀取三類來源：`openspec/changes/<change>/` 下的 artifacts 與 round files、`git` 的 worktree 與 index 狀態、以及 gate 自身內建的常數（受保護裁判面路徑集合）。gate MUST NOT 接受任何以 CLI argument、環境變數、stdin 或 context 檔案形式傳入、且其內容即為待驗命題的輸入。理由是受審者供應的事實不構成獨立驗證，且輸入缺席時 gate 只能跳過，等同讓受審者決定是否受檢。

**D2：round file 的辨識與 run 邊界推導。** round file 是 `openspec/changes/<change>/reviews/` 下檔名符合 `<skill>-r<N>.md` 的檔案，其中 `<skill>` 恰為 `propose` 或 `apply`，`<N>` 為無前導零的十進位正整數。不符該樣式的檔案——包含同目錄下必然存在的 `loop-ledger.tsv` 與可選的 `accepted-risks.md`——MUST NOT 納入任何 gate，否則阻擋型 hook 會因它們缺少四個 section 而在每個 turn 失敗。

`propose` 與 `apply` 是兩個各自從 `r1` 起算的獨立序列，因此全部排序、run 邊界推導與活動判定 MUST 逐 skill 進行，MUST NOT 跨 skill 取最高編號。對某個 skill 的序列依 `<N>` 排序後，第 N 輪開啟一個新 run 當且僅當 N 是該序列最小編號，或第 N-1 輪的 `## Decision` 是 `passed` 或 `aborted`。第 N-1 輪的 `## Decision` 無法解析（不在值域內）時，run 邊界不可導出，該 skill 序列自第 N 輪起每一輪的 `round_type_position` MUST 判 `fail` 並在 `detail` 指向第 N-1 輪；不得把不可解析視同終結值或視同 `next_round`。序列的最小編號 MUST 為 `1`，且 MUST 自該編號起連續；缺少起始編號或出現缺號時位置推導都不可靠——刪去 round file 會使其後各輪重新對齊而通過——因此兩者 MUST 判定為失敗。只錨定「該序列最小編號」而不要求它等於 `1` 攔不住刪除前綴：刪掉 `r1` 至 `r3` 後，`r4` 起的序列仍自其最小編號連續，`r4` 反被判為新 run 的第一輪，正好完成刪檔者要的重新對齊。既有規則保證合法歷史中每個 skill 序列必含 `r1`——round file 不得覆寫、re-run 續號——因此這個錨點是 host-derived 且無額外成本。

round type 判準逐字對齊 master spec `分級收斂與 micro 驗證輪`：run 的第一輪 MUST 是 `full`；第一輪之後的每一輪，當且僅當它是該 run 的第四輪時 MUST 是 `full`，否則 MUST 是 `micro`。把該 iff 寫成無條件形式會與「第一輪 MUST 是 full」直接矛盾。此推導不使用 `loop-ledger.tsv`，因此不受該檔缺少 run 識別欄的限制。

**D3：迴圈活動狀態逐 skill 判定。** 對每個 skill 各自取其最高編號 round file；某個 change 的 review loop 為 active，當且僅當**任一** skill 的最高編號 round file `## Decision` 為 `next_round`。`passed` 與 `aborted` 都是終結值。跨 skill 取單一最高編號是錯的：`propose-r3` 為 `passed` 而 `apply-r1` 為 `next_round` 時，跨 skill 最高編號者是 propose-r3，會使 gate 在整個 cash-apply loop 期間判定非 active——而 apply loop 正是最會動到受保護裁判面的階段。

檢查對象的列舉 MUST 逐字對齊既有 CLI `discovery.py` 的列舉規則：`openspec/changes/` 下排除 `archive` 與 `.parked` 兩個保留目錄名後、**且為目錄型項目、且名稱符合 `[a-z][a-z0-9-]*`** 的 change，加上 `openspec/changes/.parked/` 下同樣條件的 parked change。只搬忽略集合而丟掉「目錄」與名稱樣式兩個限定，會把 `.DS_Store` 這類非目錄項目列舉為 change，對其解析 `reviews/` 路徑時拋出例外而使整批進入 fail-open。只排除 `archive` 會把 `.parked` 本身當成一個 change 列舉，並使 parked change 下的 round files 完全不受檢，`cash park` 即成為逃逸口。

parked change MUST 納入列舉以接受結構類 gate 判定——否則 `cash park` 會使其 round files 完全不受檢——但 MUST NOT 計入 active 判定：parked change 的最高編號 round file 常永久停在 `next_round`，計入會使 repo 長期 active 而讓 grader gate 對無關 session 持續生效（見 R11）。

grader-immutability gate 僅在 active 時適用，對應既有 requirement 的「During an active cash review loop」條件。

**D4：grader-immutability 的判定三方比對。** 受保護路徑集合為 gate 內建常數，逐字對應既有 `審查迴圈的 grader 不可變性` requirement 所列的**路徑**成分；其中 `openspec/specs/` 是目錄型宣告，涵蓋其下全部 master spec 檔案。該 requirement 另有一條無 declared-scope 例外的欄位級保護（禁止改動 `openspec/signals/` 下 signal 的 `check` frontmatter），其判定粒度是欄位而非檔案且不接受宣告例外，無法以路徑集合表達，v1 不涵蓋，見 Non-Goals。變更集合取自 Git，MUST 涵蓋工作區相對 `HEAD` 的改動（含已 `git add` 的 staged 改動）與 untracked 檔案；只取 unstaged 改動會讓 `git add` 成為旁路。structured scope declarations 取自兩處——proposal `## Impact` 的 affected-code 條目，以及 `tasks.md` 中明確標示為 delivery target 的路徑。目錄型宣告涵蓋其下全部檔案，`openspec/specs/` 即依此展開。

變更集合是 repository 全域而宣告是 per-change 的，兩者粒度不同。涵蓋判定在兩種 mode 都 MUST 取聯集：`--hook` mode 對列舉到的每個 change 各自判定且任一 fail 在非重入時即 exit 2（重入依 D6）；single-change mode 的位置參數只決定回報哪個 change 的 round files 與 active 狀態，MUST NOT 把宣告來源縮小為該 change，否則同一狀態會出現 hook 判 pass 而 single-change 判 fail 的分歧，使用者無法用 single-change mode 重現 hook 的判定。聯集的來源 MUST 限於**未封存且未 parked 的被列舉 change**，MUST NOT 因來源 change 依 D3 已判定為非 active 而移除：A 合法修改受保護檔案、A 完成 `passed` 但未提交、B 仍 active 時，A 的宣告仍須涵蓋該改動。已封存或 parked change 的宣告不計入；來源完全不設限時，任何一個無關 change 目錄的 `## Impact` 都能永久解除全部判定，而 `openspec/changes/` 由受審者可寫（見 R10）。受保護路徑只要被任一未封存且未 parked 的被列舉 change 的 structured scope declaration 涵蓋即不判 fail。逐 change 各自比對會使兩個 active change 並存時，A 合法宣告的受保護路徑改動在 B 的比對中判為未宣告，阻擋型 hook 因此對合法工作每個 turn 產生偽陽性。受保護路徑出現在變更集合而未被該聯集涵蓋時，該 gate 判定 fail。

**D5：`lint-round` 是 shared-read command family。** 它不出現在 `MUTATING_FAMILIES` 中，因此 launcher 為它取得 `LOCK_SH` 而無需修改 `.cash-skills/bin/cash`。它不產生任何由 command 自身控制的寫入——不建立目錄、不寫檔案——因此沒有任何可用來保存跨次判定狀態的管道（D6 的重入規則倚賴此點）。receipt-based target 上由 import system 產生的 bytecode cache 不在 command 的控制範圍內，其處置見 `## Implementation Contract` 的驗收標準。

**D6：Stop hook 的失敗語意分兩層，且 fail open MUST 留下診斷。** gate 判定失敗時 hook 以 exit 2 阻擋並將失敗項寫入 stderr（`stop_hook_active` 為真時除外，見下文重入規則）。hook 的 fail-open 語意分成兩段，邊界是 `lint_round.py` 的進入點。進入點之後可攔截的基礎設施錯誤——workspace 解析失敗、輸入 JSON 解析失敗、任何未預期例外——一律 fail open 以 exit 1 結束，不得使 session 卡死。進入點之前的失敗——`.cash-skills/bin/cash` 缺席（shell 以 127 結束）、launcher 信任 gate 失敗（`manifest_invalid`／`receipt_invalid`／`bootstrap_invalid`，launcher 的 `fail()` 一律以 exit 1 並在 stderr 輸出 `error[<code>]`）、Python 版本不足——不在 command 可控範圍內，command 無法對其輸出任何診斷，其結束方式由 host 與 shell 決定，記於 R9。

exit code 的選擇依 host 的實際行為而非慣例：Claude Code 對 hook 的三種 exit 語意是 exit 0 表成功且 stderr 只進 debug log、stdout 僅在 transcript mode 可見；exit 2 表阻擋且 stderr 回饋給 Claude；其他非零 exit 表非阻擋錯誤且 stderr 顯示給使用者。因此以 exit 0 搭配 stderr 輸出的診斷在 host 上實際不可見，形同靜默；fail open 若要留下可見紀錄，MUST 以 exit 1 結束。進入點之前的三類失敗恰好也都是非 2 的非零 exit，與 exit 1 同屬 host 的非阻擋錯誤類，因此整體規則可收斂為一句：**只有 exit 2 阻擋，其餘非零 exit 一律非阻擋且 stderr 可見。**

取鎖阻塞不在 command 可控範圍內，因此 MUST NOT 要求 `--hook` mode 自帶時間上限。launcher 取得 `flock` 的位置早於 manifest 驗證與 `cash_cli` 的 import，而本 change 依 `## Goals` 不修改 launcher，故 `lint_round.py` 內的任何逾時機制都涵蓋不到阻塞在 `flock` 的那段；hook command 又是直接執行 launcher，不存在可插入 wrapper 的位置。時間上限改由 host 承擔：`.claude/settings.json` 的 hook 條目 MUST 宣告 host 層的 `timeout`。該上限觸發時由 host 終止 hook，其結束方式不由本 gate 的 exit code 控制，也不輸出 `gate_unavailable`，代價記於 R9。

fail open MUST NOT 靜默：進入點之後的每個 fail-open 分支 MUST 以 exit 1 結束並向 stderr 輸出可辨識的 `gate_unavailable` 診斷並指出原因；MUST NOT 以 exit 0 結束，因為 host 對 exit 0 的 stderr 不顯示。靜默 fail open 會使「gate 沒跑」與「gate 跑了且通過」在 transcript 中無法區分，而 gate 自身的檔案不在受保護集合內，受審者可藉此無聲關掉整個 gate；診斷使該旁路至少可稽核。

輸入 JSON 的 `stop_hook_active` 為真時，hook MUST 仍執行當次判定。有失敗時以 exit `1` 放行並將當次未解決失敗項寫入 stderr；沒有失敗時以 exit `0` 結束且 stderr 為空。無 `--json` 時 stdout 一律為空，因此通過時（含重入）完全靜默；帶 `--json` 時正常完成判定仍輸出 JSON，`ok` 反映當次結果。此 change 不保存前次判定結果，MUST NOT 要求輸出上次判定；一次性阻擋的取捨見 R7。完整輸出契約見 D8。

**D7：每一次改動 manifest 覆蓋的 runtime bytes 都必須在同一個 transaction 發佈 manifest。** `.cash-skills/lib/cash_cli/installer.py` 內建的 runtime inventory 常數列舉全部 `commands/*.py`，且 launcher 的 portable gate 會列舉現地 `.cash-skills/lib/cash_cli/` 下的 `.py` 並拒絕相對 manifest expected set 的 extra。因此在新增 `lint_round.py` 後、發佈 manifest 前，整支 CLI 會以 `manifest_invalid` 失效。停機窗口有兩個成因而非一個。除了新增 `.py` 使 portable gate 拒絕 extra path 之外，**編輯任何既有 runtime record 的位元組同樣致命且更早觸發**：`installer.py` 是 `.cash-skills/manifest.tsv` 的 runtime record 並綁定 digest，launcher 逐筆比對 sha256 並在不符時以 `portable manifest digest drift` 走 `manifest_invalid`。因此調升 `BUNDLE_VERSION` 這個動作本身就使整支 CLI 立即失效。規則因此是：每一次改動 manifest 覆蓋的 runtime bytes 之後、下一個 Cash command 之前都必須發佈，與既有 Managed bundle publication protocol 一致。

此外，master spec 規定「任何 launcher、runtime、skill、portable manifest schema／record或 Git logical mode改變 MUST在第一個受 guard的 production artifact改動前，將 `cash-skills.version`調升為嚴格較大版本」；觸發條件是 replaceable runtime bytes 而非只有 canonical SKILL.md。`scripts/cash-skills/tests/test_bundle_version_history.py` 的 `replaceable_paths()` 以 `rglob("*.py")` 蒐集 `.cash-skills/lib/cash_cli` 下全部 `.py`，同版本下的 inventory 變動會以 `replaceable inventory changed without a version bump` 失敗。

因此實作順序有**兩個發佈點**而非一個：先把 `cash-skills.version` 與 `installer.py` 的 `BUNDLE_VERSION` 同步調升為嚴格較大版本（現值均為 `2.21.0`）並**當場執行 source-only 發佈**——`installer.py` 本身是 manifest 的 runtime record，只調升不發佈會使 CLI 立即失效而連 `cash task done` 都不能執行；之後才擴充 installer runtime inventory、新增 runtime 檔案，並**再次發佈**。每個發佈點之後才可再呼叫 Cash command，其後每一次改動 manifest 覆蓋的 runtime bytes 都同樣適用此規則。版本調升必須是第一個動作——排在任何受 guard 的 runtime 編輯之後就是 open signal `version-bump-sequenced-after-guarded-edits` 描述的失效順序。

**D8：CLI 輸出與重入契約。** 實作 MUST 遵守 `cash-round-gate` 的 `lint-round 輸出與結束碼` requirement。正常完成判定時，single-change stdout 為人可讀 checks 或 `--json` object，stderr 為空，通過 exit `0`、gate 失敗 exit `2`。hook 的 stdout 在無 `--json` 時一律為空，有 `--json` 時為單一 JSON object；通過（含重入）exit `0` 且 stderr 為空，失敗 stderr 列出當次失敗項並在首次判定 exit `2`、重入 exit `1`。重入放行不改寫 JSON 的 `ok: false`。hook 進入點後的基礎設施錯誤，不論是否帶 `--json`，均 exit `1`、stdout 為空、stderr 含 `gate_unavailable` 與原因；不得輸出虛構 checks。single-change 參數與基礎設施錯誤維持既有統一 JSON error shape 與 exit code，不採用 hook 的 fail-open 規則。

**Review decision history（本次 review）：** 使用者授權依 spec review 修正三項決策，已同步 proposal、design、兩份 delta spec 與未完成 tasks：D4 原先僅 active change 提供宣告，改為未封存且未 parked 的 change，其宣告有效期與 gate active 條件分離；缺一份 artifact 即清空整體宣告，改為 proposal/tasks 逐檔解析；未明確的輸出行為，改為 D8 與 spec 的 stdout／stderr／exit code 矩陣。保留 D6 無 JSON 重入放行、不引入持久化 baseline、不修改 launcher 的既有範圍。已完成來源的宣告可能持續豁免後續改動，是本次取捨的限制，見 R10。

## Implementation Contract

**`cash lint-round <change> [--json]`**

- 觀察行為：讀取指定 change 的 round files 與 Git 狀態，對每個 gate 產生一筆結果，狀態為 `pass`、`fail` 或 `skip`。整體判定為 fail 當且僅當至少一筆結果為 `fail`。
- 介面：兩種 mode。single-change mode 的第一個位置參數為 change 名稱。`--hook` mode 不接受 change 名稱，改為依 D3 的列舉規則自行決定檢查對象——`openspec/changes/` 下排除 `archive` 與 `.parked` 兩個保留目錄名後、為目錄型且名稱符合 `[a-z][a-z0-9-]*` 的 change，加上 `openspec/changes/.parked/` 下同樣條件的 parked change——並逐一判定，並自 standard input 讀取 host 供應的 Stop hook JSON payload；該 payload 由 host 產生而非由 main agent 供應，command 只讀取其中的 `stop_hook_active` 欄位，該欄位不是待驗命題，因此不違反 D1；其餘欄位一律不讀取。兩種 mode 的 `grader_immutability` 宣告來源依 D4 都是全部未封存且未 parked 的被列舉 change 的聯集。`--json` 時輸出單一 JSON object，含 `ok`（boolean）與 `checks` 陣列，每筆含 `id`、`status`、`detail`；single-change mode 另含 `change`，`--hook` mode 的每筆 check 另含其所屬 `change`。stdout、stderr、exit code 與重入行為依 D8；`--json` 只改變輸出表示，不改變 exit code。
- Gate 集合與其 `id`：
  - `round_file_schema`——每個 round file 具備 `## Reviewer Findings`、`## Rating`、`## Fix Actions`、`## Decision` 四個 section。依 D2，只有檔名符合 `<skill>-r<N>.md` 者納入判定。
  - `decision_value`——每個 round file 的 `## Decision` 值恰為 `passed`、`next_round`、`aborted` 之一。擷取規則 MUST 明確：取該 section 內第一個非空行，去除 backtick 與前後空白後與值域比對；其後的 rationale 段落 MUST NOT 使 gate 失敗——既有 `Round 檔案輸出合約` 本就要求記一段 rationale，把整個 section body 當成值會使全部合規的 round file 判 `fail`。
  - `round_type_position`——每個 round file 的 `## Rating` 所記 `round_type` 與 D2 導出的位置推導相符。擷取規則 MUST 明確：取該 section 內去除 bullet 標記、backtick 與前後空白後以 `round_type` 開頭的 bullet，取其冒號（半形 `:` 或全形 `：`）之後、去除 backtick 與空白的 token；符合條件的 bullet 不恰為一筆時 MUST 判 `fail`，rationale 段落中提及 `round_type` 的句子因不以該欄位名開頭而不符合條件；實際形狀是 `` - `round_type`：`micro` ``，擷取規則不涵蓋 backtick 與全形冒號會使全部合規的 round file 判 `fail`。`## Rating` 缺少 `round_type` 欄位、其值不在 `full`／`micro` 值域內、或該 skill 的編號序列缺少起始編號或出現缺號時，一律歸入無法解析而回報 `fail`；否則刪去該欄位或刪去 round file 就成為此 gate 的旁路。
  - `grader_immutability`——依 D4 判定；依 D3 判定為非 active 時狀態為 `skip`。
- 失敗模式：change 不存在時以既有 `change_not_found` error code 與統一 JSON 錯誤 shape 失敗。`--hook` mode 會列舉到 artifacts 尚未寫齊的 change 目錄（`cash-propose` 逐步寫入 proposal、design、tasks）；`proposal.md` 與 `tasks.md` 各自解析，任一檔案缺失只使該檔案貢獻空的宣告集合，另一份存在時仍須解析，MUST NOT 因單一檔案缺失清空整體宣告或拋出例外。`reviews/` 不存在或無 round file 時不是錯誤，四個 gate 全部為 `skip` 且整體 `ok` 為真。round file 無法解析時該 gate 為 `fail` 而非例外。
- 驗收標準：命令為唯讀。比較範圍是排除 `.git/` 的 tracked 與 untracked 工作區內容、mode 與存在狀態，逐位元組不變，且不建立目錄。在 receipt-based target 上，比較範圍 MUST 另外排除 bytecode cache 產物（`__pycache__/` 目錄與 `*.pyc` 檔案），且該排除 MUST 同時適用於「逐位元組不變」與「不建立目錄」兩項。launcher 僅在 portable 分支設 `sys.dont_write_bytecode = True`，receipt-based target 的 bytecode 寫入發生在 import system、早於 handler 執行，command 無從阻止，而本 change 不修改 launcher。只豁免「不寫入 bytecode cache」而不同時把該產物排出比較範圍是無效的——`__pycache__` 本身就是工作區內新建的 untracked 目錄，仍會違反其餘兩項，豁免形同未生效。`.git/index` 的 stat-cache 因呼叫 git 而刷新不構成違反，否則該標準機械上不可驗證。命令對額外的位置參數 MUST 以既有 `unknown_command`／`invalid_arguments` error code 與統一 JSON 錯誤 shape 失敗，MUST NOT 靜默忽略——靜默忽略會使未來誤實作為有效輸入的參數逃過此驗收。

**Stop hook**

- 觀察行為：於 turn 結束時依 D3 列舉檢查對象（排除 `archive` 與 `.parked` 保留目錄的 change，加上 `.parked/` 下的 parked change），對每個具備 round file 者執行 gate；任一 change 判定 fail 時依 D6／D8 在首次判定 exit 2、重入 exit 1，並輸出當次失敗項。
- 介面：`.claude/settings.json` 的 `Stop` 事件下新增一筆 command hook，其 command 為 `"$CLAUDE_PROJECT_DIR"/.cash-skills/bin/cash lint-round --hook`——`CLAUDE_PROJECT_DIR` 是 host 提供給 hook command 的 project root 環境變數，以它錨定 launcher 的定位使其不依賴 host 執行時的 cwd；workspace 解析仍依既有 `Workspace.discover` 自 cwd 起算，其失敗屬 D6 進入點之後的 fail-open 分支——且該條目 MUST 宣告 host 層的 `timeout`（見 D6 與 R9）。列舉、判定與 exit code 語意都由該 mode 承擔，settings.json 內不含判定邏輯；`timeout` 是 host 層的執行上限而非判定邏輯，不構成例外。
- 失敗模式：依 D6。
- 驗收標準：以下驗收使用 settings 中未帶 `--json` 的 hook command；JSON 呼叫另依 D8 矩陣驗收。無 round file 的工作區中，hook 靜默 exit 0 且無輸出；非重入判定失敗時 exit 2 且 stderr 含失敗 gate 的 `id`；進入點之後的每個 fail-open 分支（workspace 解析失敗、輸入 JSON 解析失敗、未預期例外）exit 1 且 stderr 含 `gate_unavailable` 診斷，MUST NOT exit 0；`stop_hook_active` 為真且當次有未解決失敗項時 exit 1 且 stderr 列出該等失敗項，無失敗項時 exit 0 且無輸出；`.claude/settings.json` 的該 hook 條目宣告 host 層 `timeout`。進入點之前的失敗（CLI 缺席、launcher 信任 gate 失敗、Python 版本不足）不在驗收範圍，見 R9。

**受影響的既有程式碼**

- `.cash-skills/lib/cash_cli/main.py`：於 `COMMANDS` 新增 `lint-round` 鍵。`emit_help` 由該 dict 導出，因此 help 表面自動涵蓋新命令，MUST NOT 另立靜態清單。
- `.cash-skills/lib/cash_cli/commands/__init__.py`：於 `execute` 新增路由分支。
- `.cash-skills/lib/cash_cli/installer.py`：於 runtime inventory 常數新增 `.cash-skills/lib/cash_cli/commands/lint_round.py`，維持既有排序。

## Risks / Trade-offs

**R1：gate 涵蓋範圍遠小於 review-gate 的判準總數。** v1 的四個 gate 只觸及 round file 的結構與裁判面保護，disposition、cumulative blocking set、confidence filter 等語意判準仍完全依賴 main agent 自律。緩解是明確不宣稱這些被涵蓋；擴張範圍時仍受 D1 約束，凡事實來源是 reviewer 輸出者一律不納入。

**R2：Stop hook 每個 turn 都執行，可能干擾與 review loop 無關的工作。** 緩解是 D3 的活動判定與 `skip` 語意：無 round file 或迴圈已終結時，唯一會執行的仍是三個結構類 gate，而它們只在 round file 本身違規時 fail。既有已完成 change 若留有違規的歷史 round file，會在無關的 turn 被阻擋。此緩解不涵蓋「迴圈永不終結」的情形——停滯 change 使 grader gate 對無關 session 持續生效，另記於 R11。此風險在首次啟用時最高，實作應在啟用前對既有 changes 的 round files 實跑一次確認全數通過，並把本 change 實作當時的全部 round files 複製為 `scripts/cash-cli/tests/fixtures/lint_round/` 下的靜態 fixture——`cash archive` 會把 `openspec/changes/<change>/` 整個目錄移走，測試若讀取該 live 路徑，封存後要麼永久紅燈、要麼在 glob 為空時 vacuously pass，而後者正是 `expected-set-derived-from-observed-state` 的形狀，因此該測試 MUST 在 fixture 集合為空時失敗。

**R3：grader-immutability gate 的 structured scope declaration 解析可能誤判。** 既有 requirement 明訂僅 proposal `## Impact` 的 affected-code 條目與 `tasks.md` 的 delivery target 算數，出現在驗證指令、規則描述、範例或散文中的路徑不算。解析過寬會讓保護失效，過嚴會擋住合法的 declared-scope 例外。緩解是把兩種方向都寫成測試案例。

**R4：本 change 自身就是 declared-scope 例外的第一個實例。** `scripts/cash-cli/tests/cli-checks.fish` 在受保護路徑集合內，而本 change 以它為 delivery target，因此本 change 確實修改受保護路徑，並且確實依賴 structured scope declaration 例外取得合法性——該路徑同時出現在 proposal `## Impact` 的 affected-code 條目與對應 task 的 delivery target，宣告成立。這使本 change 成為 R3 的第一個 dogfooding 案例：實作 D4 的宣告解析器時，MUST 以本 change 的 `## Impact` 條目與該 task 的 delivery 行作為必須判 `pass` 的 fixture，並以 `design.md` 散文中出現的受保護路徑作為必須判定為「非宣告」的 fixture；這三份 artifact 與 round files 同理 MUST 複製為 `scripts/cash-cli/tests/fixtures/lint_round/` 下的靜態 fixture，MUST NOT 讀取 `openspec/changes/` 下的 live 路徑（見 R2）。

**R5：D7 的發佈順序若未遵守，CLI 會在中途失效且無法用 Cash command 自我診斷。** 緩解是把每一個改動 manifest 覆蓋 bytes 的 task 都與 manifest 發佈綁在同一個 task——包含只調升 `BUNDLE_VERSION` 的版本 task——並在各該 task 的驗收中要求發佈後重跑一次任意 Cash command 確認 CLI 可用。未如此綁定時 `cash task done` 本身也會失效，該 task 無法被記為完成。

**R6：已提交的受保護檔案改動不在變更集合內。** D4 的變更集合取自工作區相對 HEAD 的改動加上 untracked 檔案，因此若受保護檔案的修改在同一次 loop 內已被 commit，gate 不會看見它。迴圈本身沒有 host-derived 的「本次 loop 起點」commit 可作為 baseline——round files 通常未提交，`.cash-skills/state/` 的 touched 快照又排除 `openspec/changes/`。此 gate 因此偵測的是正常流程下的未提交違規，而非能主動提交以隱藏改動的對手。此限制與不驗證 round file 不可變性同源，兩者都受制於同一個缺失的 baseline。

**R7：重入時仍需可觀察地放行。** `stop_hook_active=true` 時仍執行當次判定；依 D8，`--hook --json` 有 fail 以 exit `1` 回傳 `ok=false` 與當次 failures，無 fail 以 exit `0` 回傳 `ok=true`，避免重入再次阻擋且不丟失診斷。無 `--json` 的重入輸出仍遵循 hook 的 stderr 契約；此 change 不保存前次判定結果。

**R8：gate 的適用與自身完整性都不受本 gate 保護。** `grader_immutability` 是否適用取決於 round file 的 `## Decision`，而 round file 由受審的 main agent 撰寫；把 `next_round` 改成 `passed` 即可使該 gate `skip`。`.claude/settings.json` 與 `lint_round.py` 也不在受保護集合內。這些限制由 R6、R9 與本次 review 的宣告有效期決策明確記錄，後續若需封閉旁路須另立 change。

**R9：`lint_round.py` 進入點之前的失敗與終止都不受本 gate 控制。** 四類情形同屬此類。其一，取鎖阻塞：launcher 以無 `LOCK_NB`、無 timeout 的 `fcntl.flock` 取鎖，且取鎖早於 import，因此 command 內部無法自我設限，改由 `.claude/settings.json` 的 hook 條目宣告 host `timeout`；該上限觸發時 hook 由 host 終止，既不走本 gate 的 exit code，也不輸出 `gate_unavailable`。其二，`.cash-skills/bin/cash` 缺席或不可執行：shell 以 127 結束，沒有任何程式能輸出 `gate_unavailable`。其三，launcher 信任 gate 失敗（`manifest_invalid`／`receipt_invalid`／`bootstrap_invalid`）：launcher 的 `fail()` 以 exit 1 並在 stderr 輸出 `error[<code>]`，早於 runtime import。其四，Python 版本不足，同樣由 launcher 以 exit 1 結束。D6 明文「不存在可插入 wrapper 的位置」，因此這四類都無法交付 `gate_unavailable`，本 change 的 spec 與 tasks MUST NOT 對其提出該義務。緩解只有一項：這四類在 host 上都落在「非 2 的非零 exit」或逾時終止，均為非阻擋且 stderr 可見（127 與 `error[<code>]` 本身即為可見診斷），不會使 session 卡死。附帶後果：D7 的兩個發佈窗口期間每次 Stop 都會以 `manifest_invalid` exit 1，屬非阻擋但無 `gate_unavailable` 的可見失敗，實作者應預期 1.1 與 1.3 進行中的 turn 結束會看到該訊息。

**R10：宣告聯集的來源目錄由受審者可寫。** D4 的涵蓋判定取未封存且未 parked 的被列舉 change 宣告聯集，而 `openspec/changes/` 不在受保護路徑集合內。受審的 main agent 因此可新建或編輯任一未封存且未 parked change 的 `proposal.md ## Impact` 寫上受保護路徑，對該次判定解除 `grader_immutability`；來源 change 即使已 `passed` 或 `aborted` 仍有效。這是本次 review 接受的範圍限制；把 `openspec/changes/` 納入受保護集合需要 MODIFIED 另一個 capability 的 master requirement，超出本 change 範圍。此旁路與 round decision 可寫的限制同族，一併界定工作區一致性檢查的成立範圍。

**R11：停滯的非 parked change 使 grader gate 對無關 session 持續生效。** active 判定完全來自磁碟，一個被擱置而最高編號 round file 停在 `next_round` 的 change 會使 repo 長期 active；其宣告同時依 D4 持續有效。使用者在完全不在 review loop 的一般開發回合中合法編輯受保護路徑時，只要無任何未封存且未 parked change 宣告該路徑，阻擋型 hook 仍 exit `2`。parked change 不計入 active 判定，也不提供宣告；非 parked 的停滯 change 則不受該排除涵蓋。緩解僅到記錄為止：使用者可 park 或終結該 change 的迴圈。

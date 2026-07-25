## Context

Cash CLI 是 repository-owned runtime，cash skills 是它的唯一消費者。兩者的契約散落在三處：CLI 的 validation.py 定義 artifact 的必要形狀、resources.py 定義模板、SKILL.md 定義 agent 實際照著寫的內容。本次要修的七項缺陷有五項的根因都是「同一個契約在多處各自定義後漂移」或「variant 特化內容滲入應為 variant 中立的層」。

現況的具體事實（實測）：

- validation.py 的 required 對 proposal.md 是 `## Summary`、`## Capabilities`、`## Impact` 三個標題的字串包含檢查；cash-propose step 5 的三個型別模板沒有一個同時含這三者。封存目錄下 19 個 change 中有 15 個的 proposal 缺少其中至少一個標題。
- 三個型別模板同時是全專案唯一教導 `## Capabilities` 的 `### New Capabilities` / `### Modified Capabilities` 子結構與 `## Impact` 的 `- Affected specs:` / `- Affected code:` 加 `New` / `Modified` / `Removed` 三列巢狀清單的地方。resources.py 現行模板只有裸標題。
- search.py 以列表推導取出所有不以 `--` 開頭的參數，第一個即為 query；`--limit` 的值因此可被誤取為 query。
- search.py 以單一 try 區塊同時包住 `arguments.index` 與 `int()`，兩種失效共用 `invalid_limit` 錯誤碼。
- search.py 的語料來源是 `workspace.walk_text_files("openspec")`，無任何排除；`walk_text_files` 只接受單一 base、沒有排除參數，且對非 UTF-8 檔案會讓整個呼叫以 `invalid_encoding` 失敗。實測前 100 筆結果中 82 筆來自封存 change 的 `reviews/` 目錄。
- drift.py 的三個 severity 分支各自以 f-string 內嵌 `$cash-` 前綴；cash-drift 兩個 variant 的 SKILL.md 逐字寫著 `a single copy-pasteable command line` 並指示輸出 `Run <primary_recommendation>.`。
- `.agents/skills/cash-ingest/SKILL.md` 有三處空 code span 與一處被剝空前綴的路徑範例。
- `.agents` 底下四個 skill 帶 Claude-only frontmatter：cash-analyze 與 cash-verify 帶 `context`、`agent`、`disallowedTools` 三個；cash-ask 與 cash-discuss 各帶 `disallowedTools`。cash-audit 與 cash-drift 是唯二完整處理過的 fork 型 skill。
- cash-discuss 兩個 variant 目前逐字相同，因此不在 skill-checks.fish 的 divergent 清單內，也沒有 parity manifest。
- skill-checks.fish 以字面值斷言 cash-skills.version 等於 `2.1.0`。
- `## What Changes` 這個字面值除了 cash-propose step 5 的模板外，還出現在兩個 variant 的第 448 行審查過濾規則中；該行位於 grader sentinel 區塊之外，因此不影響 `assert_grader_immutability` 的雜湊。

## Goals / Non-Goals

**Goals**

- proposal 的必要標題與模板各自只有一個定義點，SKILL.md 不再持有第二份模板，且收斂後不遺失下游程式碼依賴的子結構形狀。
- search 的解析結果與旗標位置無關；缺少選用旗標不再造成失敗；預設語料排除噪音來源但保留封存的決策脈絡可檢索。
- CLI runtime 不含任何 variant 專屬的 invocation 前綴，且消費該欄位的 skill 描述與之一致。
- Codex variant 的 skill 檔不含 Claude 專屬 frontmatter，也不含被剝空的 code span。
- 上述每一項都有對應的自動化斷言，且該斷言確實被測試群組呼叫到。

**Non-Goals**

- 不改動 validation.py 的必要標題集合本身。
- 不修改封存目錄下既有的 proposal 或 review 檔案。
- 不改動 search 的評分權重、排序規則或改採向量檢索。
- 不改動 grader 保護清單的成員組成。
- 不改動 cash-apply 兩個 variant 的 SKILL.md（見 Risks 的 review-loop 副本分歧條目）。
- 不處理 review 中的 B 級與 C 級項目。

## Decisions

**D1 — proposal 模板收斂到 CLI，SKILL.md 只留指向**

採用單一來源而非補齊三模板的缺漏標題。理由：open signal cross-artifact-definition-drift 已累計 10 次，補齊缺漏只消除本次症狀，不消除「模板在 SKILL.md 與 resources.py 兩處各自演化」的結構性成因。收斂後新增或調整 proposal 段落只需改 resources.py 一處，兩個 variant 自動一致。

收斂不得只搬標題。resources.py 的模板必須同時承載 `## Capabilities` 的 `### New Capabilities` / `### Modified Capabilities` 與 `## Impact` 的 `- Affected specs:` / `- Affected code:` 加 `New` / `Modified` / `Removed` 三列骨架，理由分兩層且各自成立：`## Impact` 標題本身是 `spec_merge._paths_in_section` 產生 trace 時界定區段的依據，標題消失會使 trace 抽不到任何路徑；`New` / `Modified` / `Removed` 三個標籤列則是 master spec 的 `cash-propose 的 impact 粒度提示` requirement 計數 affected-code 條目的依據，標籤消失會使該提示永遠不觸發。兩者在形狀消失時都是靜默降級而非報錯。`## Capabilities` 的兩個子標題無程式碼消費者，保留是為了與既有 artifact 的可讀性一致。（註：`drift._impact_paths` 是對整份 proposal 抽 code span，不看任何標題，不屬於此依賴。）

以在模板中加入 `## Non-Goals` 與 `## Alternatives Considered` 兩個選用段落補償型別專屬形狀的流失——這兩者是原三模板中唯二不被必要標題集合涵蓋、且確實承載內容的段落。原模板的 `## Why`、`## Problem`、`## Root Cause`、`## Success Criteria` 等段落語意可由 `## Motivation` 與 `## Proposed Solution` 承載。

cash-propose 有兩個連帶編輯點，兩者都必須處理：step 2 型別分類的結尾句「這決定 step 5 的模板格式」失去指涉對象，改寫為指向 `## Motivation` 與 `## Proposed Solution` 的敘述重心；第 448 行審查過濾規則引用了 `## What Changes`，改為只引用 `## Proposed Solution`。

**D2 — search 的位置參數以「跳過旗標所消耗的值」解析**

改為線性掃描而非過濾式推導：遇到已知的帶值旗標時同時跳過旗標與其值，遇到其他以 `--` 開頭的 token 視為未知旗標並報錯，其餘為位置參數。位置參數必須恰好一個。

未知旗標的判準採「以 `--` 開頭」而非「以連字號開頭」，因為 cash-ask 會把使用者提問原文直接餵進 query，以單一連字號開頭的自然語言查詢必須維持可用。

帶值旗標的下一個 token 若本身以 `-` 開頭，MUST 視為該旗標缺值並回傳缺值訊息，MUST NOT 吞掉該 token 當作值。否則 `search --limit --json foo` 會回傳「值不合法」而非「缺少值」，與 D3 要求的兩種訊息語意相反。

多於一個位置參數選擇報錯而非忽略。理由：現況靜默忽略多餘 token，與 open signal readonly-mode-argument-override 描述的失效模式同類——寬鬆解析讓使用者以為指令做了某件事，實際上做了另一件。

**D3 — limit 的缺席與不合法分開處理**

未提供 `--limit` 時採用預設值 10。提供了旗標才進入驗證：缺值、非整數、或超出 1 到 100 的範圍各自報錯。預設值 10 與專案 guidance 中既有的呼叫形式一致，因此不會改變任何既有呼叫點的行為。

**D4 — scope 以列舉旗標控制，預設只排除封存的 review 檔案**

`--scope` 接受 `specs`、`active`、`all` 三個值，預設 `active`。`active` 的定義是排除 `openspec/changes/archive/` 底下任何路徑片段為 `reviews` 的目錄，而非排除整個 archive。

選擇「只排除 reviews」而非「排除整個 archive」的理由：實測 82 筆噪音幾乎全部來自封存 change 的 review round 檔案，排除它們即可解決訊噪比問題；而封存的 proposal、design 與 spec 是查詢歷史決策脈絡的正當來源，cash-ask 的 step 3 明文指示以 archive 作為歷史脈絡來源。若排除整個 archive，該指示會變成永遠不可達的死指示，而該 skill 的呼叫點被 skill-checks.fish 的 byte-exact 斷言、AGENTS.md 與 CLAUDE.md 的 sha256 baseline 以及 master spec 的逐 byte 引用三重凍結，無法在本次範圍內加上旗標。

排除必須在走訪層剪枝，不得事後過濾。理由：事後過濾仍會讀取並解碼被排除的檔案，封存目錄下任何非 UTF-8 檔案或不安全形狀仍會讓整個 search 失敗，等於暴露面完全沒有縮小。走訪層剪枝需要 `workspace.walk_text_files` 接受排除參數，因此該檔納入本次範圍。

**D5 — drift 輸出不含前綴的 skill 名稱，並同步 skill 端描述**

`primary_recommendation` 改為輸出 `cash-apply <name>` 或 `cash-ingest <name>`，不含 `$` 或 `/`。

cash-drift 兩個 variant 的 SKILL.md 必須同步：欄位描述由 `a single copy-pasteable command line` 改為描述其為 skill 名稱與 change 名稱，輸出指示由 `Run <primary_recommendation>.` 改為呈現建議的下一個 skill 而非可執行指令。不同步會讓未修訂的 SKILL.md 契約變成假敘述，並產生一條不可執行的輸出行——這正是本次要消除的缺陷類別本身。

**D6 — Codex fork 段落整段視為 Claude-only，四個 skill 一起收斂**

`.agents` 的 cash-analyze 與 cash-verify 移除三個 frontmatter 欄位，並移除內文中整個 fork context 區塊——自其標題起至其後的 `---` 分隔線止，含標題、自述句與該區塊內的行為規則，因為那些規則以 fork 為前提，只刪標題會留下指涉 fork 的孤兒敘述；`.agents` 的 cash-ask 與 cash-discuss 移除 `disallowedTools`。四者收斂後與已完整處理的 cash-audit、cash-drift 一致：Claude 專屬設定只存在於 `.claude` variant，在 parity manifest 中呈現為新增區塊而非逐字替換。

cash-discuss 兩個 variant 目前逐字相同，移除後會首次產生合法差異，因此必須新增 `scripts/cash-skills/variant-parity/cash-discuss.diff` 並把 `discuss` 加入 skill-checks.fish 的 divergent 清單，否則對等比較會以「未列入的本文漂移」失敗。

**D7 — bundle 版本以相對規則提升，不硬編**

canonical SKILL.md 有內容異動，依 CASH-SKILLS.md 的規則必須在同一次變更中提升 cash-skills.version，採 minor 位。版本號在 tasks 中以「當前值的下一個 minor」表述而非硬編字面值：另一個未封存的 change `harden-installer-mode-and-recovery` 同樣要提升版本並更新 skill-checks.fish 的同一行字面值，兩者落地順序未定。實作時以當時的 `cash-skills.version` 為基準推導，並同步更新 skill-checks.fish 的斷言。

**D8 — Codex 變體的 plan 檔以純路徑解析**

`.agents/skills/cash-ingest/SKILL.md` 在無 plan 目錄的環境下，plan 檔引數 SHALL 解析為相對於目前工作目錄或 repo root 的一般路徑，不套用任何目錄前綴；若引數沒有 `.md` 副檔名則附加之。此決定同時決定第 40、45、53、267 四行的改寫內容，使該檔 `**Input**` 段落既有的不含目錄前綴之引數範例保持合法。改寫後的可斷言形式採否定式，避免依賴行號：這四行 MUST NOT 含空 code span，且 MUST NOT 含 `~/.claude/plans/` 或任何其他目錄前綴字面值。以行號表述的斷言在第 24 行附近合併語句後會失準，因此斷言一律以內容匹配定位。

**D9 — 空 code span 的判準必須排除跳脫與 fence**

markdown 以雙反引號包住含反引號的內容（`` `x` `` 的外層），也以三反引號開啟 code fence，兩者都含有相鄰反引號。以「前後字元都不是反引號」界定會失敗：cash-propose 第 114 行跳脫寫法的開閉分隔符前後都是空白，仍會被誤判。判準因此定義為「同一行中，長度恰為 2 的反引號 run 出現的次數為奇數」——合法跳脫的開閉分隔符必成對出現而為偶數，fence 的 run 長度為 3 不計入。實測此判準在 24 個 canonical SKILL.md 上恰好命中 cash-ingest 的三處殘骸，零偽陽性。已知取捨：同一行出現偶數個空 code span 時會被判為合法，這是奇偶判準的固有偽陰性。實測既有殘骸皆為一行一處，且此形狀來自變體字面值替換而非人工撰寫，同行成對出現的機率極低，因此接受此偽陰性以換取零偽陽性與可用單一 regex 表達的簡單性。

## Implementation Contract

**C1 — proposal 模板單一來源**

- 可觀察行為：依 cash-propose step 5 產出的 proposal.md 通過 `cash validate`；`cash list --json` 對該 change 回傳非空的 summary 欄位；依該模板填寫的 `## Impact` 能被 spec 合併的 trace 產生正確解析，其三個標籤列能被 impact 粒度提示正確計數。
- 介面/資料形狀：resources.py 中 proposal 的 `template` 依序含 `## Summary`、`## Motivation`、`## Proposed Solution`、`## Non-Goals`、`## Alternatives Considered`、`## Capabilities`、`## Impact` 七個段落標題；`## Capabilities` 之下含 `### New Capabilities` 與 `### Modified Capabilities`；`## Impact` 之下含 `- Affected specs:` 與 `- Affected code:`，後者含 `New`、`Modified`、`Removed` 三個標籤列（每個標籤後接冒號）。
- 失敗模式：不新增失敗模式。validation.py 的 required 集合與錯誤碼 `heading_missing` 均不變。
- 驗收標準：cash-propose 兩個 variant 的 SKILL.md 中不再出現 `## Why`、`## What Changes`、`## Problem`、`## Root Cause`、`## Success Criteria` 這五個標題字串（含第 448 行的引用）；step 5 明文指示使用 CLI 回傳的 `template`；step 2 的結尾句已改寫。以 `scripts/cash-cli/tests/test_graph_instructions.py` 斷言 `template` 含七個段落標題與兩組子結構，以 `scripts/cash-skills/tests/skill-checks.fish` 斷言五個字面值不存在。
- 範圍邊界：不修改 validation.py；不修改 design 與 tasks 的 template；不修改 cash-apply 兩個 variant 中同源的第 530 行。

**C2 — search 位置參數解析**

- 可觀察行為：`search openspec --limit 5` 與 `search --limit 5 openspec` 的 stdout 逐位元組相同。
- 介面/資料形狀：解析器辨識 `--limit` 與 `--scope` 為帶值旗標，`--json` 為無值旗標；位置參數恰好一個；未知旗標的判準為「以 `--` 開頭」；帶值旗標後方若為以 `-` 開頭的 token 則視為缺值。
- 失敗模式：零個位置參數、多於一個位置參數、未知的 `--` 開頭 token，三者皆報 `invalid_arguments` 且 exit code 為 2。
- 驗收標準：先以 `install-cash-skills.fish --target <tmpdir>` 安裝到臨時 workspace，再以 subprocess 呼叫該 workspace 內的 launcher 並將 `cwd` 指向該 workspace，比對兩種寫法的 stdout bytes 與 returncode，並覆蓋三種 `invalid_arguments` 情境與單一連字號開頭的 query 仍可用，以 `scripts/cash-cli/tests/test_lexical_search.py` 驗證。
- 範圍邊界：只改 search 的 execute 進入點，不改其他指令的參數解析。

**C3 — limit 預設值與錯誤分流**

- 可觀察行為：`cash search <query>` 不帶 `--limit` 時 exit 0 並回傳至多 10 筆結果。
- 介面/資料形狀：預設值為整數 10。既有的 1 到 100 範圍檢查維持在 `search_payload` 內。
- 失敗模式：`--limit` 出現但後方無值或後方為以 `-` 開頭的 token、值非整數、值超出 1 到 100，均報 `invalid_limit`；缺值與值不合法兩種情形的 message MUST 不相同。
- 驗收標準：以同一條臨時 workspace launcher 路徑，以 subprocess 斷言不帶旗標時 returncode 為 0，且四種 `invalid_limit` 情境中缺值與不合法兩類的 message 不同，以 `scripts/cash-cli/tests/test_lexical_search.py` 驗證。
- 範圍邊界：不改 `search_payload` 內既有的範圍上下界。

**C4 — search 語料範圍**

- 可觀察行為：預設結果不含任何位於封存 change `reviews/` 目錄下的路徑，但可含封存 change 的 proposal、design 與 spec；`--scope specs` 的結果全部位於 `openspec/specs/` 底下；`--scope all` 走訪的檔案集合是 `--scope active` 走訪集合的嚴格超集合，且其差集恰為封存 `reviews` 目錄下的檔案（此為走訪層命題，不受 `--limit` 排名截斷影響）。封存目錄下存在非 UTF-8 檔案時，`--scope active` 與 `--scope specs` MUST 仍 exit 0。`--scope specs` 在 `openspec/specs/` 不存在時 MUST 回傳空 `results` 且 exit 0。
- 介面/資料形狀：`--scope` 接受 `specs`、`active`、`all`；未提供時等同 `active`。payload 形狀不變，不新增欄位。`workspace.walk_text_files` 新增排除參數，排除在走訪層剪枝。排除的比對 MUST 以完整路徑片段進行，MUST NOT 以字串前綴或子字串比對，否則 `code-reviews` 這類名稱含 `reviews` 的目錄或 `archive-*` 這類同層兄弟目錄會被誤傷。
- 失敗模式：`--scope` 值不在三個列舉值內報 `invalid_scope`，exit code 2。
- 驗收標準：測試 workspace 同時含 master spec、非封存 change、封存 change 的 proposal 與封存 change 的 `reviews/` 檔案，並在封存目錄放一個非 UTF-8 檔；斷言三個 scope 各自的路徑集合、非 UTF-8 檔不影響 `active` 與 `specs`、缺少 `openspec/specs/` 時 `specs` 回空、以及 `invalid_scope`，以 `scripts/cash-cli/tests/test_lexical_search.py` 驗證。
- 範圍邊界：不改變評分與排序；不改變 `--scope all` 遇到非 UTF-8 檔仍失敗的既有行為。

**C5 — drift 建議 variant 中立且 skill 描述同步**

- 可觀察行為：`drift <name> --json` 的 `primary_recommendation` 欄位值為 `cash-apply <name>` 或 `cash-ingest <name>`，不含 `$` 或 `/`；非 JSON 模式的報告最後一行隨之改變；cash-drift 兩個 variant 的 SKILL.md 不再宣稱該欄位是可直接執行的指令行。
- 介面/資料形狀：欄位名稱與型別不變，僅值的字串形式改變。severity 對應不變：`light` 對 `cash-apply`，`medium` 與 `heavy` 對 `cash-ingest`。
- 失敗模式：不新增失敗模式。
- 驗收標準：`scripts/cash-cli/tests/test_analyze_drift.py` 中既有的 `startswith("$cash-")` 斷言必須被替換為「不含 `$` 且不含 `/`」的斷言，並補上三個 severity 分支的對應案例；cash-drift 兩個 variant 不再含 `copy-pasteable` 字面值，以 `scripts/cash-skills/tests/skill-checks.fish` 驗證。
- 範圍邊界：不修改 cash-apply 的 SKILL.md。

**C6 — cash-ingest Codex variant 語意完整**

- 可觀察行為：`.agents/skills/cash-ingest/SKILL.md` 全檔不含空 code span；第 40、45、53、267 四行依 D8 的純路徑解析語意改寫為完整敘述；開頭段落的重複語句合併為單一連貫敘述。
- 介面/資料形狀：檔案的 frontmatter 與步驟編號不變。
- 失敗模式：不適用。
- 驗收標準：skill-checks.fish 對 24 個 canonical SKILL.md 斷言依 D9 判準不存在空 code span；並依 D8 的否定式對該檔斷言全檔不含 `~/.claude/plans/` 或任何其他目錄前綴字面值，斷言以內容匹配而非行號定位。
- 範圍邊界：不改動 Claude variant 的 cash-ingest。

**C7 — Codex variant 移除 Claude-only frontmatter**

- 可觀察行為：`.agents/skills/` 底下 12 個 SKILL.md 的 frontmatter 皆不含 `context`、`agent`、`disallowedTools` 三個 key；cash-analyze 與 cash-verify 的內文不含 fork context 區塊，該區塊自標題起至其後的 `---` 分隔線止整段移除。
- 介面/資料形狀：四個受影響檔案的 `name`、`description`、`license`、`metadata` 欄位不變；所有 `.claude` 對應檔完全不變。`discuss` 加入 skill-checks.fish 的 divergent 清單並新增其 parity manifest。
- 失敗模式：cash-discuss 產生差異但未新增 manifest 或未加入 divergent 清單時，對等比較以「未列入的本文漂移」失敗。
- 驗收標準：skill-checks.fish 斷言 12 個 `.agents` SKILL.md 的 frontmatter 不含這三個 key，且該斷言只解析 frontmatter 區塊而非全檔；variant-parity 群組在七份既有 manifest 加一份新 manifest 下通過。
- 範圍邊界：不改動 cash-audit 與 cash-drift 的 frontmatter；不改動任何 `.claude` 檔案的 frontmatter。

**C8 — bundle 版本與斷言同步**

- 可觀察行為：cash-skills.version 為當前值的下一個 minor（三段無 leading zero 的數字加單一換行）；skill-checks.fish 的 canonical-inventory 群組通過。
- 介面/資料形狀：版本檔格式不變。
- 失敗模式：版本檔與 skill-checks.fish 斷言不一致時 canonical-inventory 群組失敗；版本升級與 runtime 或 SKILL.md 異動不在同一個 commit 時，bundle 版本歷史契約測試在提交後失敗。
- 驗收標準：`fish scripts/cash-skills/tests/skill-checks.fish` 全群組通過；提交後再執行一次確認版本歷史契約在 `current == head` 路徑下通過。
- 範圍邊界：不改動 installer 的版本比較邏輯；不改動 receipt schema。

**C9 — 良構斷言確實被執行**

- 可觀察行為：skill-checks.fish 新增一個具名測試群組承載良構斷言，且該群組同時出現在 `case all` 的呼叫序列中。
- 介面/資料形狀：新群組名稱為 `well-formedness`，與既有群組並列於 `switch` 結構。
- 失敗模式：斷言函式未被任何 group 呼叫時，全套件會在斷言從未執行的情況下回報通過。
- 驗收標準：以刻意注入一個空 code span 與一個 `disallowedTools` key 的方式，確認 `all` 與 `well-formedness` 兩個群組皆非零結束，注入後還原。
- 範圍邊界：本 contract 不改動既有群組的斷言內容；版本字面值斷言的同步由 C8 負責，divergent 清單的登記由 C7 負責，兩者對既有群組的改動不受本邊界限制。

**C10 — runtime 改動後重建 receipt**

- 可觀察行為：任一 replaceable runtime 檔改動並重建 receipt 之後，`.cash-skills/bin/cash` 的任一指令仍可正常執行並回傳既有的 exit code 語意；實作期間任一時點只要最近一次 runtime 改動後已重建過 receipt，CLI 即為可用狀態。
- 介面/資料形狀：`.cash-skills/receipt.tsv` 由 `./install-cash-skills.fish --self` 重建，schema 不變。該檔為 gitignore 項目，不列入 affected code。
- 失敗模式：未重建時 launcher 以 `receipt_invalid` 與 exit 1 失敗，訊息為 runtime record drift。
- 驗收標準：每次重建後 `.cash-skills/bin/cash validate --all` exit 0。重建可重複執行且不以版本提升為前提——launcher 的 `validate_receipt` 只檢查版本字串格式、不比對 `cash-skills.version`——但最後一次重建 MUST 在版本提升之後、任何回歸執行之前，使 receipt 首列記錄的版本與版本檔一致。
- 範圍邊界：不改動 receipt schema 與 installer 的 receipt 產生邏輯。

## Risks / Trade-offs

- **失去型別專屬 proposal 形狀**：D1 收斂後，Bug Fix 類變更不再有 `## Root Cause` 與 `## Success Criteria` 的固定位置。緩解：這兩者的內容改由 `## Motivation` 與 `## Proposed Solution` 承載，`## Non-Goals` 與 `## Alternatives Considered` 已納入模板，且下游依賴的 `## Capabilities` 與 `## Impact` 子結構完整保留；若日後證實不足，只需改 resources.py 一處即可加回。
- **search 預設行為變更**：`active` 會讓封存 change 的 review 檔案不再出現在預設結果中。這是刻意接受的取捨，且既有呼叫點無法在本次範圍內加上旗標（三重 byte-exact 凍結）。緩解：排除範圍刻意收窄為 `reviews/`，使 cash-ask 對封存 proposal、design 與 spec 的歷史脈絡查詢維持可用，其 step 3 指示不會變成死指示；需要 review 檔案時仍可用 `--scope all`。
- **review-loop 副本在單一行上分歧**：cash-propose 第 448 行改寫後，cash-apply 兩個 variant 的同源行仍引用 `## What Changes`。cash-apply 的 SKILL.md 是 grader 保護檔且未列入本次結構化範圍宣告，因此本次刻意讓四份副本在該行分歧。該行位於 grader sentinel 區塊之外，不影響 `assert_grader_immutability` 的雜湊。後續應以獨立 change 收斂。
- **與並行 change 的版本落地順序相依**：`harden-installer-mode-and-recovery` 同樣要提升 cash-skills.version 並更新 skill-checks.fish 的同一行字面值。緩解：D7 採相對規則不硬編版本號，先落地者不受影響，後落地者以當時值推導下一個 minor 並重新更新斷言。
- **本次修改一個 grader 保護檔**：`scripts/cash-skills/tests/skill-checks.fish` 在保護清單內，已於 proposal 的 Impact 明文宣告為 affected code，符合 structured scope declaration 的例外條件。`scripts/cash-cli/tests/cli-checks.fish` 經確認不需修改（本次改動的三個 CLI 測試檔 `test_lexical_search.py`、`test_analyze_drift.py`、`test_graph_instructions.py` 在該檔各有既有具名群組 `lexical-search`、`analyze-drift`、`graph-instructions`，且 `case all` 以 `test_*.py` 萬用字元全收），因此不列入宣告；若實作時發現確需修改，該修正必須改記為保護註記。
- **提交原子性**：bundle 版本歷史契約要求版本升級與全部 replaceable runtime 與 SKILL.md 異動落在同一個 commit。緩解：tasks 明訂全部實作任務的檔案必須在同一個 commit 落地，並在提交後重跑一次 skill 套件。
- **變更範圍偏大**：25 筆 affected-code 遠超過 15 的建議門檻。緩解：七項缺陷共用「契約單一來源」這一個主題；若要分批，可沿 capability 切為 cash-cli 側（C2–C5）與 cash-skill-workflows 側（C1、C6、C7、C9），C8 依賴後者完成。

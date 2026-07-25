## 1. CLI runtime

- [ ] 1.1 依 design 的 C2，把 `.cash-skills/lib/cash_cli/commands/search.py` 的 `execute` 參數解析改為線性掃描：辨識 `--limit` 與 `--scope` 為帶值旗標並同時略過旗標與其值，辨識 `--json` 為無值旗標，其餘不以 `--` 開頭的 token 才計為位置參數（以單一連字號開頭者視為位置參數）；帶值旗標後方的 token 若以 `-` 開頭則視為缺值而不吞掉；位置參數不等於一個、或出現未知的 `--` 開頭 token 時以 `invalid_arguments` 與 exit 2 失敗。驗收：兩種旗標位置寫法的 stdout 逐位元組相同且單一連字號 query 仍可用，以 `scripts/cash-cli/tests/test_lexical_search.py` 驗證。（依 design 的 C10：本任務改動 replaceable runtime 檔，完成後須立即依任務 3.4 重建 receipt，否則後續任何 `.cash-skills/bin/cash` 指令皆會失敗。）

- [ ] 1.2 依 design 的 C3，把同一支 `search.py` 的 `--limit` 缺席改為採用預設值 `10` 而非失敗；只有旗標出現時才驗證其值，並讓「缺值」與「值不合法」兩種情形回傳不同的 `invalid_limit` message。既有的 `1` 到 `100` 範圍檢查維持在 `search_payload` 內不變。驗收：不帶旗標時 exit 0 且結果不超過 10 筆，缺值與不合法兩類 message 不同，以 `scripts/cash-cli/tests/test_lexical_search.py` 驗證。

- [ ] 1.3 依 design 的 C4 的走訪層剪枝要求，為 `.cash-skills/lib/cash_cli/workspace.py` 的 `walk_text_files` 新增排除參數，使呼叫端能在遞迴進入前剪掉指定目錄，被剪掉的檔案不被開啟或解碼。既有呼叫端在不傳該參數時行為不變。驗收：被排除目錄下的非 UTF-8 檔案不會使呼叫失敗，以 `scripts/cash-cli/tests/test_lexical_search.py` 驗證。

- [ ] 1.4 依 design 的 C4，在 `search.py` 新增 `--scope`，接受 `specs`、`active`、`all` 三值，未提供時等同 `active`；`specs` 只走訪 `openspec/specs/`，`active` 走訪 `openspec/` 但以任務 1.3 的排除參數剪掉封存 change 底下路徑片段為 `reviews` 的目錄，`all` 走訪 `openspec/` 全部且不作排除；值不在列舉內時以 `invalid_scope` 與 exit 2 失敗；`--scope specs` 在 `openspec/specs/` 不存在時回傳空 `results` 且 exit 0。不改動評分權重與排序規則。驗收：三個 scope 各自的路徑集合符合界定，且 `all` 的走訪集合為 `active` 走訪集合的嚴格超集合、差集恰為封存 `reviews` 目錄下的檔案（走訪層命題，不受 `--limit` 排名截斷影響），以 `scripts/cash-cli/tests/test_lexical_search.py` 驗證。

- [ ] 1.5 [P] 依 design 的 C5，把 `.cash-skills/lib/cash_cli/commands/drift.py` 三個 severity 分支的 `primary_recommendation` 改為輸出不含 `$` 也不含 `/` 的 `cash-apply <name>` 或 `cash-ingest <name>`，維持 `light` 對應 `cash-apply`、`medium` 與 `heavy` 對應 `cash-ingest` 的既有對應。不修改 `render_report` 的行結構。驗收：JSON 與 human output 的建議皆不含前綴字元，以 `scripts/cash-cli/tests/test_analyze_drift.py` 驗證。

- [ ] 1.6 [P] 依 design 的 C1 的 CLI 側，把 `.cash-skills/lib/cash_cli/resources.py` 中 proposal 的 `template` 改為依序含七個段落標題，並在 `## Capabilities` 之下含 `### New Capabilities` 與 `### Modified Capabilities`、在 `## Impact` 之下含 `- Affected specs:` 與 `- Affected code:` 加 `New`／`Modified`／`Removed` 三個標籤列（每個標籤後接冒號）骨架。不修改 `.cash-skills/lib/cash_cli/validation.py` 的必要標題集合，也不修改 design 與 tasks 的 template。驗收：`template` 含七個標題與兩組子結構且兩次讀取逐位元組相同，以 `scripts/cash-cli/tests/test_graph_instructions.py` 驗證。

## 2. Skill 檔案

- [ ] 2.1 [P] 依 design 的 C1 的 skill 側，從 `.claude/skills/cash-propose/SKILL.md` 與 `.agents/skills/cash-propose/SKILL.md` 的 step 5 刪除三個型別模板區塊並改為明文指示使用 CLI 回傳的 `template`；把 step 2 型別分類的結尾句改寫為指向 `## Motivation` 與 `## Proposed Solution` 的敘述重心；把第 448 行審查過濾規則中對 `## What Changes` 的引用改為只引用 `## Proposed Solution`。改動全部位於 grader sentinel 區塊之外。兩個變體的改動在 invocation 前綴正規化後必須完全相同。驗收：兩檔全檔皆不含五個已移除的段落標題字面值，以 `scripts/cash-skills/tests/skill-checks.fish` 驗證。

- [ ] 2.2 [P] 依 design 的 C6 與 D8 的純路徑解析語意，改寫 `.agents/skills/cash-ingest/SKILL.md` 第 40、45、53、267 四行，使其在無 plan 目錄的環境下語意完整，且與該檔 `**Input**` 段落中不含目錄前綴的既有引數範例一致；並把開頭段落中重複的兩句合併為單一連貫敘述。不改動該檔的 frontmatter 與步驟編號，也不改動 `.claude` 變體。驗收：該檔不含空 code span，且全檔不含 `~/.claude/plans/` 或任何其他目錄前綴字面值（斷言以內容匹配而非行號定位），以 `scripts/cash-skills/tests/skill-checks.fish` 驗證。

- [ ] 2.3 [P] 依 design 的 C7，從 `.agents/skills/cash-analyze/SKILL.md` 與 `.agents/skills/cash-verify/SKILL.md` 的 frontmatter 移除 `context`、`agent`、`disallowedTools` 三個 key，並移除兩檔內文中整個 fork 情境區塊——自其標題起至其後的 `---` 分隔線止，含標題、自述句與區塊內以 fork 為前提的行為規則；已完整處理的 `.agents/skills/cash-ask/SKILL.md` 與 `.agents/skills/cash-drift/SKILL.md` 的 manifest 顯示該整段皆為 Claude-only 新增區塊，可作為先例。兩檔的 `name`、`description`、`license`、`metadata` 欄位不變，`.claude` 對應檔完全不變。驗收：兩檔 frontmatter 不含這三個 key，以 `scripts/cash-skills/tests/skill-checks.fish` 驗證。

- [ ] 2.4 [P] 依 design 的 C7，從 `.agents/skills/cash-ask/SKILL.md` 與 `.agents/skills/cash-discuss/SKILL.md` 的 frontmatter 移除 `disallowedTools`。兩檔的其餘 frontmatter 欄位與全部本文不變，`.claude` 對應檔完全不變。驗收：`.agents` 底下 12 個 `SKILL.md` 的 frontmatter 皆不含 `context`、`agent`、`disallowedTools`，以 `scripts/cash-skills/tests/skill-checks.fish` 驗證。

- [ ] 2.5 [P] 依 design 的 C5 的 skill 側，把 `.claude/skills/cash-drift/SKILL.md` 與 `.agents/skills/cash-drift/SKILL.md` 中 `primary_recommendation` 的欄位描述由可直接執行的指令行改為 skill 名稱與 change 名稱，並把輸出範本中以執行動詞包裹該欄位值的兩處改為呈現建議的下一個 skill。兩個變體的改動在 invocation 前綴正規化後必須完全相同。驗收：兩檔皆不含 `copy-pasteable` 字面值，以 `scripts/cash-skills/tests/skill-checks.fish` 驗證。

## 3. Manifest、divergent 清單與版本

- [ ] 3.1 把 `discuss` 加入 `scripts/cash-skills/tests/skill-checks.fish` 的 divergent 清單，並新增 `scripts/cash-skills/variant-parity/cash-discuss.diff`，使其逐行反映任務 2.4 之後 cash-discuss 兩個變體的實際差異。驗收：variant-parity 群組通過，以 `scripts/cash-skills/tests/skill-checks.fish` 驗證。

- [ ] 3.2 對 `scripts/cash-skills/variant-parity/` 之下 cash-propose、cash-drift、cash-ingest、cash-analyze、cash-verify、cash-ask 六份 manifest 重跑正規化 diff：對實際產生變動者更新為逐行反映任務 2.1 至 2.5 之後的實際差異，對未變動者確認其逐位元組不變。cash-propose 與 cash-drift 的既有 hunk 皆位於本次編輯點之前或之後，預期不變，但仍須以重跑確認而非假設；cash-analyze 與 cash-verify 的 fork 段落必須由逐字替換形式改為新增區塊形式。驗收：variant-parity 群組通過，以 `scripts/cash-skills/tests/skill-checks.fish` 驗證。

- [ ] 3.3 依 design 的 D7 與 C8，把 `cash-skills.version` 提升為實作當下該檔值的下一個 minor（三段數字加單一換行），並同步更新 `scripts/cash-skills/tests/skill-checks.fish` 中 `assert_inventory` 的版本字面值斷言為相同的值。不硬編特定版本號，因為並行的 `harden-installer-mode-and-recovery` 也會更動同一行。不改動 installer 的版本比較邏輯與 receipt schema。驗收：canonical-inventory 群組通過，以 `scripts/cash-skills/tests/skill-checks.fish` 驗證。

- [ ] 3.4 每一次改動任一 replaceable runtime 檔之後、下一次執行任何 `.cash-skills/bin/cash` 指令之前，於 project root 執行 `./install-cash-skills.fish --self` 重建 `.cash-skills/receipt.tsv`；此步驟可重複執行，且最後一次重建 MUST 在任務 3.3 的版本提升之後、任何回歸執行之前。理由：launcher 每次執行都逐檔比對 receipt 記錄的 runtime digest，任一 runtime 檔改動而未重建 receipt，`.cash-skills/bin/cash` 即全面以 `receipt_invalid: runtime record drift` 與 exit 1 失敗——包含 cash-apply 自身用來標記 checkbox 的 `task done`、`touched ensure` 與 `instructions apply`。因此重建不能只排在版本提升之後：任務 1.1 一落地就必須先重建一次，否則任務 1.1 至 3.3 之間的 14 個任務都無法標記完成。版本提升不是重建的前提（launcher 的 `validate_receipt` 只檢查版本字串格式、不比對 `cash-skills.version`，版本未提升時 `--self` 亦可成功）。receipt 為 gitignore 檔，不列入 affected code。驗收：每次重建後 `.cash-skills/bin/cash validate --all` 須 exit 0；本任務的驗證載具是該指令本身的 exit code，並由任務 4.6 的第三步再次確認。

## 4. 驗證覆蓋

- [ ] 4.1 [P] 在 `scripts/cash-cli/tests/test_lexical_search.py` 補上覆蓋任務 1.1 至 1.4 的案例。涉及 stdout 逐位元組相同與 exit code 的案例必須先以 `install-cash-skills.fish --target <tmpdir>` 把 launcher 與 runtime 安裝進臨時 workspace，再以 subprocess 呼叫該臨時 workspace 內的 `.cash-skills/bin/cash`，而非只呼叫 `search_payload`，也不得直接呼叫 repo 自身的 launcher——launcher 由自身路徑推導 `CASH_PROJECT_ROOT`，對臨時 workspace 會以 `workspace_root_mismatch` 失敗。subprocess MUST 以 `cwd` 指向該臨時 workspace 呼叫：launcher root 與由 cwd 解析出的 git root 兩者任一不符都會以 `workspace_root_mismatch` 失敗，因此 cwd 未設時即使呼叫臨時 launcher 也會得到同一個錯誤碼。既有可循的先例是 `scripts/cash-cli/tests/test_negative_atomicity.py` 的 launcher 測試，其每個 subprocess 呼叫都帶 `cwd`。案例須含：旗標前置與後置回傳相同 stdout、零個與兩個位置參數與未知 `--` 旗標三種 `invalid_arguments`、單一連字號開頭的 query 可用、`--limit` 缺席採預設值、`--limit` 的缺值與非整數與越界三種 `invalid_limit` 且缺值與不合法兩類 message 不同、三個 `--scope` 值各自的路徑集合、`invalid_scope`、封存 `reviews` 下的非 UTF-8 檔不影響 `active` 與 `specs`、以及缺少 `openspec/specs/` 時 `--scope specs` 回空且 exit 0——此案例 MUST 在其專屬的臨時 workspace 執行，且 MUST 在建立 fixture 之後先移除 `openspec/specs/` 目錄再執行——該目錄是本測試檔的 workspace fixture 為建立 master spec 而造出的（installer 本身不建立它），不移除則測到的是空目錄而非缺目錄，斷言會在未覆蓋目標條件的情況下綠燈；用專屬 workspace 是為了避免移除動作連帶清掉其他 scope 案例所需的 master spec。測試 workspace 必須同時建立 master spec、非封存 change、封存 change 的 `proposal.md` 與封存 change 的 `reviews/` 檔案。驗收：以 `scripts/cash-cli/tests/test_lexical_search.py` 驗證。

- [ ] 4.2 [P] 在 `scripts/cash-cli/tests/test_analyze_drift.py` 把既有第 109 行的 `startswith("$cash-")` 斷言替換為「不含 `$` 且不含 `/`」的斷言（是替換而非新增，否則既有斷言會與任務 1.5 相反而必定紅燈），並補上 `light`、`medium`、`heavy` 三個 severity 各自對應正確 skill 名稱的案例。驗收：以 `scripts/cash-cli/tests/test_analyze_drift.py` 驗證。

- [ ] 4.3 [P] 在 `scripts/cash-cli/tests/test_graph_instructions.py` 補上覆蓋任務 1.6 的案例：斷言 proposal 的 `template` 依序含七個段落標題、含 `### New Capabilities` 與 `### Modified Capabilities`、含 `- Affected specs:` 與 `- Affected code:` 及其下的 `New`／`Modified`／`Removed` 三個標籤列（斷言須含每個標籤後接冒號的形狀），且兩次讀取逐位元組相同。驗收：以 `scripts/cash-cli/tests/test_graph_instructions.py` 驗證。

- [ ] 4.4 依 design 的 C9，在 `scripts/cash-skills/tests/skill-checks.fish` 新增一個名為 `well-formedness` 的測試群組承載獨立於 variant-parity 的良構斷言，並把該群組同時加入 `case all` 的呼叫序列。斷言內容共五項：對 24 個 canonical `SKILL.md` 以「同一行中長度恰為 2 的反引號 run 出現奇數次」為判準檢查不存在空 code span（此判準使雙反引號跳脫因成對而為偶數、三反引號 fence 因 run 長度為 3 而不計入，皆不誤判）、對 `.agents` 底下 12 個 `SKILL.md` 只解析 frontmatter 區塊檢查不含三個 key、對兩個 cash-propose 變體檢查不含五個已移除的段落標題字面值、對兩個 cash-drift 變體檢查不含 `copy-pasteable`、對 `.agents/skills/cash-ingest/SKILL.md` 依 D8 的否定式檢查全檔不含 `~/.claude/plans/` 或任何其他目錄前綴字面值。驗收：以 `scripts/cash-skills/tests/skill-checks.fish` 驗證。

- [ ] 4.5 驗證任務 4.4 的斷言確實被執行：在任一 canonical `SKILL.md` 注入一個空 code span、在任一 `.agents` `SKILL.md` 注入一個 `disallowedTools` key，確認 `well-formedness` 群組與全量執行路徑皆非零結束，並確認含雙反引號跳脫與 code fence 的既有檔案不被誤判；驗證後還原注入。驗收：以 `scripts/cash-skills/tests/skill-checks.fish` 驗證。

- [ ] 4.6 執行完整回歸並確認全綠：先執行 `scripts/cash-cli/tests/cli-checks.fish`，再執行 `scripts/cash-skills/tests/skill-checks.fish`，最後執行 `.cash-skills/bin/cash validate --all`，三者皆須 exit 0。任務 1.1 至 3.3 所涉的全部檔案 MUST 在同一個 commit 落地，因為 bundle 版本歷史契約要求版本升級與 runtime 及 SKILL.md 異動落在同一個 first-parent commit；提交後再執行一次 skill 套件確認版本歷史契約在 `current == head` 路徑下通過。驗收：以 `scripts/cash-cli/tests/cli-checks.fish` 與 `scripts/cash-skills/tests/skill-checks.fish` 驗證。

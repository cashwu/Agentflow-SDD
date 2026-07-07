## Context

add-review-loop-discipline 已把 plus review loop 的裁判不可改規則、loop ledger、signal-derived check 確定性執行寫進模板與 master specs。該 change 的 propose-r3 review 留下數個降級 Suggestion：declared-scope exception 會被順帶提到的路徑誤觸發、exit 1 分流在自指涉模板 change 中可能同時命中 MUST fix 與 MUST NOT fix、completion summary 沒有明確落點、以及 check failure 的 in-scope / pre-existing 判定缺少程序。

這次 change 只處理這些邊界規則的文字與測試錨點，不改 plus loop 的核心架構。

## Goals / Non-Goals

**Goals:**

- 讓 protected grader path 的 scope exception 只由結構化範圍宣告觸發，不被驗證命令、規則描述、範例或 review context 中的路徑誤觸發。
- 讓 deterministic signal-derived check 的 exit 1 分流互斥，避免 scope 內修改檔與 protected grader path 同時產生相反義務。
- 為 check failure 的位置判定提供可操作程序，缺乏位置資訊時 fail closed。
- 為 unfixed-due-to-grader-protection records 定義具體 workflow completion output 錨點。
- 補強 signal check authoring guidance，避免管線、盲目反轉與原生 exit 1 工具折疊執行錯誤。

**Non-Goals:**

- 不改變 round decision、confidence filter、micro round、loop ledger 或 signals write step 的收錄門檻。
- 不新增自動產生 signal check 的能力。
- 不改既有 signal status/check 欄位的人工作業治理。
- 不處理 add-review-loop-discipline propose-r3 中 confidence 50 的其他文字建議，除非它們是 completion output 或 check authoring guidance 的直接支援文字。

## Decisions

### Decision 1: Structured scope declarations control grader exceptions

Declared-scope exception 應只由 proposal ## Impact 的 affected-code entries 與 tasks.md 中明確作為交付標的的路徑觸發。單純在驗證步驟、命令、規則描述、範例或 finding context 中出現同一個路徑，不代表該 protected grader file 被授權修改。

替代方案是保留任何 artifact 中逐字出現路徑即授權。這太寬，會讓 tasks.md 為了描述規則而提到 openspec/specs/ 時意外解鎖 master specs，因此拒絕。

### Decision 2: Exit 1 check handling uses mutually exclusive branches

Signal check exit 1 的處理順序應先判斷 detected instance / fix location 是否落在本 change 範圍，再判斷是否被未覆蓋的 grader protection 阻擋。若 protected grader path 已被 structured scope declarations 覆蓋，就不能再用 grader protection 阻止修復；若未被覆蓋，則必須記錄範圍外 check 失敗而不修改。

這讓自指涉模板 change 的 review-loop-block.md 可以在 scope 內被修復，同時仍保護 scope 外的 grader surface。

### Decision 3: Check scope classification is path-based and fail-closed

check 命令只能用 exit code 表達存在與否，因此 scope 判定需要額外程序。新規則要求 main agent 優先使用 check output 中的 project-root-relative path 與本 change 的 artifact/source file set 做交集；有交集即視為 scope 內。若 check 沒有輸出可定位路徑，或輸出無法可靠對應到 project-root-relative path，則 fail closed，視為 scope 內問題，除非 agent 能以已讀取的 repository state 明確證明它是 pre-existing 或 fix location 在 scope 外。

這保留既有 pre-existing escape hatch，但把舉證責任放在要跳過修復的一方。

### Decision 4: Completion output anchors are named by skill and outcome

unfixed-due-to-grader-protection records 不應依賴模糊的 completion summary 詞彙。模板需要點名：propose-plus passed 時列在 final summary；apply-plus passed 時列在 gate 後最終回覆；任何 aborted outcome 則列在 unresolved-findings warning。這些都是 user-visible workflow completion output。

### Decision 5: README guidance covers location output and shell error traps

signals README 應明確建議新寫的 check 在偵測到 anti-pattern 時輸出 project-root-relative path，讓 review loop 能判定 scope。README 也應警告 POSIX sh 沒有 pipefail，管線只回傳最後一段命令的 exit code；若使用 grep 以外原生 exit 1 代表錯誤的工具，作者必須重新映射 exit code，維持 0 = absent、1 = present、其他 = execution error。

### Decision 6: Canonical check example emits paths

signals shared layer 的權威 `check` 範例必須與 README guidance 同步。既有 quiet `grep -rq` 範例雖然有正確的 exit-code remapping，但不輸出任何 path；在 fail-closed 規則下，照抄該範例會讓可定位的既有問題也難以被判為範圍外。因此範例應改成會輸出 project-root-relative paths 的 pattern，例如使用 recursive grep 的 filename output，並保留 explicit exit-code remapping 與不寫檔的唯讀特性。

## Implementation Contract

- Template behavior: scripts/spectra-plus/template/review-loop-block.md 的 GRADER-IMMUTABILITY 區塊必須定義 structured scope declarations，並明確排除驗證命令、規則描述、範例與 finding context 中的路徑。
- Template behavior: Signal-derived checks 的 exit 1 分流必須使用互斥語意，只有未被 declared-scope exception 覆蓋的 protected grader path 才走不得修復分支。
- Template behavior: Signal-derived checks 必須定義 path-based scope classification；check output 中命中的 project-root-relative path 與本 change artifact/source file set 有交集時視為 scope 內，無法定位時 fail closed。
- Template behavior: GRADER-IMMUTABILITY 區塊必須定義 workflow completion output anchors，分別覆蓋 propose-plus passed、apply-plus passed 與 aborted outcomes。
- README behavior: openspec/signals/README.md 必須說明 check authoring 應優先輸出 project-root-relative paths，並說明 POSIX sh pipeline、blind negation、原生 exit 1 錯誤碼的處理規則。
- Spec example behavior: signals shared layer 的 canonical `check` example 必須輸出命中的 project-root-relative paths，且使用不寫檔的 explicit exit-code remapping，避免 quiet check 範例與 fail-closed scope 判定衝突。
- Generated output: 執行 scripts/spectra-plus/generate.fish 後，四個 generated plus skill 檔必須包含上述模板文字，不得手改 generated files。
- Verification: scripts/spectra-plus/tests/generator-checks.fish 必須新增或調整 assertions，確認 structured scope declarations、mutually exclusive protected path 分流、fail-closed scope 判定、completion output anchors 與 README guidance 的關鍵文字存在。
- Scope boundary: 本 change 不修改 scripts/spectra-plus/rules.yaml，也不新增 signal check 欄位。

## Risks / Trade-offs

- [Risk] structured scope declarations 的定義太窄，可能讓真正需要修改的 protected file 被判為未授權。→ Mitigation：proposal ## Impact 與 tasks.md 的交付標的仍可明確列入；模板檔列入時仍連帶允許四份 generated outputs。
- [Risk] fail closed 會讓缺乏位置輸出的 check 更容易阻擋 loop。→ Mitigation：README 要求新 check 優先輸出 project-root-relative paths，且 pre-existing / out-of-scope 仍可由已讀 repository state 明確證明後跳過。
- [Risk] completion output anchors 只改善 agent workflow wording，不是機器可驗證的 runtime 行為。→ Mitigation：用 generator checks 固定模板文字，讓生成技能維持一致。

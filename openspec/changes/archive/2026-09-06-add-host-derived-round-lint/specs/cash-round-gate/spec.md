## ADDED Requirements

### Requirement: Round gate 只採納 host-derived 事實

系統 SHALL 提供唯讀 command `lint-round`，其判定所依據的事實只能來自三類來源：`openspec/changes/<change>/` 下的 artifacts 與 round files、Git 的 worktree 與 index 狀態，以及 command 自身內建的常數。command MUST NOT 接受任何以 CLI argument、環境變數、standard input 或 context 檔案形式傳入、且其內容即為待驗命題的輸入。缺少此限制時，受審的 main agent 可藉由供應或省略輸入單方面決定判定結果，gate 即退化為裝飾。command 對描述待驗事實的額外位置參數 MUST 以既有 `unknown_command` 或 `invalid_arguments` error code 與統一 JSON 錯誤 shape 失敗，MUST NOT 靜默忽略。command MUST 為唯讀：比較範圍為排除 `.git/` 的 tracked 與 untracked 工作區內容、mode 與存在狀態，執行前後 MUST 逐位元組不變，且 MUST NOT 建立目錄。在 receipt-based target 上，比較範圍 MUST 另外排除 bytecode cache 產物（`__pycache__/` 目錄與 `*.pyc` 檔案），且該排除 MUST 同時適用於「逐位元組不變」與「不建立目錄」兩項。launcher 僅在 portable 分支設 `sys.dont_write_bytecode = True`，receipt-based target 的 bytecode 寫入發生在 import system、早於 handler 執行，command 無從阻止，而本 change 不修改 launcher。只豁免「不寫入 bytecode cache」而不同時把該產物排出比較範圍是無效的——`__pycache__` 本身就是工作區內新建的 untracked 目錄，仍會違反其餘兩項，豁免形同未生效。`.git/index` 的 stat-cache 因呼叫 git 而刷新 MUST NOT 視為違反；不排除 `.git/` 會使此標準機械上不可驗證。

#### Scenario: 拒絕描述待驗事實的參數

- **WHEN** caller 以額外位置參數傳入描述 round 判定結果的值
- **THEN** command 以 `unknown_command` 或 `invalid_arguments` error code 與統一 JSON 錯誤 shape 失敗
- **AND** command 不將該值納入任何 gate 的判定

#### Scenario: 執行後工作區不變

- **GIVEN** 一個具備 round files 的 active change
- **AND** 該 target 為 portable-manifest target
- **WHEN** 執行 `.cash-skills/bin/cash lint-round <change> --json`
- **AND** 比較執行前後排除 `.git/` 的工作區
- **THEN** 沒有任何檔案內容、mode 或存在狀態改變
- **AND** 沒有產生 `__pycache__`

#### Scenario: receipt-based target 排除 bytecode cache 後仍逐位元組不變

- **GIVEN** 一個具備 round files 的 active change
- **AND** 該 target 為 receipt-based target
- **WHEN** 執行 `.cash-skills/bin/cash lint-round <change> --json`
- **AND** 比較執行前後排除 `.git/`、`__pycache__/` 與 `*.pyc` 的工作區
- **THEN** 沒有任何檔案內容、mode 或存在狀態改變
- **AND** 該 target 上新產生的 `__pycache__` 不使判定失敗

### Requirement: Round file 辨識與 run 邊界導出

系統 SHALL 只把 `openspec/changes/<change>/reviews/` 下檔名符合 `<skill>-r<N>.md` 的檔案視為 round file，其中 `<skill>` 恰為 `propose` 或 `apply`，`<N>` 為無前導零的十進位正整數。不符該樣式的檔案 MUST NOT 納入任何 gate；同目錄下的 `loop-ledger.tsv` 與 `accepted-risks.md` 不具備 round file 的 section，若被納入會使阻擋型 hook 在每個 turn 失敗。

`propose` 與 `apply` MUST 視為兩個各自從 `r1` 起算的獨立序列；排序、run 邊界導出與活動判定 MUST 逐 skill 進行，MUST NOT 跨 skill 取單一最高編號。

系統 SHALL 從 round file 序列自行導出 run 邊界，MUST NOT 依賴 `loop-ledger.tsv`。對某個 skill 的序列依 `<N>` 排序後，第 N 輪開啟新 run 當且僅當 N 是該序列最小編號，或第 N-1 輪的 `## Decision` 值是 `passed` 或 `aborted`。第 N-1 輪的 `## Decision` 值無法解析時，run 邊界不可導出，該 skill 序列自第 N 輪起每一輪的 `round_type_position` MUST 判 `fail` 並指向第 N-1 輪，MUST NOT 把不可解析視同終結值或視同 `next_round`。序列的最小編號 MUST 為 `1`，且 MUST 自該編號起連續；缺少起始編號或出現缺號時 MUST 判定為失敗。位置推導完全由檔案集合決定，刪去 round file 會使其後各輪重新對齊而通過；只要求「自該序列最小編號起連續」攔不住刪除前綴——刪掉 `r1` 至 `r3` 後，`r4` 起的序列仍自其最小編號連續，`r4` 反被判為新 run 的第一輪，正好完成刪檔者要的重新對齊。既有規則保證合法歷史中每個 skill 序列必含 `r1`。

系統 SHALL 以該位置推導判定每個 round file 記錄的 `round_type` 是否正確：run 的第一輪 MUST 是 `full`；run 第一輪之後的每一輪，當且僅當它是該 run 的第四輪時 MUST 是 `full`，否則 MUST 是 `micro`。該 iff MUST 只作用於第一輪之後的輪；寫成無條件形式會與「第一輪 MUST 是 `full`」直接矛盾。`round_type` 的值 MUST 以下列規則擷取：取 `## Rating` section 內去除 bullet 標記、backtick 與前後空白後以 `round_type` 開頭的 bullet，取其冒號（半形 `:` 或全形 `：`）之後、去除 backtick 與空白的 token；符合條件的 bullet 不恰為一筆時 MUST 判 `fail`。實際 round file 的形狀是 `` - `round_type`：`micro` ``，擷取規則不涵蓋 backtick 與全形冒號會使全部合規的 round file 判 `fail`。`## Rating` 缺少 `round_type` 欄位或其值不在 `full`／`micro` 值域內時，MUST 歸入無法解析而回報 `fail`。此推導不使用 ledger，因此不受 ledger 缺少 run 識別欄位、`(skill, round)` 非唯一鍵與 re-run 列同檔累積的限制。

#### Scenario: abort 後的 re-run 重新起算位置

- **GIVEN** round file 序列的第 3 輪 `## Decision` 為 `aborted`，且存在第 4、5、6、7 輪
- **WHEN** 執行 round gate
- **THEN** 第 4 輪被判定為新 run 的第一輪且 `round_type` MUST 是 `full`
- **AND** 第 7 輪被判定為該 run 的第四輪且 `round_type` MUST 是 `full`
- **AND** 第 5、6 輪的 `round_type` MUST 是 `micro`

#### Scenario: round type 與位置推導不符

- **GIVEN** 某 run 的第二輪 round file 記錄 `round_type` 為 `full`
- **WHEN** 執行 round gate
- **THEN** `round_type_position` gate 的狀態是 `fail`
- **AND** 失敗說明指出該 round file 與導出的位置

#### Scenario: 非 round file 不納入判定

- **GIVEN** `reviews/` 下同時存在 `propose-r1.md`、`loop-ledger.tsv` 與 `accepted-risks.md`
- **WHEN** 執行 round gate
- **THEN** 只有 `propose-r1.md` 納入 `round_file_schema` 判定
- **AND** `loop-ledger.tsv` 與 `accepted-risks.md` 不使任何 gate 失敗

#### Scenario: 兩個 skill 的序列各自起算

- **GIVEN** `reviews/` 下存在 `propose-r1.md`、`propose-r2.md` 與 `apply-r1.md`
- **WHEN** 執行 round gate
- **THEN** `apply-r1.md` 被判定為 apply 序列中新 run 的第一輪且 `round_type` MUST 是 `full`
- **AND** 它不因 propose 序列已有兩輪而被推導為第三輪

#### Scenario: 序列缺少起始編號

- **GIVEN** 某 skill 的 round file 序列為 `r4`、`r5`
- **WHEN** 執行 round gate
- **THEN** `round_type_position` gate 的狀態是 `fail`
- **AND** 失敗說明指出缺少的起始編號

#### Scenario: 編號缺號

- **GIVEN** 某 skill 的 round file 序列為 `r1`、`r2`、`r4`
- **WHEN** 執行 round gate
- **THEN** `round_type_position` gate 的狀態是 `fail`
- **AND** 失敗說明指出缺少的編號

#### Scenario: round_type 以 backtick 與全形冒號記錄仍可解析

- **GIVEN** 某 round file 的 `## Rating` 含 bullet `` - `round_type`：`micro` ``
- **AND** 位置推導導出該輪應為 `micro`
- **WHEN** 執行 round gate
- **THEN** `round_type_position` gate 的狀態是 `pass`

#### Scenario: Rating 缺少 round_type

- **GIVEN** 某 round file 的 `## Rating` 沒有 `round_type` 欄位
- **WHEN** 執行 round gate
- **THEN** `round_type_position` gate 的狀態是 `fail`

### Requirement: 迴圈活動狀態逐 skill 判定

系統 SHALL 對每個 skill 各自取其最高編號 round file，並判定某個 change 的 review loop 為 active，當且僅當**任一** skill 的最高編號 round file `## Decision` 值為 `next_round`。MUST NOT 跨 skill 取單一最高編號：`propose-r3` 為 `passed` 而 `apply-r1` 為 `next_round` 時，跨 skill 最高編號者是 `propose-r3`，會使僅在 active 時適用的 gate 在整個 cash-apply loop 期間 `skip`，而該階段正是最會改動受保護裁判面的階段。`passed` 與 `aborted` MUST 都視為終結值。

檢查對象的列舉 MUST 逐字對齊既有 CLI `discovery.py` 的列舉規則：`openspec/changes/` 下排除 `archive` 與 `.parked` 兩個保留目錄名後、且為目錄型項目、且名稱符合 `[a-z][a-z0-9-]*` 的 change，加上 `openspec/changes/.parked/` 下同樣條件的 parked change。非目錄項目與名稱不符樣式的項目 MUST NOT 被列舉，也 MUST NOT 使判定進入 fail-open。只排除 `archive` 會把 `.parked` 本身當成 change 列舉，並使 parked change 的 round files 完全不受檢，`cash park` 即成為逃逸口。

parked change MUST 納入列舉以接受結構類 gate 判定，但 MUST NOT 計入 active 判定：parked change 的最高編號 round file 常永久停在 `next_round`，計入會使 repository 長期處於 active，而使僅在 active 時適用的 gate 對完全不在 review loop 的 session 持續生效。僅在 active 時適用的 gate 在非 active 時 MUST 回報狀態 `skip` 而非 `pass`，使「未檢查」與「已檢查且通過」在輸出中可區分。

#### Scenario: 迴圈已終結時跳過活動期 gate

- **GIVEN** 每個 skill 的最高編號 round file `## Decision` 都是 `passed` 或 `aborted`
- **WHEN** 執行 round gate
- **THEN** `grader_immutability` gate 的狀態是 `skip`

#### Scenario: 另一個 skill 的迴圈仍進行中

- **GIVEN** `propose-r3.md` 的 `## Decision` 為 `passed`
- **AND** `apply-r1.md` 的 `## Decision` 為 `next_round`
- **WHEN** 執行 round gate
- **THEN** 該 change 判定為 active
- **AND** `grader_immutability` gate 的狀態 MUST NOT 是 `skip`

#### Scenario: parked change 不使判定為 active

- **GIVEN** 唯一具備 round file 的 change 位於 `openspec/changes/.parked/` 且其最高編號 round file `## Decision` 為 `next_round`
- **WHEN** 執行 round gate
- **THEN** 該 change MUST NOT 判定為 active
- **AND** `grader_immutability` gate 的狀態是 `skip`

#### Scenario: parked change 仍受檢

- **GIVEN** 某個 change 位於 `openspec/changes/.parked/` 且其最高編號 round file `## Decision` 為 `next_round`
- **WHEN** Stop hook 執行列舉
- **THEN** 該 parked change 納入判定
- **AND** `.parked` 本身不被當成一個 change 列舉

#### Scenario: 沒有 round file 不是錯誤

- **GIVEN** change 目錄下不存在 `reviews/` 或其中沒有 round file
- **WHEN** 執行 round gate
- **THEN** 全部 gate 的狀態都是 `skip`
- **AND** 整體判定為通過

#### Scenario: 非目錄項目不被列舉為 change

- **GIVEN** `openspec/changes/` 下存在一個非目錄項目（例如 `.DS_Store`）
- **WHEN** 執行 `lint-round --hook`
- **THEN** 該項目不被列舉為 change
- **AND** 判定不進入 fail-open

### Requirement: Round file 結構判定

系統 SHALL 對每個 round file 驗證其具備 `## Reviewer Findings`、`## Rating`、`## Fix Actions` 與 `## Decision` 四個 section，且 `## Decision` 的值恰為 `passed`、`next_round`、`aborted` 三者之一。

`## Decision` 的值 MUST 以下列規則擷取：取該 section 內第一個非空行，去除 backtick 與前後空白後與值域比對。該值之後的 rationale 段落 MUST NOT 使 gate 失敗——既有 `Round 檔案輸出合約` 本就要求記一段 rationale，把整個 section body 當成值會使全部合規的 round file 判 `fail`，而阻擋型 hook 會因此在啟用當天對每個無關 turn exit `2`。

round file 無法解析時，對應 gate MUST 回報 `fail` 並指出該檔案，MUST NOT 以例外中止整個判定，其餘 gate MUST 仍回報各自結果。

#### Scenario: 缺少 section

- **GIVEN** 某 round file 沒有 `## Fix Actions` section
- **WHEN** 執行 round gate
- **THEN** `round_file_schema` gate 的狀態是 `fail`
- **AND** 失敗說明指出該檔案與缺少的 section

#### Scenario: Decision 值不在值域內

- **GIVEN** 某 round file 的 `## Decision` 值不是 `passed`、`next_round` 或 `aborted`
- **WHEN** 執行 round gate
- **THEN** `decision_value` gate 的狀態是 `fail`

#### Scenario: Decision 值之後的 rationale 段落不使 gate 失敗

- **GIVEN** 某 round file 的 `## Decision` section 為一行 backtick 包裹的 `next_round`，其後接一段 rationale 段落
- **WHEN** 執行 round gate
- **THEN** `decision_value` gate 的狀態是 `pass`

#### Scenario: round file 無法解析

- **GIVEN** 某個檔名符合 `<skill>-r<N>.md` 的檔案內容為空或不可解析
- **WHEN** 執行 round gate
- **THEN** `round_file_schema` gate 的狀態是 `fail` 並指出該檔案
- **AND** 判定不以例外中止，其餘 gate 仍回報各自結果

### Requirement: Grader immutability 以三方比對判定

系統 SHALL 在迴圈 active 時，把內建的受保護裁判面路徑集合、Git 導出的變更集合，以及全部未封存且未 parked 的被列舉 change 的 structured scope declarations 聯集三者比對。受保護路徑集合 MUST 逐字對應 `審查迴圈的 grader 不可變性` requirement 所列的**路徑**成分，其中 `openspec/specs/` MUST 視為目錄型宣告而涵蓋其下全部 master spec 檔案。該 requirement 另有一條判定粒度為欄位、且明文不接受 declared-scope 例外的保護（`openspec/signals/` 下 signal 的 `check` frontmatter），其形狀無法以路徑集合比對表達，本 requirement MUST NOT 主張涵蓋它。變更集合 MUST 取自 Git，涵蓋工作區相對 `HEAD` 的改動——包含已 `git add` 的 staged 改動——與 untracked 檔案；只取 unstaged 改動會使 `git add` 成為旁路。structured scope declarations MUST 只取自 proposal `## Impact` 的 affected-code 條目與 `tasks.md` 中明確標示為 delivery target 的路徑；出現在驗證指令、規則描述、範例、審查發現或其他附帶散文中的路徑 MUST NOT 計入。目錄型宣告 MUST 涵蓋其下全部檔案。系統 MUST 逐檔解析 `proposal.md` 與 `tasks.md`：缺少的檔案只貢獻該份的空宣告集合，存在的檔案仍 MUST 貢獻其可解析宣告；兩份皆缺少時才貢獻空聯集，MUST NOT 因缺檔拋出例外——`--hook` mode 會列舉到 artifacts 尚未寫齊的 change 目錄，拋出例外會使整批進入 fail-open，讓 gate 每個 turn 都以 `gate_unavailable` fail open 而不可用。

變更集合是 repository 全域而宣告是 per-change 的。涵蓋判定在 single-change mode 與 `--hook` mode 都 MUST 取聯集——single-change mode 的位置參數只決定回報哪個 change 的 round files 與 active 狀態，MUST NOT 把宣告來源縮小為該 change，否則同一工作區狀態會出現 hook 判 pass 而 single-change 判 fail 的分歧——且聯集來源 MUST 限於未封存且未 parked 的被列舉 change，MUST NOT 因來源 change 的最高 round 為 `passed` 或 `aborted` 而移除其宣告。A 合法修改受保護檔案、A 完成 `passed` 但未提交、B 仍 active 時，A 的宣告仍須涵蓋該改動。已封存或 parked change 的宣告不計入；來源完全不設限時，任何一個無關 change 目錄的 `## Impact` 都能永久解除全部判定。受保護路徑只要被任一未封存且未 parked 的被列舉 change 的 structured scope declaration 涵蓋即 MUST NOT 判 `fail`。逐 change 各自比對會使一個 change 合法宣告的改動在另一個 change 的比對中判為未宣告，而 `--hook` mode 非重入時任一 change fail 即以 exit `2` 阻擋，因此會對合法工作產生每個 turn 的偽陽性。受保護路徑出現在變更集合而未被該聯集涵蓋時，gate MUST 回報 `fail`。

#### Scenario: 未宣告即修改受保護路徑

- **GIVEN** 迴圈 active 且 `scripts/cash-skills/blocks/review-gate.md` 有未提交的改動
- **AND** 該路徑未出現在 proposal `## Impact` 或 `tasks.md` 的 delivery target
- **WHEN** 執行 round gate
- **THEN** `grader_immutability` gate 的狀態是 `fail`
- **AND** 失敗說明指出該受保護路徑

#### Scenario: 已宣告的受保護路徑不觸發失敗

- **GIVEN** 迴圈 active 且 `.claude/skills/cash-apply/SKILL.md` 有未提交的改動
- **AND** 該路徑出現在 proposal `## Impact` 的 affected-code 條目
- **WHEN** 執行 round gate
- **THEN** `grader_immutability` gate 的狀態是 `pass`

#### Scenario: 僅由 tasks.md delivery target 宣告亦成立

- **GIVEN** 迴圈 active 且某受保護路徑有未提交的改動
- **AND** 該路徑只出現在 `tasks.md` 某個 task 的 delivery target，未出現在 proposal `## Impact`
- **WHEN** 執行 round gate
- **THEN** `grader_immutability` gate 的狀態是 `pass`

#### Scenario: 半成品 change 目錄不使判定中止

- **GIVEN** `--hook` mode 列舉到一個只有 `proposal.md`、尚無 `tasks.md` 的 change 目錄
- **WHEN** 執行 round gate
- **THEN** 缺少的 `tasks.md` 貢獻空集合，存在的 proposal `## Impact` 宣告仍被解析
- **AND** 判定不進入 fail-open，其餘 change 仍逐一判定

#### Scenario: 目錄型宣告涵蓋其下檔案

- **GIVEN** 迴圈 active 且 `openspec/specs/cash-cli/spec.md` 有未提交的改動
- **AND** proposal `## Impact` 的 affected-code 條目宣告了 `openspec/specs/`
- **WHEN** 執行 round gate
- **THEN** `grader_immutability` gate 的狀態是 `pass`

#### Scenario: 未宣告即修改 master spec

- **GIVEN** 迴圈 active 且 `openspec/specs/cash-cli/spec.md` 有未提交的改動
- **AND** 沒有任何被列舉 change 宣告 `openspec/specs/` 或該檔案路徑
- **WHEN** 執行 round gate
- **THEN** `grader_immutability` gate 的狀態是 `fail`

#### Scenario: parked 或已封存 change 的宣告不解除判定

- **GIVEN** 某 active change 正在受檢且某受保護路徑有未提交的改動
- **AND** 該路徑只被 parked 或已封存的 change 宣告
- **WHEN** 執行 round gate
- **THEN** active change 的 `grader_immutability` gate 狀態是 `fail`
- **AND** parked 與已封存 change 的宣告不計入聯集

#### Scenario: 另一個 change 的宣告涵蓋該路徑

- **GIVEN** `--hook` mode 同時列舉 change A 與 change B 且兩者皆 active
- **AND** 某受保護路徑有未提交的改動且只出現在 change A 的 proposal `## Impact`
- **WHEN** 執行 round gate
- **THEN** change B 的 `grader_immutability` gate MUST NOT 因該路徑判 `fail`

#### Scenario: 已 staged 的受保護路徑仍在變更集合內

- **GIVEN** 迴圈 active 且某受保護路徑的改動已 `git add` 但未 commit
- **AND** 該路徑未出現在 proposal `## Impact` 或 `tasks.md` 的 delivery target
- **WHEN** 執行 round gate
- **THEN** `grader_immutability` gate 的狀態是 `fail`

#### Scenario: 散文中的路徑不構成宣告

- **GIVEN** 迴圈 active 且某受保護路徑有未提交的改動
- **AND** 該路徑只出現在 `design.md` 的規則描述中，未出現在 proposal `## Impact` 或 `tasks.md` 的 delivery target
- **WHEN** 執行 round gate
- **THEN** `grader_immutability` gate 的狀態是 `fail`

#### Scenario: 已完成來源 change 的宣告仍涵蓋 active change

- **GIVEN** change A 的最高 round `## Decision` 為 `passed` 或 `aborted` 且 A 尚未封存或 parked
- **AND** change B 的最高 round `## Decision` 為 `next_round`
- **AND** A 的 structured scope declaration 涵蓋某受保護路徑，該路徑有未提交改動
- **WHEN** 執行 B 的 single-change gate 或 `--hook`
- **THEN** A 的宣告計入聯集，該路徑不因 B 的判定而被視為未宣告

#### Scenario: 半成品只缺一份宣告來源時保留另一份

- **GIVEN** 被列舉 change 缺少 `proposal.md` 但存在 `tasks.md` 且含 delivery target
- **WHEN** 執行 round gate
- **THEN** proposal 貢獻空宣告集合
- **AND** tasks.md 的 delivery target 仍貢獻其可解析宣告

#### Scenario: 缺少 tasks 時保留 proposal 宣告

- **GIVEN** 被列舉 change 存在 `proposal.md` 但缺少 `tasks.md`
- **WHEN** 執行 round gate
- **THEN** proposal `## Impact` 的宣告仍被解析
- **AND** 缺少的 tasks.md 貢獻空宣告集合

### Requirement: Stop hook 自行判定對象並在失敗時阻擋

系統 SHALL 在 `.claude/settings.json` 的 `Stop` 事件下提供一筆 command hook。hook MUST 自行從磁碟依 `迴圈活動狀態逐 skill 判定` requirement 的列舉規則決定檢查對象，MUST NOT 從 main agent 取得 change 名稱或任何判定輸入。任一 change 判定失敗時 hook MUST 以 exit `2` 結束並將失敗項輸出至 standard error（`stop_hook_active` 為真時除外，見下段）。hook 在 `lint_round.py` 進入點之後可攔截的基礎設施錯誤——workspace 解析失敗、輸入 JSON 解析失敗，以及任何未預期例外——MUST fail open 以 exit `1` 結束，使 referee 的缺陷不會使 session 無法結束。exit code 語意依 host 實際行為：exit `0` 時 standard error 不顯示，exit `2` 阻擋，其餘非零 exit 非阻擋且 standard error 顯示給使用者；因此 fail-open 分支 MUST NOT 以 exit `0` 結束，否則診斷形同靜默。進入點之前的失敗——`.cash-skills/bin/cash` 缺席或不可執行、launcher 信任 gate 失敗、Python 版本不足——不在 command 可控範圍內，本 requirement MUST NOT 對其提出 exit code 或 `gate_unavailable` 義務；它們在 host 上均為非 `2` 的非零 exit，非阻擋且 standard error 可見。

系統 MUST NOT 要求 hook mode 自帶取鎖時間上限：launcher 取得 `flock` 早於 manifest 驗證與 runtime import，而本 requirement 不修改 launcher，因此 command 內的逾時機制涵蓋不到該段阻塞。時間上限改由 host 承擔——`.claude/settings.json` 的 hook 條目 MUST 宣告 host 層的 `timeout`。該上限觸發時 hook 由 host 終止，其結束方式不由本 gate 的 exit code 控制，也不輸出 `gate_unavailable`。進入點之後的每個 fail-open 分支 MUST 以 exit `1` 結束並向 standard error 輸出可辨識的 `gate_unavailable` 診斷並指出原因，MUST NOT 靜默通過；靜默會使「gate 未執行」與「gate 執行且通過」無法區分，而 gate 自身的檔案不在受保護路徑集合內。輸入 JSON 的 `stop_hook_active` 為真時 hook MUST 仍執行判定；當次存在未解決失敗項時 MUST 將**當次**未解決的失敗項輸出至 standard error 後以 exit `1` 結束——非阻擋且可見——避免修正回合再次被攔而形成迴圈；當次無失敗項時 MUST 以 exit `0` 結束；無 `--json` 時無輸出，帶 `--json` 時仍 MUST 依 `lint-round 輸出與結束碼` requirement 輸出 JSON。該輸出義務 MUST 以當次判定為準：command 不產生任何由自身控制的寫入，沒有可保存前次判定結果的 host-derived 管道，因此 MUST NOT 要求輸出上一次判定的失敗項。此短路使阻擋語意的實效上限為「阻擋一次並列出失敗項」。

#### Scenario: 判定失敗時阻擋

- **GIVEN** 某個 active change 的 round gate 判定為失敗且 `stop_hook_active` 為 `false`
- **WHEN** Stop hook 以未帶 `--json` 的 `lint-round --hook` 執行
- **THEN** hook 以 exit `2` 結束
- **AND** standard error 含該失敗 gate 的 `id` 與說明

#### Scenario: 無 round file 時靜默通過

- **GIVEN** 全部被列舉的 change 都沒有 round file
- **WHEN** Stop hook 以未帶 `--json` 的 `lint-round --hook` 執行
- **THEN** hook 以 exit `0` 結束
- **AND** 沒有任何輸出

#### Scenario: 基礎設施錯誤 fail open 且留下可見診斷

- **GIVEN** standard input 的 Stop hook JSON payload 無法解析
- **WHEN** 執行 `lint-round --hook`
- **THEN** command 以 exit `1` 結束
- **AND** standard error 含 `gate_unavailable` 診斷與原因
- **AND** command 不以 exit `0` 結束

#### Scenario: hook 條目宣告 host 層 timeout

- **GIVEN** `.claude/settings.json` 的 `Stop` 事件下存在該 command hook 條目
- **WHEN** 檢視該條目
- **THEN** 條目宣告了 host 層的 `timeout`
- **AND** command 本身不實作取鎖時間上限

#### Scenario: 重入時仍執行判定後放行

- **GIVEN** 輸入 JSON 的 `stop_hook_active` 為 `true`
- **AND** 當次判定存在未解決的失敗項
- **WHEN** Stop hook 以未帶 `--json` 的 `lint-round --hook` 執行
- **THEN** hook 以 exit `1` 結束而非 exit `2`
- **AND** standard error 列出當次判定仍未解決的失敗項

#### Scenario: 重入時無失敗項則靜默放行

- **GIVEN** 輸入 JSON 的 `stop_hook_active` 為 `true`
- **AND** 當次判定沒有未解決的失敗項
- **WHEN** Stop hook 以未帶 `--json` 的 `lint-round --hook` 執行
- **THEN** hook 以 exit `0` 結束
- **AND** 沒有任何輸出

### Requirement: lint-round 輸出與結束碼

系統 SHALL 依以下契約輸出判定。正常完成判定時，`--json` MUST 將單一 JSON object 輸出至 stdout：`ok` 為 boolean，當且僅當沒有 check 為 `fail` 時為 `true`；`checks` 為陣列，每筆含 `id`、`status`（`pass`／`fail`／`skip`）與 `detail`。single-change object 另 MUST 含 `change`；hook mode 每筆 check 另 MUST 含所屬 `change`。重入放行 MUST NOT 把實際失敗的 `ok` 改成 `true`。

| 呼叫與判定 | stdout | stderr | exit code |
| --- | --- | --- | --- |
| single-change 通過 | 人可讀 checks；帶 `--json` 時為 JSON object | 空 | `0` |
| single-change gate 失敗 | 人可讀 checks；帶 `--json` 時為 JSON object | 空 | `2` |
| hook 通過，包含重入 | 無 `--json` 時空；帶旗標時為 JSON object | 空 | `0` |
| hook gate 失敗，`stop_hook_active: false` | 無 `--json` 時空；帶旗標時為 JSON object | 當次失敗 gate 的 `id` 與說明 | `2` |
| hook gate 失敗，`stop_hook_active: true` | 無 `--json` 時空；帶旗標時為 JSON object | 當次失敗 gate 的 `id` 與說明 | `1` |
| hook 進入點後的基礎設施錯誤 | 空，包含帶 `--json` 時 | `gate_unavailable` 與原因 | `1` |

以上輸出與 exit code MUST 遵守表格；hook 的通過靜默規則只適用於未帶 `--json` 的呼叫。single-change 的參數錯誤、`change_not_found` 與基礎設施錯誤 MUST 維持既有統一 JSON error shape 與 error exit code，MUST NOT 冒充已完成判定的 checks；`gate_unavailable` fail-open 語意只適用於 hook mode。launcher 進入點之前的錯誤維持既有信任 gate 契約。

#### Scenario: single-change 通過與失敗均輸出 checks

- **GIVEN** 指定 change 的判定正常完成
- **WHEN** 執行 `cash lint-round <change>` 或 `cash lint-round <change> --json`
- **THEN** stdout 分別為人可讀 checks 或含 `change`、`ok`、`checks` 的單一 JSON object，stderr 為空
- **AND** 通過時 exit `0`，至少一項 gate 失敗時 exit `2`

#### Scenario: JSON hook 首次判定保留診斷

- **GIVEN** `stop_hook_active` 為 `false` 且判定正常完成
- **WHEN** 執行 `cash lint-round --hook --json`
- **THEN** stdout 為單一 JSON object，checks 各含所屬 `change`
- **AND** 通過時 exit `0` 且 stderr 為空；失敗時 exit `2` 且 stderr 含當次失敗 gate

#### Scenario: JSON hook 重入失敗仍呈現真實判定

- **GIVEN** `stop_hook_active` 為 `true` 且當次有 gate 失敗
- **WHEN** 執行 `cash lint-round --hook --json`
- **THEN** exit code 為 `1`，stdout 為 `ok: false` 的 JSON object
- **AND** stderr 列出當次未解決失敗項

#### Scenario: JSON hook 重入通過仍輸出 JSON

- **GIVEN** `stop_hook_active` 為 `true` 且當次全部 gate 為 `pass` 或 `skip`
- **WHEN** 執行 `cash lint-round --hook --json`
- **THEN** exit code 為 `0`，stdout 為 `ok: true` 的 JSON object，stderr 為空

#### Scenario: JSON hook 基礎設施錯誤不輸出虛構 checks

- **GIVEN** standard input 不是合法 JSON payload
- **WHEN** 執行 `cash lint-round --hook --json`
- **THEN** exit code 為 `1`，stdout 為空，stderr 含 `gate_unavailable` 與原因

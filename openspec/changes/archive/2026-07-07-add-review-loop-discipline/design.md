## Context

Spectra Plus 的 review loop 定義集中在共享模板 scripts/spectra-plus/template/review-loop-block.md，由 scripts/spectra-plus/generate.fish 依 scripts/spectra-plus/rules.yaml 注入 spectra-propose-plus 與 spectra-apply-plus 兩個 skill 的 Claude 與 Codex 變體（共 4 個生成檔）。生成內容的驗證斷言集中在 scripts/spectra-plus/tests/generator-checks.fish，既有慣例是以唯一 sentinel 註解（如 `<!-- MECHANICAL-SELF-CHECK -->`、`<!-- SIGNALS-WRITE-STEP -->`）標記模板區塊並在測試中斷言其存在。

signals 共享層的 schema 定義在 `signals-shared-layer` master spec 與 openspec/signals/README.md：frontmatter 目前恰好包含 `id`、`type`、`status`、`occurrences`、`first_seen`、`last_seen`、`links` 七個欄位。mechanical self-check 的「Signal-derived checks」目前要求 agent 以 best-effort 判斷 open signal 是否描述 machine-checkable anti-pattern 並「執行對應檢查」，但沒有結構化欄位，檢查內容與是否執行完全取決於 agent 當下的解讀。

本 change 對照 AutoResearch loop（裁判 prepare.py 不可改、results.tsv 軌跡）與 Bilevel Autoresearch（外層以結構化方式改變內層搜尋）的紀律設計，補齊三個缺口。

## Goals / Non-Goals

**Goals:**

- Review loop 的 fix action 有明文、可判定的「裁判面禁改」規則，防止為通過 gate 而修改 review 流程定義本身。
- 每個 change 的 review loop 產生一份緊湊、機器可讀的軌跡檔（loop ledger），供後續 meta 分析。
- Signal schema 支援選填的確定性檢查欄位 `check`，讓 Signal-derived checks 從 best-effort 判斷升級為確定性執行。

**Non-Goals:**

- 不改變 round file 的四段結構、機械決策規則、confidence filter、6 輪上限與 micro/full 推導 — 這些既有契約全部維持原樣。
- 不引入自動回退（git reset / candidate patch）機制；keep/discard 紀律留待未來 change。
- 不新增 rules.yaml transformation 或新模板檔 — 三項變更全部落在既有共享模板 review-loop-block.md 的內容內，經既有 transformation 注入；唯一 `rules.yaml` 變更限於收斂既有 Codex slash-command substitution，避免 literal protected paths 被誤改。
- 不自動轉換既有 signal 的 status，也不回填既有 signal 的 `check` 欄位。
- loop-ledger.tsv 不做跨 change 彙總（每 change 一份，隨 change 目錄歸檔）。

## Decisions

### Decision 1: GRADER-IMMUTABILITY 規則以路徑集加範圍例外定義

在 review-loop-block.md 的 Fix actions 段落新增以 `<!-- GRADER-IMMUTABILITY -->` sentinel 標記的規則。規則約束 loop 進行中主 agent 的所有修改（含 fix action 與 mechanical self-check 修復 — self-check 修復發生在 round file 之前，若不涵蓋會留下規則外的行為者）。裁判面保護路徑集（protected path set）明確列舉為：

- scripts/spectra-plus/template/ 下的所有檔案
- scripts/spectra-plus/rules.yaml
- scripts/spectra-plus/generate.fish
- 生成的 plus skill 檔案：.claude/skills/spectra-propose-plus/SKILL.md、.claude/skills/spectra-apply-plus/SKILL.md、.agents/skills/spectra-propose-plus/SKILL.md、.agents/skills/spectra-apply-plus/SKILL.md
- .spectra.yaml
- openspec/specs/ 下的 master spec 檔案（reviewers 據以審 delta 的「法源」；loop 中改它可以讓 adherence finding 憑空消解）

除路徑集外，主 agent 也不得增加、修改或刪除 `openspec/signals/` 下任何 signal 的 `check` 欄位，**此禁令一律生效、不受下述範圍例外影響** — `check` 是 self-check 的裁判輸入（Decision 3），若 loop 中可改寫它，等於讓 agent 把考題改簡單，會抵銷本 change 自身引入的紀律。

**例外**：當保護路徑集中的某檔案本身被此 change 的 proposal `## Impact` 或 tasks.md 明文列入修改範圍（自指涉 change，例如本 change 自己就修改 review-loop-block.md），fix action 可以修改它；此時該修改仍受既有 re-derivation 規則約束（行為變更 → 下一輪強制 full）。「明文列入」的判定規則：檔案的專案根目錄相對路徑逐字出現即為列入；列入某目錄路徑視同列入其下所有檔案。範圍列入某模板檔時，其重生成產物（四個生成的 plus skill 檔）視同一併列入 — 修模板必須重生成，否則產物過期會違反冪等性與測試契約。範圍內修改模板並重生成時，進行中的 loop 仍依其啟動時的規則版本執行完畢，重生成的指令自下一次 loop 啟動才生效（避免自指涉版本混亂）。

**與既有母 spec 的優先序**：母 spec `spectra-propose-plus quality gate` 與 `spectra-apply-plus quality gate` 兩個 requirement 的場景要求「fixes the … findings before starting the next round」；裁判保護規則是其明文例外（被保護而未修復的 finding 記錄後保持存活）。delta 以 MODIFIED 修改該兩個 requirement 的對應場景來定義優先序，不靠隱含解讀（對應 open signal `spec-precedence-exception-missing`）。

**違規處理**：若某 finding 的修復必須修改範圍外的保護路徑，fix action 不得執行該修改；在 `## Fix Actions` 記錄「未修復：裁判面保護」與原因，該 finding 保持存活。若因此 loop 走到第 6 輪仍不過，依既有規則 `decision: aborted` — fail loud 是預期行為，由人決定是否另開 change 修改裁判面。輪次是無記憶的（每輪決策只看該輪 fresh reviewers 的過濾後 findings），後續輪的 reviewers 可能不再發現同一問題而讓 loop 通過 — 因此無論最終 decision 為何，workflow 完成摘要必須列出 loop 全部輪次的「未修復：裁判面保護」記錄，確保已知未修復缺陷不會靜默消失。

**理由與替代方案**：曾考慮以「意圖」定義（禁止「為了過 gate 而改裁判」）但意圖不可機械判定，路徑集才可判定（對應 open signal `source-sensitive-scope-mismatch` 的教訓：保護集必須與設計意圖精確一致）。曾考慮把 scripts/spectra-plus/tests/ 也列入保護集，但測試檔是 apply-plus change 的常見合法實作標的，靠「Impact/tasks 範圍例外」不足以涵蓋所有測試修改情境（TDD 中途新增測試），故不列入；測試的品質由 Reviewer B 把關。同理不列入 install-spectra-plus.fish 與 scripts/spectra-plus/repair-all.fish — 它們是部署/修復驅動器而非評分規則本身，且是 plus 基礎設施 change 的常見合法標的。

### Decision 2: LOOP-LEDGER-STEP 在每輪 round file 定稿後追加一行 TSV

在 review-loop-block.md 新增以 `<!-- LOOP-LEDGER-STEP -->` sentinel 標記的步驟，向 `openspec/changes/<change>/reviews/loop-ledger.tsv` 追加一行。**追加時點**（確定性定義，避免 `## Fix Actions` 事後補記造成低估）：`next_round` 輪在該輪全部 fix actions、fix 後 self-check 記錄、validation 重跑的修復記錄與可能的 re-derivation 註記都寫入 round file 之後、spawn 下一輪 reviewers 之前追加（「spawn 前」為最終錨點，任何會補寫 `## Fix Actions` 的動作都必須先完成）；最終輪（`passed` 或 `aborted`）在 loop 結束時、signals write step 之前追加。檔案不存在時先寫入表頭行 — 表頭內容釘死為七個欄位名依序以 tab 分隔：`skill	round	round_type	criticals	warnings	decision	fixed_files`。欄位（tab 分隔）：

| 欄位 | 值 |
| ---- | -- |
| `skill` | `propose` 或 `apply` |
| `round` | 1 起算的輪次整數 |
| `round_type` | `full` 或 `micro` |
| `criticals` | 過濾後存活 Critical 數（無過濾後 finding 時為 0，含 sub-agent 失敗導致的 aborted 輪） |
| `warnings` | 過濾後存活 Warning 數（同上，無則為 0） |
| `decision` | `passed`、`next_round` 或 `aborted` |
| `fixed_files` | 該輪 `## Fix Actions` 記錄為已修改的相異檔案數（未記錄任何修改時為 0；退回註記等非修改行不計入） |

**重跑與跨迴圈語意**：ledger 是事件日誌（append-only），同一 change 的 propose 迴圈、apply 迴圈與 aborted 後重跑的迴圈依時間順序累加；`(skill, round)` 不是唯一鍵，重跑會出現重複的輪次編號，屬合法狀態。Round file 仍是完整權威記錄；ledger 只是彙總投影，兩者不一致時以 round file 為準。寫入失敗時印出警告但不使 plus workflow 失敗（與 signals write 相同的 failure handling）。選 TSV 而非 JSONL：欄位全是固定的短 scalar（enum 與整數），TSV 可直接用 awk/cut 分析，且無跳脫問題（欄位值不含 tab 與換行）。

### Decision 3: signal frontmatter 新增選填 check 欄位，self-check 確定性執行

`signals-shared-layer` 的 schema 從「恰好七個欄位」放寬為「七個必要欄位加選填 `check`」。`check` 的值是一條單行 shell 檢查命令，**由人工撰寫**，執行形式明定為從專案根目錄把 `check` 的值作為 `sh -c` 的單一命令字串參數傳入執行（不得把值內插進一段帶引號的 shell 字串 — 值本身常含引號，內插會產生引號不匹配的假性執行錯誤；也不依賴使用者的互動 shell，Claude 與 Codex runtime 行為一致）。exit code 慣例：`0` 代表通過（anti-pattern 不存在）、`1` 代表偵測到 anti-pattern、**其他任何 exit code（如 2、126、127）視為執行錯誤**，不視為偵測結果。

**治理**：`check` 欄位與 `status` 同屬人工維護 — 自動化寫入者（含 signals write step 與 review loop 的 fix action）不得增加、修改或刪除任何 signal 的 `check` 欄位。這防止兩個漏洞：loop 中把失敗的 check 改寬鬆以過 self-check，以及 signals write step 自行鑄造未經人審的 shell 命令供後續 run 自動執行。為此 review-loop-block.md 的 SIGNALS-WRITE-STEP 區塊同步修訂：schema 敘述行提及選填 `check` 欄位，且 update-in-place 規則明文要求保留既有 `check` 逐字節不動。

mechanical self-check 的「Signal-derived checks」項目改寫為兩層：

1. 對每個帶有 `check` 欄位的 open signal → **一律**以 `sh -c` 從專案根目錄執行該命令（不經 relevance 篩選 — 確定性檢查成本低，跳過篩選才能保證確定性）。exit `1` 為偵測到 anti-pattern：若偵測到的實例位於本 change 自己的 artifacts 或修改檔案內，須在 spawn reviewers 前修復；若實例是既有問題、或其修復落在 change 宣告範圍外或裁判保護路徑內，則**不修復**，在該輪 round file 的 `## Fix Actions` 記錄一行「範圍外 check 失敗」註記，並把該失敗的 check 結果納入該輪 reviewers 的 context 後照常 spawn（避免一個既有 anti-pattern 讓所有後續 loop 死鎖）。exit code 非 0 非 1（執行錯誤）→ 視同無 `check` 欄位退回第 2 層，並在該輪 round file 寫入時於 `## Fix Actions` 記錄一行退回原因（各種註記行與「None; pass condition met.」共存、不計入 `fixed_files`）。
2. 無 `check` 欄位（或退回）的 open signal → 維持現行 best-effort 判斷行為，完全不變。

openspec/signals/README.md 增記 `check` 欄位的語意、`sh -c` 單一參數執行形式、exit code 慣例（0/1/其他）與撰寫規則：命令必須唯讀（不得修改任何檔案）、快速、離線、非互動；偵測結果只以 0 或 1 回報，**可預見的執行錯誤（如路徑不存在）須讓它以其他 exit code 浮現，不得用 `!` 之類的盲目反轉把錯誤折疊成 0 或 1**（否則執行錯誤會被誤讀為通過）；並提醒 YAML 單行字串的引號與 `#` 截斷陷阱。**信任邊界**：signal 檔案是版本庫內容、`check` 為人工撰寫（同 `status` 治理）、與測試腳本同信任域，執行其 `check` 命令不引入新的信任問題；self-check 執行時命令內容對使用者可見。

**替代方案**：曾考慮 `check_pattern`（grep pattern，match 即違規）— 較安全但表達力不足（許多 anti-pattern 需要多檔案或計數比對）；shell 命令一條即可組合 grep/awk，且與 self-check 其他 grep 檢查的能力一致。曾考慮讓 signals write step 自動生成 `check` — 否決，理由見治理段。

## Implementation Contract

- **行為 1（裁判不可改）**：任一 plus review loop 進行中，主 agent（含 fix action 與 self-check 修復）修改的每個檔案，若屬於 Decision 1 的保護路徑集且未被該 change 的 proposal `## Impact` 或 tasks.md 明文列入（依「明文列入」判定規則），則該修改不得發生；任何 signal 的 `check` 欄位一律禁改；round file 的 `## Fix Actions` 出現「未修復：裁判面保護」記錄，該 finding 保持存活；完成摘要列出全部輪次的裁判保護記錄。生成的 4 個 plus skill 檔案都包含 `<!-- GRADER-IMMUTABILITY -->` sentinel 與保護路徑集全文。母 spec 兩個 quality gate requirement 經 delta MODIFIED：SHALL 段各加一句「Fix obligations … are subject to the grader-protection exception …」優先序句，且「fixes the … findings」場景帶有裁判保護例外字句。
- **行為 2（loop ledger）**：任一 plus review loop 的每一輪在 Decision 2 定義的追加時點後，`openspec/changes/<change>/reviews/loop-ledger.tsv` 存在且較追加前多恰好一行（首次建立時另含一行釘死的表頭）；每行欄位依 Decision 2 的表格順序；跨迴圈與重跑累加、`(skill, round)` 非唯一鍵。生成的 4 個 plus skill 檔案都包含 `<!-- LOOP-LEDGER-STEP -->` sentinel。ledger 寫入失敗只產生警告。
- **行為 3（signal check）**：`openspec/signals/<slug>.md` 的 frontmatter 允許選填、人工撰寫的 `check` 欄位；README 文件記載其語意與撰寫規則。plus skill 的 mechanical self-check 文字包含「帶 `check` 的 open signal 一律以 `sh -c` 單一參數執行、exit 1 且實例在 change 範圍內為須修復失敗、exit 1 但實例範圍外則記錄註記並納入 reviewers context、exit 非 0 非 1 退回 best-effort 並記錄註記」的兩層規則；SIGNALS-WRITE-STEP 區塊提及 `check` 且 update-in-place 保留既有 `check` 逐字節不動；自動化寫入者不得增改刪 `check`。
- **驗收方式**：
  - `scripts/spectra-plus/generate.fish` 全量重生成後 exit 0，且 4 個生成檔各包含 `<!-- GRADER-IMMUTABILITY -->` 與 `<!-- LOOP-LEDGER-STEP -->`。
  - `scripts/spectra-plus/tests/generator-checks.fish` 新增上述兩個 sentinel 的 assert_contains 斷言（比照既有 `<!-- MECHANICAL-SELF-CHECK -->` 斷言寫法），且全部測試通過。
  - openspec/signals/README.md 包含 `check` 欄位段落。
  - 連續兩次重生成 byte-identical（既有冪等性契約不被破壞）。
- **範圍邊界**：in scope = review-loop-block.md 內容、README.md、generator-checks.fish 斷言、重生成產物、scripts/spectra-plus/rules.yaml 中既有 Codex `/spectra-` substitution 的窄化；out of scope = generate.fish 程式邏輯、rules.yaml 結構與新增 transformation、spectra CLI、既有 signal 檔案內容、任何自動回退機制。

## Risks / Trade-offs

- [自指涉例外被濫用：change 把裁判檔塞進 Impact 就能改裁判] → 例外要求「明文列入 proposal Impact 或 tasks.md」，而這兩者正是 Reviewer A 的 adherence 審查對象；濫用會被審為 scope 問題。人仍是最終 gate（archive 前人工決策）。
- [`check` 命令執行任意 shell] → `check` 為人工撰寫（自動化寫入者禁止增改刪）、信任域與版本庫內測試腳本相同；README 要求唯讀、快速、離線、非互動；self-check 執行時命令內容對使用者可見。不新增沙箱（超出本 change 範圍）。
- [`check` 命令懸掛或依賴網路，阻塞每輪 self-check] → README 撰寫規則要求快速、離線、非互動；違反者屬 signal 品質問題，人工修正該 signal。
- [ledger 與 round file 不一致] → 明文規定 round file 為權威、ledger 為投影；ledger 寫入失敗不中斷 workflow。
- [保護路徑集過窄（漏保護）或過寬（擋住合法修復）] → 對應 `source-sensitive-scope-mismatch` signal；Decision 1 逐檔列舉並記錄了不列入 tests/ 的理由，未來偏差可經 signals 回饋修正。
- [review-loop-block.md 越長，生成 skill 的指令負擔越重] → 兩個新 sentinel 區塊（GRADER-IMMUTABILITY、LOOP-LEDGER-STEP）加上既有 MECHANICAL-SELF-CHECK 與 SIGNALS-WRITE-STEP 區塊內的改寫，合計約 40 行，相對現有模板約 145 行為可控增量；新區塊有 sentinel 便於日後拆分。

## Migration Plan

1. 修改 review-loop-block.md（兩個新 sentinel 區塊、MECHANICAL-SELF-CHECK 區塊內的 Signal-derived checks 改寫、SIGNALS-WRITE-STEP 區塊的 `check` 保留修訂）與 openspec/signals/README.md。
2. 執行 scripts/spectra-plus/generate.fish 重生成 4 個 plus skill 檔。
3. 更新並執行 scripts/spectra-plus/tests/generator-checks.fish。
4. 回滾策略：還原模板與 README 後重新執行生成器即可（生成物是純衍生物，無狀態遷移）。既有 change 的 reviews/ 目錄不受影響；舊 change 沒有 loop-ledger.tsv 是合法狀態。

## Open Questions

（無 — 三項決策的替代方案均已在 Decisions 內評估並收斂。）

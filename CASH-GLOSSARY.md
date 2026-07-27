# Cash Glossary

Cash skill 系統的核心詞彙。每個詞條有三部分：**定義**說明它是什麼、**關係**指向相關詞條、**avoid** 列出不應使用的近義寫法。修訂 skill 內文時以本表用語為準。

## change

**定義**：一次成組的意圖變更，是 Cash 工作流程的基本單位。live change 位於 `openspec/changes/<name>/`，內含該次變更的全部 artifacts。change 有名稱、狀態（active、parked、archived）與 schema（例如 `spec-driven`）。

**關係**：一個 change 包含多個 [artifact](#artifact)；實作阻塞時可能被 [park](#parked)；完成後 archive 到 `openspec/changes/archive/`。change 的觸及檔案記錄在 [touched state](#touched-state)。

**avoid**：不要寫成 ticket、issue、feature、branch、PR 或「需求單」。這些指向 change 以外的追蹤系統，Cash 不與它們同義。

## artifact

**定義**：change 目錄下由 schema 定義、有固定 `outputPath` 的產出檔案，例如 `proposal.md`、`design.md`、`specs/**/spec.md`、`tasks.md`。artifact 的存在與相依關係由 Cash CLI 的 schema 宣告，`"$cash_cli" status` 逐項回報其 `status` 與 `missingDeps`。

**關係**：artifact 屬於某個 [change](#change)；`design.md` 內含 [contract](#contract)；`tasks.md` 的 checkbox 是實作進度的唯一來源。master spec（`openspec/specs/`）不是 artifact，而是 archive 時由 spec delta 併入的權威文件。

**avoid**：不要寫成 document、file、deliverable 或「文件」泛稱。artifact 特指 schema 宣告的那組檔案，泛稱會把 `implementation-notes.md`、round file 等非 schema 檔一併混入。

## contract

**定義**：`design.md` 的 `## Implementation Contract` 段落，逐條列出本次變更要交付的可觀察行為、interface 或資料形狀、失敗模式、驗收標準與範圍邊界。它是跨 session 的持久交接面：無論由誰接手實作，成果都以 contract 逐條衡量。

**關係**：contract 寫在 `design.md` 這個 [artifact](#artifact) 裡，由 `tasks.md` 的各條任務分頭實現；[deviation](#deviation) 是相對於 contract 的偏離；review loop 的 Reviewer A 以 contract 為對照基準。

**avoid**：不要寫成 spec、requirement、acceptance criteria 或「規格」。`spec.md` 的 requirement／scenario 是能力層級的長期規格，contract 是本次 change 的實作交接面，兩者範圍與生命週期不同。

## deviation

**定義**：實作刻意偏離 `spec.md`、`design.md` 或 `tasks.md` 的一次記錄，寫在 `implementation-notes.md`，`類別：deviation`。適用情形是原設計指定的達成手段在目標平台或現實不可行，但要交付的觀察行為、interface、失敗模式與驗收標準都不變。

**關係**：deviation 記在 `implementation-notes.md`；判定邊界是 [contract](#contract) 是否改變——contract 不變記 deviation 後繼續，contract 改變則成為 [blocker](#blocker) 並導向 `cash-ingest`。未在 `design.md` 回填的 deviation 至少是一個 Warning finding。

**avoid**：不要寫成 workaround、hack、compromise、tradeoff 或「權宜之計」。這些詞暗示品質妥協；deviation 是手段替換的正式記錄，且必須附原因。也不要用來記錄與 artifacts 相符的一般實作判斷。

## blocker

**定義**：使 task loop 無法在不改變 [contract](#contract) 的前提下繼續的阻塞。判準是阻塞是否改變要交付的觀察行為、範圍或使用者可見的取捨，或替代手段是否需要 `a synchronization primitive, identity/generation type, or state machine not defined in design.md`。

**關係**：blocker 與 [deviation](#deviation) 互斥——同一個阻塞只會落入其中一邊。blocker 使 `cash-apply` 暫停並引導使用者前往 `cash-ingest`；在 review loop 的修正階段，同一個判準以 fix-loop design circuit breaker 的形式出現，觸發 `decision: aborted`。

**avoid**：不要寫成 issue、problem、obstacle 或「卡住」。blocker 是有明確判準與明確處置（暫停並導向 ingest）的分類結果，不是任何困難的泛稱。

## touched state

**定義**：Cash CLI 為每個 change 維護的觸及檔案清單，記錄該 change 修改過哪些 change 目錄以外的專案檔案。以 `"$cash_cli" touched ensure` 建立、`"$cash_cli" touched record --path` 逐條追加。

**關係**：touched state 屬於某個 [change](#change)；`cash-commit` 以它作為 commit 的 source allowlist。archive 會刪除 touched state，因此 `cash-archive` 單獨執行後 `cash-commit` 只能退回 archive manifest 的時間點快照。

**avoid**：不要寫成 changed files、staging area、index 或「暫存區」。這些是 git 概念；touched state 是 Cash 自有記錄，不隨 git 狀態變動。

## parked

**定義**：change 的一種狀態，表示暫時擱置但未放棄。parked change 不出現在 `"$cash_cli" list` 的預設輸出，需以 `--parked` 列出，並可用 `"$cash_cli" unpark` 恢復。

**關係**：parked 是 [change](#change) 的狀態之一，與 active、archived 並列。`cash-apply` 在選定 change 後必須確認它是否 parked，並在使用者同意後才 unpark 並繼續。

**avoid**：不要寫成 paused、on hold、frozen、deferred 或「暫停」。「暫停」在 Cash 已指 task loop 遇到 [blocker](#blocker) 時的行為，與 change 狀態不同層。

## signal

**定義**：`openspec/signals/` 下的一個檔案，記錄一類跨 change 重複出現的 review finding。frontmatter 含 `id`（= slug）、`type`、`status`、`occurrences`、`first_seen`、`last_seen`、`links` 與選填的人工撰寫 `check`。slug 是語意化的 issue-class 識別碼，不是 `location + summary` 的機械轉換。

**關係**：signal 由 review loop 結束後的 signals write step 產生或更新，來源是任一 [round](#round) 中通過 confidence filter 且為 Critical／Warning 的 finding。`status` 與 `check` 由人維護，自動 writer 不得變更；`check` 是每輪前機械自我檢查的 grader 輸入。

**avoid**：不要寫成 finding、warning、lesson、note 或「經驗」。finding 是單一輪次的觀察，signal 是跨 change 去重後的 issue class；兩者的生命週期與去重鍵不同。

## round

**定義**：sub-agent review／rating／fix loop 的一次完整迭代，產出一個 round file（`openspec/changes/<change>/reviews/<skill>-r<N>.md`）。型別為 `full`（兩個平行 reviewer）或 `micro`（單一驗證 reviewer），由該輪在本次執行中的位置推導。每次執行最多 6 輪。

**關係**：round 的決策只由 [cumulative blocking set](#cumulative-blocking-set) 推導；每輪結束後在 `loop-ledger.tsv` 追加一列。已完成的 round file 在迴圈進行中不可變更，是決策的 gate input。

**avoid**：不要寫成 iteration、pass、cycle、attempt 或「回合」。round 有固定的檔案 schema、型別規則與計數上限，泛稱會失去這些約束。

## cumulative blocking set

**定義**：跨整個迴圈執行維護的阻斷性 finding 集合。每個阻斷性 finding 在被發現的那一輪加入；即使後續 reviewer 未再回報，成員仍留在集合內，只能經「已驗證解決」或「已同意的 accepted risk」兩條路離開。

**關係**：round 的 pass／`next_round`／`aborted` 決策只看 confidence filter 之後的 cumulative blocking set；`critical_gap` 為 `true` 若且唯若該集合含 Critical。abort 時 bucket 1 即未被同意接受的集合成員，用於 seed 後續 re-run。

**avoid**：不要寫成 open issues、backlog、outstanding findings 或「未解決清單」。這些不帶「只能經兩條指定路徑離開」的語意，會讓成員被靜默移除。

## accepted risk

**定義**：使用者在當前 session 明確同意接受的缺陷，記錄於 `openspec/changes/<change>/reviews/accepted-risks.md`，每筆含 `severity`、`location`、缺陷機制、接受理由與日期。

**關係**：accepted risk 是 [cumulative blocking set](#cumulative-blocking-set) 成員離開的兩條路徑之一。命中的 finding 其 confidence 降至 ≤ 25 並記錄降級軌跡。此檔案是 gate input，迴圈不得以修正動作自行編輯；沒有明確同意就不寫入。

**avoid**：不要寫成 known issue、wontfix、tech debt、exception 或「已知問題」。這些不要求使用者明確同意，也不帶降級與記錄義務。

## variant

**定義**：同一個 cash skill 的兩種工具側呈現：Codex 側位於 `.agents/skills/cash-*/SKILL.md`（以 `$cash-*` 呼叫），Claude 側位於 `.claude/skills/cash-*/SKILL.md`（以 `/cash-*` 呼叫）。`.claude` 是人工維護的權威源頭，`.agents` 是由 `scripts/cash-skills/generate.fish` 依 `scripts/cash-skills/variant-rules.yaml` 產生的輸出。

**關係**：variant 差異分兩類——通用轉換規則（invocation 前綴置換、工具專屬 frontmatter 移除、fork 區塊移除）與在 `variant-rules.yaml` 具名登記的 per-skill entry。回歸套件以重新生成的 freshness 比對驗證一致性；另有一組不依賴該比對的良構斷言。

**avoid**：不要寫成 copy、duplicate、fork、mirror 或「副本」。這些暗示兩份對等的手工維護檔案，與「單一源頭加生成輸出」的模型相反。也不要把 `.agents` 稱為 canonical。

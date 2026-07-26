# Cash Propose Review — Round 1

兩位 full-round reviewers 獨立執行、未互相傳遞輸出。主 agent 已逐項獨立重跑驗證，不採信 reviewer 敘述。

## Reviewer Findings

### Critical

- **C1** `severity: Critical` / `confidence: 100` / `layer: design` / `location: specs/cash-cli/spec.md 全檔（MODIFIED `Atomic park、sync 與 archive`）` / reviewer: A
  - `summary`: delta 的 MODIFIED block 只重述 master requirement 的第一段，遺漏其餘段落與全部 8 個既有 Scenario；`_merge` 以整塊取代，sync 會直接從 master spec 刪除它們。
  - `recommendation`: 把 master 該 requirement 的完整內容逐 byte 補回 delta，再接上本 change 新增的段落與 Scenario。
  - 主 agent 驗證：master 該 requirement 109 行、8 個 Scenario；delta 58 行、0 個既有 Scenario。成立。

- **C2** `severity: Critical` / `confidence: 90` / `layer: design` / `location: design.md D4 與 Implementation Contract 5–6；.cash-skills/lib/cash_cli/spec_merge.py:280-297` / reviewer: B
  - `summary`: sync manifest 的 no-op 判定只涵蓋 delta spec digest，`proposal.md` 與 `tasks.md` 不在輸入指紋內；作者依診斷修好 proposal 後重跑 `sync` 會以 `already_synced` 返回，空 trace 無法收斂，且第二次執行的 gap 為空使診斷「自己消失」。
  - `recommendation`: 把 trace 的兩個輸入來源納入 sync manifest 的 no-op 判定，mismatch 時視為需要重新 merge 而非 fail closed。
  - 主 agent 驗證：`delta_digests` 僅由 `workspace.spec_files(...specs)` 產生，`build_sync_plan` 的 `already_synced` 分支不讀 proposal／tasks。成立。

### Warning

- **W1** `100` / `design` / `design.md D1 與 Risks；proposal.md Proposed Solution 第 1 點` / A — 「限定 ASCII 後零偽陽性」不成立：`runtime/install` 來自 `archive/2026-07-24-replace-spectra-cli-with-cash-cli/proposal.md:66` 的散文 `- Generated（runtime/install 產生，不進版控）:`，repo 中不存在該路徑。主 agent 驗證成立。
- **W2** `100` / `design` / `design.md D5；proposal.md Motivation 與 Alternatives Considered` / A — 「23 個空 `tests` 代表那些 change 本來就沒有驗證目標」不成立：23 個 trace 的 `source` 全為 `replace-spectra-cli-with-cash-cli`，其 tasks.md 有 13 行含 `cli-checks.fish`，但 `_VERIFICATION_CLAUSE` 在該檔定位到 0 個 clause（寫成 `以` 後無空白）。D5「診斷而非 fail closed」的論據失去支撐。主 agent 驗證成立。
- **W3** `100` / `design` / `proposal.md Motivation` / A — 引為動機的事故無法從 repo 稽核。主 agent 驗證：該事故確實發生，但修正與封存落在同一個 commit `ebfbe58`，故 git 中該 trace 為 code 3／tests 3。A 另指出兩個可稽核事故，主 agent 驗證成立：`Cash workflow command surface` code 5→0（`07254d7`）、`Cash guidance deployment` code 37→0（`6afc4ee`）。
- **W4** `100`（A）／`90`（B） / `design` / `tasks.md 3.3` / A+B（同一 location 與 summary，已合併） — 3.3 斷言 `code` 含 `## Impact` 宣告的四條路徑，但 `cash-skills.version` 不含斜線，`_paths_in_section` 的 `if "/" in value` 永遠濾掉它，該斷言必然失敗。主 agent 驗證成立。
- **W5** `95` / `design` / `specs/cash-cli/spec.md 診斷條款 對 design.md Implementation Contract 7 與 tasks.md 2.4` / A — delta 把診斷義務指派給 `installer`，但本 master spec 中 `installer` 專指 `install-cash-skills.fish`／`installer.py`，兩者不在 `## Impact`；實作位置是 `commands/archive.py` 的 `execute`。屬 normative scope overreach。主 agent 驗證成立。
- **W6** `95` / `design` / `tasks.md 1.1` / A — 1.1（b）被標為紅燈，但現行 `_paths_in_section` 對「同一路徑同時以 backtick 與純文字出現」已只回傳一次，實作前即為綠燈。主 agent 驗證成立。
- **W7** `90`（A）／`75`（B） / `design` / `specs/cash-cli/spec.md 診斷條款 對 tasks.md 1.4、1.5、2.4` / A+B（已合併） — delta 對 `execute` 層立了三條 MUST（JSON 與非 JSON 皆出現、不改 exit code、不成為 execution error），但全部 task 只斷言 `sync_change`／`archive_change` 回傳值的 gap 欄位，無任何一步觸及 `execute` 的 stderr 與 exit code。主 agent 驗證成立。
- **W8** `85` / `design` / `specs/cash-cli/spec.md 兩個診斷 Scenario 對 design.md Implementation Contract 6 與 tasks.md 1.5` / A — `archive` 未帶 `--skip-specs` 但 `plan.already_synced` 為真時，兩個 Scenario 互相牴觸且無 task 覆蓋。主 agent 驗證成立。
- **W9** `85` / `design` / `design.md D4 與 Implementation Contract 5–6；specs/cash-cli/spec.md 最後一個 Scenario` / B — 只含 `## REMOVED Requirements` 的 delta 會產生非空 `plan.writes`、`already_synced` 為 False、`skip_specs` 為 False，但 `_with_trace` 只在 MODIFIED／ADDED／RENAMED 分支被呼叫，trace 一次也沒寫入；此時仍會依欄位是否為空回報 gap，違反自訂的「不寫入 trace 的執行 MUST NOT 輸出該 diagnostic」。主 agent 驗證成立。
- **W10** `85` / `design` / `design.md D1／D5；proposal.md Proposed Solution 第 3 點` / B — D1 放寬後 `code` 幾乎不可能為空，使 D5 針對 `code` 的診斷實質不可觸發。主 agent 驗證：舊規則 `code` 為空 14/29 份，新規則 0/29 份；即使把抽取收斂到 `- Affected code:` 子清單仍為 0/29。另 `- Affected specs:` 的 spec 路徑被收進 `code`（12 份，收斂後 7 份）。成立。
- **W11** `80` / `design` / `proposal.md Non-Goals；design.md Risks 最後一則` / B — 「歷史 trace 由各自的 change 之後重新 sync 時自然收斂」對已封存 change 不成立：`workspace.change_path` 只解析 `openspec/changes/<name>`，封存後該名稱無法再 sync；且 `archive` 的診斷在 `transaction.commit()` 之後才輸出，作者當下已無法修正。主 agent 驗證成立。

### Suggestion

- **S1** `70` / `design` / `specs/cash-cli/spec.md canonical 形式句 對 Implementation Contract 2` / A — 「寫入 trace 的路徑 MUST 為剝除 `./` 後的 canonical 形式」未限定於 `tests`，但 contract 只為 `tests` 加剝除。
- **S2** `60` / `design` / `design.md Implementation Contract 6；commands/archive.py` / B — contract 要求「同一個 result dict 欄位名稱」，但 `sync_change` 用 snake_case、`archive_change` 用 camelCase，任一單一名稱都會破壞其中一邊慣例；屬 contract-level decision deferred to implementer。
- **S3** `60` / `design` / `proposal.md Impact；.claude/skills/cash-archive/SKILL.md` / B — 診斷寫到 stderr，但 cash-archive 的完成摘要是固定欄位樣板，警告可能不會被轉述給使用者。
- **S4** `55` / `design` / `specs/cash-cli/spec.md 保留句 對 新增句` / A — 同一 requirement 內定義漂移：保留句稱 `code` 取 affected-code paths，新增句規範為 `## Impact` 區段內全部路徑。
- **S5** `55` / `design` / `design.md D1／D3` / B — D3 為 `tests` 剝除 `./`，D1 新開放的 `code` 裸 token 沒有任何正規化。

信心過濾器：A 另有一項 `confidence: 40` 的 finding（tasks 2.3 的驗證為套套邏輯，直接建構 `SyncPlan` 無法驗證 `build_sync_plan` 的推導）低於 50 被完全捨棄，不列入上方。S1–S5 由 `[50, 80)` 降級為 `Suggestion`。

## Rating

- 過濾後累積 blocking 集合 Critical：2
- 過濾後累積 blocking 集合 Warning：11
- Non-blocking triaged findings：5
- `critical_gap`: `true`
- `round_type`: `full`

本輪為未 seed 執行的第一輪，因此每個存活的 `Critical` 與 `Warning` 都是 blocking，累積 blocking 集合為 13 個成員，不符合通過條件。兩個 Critical 各自獨立地使本變更無法達成其宣稱目的：C1 會在 sync 時從 master spec 刪除 8 個既有 Scenario；C2 使診斷指出的缺陷無法被作者收斂。11 個 Warning 中有 4 個（W1、W2、W3、W10）是 design 引用的量測數據或推論不成立，屬 `design-claim-unverified-against-code` 與 `enumerated-site-set-factually-wrong` 的形狀。

## Fix Actions

修改的檔案：`proposal.md`、`design.md`、`tasks.md`、`specs/cash-cli/spec.md`（4 個相異檔案）。

**C1（delta subset loss）** — 以程式方式自 master 逐 byte 取出該 requirement 的完整內容重建 delta：既有段落與 8 個既有 Scenario 逐 byte 保留（已機械驗證 `blk[:first] in delta` 與 `blk[first:] in delta` 皆為真），新增段落插入於既有段落之後、既有 Scenario 之前，新增 Scenario 附於末尾。delta 由 58 行／7 個 Scenario 變為 142 行／17 個 Scenario（既有 8 + 新增 9）。

**C2（manifest no-op 使診斷無法收斂）** — 新增 D6 與 Implementation Contract 7：sync manifest 增設 `trace_inputs` 欄位承載 `proposal.md` 與 `tasks.md` 的 digest，納入 `already_synced` 判定；不相符或欄位缺失時重新 merge 而非 fail closed，並明寫其失配語意 MUST 與 `delta_digests` 的 fail-closed 不同。delta spec 新增對應段落與 Scenario `trace 輸入改變使 sync 重新 merge`，tasks 新增 Red case 1.7 與實作 task 2.4。

**W1（零偽陽性宣稱不成立）** — D1 與 proposal 第 1 點改為誠實記載：72 個值中殘留 1 個 ASCII 散文偽陽性 `runtime/install`，並記錄接受它的理由（僅憑 token 形狀無法區分 ASCII 散文與路徑；再加副檔名或存在性條件會分別排除合法的目錄項與已刪除檔案的歷史項）。Risks 增列該項，tasks 3.4 明寫該偽陽性不視為失敗。

**W2（D5 論據不成立）** — 移除「23 個空 tests 代表合法無測試」的推論。改為記載其真實成因：23 個 trace 的 source 全為同一 change，其 tasks 的驗證子句寫成 `以` 後不接空白，`_VERIFICATION_CLAUSE` 在該檔定位到 0 個 clause。D5 的不 fail-closed 理由改建立在「doc-only 與 skills-only change 本來就可能沒有測試目標路徑」之上；並在 proposal `## Non-Goals` 與 design Non-Goals 明確排除 clause 定位缺陷，說明診斷會使其變成可見。

**W3（動機事故無法稽核）** — proposal `## Motivation` 改引兩個可從 history 稽核的事故：`Cash workflow command surface` 的 code 在 `07254d7` 由 5→0、`Cash guidance deployment` 的 code 在 `6afc4ee` 由 37→0（主 agent 已以 `git show` 逐一驗證）。附註：reviewer A 判定原引事故「不存在」，主 agent 驗證後更正為「確實發生，但修正與封存落在同一個 commit `ebfbe58`，因此無法從 repo 稽核」；採納其建議的理由是可稽核性，而非接受該事故不存在。

**W4（tasks 3.3 不可滿足）** — 3.3 改為斷言 `code` 恰為三條含斜線的 affected-code 路徑，並明寫 `cash-skills.version` 位於 repo root、不含斜線因而不入 `code`，此為預期而非缺陷。

**W5（normative scope overreach）** — delta 中的 `installer MUST輸出…` 改為 `sync`與`archive` MUST輸出…，使規範主體與 Implementation Contract 9 及 `## Impact` 宣告的 `.cash-skills/lib/cash_cli/commands/archive.py` 一致（已機械驗證 delta 不再含 `installer MUST輸出`）。

**W6（1.1(b) 誤標紅燈）** — 1.1 全面改為逐 case 標註【Red】或【護欄】，(b) 與 (c) 標為護欄；並在第 1 節前言明寫護欄 case 一開始就綠燈不得視為 task 未完成。1.2、1.3 比照辦理。

**W7（execute 層 MUST 無驗證）** — 新增 Red case 1.6：以捕獲 stdout／stderr 的方式對 `--json` 與非 `--json` 兩種 argv 呼叫 `execute("sync", ...)`，斷言兩種模式 stderr 皆有診斷、JSON stdout 仍可解析、回傳 0。Implementation Contract 9 對應加上「與 `--json` 無關地出現」與「不改變 exit code」。

**W8（archive 於 sync 後的情形 Scenario 互相牴觸）** — 改由 W9 的統一判定解決：Scenario `空 trace 欄位產生診斷但不阻斷` 的 WHEN 限定為「未帶 `--skip-specs` 且本次實際套用 trace」，Scenario `未套用 trace 的執行不輸出該診斷` 增列「`sync` 之後未帶 `--skip-specs` 的 `archive`」。tasks 1.5 新增 case (c)。

**W9（REMOVED-only delta 誤報 gap）** — 新增 D4：gap 判定改依「本次 merge 是否實際套用過 trace」，即 `delta.modified | delta.added | delta.renamed` 是否非空，不以列舉特例成立。Implementation Contract 6 對應改寫，delta spec 明寫該判定 MUST NOT 以列舉特例方式成立並列出 REMOVED-only 情形，tasks 1.5 新增 case (d)。

**W10（code 診斷不可觸發 + Affected specs 污染）** — 兩部分處理：抽取範圍收斂到 `- Affected code:` 子清單（Implementation Contract 3、delta 新增 Scenario `Affected specs 的路徑不進入 code trace`、tasks 1.1(d)）；並在 D5、proposal 第 3 點與 Risks 誠實重寫該診斷的定位為「未來形狀再度流失時的迴歸護欄」，明記收斂後 `code` 為空仍是 0/29，當前缺陷由 D1 直接消除。

**W11（自然收斂不成立）** — proposal `## Non-Goals` 改為事實陳述：`workspace.change_path` 只解析 `openspec/changes/<name>`，封存後不可再 sync；主 agent 驗證目前 8 個空 code trace 分屬 `track-review-loop-outputs-in-allowlist`(4)、`guard-post-archive-commit-allowlist`(3)、`tolerate-versioned-legacy-guidance-marker`(1) 三個已封存 change。另新增 D7 與 Implementation Contract 9，要求 `archive` 的診斷在 `transaction.commit()` 之前輸出。

**Suggestion 處置** — S1 與 S5 合併處理：新增 `_canonical_path` helper 供 `code` 與 `tests` 共用，delta 的 canonical 條款改為涵蓋兩個欄位（Implementation Contract 2、tasks 1.3(c)）。S4 由 W10 的範圍收斂自動解決：抽取範圍收斂後與保留句「`code` 取 proposal affected-code paths」一致，故保留句維持逐 byte 不動。S2 新增 D8：兩個 command 各自沿用既有 key 命名慣例（`trace_gaps` 與 `traceGaps`），以語意欄位而非字面名稱對齊。**S3 不採納**（triage note）：把 `.claude/skills/cash-archive/SKILL.md` 與 `.agents` 變體納入範圍會使本變更同時觸及 CLI 與 skill 兩層並帶來變體對等工作，超出「修抽取與加診斷」的宣告範圍；診斷已在 CLI 層可見，skill 轉述屬後續 change。

**信心過濾器捨棄的 finding** — reviewer A 另有一項 `confidence: 40`（tasks 2.3 的驗證為套套邏輯）低於 50 被捨棄，但主 agent 認同其技術內容，已於重寫時一併處理：2.3 的驗證改為以測試檔的 case 判定，不再以直接建構 `SyncPlan` 實例作為驗證。

**修正後機械式自我檢查** — 重跑並抓到一項：自 master 逐 byte 複製 Scenario 時把該 requirement 的 `<!-- @trace -->` footer 一併帶入 delta。已移除（移除後 delta 的 `<!--` 與 `-->` 計數皆為 0，8 個既有 Scenario 去 trace 後仍逐 byte 保留）。identifier cross-grep、delta 標題身分與計數一致性皆通過；有 `check` 欄位的 open signal 為 0 個。`"$cash_cli" validate` 於全部修正後重跑通過。

## Decision

next_round

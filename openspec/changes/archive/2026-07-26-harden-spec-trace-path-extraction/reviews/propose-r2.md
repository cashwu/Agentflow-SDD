# Cash Propose Review — Round 2

micro round，單一 Reviewer V 做差異驗證。主 agent 已對其裁定與 findings 獨立重跑驗證。

## Reviewer Findings

### 累積 blocking 集合裁定（13 位成員）

Reviewer V 對每位成員回傳明確裁定：**11 位 resolved、2 位 unresolved**。

- resolved：C1、W1、W2、W3、W4、W6、W7、W8、W9、W10、W11
- unresolved：**C2**、**W5**

C1 的驗證方式值得記錄：Reviewer V 把 master requirement 依空行切成 20 個 segment 逐一測試 `seg in delta`，19 個為 True，唯一 MISS 是刻意移除的 `@trace` footer。

### Critical

- **R2-C1**（即 C2 未解決）`Critical` / `confidence: 100` / `layer: design` / `disposition: fix-introduced` / `introduced_by: 第 1 輪 C2 修正新增的 D6 與 Implementation Contract 7` / `location: design.md D6 與 Implementation Contract 7；delta 第 7 段；tasks 1.7、2.4`
  - `summary`: `trace_inputs` 失配即重新 merge 的設計只對 MODIFIED-only delta 成立，且 `already_synced` 與 `validation.py` 耦合，會使全部既有 workspace 在上線後第一次 `sync`／`archive`／`validate` 就踩到硬性回歸。
  - 主 agent 驗證：`spec_merge.py:213-215` 對不在 master 的 MODIFIED／REMOVED／RENAMED title raise `requirement_identity_mismatch`；`:216-218` 對已在 master 的 ADDED title raise `requirement_collision`。sync 套用後這些條件都成立，故 merge 只對 MODIFIED-only 冪等，Implementation Contract 7 的「MUST NOT raise」與 Risks 的「merge 對相同輸入是冪等的」皆不成立。`validation.py:235-239` 以 `build_sync_plan(...).already_synced` 推導 `identities_already_applied`，翻為 False 會使預設帶 validation 的 `archive` 以 `validation_failed` 失敗。tasks 1.7 使用的 `make_workspace` delta 為 ADDED+MODIFIED+RENAMED，該 task 不可滿足。**成立。**

### Warning

- **R2-W1**（即 W5 未解決）`95` / `design` / `disposition: unresolved-prior` / `location: delta 第 7 段與對應 Scenario` — 原診斷條款的 `installer MUST輸出` 雖已移除，但 C2 的修正把同一種 scope overreach 帶回：新增段落寫「installer MUST重新執行merge」。主 agent 驗證成立。
- **R2-W2** `90` / `design` / `disposition: fix-introduced` / `introduced_by: W10 修正引入的抽取範圍收斂` / `location: Implementation Contract 11；tasks 2.1；test_sync_archive_transaction.py:75-79` — 共用 fixture `make_workspace` 的 proposal 沒有 `- Affected code:` 標籤，範圍收斂後其 `code` 必為空，會使既有綠燈的 `test_sync_applies_fixed_phases_and_is_idempotent` 轉紅，而 tasks 對此必然的 fixture 破壞沒有任何落點。主 agent 驗證成立。
- **R2-W3** `85` / `design` / `disposition: fix-introduced` / `introduced_by: C2 修正的 delta 第 7 段與 W8／W9 修正後的第 6 段併存` / `location: delta 第 6 段對第 7 段、既有 Scenario「Sync 後 archive 不重複 merge」` — 兩條互相否定：第 6 段無條件規定「sync 之後未帶 `--skip-specs` 的 archive MUST 回報空 gap」，第 7 段卻使該情形可能重新 merge 並套用 trace；且逐 byte 保留的既有 Scenario 在缺 `trace_inputs` 的既有 manifest 上必然被違反（重新 merge 的 `updated` 取當日，master bytes 必變）。主 agent 驗證成立。
- **R2-W4** `80` / `design` / `disposition: fix-introduced` / `introduced_by: W11 修正新增的 D7 與 W7 修正新增的 tasks 1.6（只覆蓋 sync）` / `location: delta archive 診斷條款；tasks 1.6 與追溯表` — delta 對 archive 立了兩條可觀察 MUST（兩種模式皆輸出、MUST 早於 commit），但 1.6 只呼叫 `execute("sync", ...)`，追溯表把該行為掛到不覆蓋它的落點上。主 agent 驗證成立。

### Suggestion（非 blocking，已 triage）

- **R2-S1** `85` / `design` / `disposition: new` — `_PLAIN_PATH` 的「ASCII 路徑字元集合」未列舉，而 `,` 是合法檔名字元；corpus 中有以 ASCII 逗號分隔的純文字路徑列，含 `,` 會使除最後一項外每個值都帶尾逗號寫入 `code`。屬 `contract-level-decision-deferred-to-implementer`。
- **R2-S2** `65→Suggestion` / `design` / `disposition: fix-introduced` — tasks 1.6 若在同一 workspace 連續兩次呼叫 `execute("sync", ...)`，第二次會以 `already_synced` 返回而依規格不得輸出診斷，第二個斷言必然失敗。
- **R2-S3** `100` / `text` / `disposition: fix-introduced` — proposal 寫「分三個部分」但 C2 修正後實際列出四點。
- **R2-S4** `70` / `design` / `disposition: new` — D2／D3 的量測數字不可重現：D2 括號註明「以出現次數計」實際為 +16，D3 的「新增 5 條」在三種解讀下都不是 5。

信心過濾器：R2-S2 由 `confidence: 65` 降級為 `Suggestion`。無 `confidence < 50` 的 finding 被捨棄。

## Rating

- 過濾後累積 blocking 集合 Critical：1
- 過濾後累積 blocking 集合 Warning：4
- Non-blocking triaged findings：4
- `critical_gap`: `true`
- `round_type`: `micro`

第 1 輪的 13 位成員中 11 位經 Reviewer V 驗證解決並移除；C2 與 W5 維持 unresolved，另有三項 `fix-introduced` 進入集合。本輪不符合通過條件。核心教訓是第 1 輪為 C2 設計的補救機制本身是回歸來源：它同時觸及 `_merge` 的冪等性假設與 `validation.py` 的 `already_synced` 耦合，兩者都未在第 1 輪被驗證。

## Fix Actions

修改的檔案：`proposal.md`、`design.md`、`tasks.md`、`specs/cash-cli/spec.md`（4 個相異檔案）。

**R2-C1／C2 —— 以縮減範圍解決，而非再修一次機制。** 移除 D6、Implementation Contract 7、delta 的 manifest 段落、對應 Scenario `trace 輸入改變使 sync 重新 merge`、tasks 1.7 與 2.4，並重編號（Contract 由 11 條變 10 條，tasks 1.x 由 8 條變 7 條、2.x 由 5 條變 4 條）。改為在 proposal `## Non-Goals`、design Non-Goals 與 Risks 明記事實與實測理由：`_merge` 只對 MODIFIED-only 冪等（ADDED 撞 `requirement_collision`、REMOVED 與 RENAMED 撞 `requirement_identity_mismatch`），且 `already_synced` 被 `validation.py:239` 用來推導 `identities_already_applied`；可行修法是「只重寫既有 requirement 的 `@trace` footer 而不重跑 operation phase」，屬另一個 change。此決定使本變更回到單一主張——修抽取、加診斷——而診斷的實務價值改述為「讓作者在下一個 change 改對」，並由 D6（原 D7）確保 `archive` 的診斷早於目錄搬移。

**R2-W1／W5 —— 隨 manifest 段落移除而消除。** 機械驗證 delta 的 `installer` 出現次數為 0。

**R2-W2 —— fixture 破壞納入 tasks 與 contract。** tasks 2.1 明寫要把 `make_workspace` 的 proposal 改為模板形狀，並在驗證目標加上「`test_sync_applies_fixed_phases_and_is_idempotent` 維持綠燈」；Implementation Contract 10 列出該 fixture 更新為預期而非實作缺陷。

**R2-W3 —— 由範圍縮減直接消除**（第 7 段已不存在）。另把第 6 段的第三個列舉由「`sync` 之後未帶 `--skip-specs` 的 `archive`」限定為「`sync` 之後 manifest 相符因而以 `already_synced` 返回的 `archive`」，使其與逐 byte 保留的既有 Scenario `Sync 後 archive 不重複 merge` 語意一致。

**R2-W4 —— tasks 1.6 擴充至 archive 側。** 改為對 `execute("sync", ...)` 與 `execute("archive", ...)` 各兩種 argv 共四種組合斷言 stderr 診斷；另新增「注入 commit 失敗後 stderr 仍含診斷且 `openspec/changes/<name>/` 未被移走」的 case 驗證 pre-commit 條款。Implementation Contract 10 對應改為涵蓋兩個 command。

**Suggestion 處置** — R2-S1 已修：Implementation Contract 1 逐字列出字元集 `[A-Za-z0-9_.@+~-]` 與 `/`，並明寫 MUST NOT 含 `,`、`;`、`(`、`)` 及其理由；tasks 3.4 增列「不含尾端標點」斷言。R2-S2 已修：1.6 明寫每次呼叫 MUST 使用各自獨立的 workspace，並說明共用會使斷言必然失敗的原因。R2-S3 已由範圍縮減自動解決（第 4 點移除後「分三個部分」重新成立，已機械驗證）。R2-S4 已修：主 agent 重新量測並統一以**全域相異值**為基準——現行規則 9 條、只放寬 token 掃描 13 條、提案最終規則 11 條，相對現行損失 0、新增 2 條（`generator-checks.fish` 與 `installer-commit-guard-checks.fish`），且相對「只放寬 token 掃描」少收 `./install-cash-skills.fish` 與 `scripts/spectra-plus/generate.fish` 兩個 source 腳本；D2、D3 與 proposal 對應改寫並註明計量基準。

**修正後機械式自我檢查** — 重跑並抓到一項：tasks 2.2 的驗證目標仍引用已重編號的 `1.8`，已改為 `1.7`。註解 lint（`<!--`／`-->` 皆 0）、C1 的 8 個既有 Scenario 逐 byte 保留、`installer` 殘留 0、`trace_inputs` 殘留 0、有 `check` 欄位的 open signal 0 個，皆通過。`validate` 於全部修正後重跑通過。

## Decision

next_round

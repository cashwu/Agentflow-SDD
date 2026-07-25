# Cash Propose Review — Round 6

本輪為 micro 輪，亦為 6 輪上限的最後一輪。

## Reviewer Findings

### Reviewer 失敗與重試

本輪第一次 spawn 的 Reviewer V 因 session limit 在產出任何 finding 之前被中斷，回傳為不完整輸出。依 failure handling 規則「若 reviewer 回傳無回應或格式錯誤的輸出，以 fresh sub-agent 重試該角色一次」，以較精簡的提示重試一次並成功取得完整判定。同一角色未連續失敗兩次，因此不觸發 workflow abort。此記錄依規則寫入本輪 `## Decision` 所屬的輪次檔案。

### Cumulative blocking set 逐項判定

round 5 的 2 個 blocking 成員全數 `resolved`，7 個非阻斷項亦全數關閉。

| member | verdict | 依據摘要 |
| --- | --- | --- |
| V1 | resolved | tasks 1.1 與 IC4 已改為 `tempfile` + `git init` + `os.chdir` + `addCleanup`，並明寫 `CASH_PROJECT_ROOT` 是一致性守衛而非 workspace 來源；與 `workspace.py` 的 `Workspace.discover` 一致。Reviewer V 實跑確認在該 setup 下 `new bogus <artifact-id>` 與 `instructions --skill bogus` 都到達 `unknown_command` |
| V2 | resolved | proposal `## Proposed Solution` A 段已改為「移除 `assert_inventory` 的字面值斷言，形狀驗證改置於 `assert_installer`」並言明委派與不含格式常數，與 design D1／IC1、tasks 2.3、delta spec 一致 |
| V3–V9 | closed | 逐一核對：proposal 與 delta spec 的格式常數皆為 0；Goals 無「第四次」；Context 無「上述三者」；proposal 的擁有者列舉含 `bin/cash`；task 1.2 首句為 characterization test；GIVEN 為「嚴格高於 `HEAD`」；tasks 2.3 已明訂 import 機制且 Reviewer V 實跑驗證 `version_parts` 可用 |

### Warning

**F1**
- `severity`: Warning
- `confidence`: 90
- `layer`: design
- `location`: design.md IC4；tasks.md task 1.1
- `summary`: 暫存 workspace 對 `.cash-workspace.lock` 的條款在 design 中缺漏、在 tasks 中寫反。IC4 完全未提該檔；tasks 1.1 把它併入「寫入**內容有效**的……」並附註「只建空檔會先失敗於 `config_invalid`」，但 `workspace.py` 的 `_require_lock` 要求該檔必須是 `st_size == 0` 且 mode 恰為 `0644` 的 single-link regular file——對它「建空檔」正是唯一正確做法。
- `failure_scenario`: 主 agent 實跑三種形態確認——缺檔得 `workspace_lock_invalid: Workspace lock is missing or unsafe.`；寫入內容得 `workspace_lock_invalid: Workspace lock must be an empty 0644 regular file.`；空的 `0644` 才到達 `unknown_command: Unknown new mode: bogus`。前兩者皆在 mode／discipline 判定之前失敗，task 1.1 的驗收無法達成。另 tasks 1.1 建議沿用的 `LauncherLockTests.setUp` 樣板，其 `.cash.yaml` 與 lock 是由 installer 產生的，而本任務明確不走安裝路徑，照抄反而會漏掉這兩個檔。
- `recommendation`: IC4 補上該檔；tasks 1.1 把它移出「內容有效」群組並改寫為空檔加顯式 `0644`；樣板建議降級為僅沿用骨架。
- `disposition`: `fix-introduced`
- `introduced_by`: round 5 `## Fix Actions` 的「**修 V1** — tasks 1.1 與 IC4 改寫為正確機制：以 `tempfile` 建立……含內容有效 `.cash.yaml`／`openspec/config.yaml`（`schema: spec-driven`）／`.cash-workspace.lock` 的暫存 workspace」——該句把三個檔案併為同一類要求，而第三個的要求恰好相反。

### 經 confidence filter 丟棄（保留 downgrade trace）

**F2**（confidence 45 < 50，依規則丟棄）IC4 以「`test_runtime_and_errors.py` 目前是零 subprocess 的純 unit test」作為移出 receipt gate 覆蓋的理由，但同一條 IC4 規定的暫存 workspace 需要 `git init`，且 `Workspace.discover` 每次都 shell out 到 `git rev-parse`，實作後該檔不再是零 subprocess。此項雖被丟棄，但修法只需一句措辭調整，因此一併修正。

## Rating

- post-filter cumulative blocking set Critical count: **0**
- post-filter cumulative blocking set Warning count: **1**（F1）
- 非阻斷 triaged finding count: **0**（F2 因 confidence < 50 被丟棄，非 triage）
- `critical_gap`: **false**
- `round_type`: **micro**

rationale：round 5 的 2 個成員全部以 verified resolution 離開集合，7 個非阻斷項亦全數關閉，且 Reviewer V 以實跑驗證了 V1 修正後的 setup 確實能到達目標錯誤碼。缺陷密度在六輪間持續下降：1C+8W → 0C+4W → 0C+1W → 0C+3W → 0C+2W → 0C+1W。本輪唯一的 blocking 是 round 5 修 V1 時把三個檔案併為同一類要求，而 `.cash-workspace.lock` 的要求恰好與另外兩個相反——這是一個具體且已實證的可實作性缺陷，不是措辭問題。依 6 輪上限規則，post-filter blocking set 非空即 `aborted`。

## Fix Actions

唯一的 blocking 成員（F1）與被丟棄的 F2 皆已在本輪修復。無 grader-protection 保留項，無 accepted-risks 條目。修改檔案共 2 個：`design.md`、`tasks.md`。這些修復未經任何 reviewer 驗證——依規則它們構成 bucket 1，是 re-run 的前提而非本輪的 pass 依據。

**修 F1** — tasks 1.1 把 `.cash-workspace.lock` 移出「內容有效」群組，改寫為「必須是空檔且 mode 恰為 `0644`（須顯式 `os.chmod`，勿依賴 umask），寫入任何內容或非 `0644` 都會先以 `workspace_lock_invalid` 失敗」並附上三種形態的實測結果；「只建空檔會先失敗於 `config_invalid`」限定到 `.cash.yaml` 與 `openspec/config.yaml` 兩檔；沿用樣板的建議降級為僅沿用 `tempfile` 加 `git init` 加 `addCleanup` 骨架，並註明該樣板的 `.cash.yaml` 與 lock 來自 installer、本任務須自行建立。IC4 補上「以及一個空的 `0644` `.cash-workspace.lock`（該檔的要求與前兩者相反）」。

**修 F2** — IC4 的理由由「零 subprocess 的純 unit test」改為「不含 launcher 或安裝路徑的 subprocess」，避免實作後理由自我失效。

**修正後的機械自檢與驗證** — 4 份 artifact comment/annotation 平衡皆 0/0；兩個 MODIFIED 標題與 master 逐 byte 相符；7 個新增 scenario 全數有 backing task 且雙向對應；Impact 的 7 個含 `/` 路徑全部被 tasks 引用；ghost bold 為 0；無 lowercase `may`／`should`。重跑 `cash validate` 通過，`cash analyze` 非 Suggestion finding 為 0。

**Signal-derived checks** — 全部 open signal 無 `check` frontmatter，採 best-effort。本輪最相關者：`design-claim-unverified-against-code`（F1 —— 我在 round 5 寫下三個檔案的建置要求時，只實測了 `.cash.yaml` 與 `openspec/config.yaml` 的失敗模式，沒有分別實測 lock 檔）。

## Decision

aborted

第六輪為 6 輪上限的最後一輪，post-filter cumulative blocking set 仍含 1 個 Warning（F1），未滿足 pass 條件，依規則記錄 `aborted` 並執行 Abort triage。

### Abort triage

**bucket 1 — 仍屬本 change 的義務（seeds a later re-run）**

- **F1**（Warning，`fix-introduced`，`layer`: design）暫存 workspace 的 `.cash-workspace.lock` 條款在 IC4 缺漏、在 tasks 1.1 寫反。已於本輪修復（`design.md` IC4、`tasks.md` task 1.1），但未經 reviewer 驗證。

未取得 accepted-risk 同意，因此留在 bucket 1。

**bucket 2 — 新發現且從未 blocking 的問題**

- **F2**（confidence 45，經 confidence filter 丟棄）IC4 的「零 subprocess」理由在實作後自我失效。已於本輪一併修復，不涉及 Critical，不需另提 follow-up change proposal。

**bucket 3 — 已接受的取捨**

無。本輪未向使用者徵詢任何 accepted-risk。

### Re-run 的具體前提

不建議原封不動重跑。bucket 1 的唯一項目已在本輪修復，因此 re-run 的前提是**驗證該修復**而非再次修復：re-run 的第一輪為 full 輪，須以 F1 為 seeded cumulative blocking set，由該輪的兩位 reviewer 各自給出 resolved／unresolved 判定；任一 `unresolved` 即保留該成員。re-run 的輪次編號自 7 起續編，且須帶入本次全部六份 round file（或依規則使用 extract fallback）。

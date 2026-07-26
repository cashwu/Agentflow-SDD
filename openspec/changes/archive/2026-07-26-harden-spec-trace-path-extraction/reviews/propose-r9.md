# Cash Propose Review — Round 9

micro round，重跑的第三輪。單一 Reviewer V 做差異驗證。本輪於前一工作階段中斷後接續：第 8 輪的 fix actions 已於該輪記錄並落地，本輪 spawn 前主 agent 重跑了機械式自我檢查（註解 lint 0/0、title identity 逐字存在、Scenario 總數 14、`validate` 通過、無帶 `check` 欄位的 open signal），全部通過。

## Reviewer Findings

### 累積 blocking set 裁定（1 位）

- **R8-W1 — `unresolved`**。Reviewer V 直接讀 design.md:62 並以自寫腳本獨立重跑量測（`os.walk` 枚舉全部 29 份 proposal 與 29 份 tasks，含 `archive/` 與 `.parked/` 隱藏目錄）：條目中「`tests` 側損失 0」「`code` 側恰 2 例、值恰為 `.spectra/` 與 `/spectra-`、皆非路徑宣告、皆屬已封存 proposal」全部成立，**但「皆來自同一份已封存 proposal」為偽**——`/spectra-` 唯一出現於 `openspec/changes/archive/2026-07-07-add-review-loop-discipline/proposal.md:27`，`.spectra/` 唯一出現於 `openspec/changes/archive/2026-07-24-replace-spectra-cli-with-cash-cli/proposal.md:68`，分屬兩份不同的已封存 proposal。R8-W1 的缺陷是「未經量測即寫入『實測』宣稱」；第 8 輪修正把計數與值修對，卻在同一句寫入另一個未經驗證的出處歸屬，缺陷以變形態存續。

### Warning

- **R9-W1**（即 R8-W1 的存續形態） `100` / `design` / `unresolved-prior` / `location: design.md:62（Risks 尾斜線條目）`
  - `summary`: 條目宣稱 `code` 側 2 例「皆來自同一份已封存 proposal」，實測兩例分屬兩份不同的已封存 proposal。
  - `recommendation`: 改為「分別來自兩份已封存 proposal 的 `- Affected code:` 範圍內散文」，其餘經獨立驗證成立的量測敘述維持不動。
  - 主 agent 覆核：以 `grep -rn` 對全語料獨立確認兩值各只出現一次、分屬上述兩檔——成立。錯誤僅存在於 design.md:62 一處，無其他傳播點。

### 第 8 輪其餘修正的傳播驗證

- **R8-S1**（delta Scenario GIVEN 收窄 + tasks 1.1（c）註記）：**landed**。delta spec.md:88 GIVEN 已為「以純文字（非code span）書寫」；tasks 1.1（c）註記落地且語意一致。Reviewer V 另對 tasks 3.4 的「`code` 不含非 ASCII 字元」斷言獨立量測：語料 `- Affected code:` 範圍內含斜線的非 ASCII code span 為 0，斷言在現行語料上成立。
- **主 agent 追加修正**（proposal Alternatives Considered 替換）：**landed**。「23 個是合法結果」在四個 artifact 0 命中；替換後條目與 proposal Non-Goals 第 3 條引用同一判準片語、方向互相支撐，無矛盾。
- 另確認第 8 輪編輯未破壞既有保留面：master `### Requirement: Atomic park、sync 與 archive` 去 trace 後 19 個 segment 逐 byte 存在於 delta，delta Scenario 總數 14（既有 8 + 新增 6）。

## Rating

- 過濾後累積 blocking 集合 Critical：0
- 過濾後累積 blocking 集合 Warning：1
- Non-blocking triaged findings：0
- `critical_gap`: `false`
- `round_type`: `micro`

R8-W1 經 Reviewer V 獨立量測裁定 unresolved：第 8 輪修正修對了計數與值，但同句寫入了錯誤的出處歸屬，屬同一缺陷機制（以「實測」名義記載未經驗證的事實）的存續，依 disposition 規則記為 `unresolved-prior` 而非新成員。累積 blocking set 維持 1 個 Warning 成員，不滿足 pass 條件。

## Fix Actions

修改的檔案：`design.md`（1 個檔案）。

**R9-W1（= R8-W1 存續）** — design.md:62 的「皆來自同一份已封存 proposal 的 `- Affected code:` 範圍內散文」改為「分別來自兩份已封存 proposal 的 `- Affected code:` 範圍內散文」。修正前主 agent 先以 `grep -rn` 獨立覆核 Reviewer V 的歸屬量測（`/spectra-` → `archive/2026-07-07-add-review-loop-discipline/proposal.md:27`；`.spectra/` → `archive/2026-07-24-replace-spectra-cli-with-cash-cli/proposal.md:68`），確認成立後才修改。

**修正傳播檢查** — `同一份已封存 proposal` 在四個 artifact 修正後 0 命中；design.md:61 的「該值只影響一份已封存 proposal」指的是 `runtime/install` 偽陽性（單值單檔，經 Reviewer V 第 8 輪前的量測背書），與本修正的兩例歸屬無關，不需同步。

**修正後機械式自我檢查** — 註解 lint 0/0；Scenario 總數 14；title identity 逐字存在；`validate` 重跑通過。無帶 `check` 欄位的 open signal，signal-derived checks 無可執行項。

**輪次接續記錄** — 本輪在新的工作階段接續中斷的 loop；Reviewer V 的 context 以檔案路徑提供全部 r1–r8 round file 由其自行完整讀取，未使用摘錄 fallback。

## Decision

next_round

# Cash Propose Review — Round 10

full round，重跑的第 4 輪檢查點。兩位全新 reviewer（A — Adherence、B — Quality）平行執行、未互相傳遞輸出，兩位皆對累積 blocking set 成員回傳明確裁定。

## Reviewer Findings

### 累積 blocking set 裁定（2 位，檢查點）

**R8-W1（r9 記為 R9-W1）——兩位 reviewer 一致裁定 `resolved`，無分歧。** 兩位各自以自寫腳本獨立重跑量測（`os.walk` 枚舉全部 29 份 proposal 與 29 份 tasks，含 `archive/` 與 `.parked/` 隱藏目錄），未採信 r9 `## Fix Actions` 自述：

- 第 9 輪修正字串「分別來自兩份已封存 proposal」已落地於 design.md:62，「同一份已封存 proposal」在四個 artifact 0 命中。
- 條目的每個事實宣稱經獨立驗證成立：`code` 側被丟棄值恰 2 例、值恰為 `.spectra/`（`archive/2026-07-24-replace-spectra-cli-with-cash-cli/proposal.md:68`）與 `/spectra-`（`archive/2026-07-07-add-review-loop-discipline/proposal.md:27`）、確屬兩份不同的已封存 proposal、皆為 `- Affected code:` 範圍內散文而非路徑宣告；`tests` 側損失 0（Reviewer A 與 B 各自以現行 `_VERIFICATION_CLAUSE` + 舊 `_verification_path` 重建舊結果比對）。
- 「以『實測』名義記載未經驗證事實」的缺陷機制在該條目已無殘留。

依累積集合規則，R8-W1 以 verified resolution 移除（fix 記錄於 r9 `## Fix Actions`；驗證者：Reviewer A 與 Reviewer B，一致 resolved）。**累積 blocking set 清空。**

### 信心過濾後 findings（全部非 blocking）

過濾軌跡：B-F1 `confidence 75 ∈ [50, 80)` 降為 `Suggestion`；A-F1、B-F2、B-F3、B-F4 原即 `Suggestion` 或 `confidence 50` 降為 `Suggestion`。過濾後無任何 `Critical` 或 `Warning` 存活，无成員可進入累積集合。

- **A-F1** `50` / `text` / `fix-introduced` / `introduced_by: 第 7 輪 R7-S1 修正引用第 6 輪 R6-S4 寫入的 delta 條款時未逐字對齊` / A / `location: tasks.md 3.4 引文`
  - `summary`: tasks 3.4 以直接引號引用 delta 字元集禁令，但引文含 delta 原文所無的空白（「NOT 含」「`=` 等」），機械 grep 兩檔互不命中；語意相同，規範效力不受影響。
  - `recommendation`: 引文改為與 delta 逐 byte 一致。
- **B-F1** `75→Suggestion` / `design` / `new` / B / `location: specs/cash-cli/spec.md:11 `tests` 判準句 對 design Contract 4`
  - `summary`: delta 判準句只寫「剝除單一個 `./` 前綴」後即套判準，Contract 4 則先經 `_canonical_path` 再套判準；尾斜線 token（如 `scripts/x/tests/`）依 delta 字面會被收入、依 Contract 會被丟棄，而 design Risks 明文記載後者才是意圖。delta 是會併入 master spec 的 normative 文字，字面實作與 Contract 實作產生相反可觀察結果。
  - `recommendation`: delta 判準句改為 canonical 化先行、判準作用於 canonical 化後的值。
  - 主 agent disposition 覆核：該句的字元集前置部分為前幾輪修正所加，canonical 化條款與判準句的失同步可能源自修正傳播不完整，屬 `fix-introduced` 的合理懷疑；因過濾後為 `Suggestion`（非 blocking），blocking 狀態不受 disposition 影響，據實記錄於此。
- **B-F2** `50→Suggestion` / `design` / `new` / B / `location: design Contract 2`
  - `summary`: `_canonical_path` 只剝單一個 `./` 前綴與（未寫明層數的）結尾 `/`，對 `scripts/foo//`、`././x/y` 這類重複形態會輸出仍非 canonical 的值，違反 delta 無條件的 canonical MUST；現行 corpus 0 例，屬護欄缺口。
  - `recommendation`: 改為反覆剝除至不動點，tasks 1.3（c）補重複形態輸入。
- **B-F3** `50→Suggestion` / `design` / `new` / B / `location: design Contract 3 的 `_CODE_SPAN.sub("", line)``
  - `summary`: 以空字串移除 code span 會把 span 兩側殘餘文字拼接，可能拼出行內從未出現的假路徑交給 `_PLAIN_PATH`。
  - `recommendation`: 改為 `_CODE_SPAN.sub(" ", line)`。
- **B-F4** `50→Suggestion` / `design` / `new` / B / `location: tasks.md 3.4`
  - `summary`: 3.4 以 `git show HEAD:` 取舊版，隱含「執行當下 HEAD 尚未含本 change 實作」的未斷言前提；若中途已 commit，新舊對照退化為自我比較，超集與損失集合斷言空洞通過且無訊號。
  - `recommendation`: 加前置斷言：舊版與工作區版內容 MUST 不同，相同則以明確訊息失敗。

### Reviewer A 全面重掃記錄（無 finding 的驗證面）

四向判準一致（抽取範圍、ASCII 字元集與標點禁令、全 token 掃描、`/tests/`／`test_` 判準、canonical 化語意、裸檔名特例順序）；delta 6 個新增 Scenario 逐一有 tasks 落點且追溯表正確；Impact ↔ tasks 交付檔案一致無多無漏；數字宣稱互證通過（14/29↔14→0、3→12→7、9→13、9→11、0/29）；design Context 對 `spec_merge.py` 現況的描述逐項屬實；master requirement 去 trace 後 19 個 segment 逐 byte 存在於 delta、title 逐 byte 一致（程式化驗證）。

## Rating

- 過濾後累積 blocking 集合 Critical：0
- 過濾後累積 blocking 集合 Warning：0
- Non-blocking triaged findings：5
- `critical_gap`: `false`
- `round_type`: `full`

唯一的累積集合成員 R8-W1 經兩位檢查點 reviewer 各自獨立量測後一致裁定 resolved 並移除，集合清空。本輪過濾後無任何 blocking finding：5 個 triaged findings 全為 `Suggestion` 級（其中 B-F1 為 75 降級），依規則非 blocking、不阻擋 pass。pass 條件成立。

## Fix Actions

**Verified-resolution 移除記錄** — 成員：R8-W1；fix 參照：r9 `## Fix Actions` 對 design.md:62 的歸屬修正；驗證者：Reviewer A 與 Reviewer B（檢查點雙裁定，一致 resolved）。

以下為 5 個非 blocking `Suggestion` 的主動修正（非 pass 條件所需；為避免已確認的缺陷帶入 apply 階段而於本輪一併處理）。修改的檔案：`design.md`、`tasks.md`、`specs/cash-cli/spec.md`（3 個相異檔案）。全部編輯使用帶斷言的替換，修正後逐字串機械驗證落地。

- **A-F1** — tasks 3.4 引文改為與 delta 逐 byte 一致（去除「NOT 含」與「`=` 等」中的空白）。修正後 grep 確認該引文片語在 tasks 與 delta 兩檔一致命中。
- **B-F1** — delta 判準句改為「再經canonical化（剝除`./`前綴與結尾的`/`；以`/`起首或剝除後不含斜線的token MUST NOT進入`tests`），最後要求canonical化後的值滿足…」，使尾斜線目錄 token 的丟棄成為 delta 可導出的結論、與 Contract 4 及 design Risks 記載的意圖一致。傳播面：design D3 摘要句同步改為 canonical 先行（「先經 `_canonical_path` 正規化…再要求正規化後的值滿足…」）；Contract 4 與 tasks 2.2 原本即為 canonical 先行，無需修改。
- **B-F2** — Contract 2 與 tasks 2.1 的 `_canonical_path` 定義改為「反覆剝除 `./` 前綴與結尾 `/` 至不再變化」，並在 Contract 2 註明反覆剝除是 delta canonical MUST 的必要條件；tasks 1.3（c）補「以 `././` 起首與以 `//` 結尾的重複形態各一」的輸入與輸出斷言。
- **B-F3** — Contract 3、D1 說明句與 tasks 2.1 的 `_CODE_SPAN.sub("", line)` 全部改為 `_CODE_SPAN.sub(" ", line)`（以空白取代而非刪除），並記載拼接假路徑的理由。
- **B-F4** — tasks 3.4 加入前置斷言：`git show HEAD:.cash-skills/lib/cash_cli/spec_merge.py` 與工作區版內容 MUST 不同，相同則以明確訊息失敗並改取本 change 實作前的 commit 作為舊版來源。

**修正後機械式自我檢查** — 「單一個」與 `_CODE_SPAN.sub("", line)` 在四個 artifact 0 殘留；新字串（「反覆剝除」「至不再變化」「再經canonical化」「退化為自我比較」與逐 byte 對齊後的引文）逐一命中；註解 lint 0/0；Scenario 總數 14；master title 逐 byte 存在；`validate` 重跑通過。

**Fix 修改檔案（change 目錄外）** — 無；三個修改檔皆在 `openspec/changes/` 之下，依規則不呼叫 touched record。

## Decision

passed

# Cash Propose Review — Round 1

## Reviewer Findings

以 `location + summary` 聚合兩位 reviewer 的獨立輸出後，套用 confidence filter 的結果。共同提出的 finding 已合併並取較高 severity；`layer` 全部為 `design`。

### Critical

**C1 — home-relative 路徑使 delta 的 root containment 條文不成立**

- `severity`: `Critical`
- `confidence`: `100`
- `layer`: `design`
- `location`: `specs/cash-cli/spec.md` 第四段；`design.md` D1 與 `## Goals`
- `summary`: 條文寫「使指向repo之外或含非canonical路徑段的值 MUST NOT進入任一欄位」，但 `~` 在 `_PLAIN_PATH` 與 `_verification_path` 共用的字元集內，且 home-relative 路徑的每一段都不是 `""`／`.`／`..`，因此只加路徑段條件時 `~/outside/x.py` 仍會進入 `code`、`~/outside/tests/test_a.py` 仍會進入 `tests`。
- `recommendation`: 於 `_canonical_path` 增加「第一段以 `~` 起首則回傳 `None`」，並同步 delta 條文、Contract、tasks case；或退而收斂條文宣稱的範圍。
- 來源：Reviewer B（附原型實測輸出）
- 主 agent 複核：已獨立重現。`_canonical_path('~/outside/x.py')` 現行回傳原值；`_PLAIN_PATH` 確實命中 `~/`；語料中以 `~` 起首的路徑 token 數為 0，故修法對現行語料零衝擊。

### Warning

**W1 — 全形冒號條文無測試落點，且 §4 追溯表宣告了不存在的落點**

- `severity`: `Warning`；`confidence`: `100`；`layer`: `design`
- `location`: `specs/cash-cli/spec.md` 第三段末句 + `tasks.md` §1.3、§4 追溯表 + `design.md` Contract 5
- `summary`: delta 對粗體與全形冒號並列同一條 MUST NOT，但 tasks 1.3 只有粗體 case、Contract 5 的清單也只列粗體；§4 追溯表卻逐字寫「粗體與全形冒號 … | 1.3（Red 與護欄）」。
- `recommendation`: 增列全形冒號護欄 case，並同步 Contract 5 與追溯表。
- 來源：Reviewer A、Reviewer B 各自獨立提出（合併）

**W2 — `cash-skills.version` 的工作區狀態陳述與事實不符**

- `severity`: `Warning`；`confidence`: `100`；`layer`: `design`
- `location`: `design.md` `## Risks / Trade-offs` 末項 + `tasks.md` §3.1
- `summary`: 兩處寫「前一個 change 已在工作區提升過該檔且尚未提交」，但該 change 已封存並提交，工作區值與 `git show HEAD:cash-skills.version` 相同。指示本身安全，但支撐它的事實前提為假，會使實作者預期一個不存在的 dirty working tree。
- `recommendation`: 改為與狀態無關的表述（以工作區值與 HEAD 值的最大值為基準，兩者相等與不等皆為合法狀態）。
- 來源：Reviewer A（`Warning`/100）與 Reviewer B（`Suggestion`/100）合併，取較高 severity

**W3 — tasks 3.4（b）的 `new ⊆ old` 不變式與標籤放寬方向矛盾**

- `severity`: `Warning`；`confidence`: `100`；`layer`: `design`
- `location`: `tasks.md` §3.4（b）
- `summary`: 本變更由方向相反的兩個改動組成（`_canonical_path` 收緊、標籤形狀放寬），子集性質只編碼了收緊那一半。一旦語料新增一份以 `- Affected code: <path>` 行內形式書寫的合法 proposal，`new - old` 即非空，斷言會把正確實作判為缺陷，且 3.4 同時禁止所有脫困手段。
- `recommendation`: 改為分側不變式，刪除子集斷言。
- 來源：Reviewer B（`Warning`/100）與 Reviewer A（`Suggestion`/55）合併，取較高 severity

**W4 — 「MUST 為拒絕而非解析」無任何可機械驗證的落點**

- `severity`: `Warning`；`confidence`: `80`；`layer`: `design`
- `location`: `specs/cash-cli/spec.md` 第四段末句與相關 scenario + `tasks.md` §1.1、§3.4
- `summary`: tasks 1.1 只斷言「該值不入 `code`」。一個先 `os.path.normpath` 再接受的實作會把 `../outside/x.py` 寫成 `outside/x.py`、`a/./b.py` 與 `a//b.py` 寫成 `a/b.py`，因而通過全部 case；3.4 的語料等價性也擋不住，因為現行語料該分支出現數為 0。D1 的核心決策完全未被固定。
- `recommendation`: 拒絕類 case 的斷言改為集合相等。
- 來源：Reviewer A

### Suggestion

以下 6 項 confidence 落在 `[50, 80)` 而依 confidence filter 降級為 `Suggestion`，屬非阻塞。本輪一併修復（見 `## Fix Actions`）。

- **S1**（Reviewer B，75）：3.4 的退化守衛檢查錯對象——只比對檔案 bytes 而非實際 import 的模組物件；且字面配方複製後仍叫 `cash_cli`，同一直譯器內先命中者會同時充當新舊兩側，比較必得 0 差異。
- **S2**（Reviewer B，75）：標籤列殘餘內容的 code span 分支會收進「被引述而非被修改」的真實路徑，其嚴重度高於既有的 `runtime/install` 類散文偽陽性，Risks 未記錄；且「22/28 行內內容」的證據只支持「會帶行內內容」，不支持「會帶行內路徑」——後者語料出現數為 0。
- **S3**（Reviewer B，75）：`## Impact` 尾隨空白條文有 MUST 但無 scenario。
- **S4**（Reviewer B，75）：粗體 scenario 的 THEN 是內部狀態而非可觀察輸出，且以 `code` 為空作 proxy 無法與「整段抽取失效」區辨。
- **S5**（Reviewer B，50）：同層終止條件放寬是純粹擴張，會使子清單內任何縮排且以 `- Affected ` 起首的 bullet 提前終止子清單並靜默丟棄其後路徑，Risks 只記了起點側。
- **S6**（Reviewer B，50）：`strip()`／`rstrip()` 依 `isspace()` 判定，實際容忍全部 Unicode 空白（含 U+3000、U+00A0），比宣告的「前後空白」寬。

## Rating

- post-filter 累積阻塞集合 Critical：1
- post-filter 累積阻塞集合 Warning：4
- 非阻塞 triaged finding：6
- `critical_gap`：`true`
- `round_type`：`full`

本輪為未 seeded run 的第一輪，因此全部通過 confidence filter 的 `Critical` 與 `Warning` 皆為阻塞。累積阻塞集合含 1 個 Critical 與 4 個 Warning，不符通過條件，決定為 `next_round`。6 個 `Suggestion` 不進入阻塞集合，但因其修法皆為 artifact 文字層級且能實質提高本變更品質，本輪一併修復並記錄。

## Fix Actions

**C1** — 修改 `specs/cash-cli/spec.md`、`design.md`、`tasks.md`、`proposal.md`：`_canonical_path` 增加第二條新條件「第一段以 `~` 起首則回傳 `None`」，且 MUST 只判定第一段以免誤殺 `a/~b/c.py`。delta 條文改為逐一列舉三類拒絕條件並明示其涵蓋 `../` 逃逸與 `~` home-relative 兩種形式，同時明文允許 `~` 出現在第一段以外；`## Goals`、D1、Contract 1、Contract 5、tasks 1.1（e）（f）、2.1、§4 追溯表、proposal Summary／Motivation／Proposed Solution 全部同步。D1 另加一段界定判定邊界（symlink 與不存在路徑不在範圍，理由回指 proposal 已否決的存在性判準）。

**W1** — 修改 `tasks.md`、`design.md`：tasks 1.3 增列（a2）全形冒號護欄 case；Contract 5 的 case 清單補上該形式；§4 追溯表拆列為「粗體形式」與「全形冒號形式」兩列，各自指向 1.3（a）與 1.3（a2）。

**W2** — 修改 `design.md`、`tasks.md`：刪除「已在工作區提升過且尚未提交」這個事實宣稱，改為「以工作區值與 `git show HEAD:cash-skills.version` 兩者的最大值決定，兩者相等與不等皆為合法狀態，MUST NOT 據此推斷環境異常」。

**W3** — 修改 `tasks.md` §3.4（b）：刪除 `new ⊆ old` 與「`new` 減 `old` MUST 為空」，改為分側不變式——`old - new` 每個值 MUST 含空段／`.`／`..`／第一段以 `~` 起首（收緊側），`new - old` 每個值 MUST 出自 strip 後才命中的標籤列、其 colon 之後行內內容、或帶尾隨空白的 `## Impact`（放寬側），無法歸入任一側者即為實作缺陷。

**W4** — 修改 `tasks.md` §1.1、`design.md` Contract 5：拒絕類 case 的斷言改為集合相等，並逐字寫出理由（`os.path.normpath` 實作會通過僅斷言「不含原字面值」的 case）。delta 的 `含非 canonical 路徑段的值不進入 code` scenario 的 `AND` 改為「該值解析或正規化後的形式同樣 MUST NOT出現在該欄位」，使規範句本身即排除解析型實作。

**S1** — 修改 `tasks.md` §3.4、`design.md` Contract 7：明寫複製後的套件目錄 MUST 改名（例如 `cash_cli_old`）及其理由；退化守衛改為行為 sentinel（`old.__file__ != new.__file__`、`old._canonical_path("../x/y") == "../x/y"`、`new._canonical_path("../x/y") is None`），bytes 比較降為輔助。

**S2** — 修改 `design.md`：D2 拆分「證據支持什麼、不支持什麼」，明記行內**路徑**形式的語料出現數為 0、22/28 只支持「會帶行內內容」；`## Risks / Trade-offs` 增列 code span 分支會收進「被引述而非被修改」路徑的風險，並說明其嚴重度高於 `runtime/install` 類、以及為何仍接受（替代方案會造成更難察覺的靜默落空）。

**S3** — 修改 `specs/cash-cli/spec.md`：新增 scenario `Impact 標題列帶尾隨空白時仍定位子清單`。

**S4** — 修改 `specs/cash-cli/spec.md`：原 `粗體標籤不被視為子清單起點` 改寫為 `粗體與全形冒號標籤不被視為子清單起點`，THEN 改為可觀察形式（該兩種標籤列之下的路徑不出現在 `code`），並加 `AND` 要求同一份 proposal 中精確形狀子清單的路徑仍出現，使「不容忍」與「整段抽取失效」可區辨。tasks 1.3（a）（a2）的 fixture 同步要求此形狀。

**S5** — 修改 `design.md` `## Risks / Trade-offs`：增列同層終止條件放寬所造成的提前終止面。

**S6** — 修改 `design.md` `## Risks / Trade-offs`：記錄 `strip()`／`rstrip()` 實際容忍全部 Unicode 空白，並說明其與全形冒號屬不同類而非雙重標準。

**修復後的機械自檢**：註解平衡（四份 artifact 皆 0／0、無裸 `---`）；delta 的 `### Requirement:` 標題仍與 master 逐 byte 相符；scenario 數 21（master 既有 14 + 新增 7）；跨 artifact 識別字（`cash_cli_old`、`__file__`、`~`、case 標號）一致。

**修復後的重新驗證**：`cash validate harden-trace-path-containment-and-label-shape` 通過。以套用全部 Contract 的原型對全語料重測，29 份 `proposal.md` 與 29 份 `tasks.md` 的 `code` 與 `tests` 差異數皆維持 0；delta 的 7 個新增 scenario 全部以原型逐條實測符合預期（含 `~` 拒絕、`a/~b/c.py` 保留、粗體與全形冒號可區辨）。

**本輪 Fix Actions 修改的檔案**（全部位於 `openspec/changes/` 之下，依 touched record 規則不需呼叫 Cash CLI）：`proposal.md`、`design.md`、`tasks.md`、`specs/cash-cli/spec.md`。

## Decision

next_round

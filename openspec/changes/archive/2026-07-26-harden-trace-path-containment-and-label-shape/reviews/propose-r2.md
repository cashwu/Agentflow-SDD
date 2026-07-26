# Cash Propose Review — Round 2

## Reviewer Findings

本輪為 micro round，由單一 Reviewer V 對 Round 1 的累積阻塞集合做差異驗證。

### 累積阻塞集合 verdict

Reviewer V 對 Round 1 的 5 個成員逐一回傳 verdict，全部為 `resolved`；主 agent 已就 C1 與 W2 獨立複核。

- **C1**（Critical，home-relative 路徑）→ `resolved`。原型實測 `~/outside/x.py`、`~user/x.py` 皆回傳 `None`，`a/~b/c.py` 維持被接受，`./a/b.py` 的既有剝除未受影響；`tests` 側兩個裸檔名映射在 `_canonical_path` 之前判定，不受波及。條文、Contract、tasks case、追溯表四處同步完成。
- **W1**（全形冒號無測試落點）→ `resolved`。1.3（a2）、Contract 5 清單、§4 追溯表拆列、delta scenario 四處一致。
- **W2**（版本狀態陳述）→ `resolved`。實測工作區值與 `git show HEAD:cash-skills.version` 皆為 `2.6.2`，改後措辭與該狀態相容，全 change 內無殘留的錯誤事實宣稱。
- **W3**（`new ⊆ old` 不變式）→ `resolved`。子集斷言已刪除並改為分側不變式。
- **W4**（拒絕而非解析無落點）→ `resolved`。tasks 1.1、Contract 5、§4 追溯表、delta scenario 四處落點齊備且可機械驗證。

五個成員皆以「verified resolution」離開累積阻塞集合，驗證者為 Reviewer V。

### Fix propagation 檢查

Reviewer V 逐項核對 `~` 條件（proposal 3 處、design 4 處、tasks 3 處、delta 2 處）、全形冒號（6 處）、1.1 新增（e）（f）後 1.1 與 2.1 的驗證句範圍，結論為**未發現只改一處而留下不一致的地方**。機械項目另行確認：delta 標題與 master 逐 byte 相符、scenario 數 21（master 14 + 新增 7）、全語料 29+29 份差異數維持 0。

### Warning

**F1 — 護欄 fixture 未約束標籤順序，在其中一種排列下對正確實作為假**

- `severity`: `Warning`；`confidence`: `100`；`layer`: `design`
- `disposition`: `fix-introduced`；`introduced_by`: Round 1 的 **S4**（把粗體 scenario 的 THEN 改為可觀察形式並要求同一份 proposal 另含精確形狀子清單），以及沿用同一 fixture 要求的 **W1**
- `location`: `specs/cash-cli/spec.md` scenario `粗體與全形冒號標籤不被視為子清單起點`；`tasks.md` §1.3（a）的 fixture 要求
- `summary`: `- **Affected code:**` 經 strip 後既不以 `- Affected code:` 起首（不成為起點）也不以 `- Affected ` 起首（不成為同層終止條件）。原 GIVEN 未約束順序，因此當精確形狀子清單排在粗體標籤**之前**時，粗體標籤與其下路徑會被當成該子清單的一般內容行而收進 `code`，THEN 對一個完全符合 Contract 2 的實作為假。實作者照字面除錯的唯一修法（把粗體納入起點或終止條件）分別被 proposal 與 design 的 `## Non-Goals` 直接禁止。
- `recommendation`: 於 GIVEN 增加順序約束，tasks fixture 同步寫明並附理由。
- 主 agent 複核：已重現。護欄在前得 `['exact/ok.py']`（斷言成立）；精確在前得 `['bold/leak.py', 'exact/ok.py']`（斷言為假）。

**F2 — 3.4（b）收緊側枚舉未涵蓋「提前終止造成的損失」，會把已具名接受的取捨判成實作缺陷**

- `severity`: `Warning`；`confidence`: `100`；`layer`: `design`
- `disposition`: `fix-introduced`；`introduced_by`: Round 1 的 **W3**（以分側不變式取代 `new ⊆ old`）
- `location`: `tasks.md` §3.4（b）
- `summary`: 分側不變式假設「標籤形狀改動只會增加」，但其第 3 項（同層終止條件由 `startswith` 改為 `strip().startswith`）是嚴格擴張的**終止**條件，會使子清單內任何縮排且以 `- Affected ` 起首的 bullet 提前終止掃描、其後路徑被丟棄——正是 design `## Risks / Trade-offs` 已具名接受並記錄的面。這類值落在 `old - new` 卻不含空段／`.`／`..`／第一段 `~`，因而被判為「無法歸入任一側即為實作缺陷」，而 3.4 同時禁止所有脫困手段。
- `recommendation`: 收緊側枚舉增列第四款並回指 design Risks 的同一條取捨。
- 主 agent 複核：已重現。`old-new = ['dropped/b.py']`、`new-old = []`，該值確實不落在原三款枚舉內。

### Suggestion

**F3**（`confidence` 100，`disposition`: `fix-introduced`，`introduced_by`: Round 1 的 **W4**）：集合相等斷言所引用的 `os.path.normpath` 反例對（a）（e）為假——實測 `normpath` 不摺疊開頭的 `..`、也不展開 `~`，該反例只成立於（b）（c）。要求本身無害且更嚴格，但支撐它的事實前提對兩個列舉的 case 不成立。

**F4**（`confidence` 100，`disposition`: `fix-introduced`，`introduced_by`: Round 1 的 **C1**）：D1 末句「現行語料中以 `~` 起首的路徑 token 數為 0」與事實不符——本 change 以外的已封存 artifact 的 code span 內有 4 個（`~/.claude/plans/` 三處、`~/Library/LaunchAgents` 一處）。它們零影響的原因是位置而非形狀。正確陳述為「受影響條目為 0」。

兩者依 confidence filter 維持 `Suggestion`，屬非阻塞，本輪一併修復。

## Rating

- post-filter 累積阻塞集合 Critical：0
- post-filter 累積阻塞集合 Warning：2
- 非阻塞 triaged finding：2
- `critical_gap`：`false`
- `round_type`：`micro`

Round 1 的 5 個成員全部以 verified resolution 離開累積阻塞集合，但 Reviewer V 找出 4 個由 Round 1 fix actions 引入的缺陷，其中 F1、F2 通過 confidence filter 後維持 `Warning` 且 `disposition` 為 `fix-introduced`，依規則為阻塞。累積阻塞集合因此非空，決定為 `next_round`。

## Fix Actions

**F1** — 修改 `specs/cash-cli/spec.md`、`tasks.md`、`design.md`：scenario 的第二個 GIVEN 增加「且該子清單位於前述兩個標籤列**之後**」；tasks 1.3 的 fixture 要求增寫順序約束與其理由（粗體標籤既不成為起點也不成為同層終止條件，故排在已開啟的子清單之後時其路徑會被當成一般內容行收進 `code`，那是既有範圍定義的結果而非實作缺陷）；design Contract 5 增列同一段順序約束說明。同時記錄全形冒號形式無此問題（其 strip 後以 `- Affected ` 起首，兩種順序下都會終止子清單），但（a2）沿用同一順序以與（a）一致。

**F2** — 修改 `tasks.md` §3.4（b）：收緊側枚舉由三款增為四款，新增「或該值位於一個 strip 後才命中同層終止條件 `- Affected ` 的 bullet 之後，因子清單提前終止而被丟棄」，並註明該形態為 design `## Risks / Trade-offs` 已具名接受的取捨、語料出現數 0、MUST NOT 被判為實作缺陷。

**F3** — 修改 `tasks.md` §1.1 第二段與 `design.md` Contract 5：把集合相等的理由拆為兩類並明示 MUST NOT 互相代用——（b）（c）沿用 `os.path.normpath` 反例；（a）（e）改述為防禦 `relpath`／`expanduser`／`resolve` 型實作（產生一個不同於原宣告卻落在 repo 內的值），並逐字記錄 `normpath("../outside/x.py")` 實測仍為原值。

**F4** — 修改 `design.md` D1：把「語料中以 `~` 起首的路徑 token 數為 0」改為標明範圍的正確陳述，逐一列出那 4 個既有 token 及其零影響的原因（位置而非形狀：不在 `- Affected code:` 子清單內、且不滿足 `tests` 側判準）。同一段落中關於 `..` token 的括號說明一併改為標明範圍的形式。

**修復後的機械自檢**：註解平衡（四份 artifact 皆 0／0、無裸 `---`）；delta 標題仍與 master 逐 byte 相符；scenario 數維持 21；順序約束在 delta、tasks、design 三處一致；3.4 收緊側四款到位。

**修復後的重新驗證**：`cash validate harden-trace-path-containment-and-label-shape` 通過。F1 修法以原型實測確認——護欄在前得 `['exact/ok.py']`、精確在前得 `['bold/leak.py', 'exact/ok.py']`，GIVEN 的順序約束為斷言成立的必要條件。F2 修法以原型實測確認提前終止的損失值確實不落在原三款枚舉內。

**本輪 Fix Actions 修改的檔案**（全部位於 `openspec/changes/` 之下，依 touched record 規則不需呼叫 Cash CLI）：`design.md`、`tasks.md`、`specs/cash-cli/spec.md`。

## Decision

next_round

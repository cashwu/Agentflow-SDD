# Cash Propose Review — Round 3

## Reviewer Findings

本輪為 micro round，由單一 Reviewer V 對 Round 2 的累積阻塞集合做差異驗證。

### 累積阻塞集合 verdict

Reviewer V 對 Round 2 的 2 個成員逐一回傳 verdict，兩者皆為 `resolved`；主 agent 已就 F1 的關鍵反例獨立複核。

- **F1**（Warning，護欄 fixture 未約束標籤順序）→ `resolved`。Reviewer V 以嚴格依 Contract 1／2／3 撰寫的原型窮舉七種排列：改後 GIVEN 所述的三種排列（粗體→全形→精確、全形→粗體→精確、`- Affected specs:`→粗體→全形→精確）與（a）（a2）各自的單獨 fixture 全部得 `['exact/ok.py']`，delta 的 THEN 與 tasks 1.3 的集合相等斷言同時成立；兩種違反 GIVEN 的排列則得 `['bold/leak.py', 'exact/ok.py']`，確認順序約束為斷言成立的必要條件。三處措辭（delta scenario、`tasks.md` §1.3、`design.md` Contract 5）一致且互不矛盾。
- **F2**（Warning，收緊側枚舉未涵蓋提前終止損失）→ `resolved`。第四款所述形態實測 `old-new = ['dropped/b.py']`、`new-old = []`，已落在枚舉內。Reviewer V 另窮舉 `_paths_in_section` 的每一處放寬：`_canonical_path` 收緊由第一、二款覆蓋；起點放寬只產生 gain 不產生 loss（起點檢查在終止檢查之前）；同層終止放寬由第四款覆蓋。F2 所指的具體形態已封閉。

兩個成員皆以 verified resolution 離開累積阻塞集合，驗證者為 Reviewer V。**累積阻塞集合現為空。**

### Suggestion

Reviewer V 找出 5 個由 Round 2 fix actions 引入的缺陷，經 confidence filter 後全部為 `Suggestion`（非阻塞）。`layer` 逐一複查：Finding 4、5 的修法僅涉及措辭且不改變任何行為或設計陳述，維持 `text`；其餘為 `design`。

- **Finding 1**（`confidence` 100，`layer` `design`，`disposition` `fix-introduced`，`introduced_by`: Round 2 的 **F3**）：F3 把一個假的反例換成另一個假的反例。tasks §1.1 與 design Contract 5 現寫「（a）（e）的理由是防禦 `relpath`／`expanduser`／`resolve` 型實作」，但實測三者對（a）（e）都不產生落在 repo 內的值——`relpath(expanduser('~/outside/x.py'), ROOT)` = `../../outside/x.py`（逃逸）、`expanduser('~/outside/x.py')` = 絕對路徑（被既有 `startswith("/")` 條件擋下）、`relpath(realpath(ROOT/'../outside/x.py'), ROOT)` = `../outside/x.py`（與原宣告相同）。Reviewer V 提出的替代反例經主 agent 實測成立且更強。
- **Finding 2**（`confidence` 50，`layer` `design`，`disposition` `fix-introduced`，`introduced_by`: Round 2 的 **F2**）：第四款的位置判準未要求該 bullet 位於已開啟的子清單內，可被構造為吸收真正的實作缺陷。語料中縮排的 `- Affected ` bullet 出現數實測為 0，故今日不可能被引用。
- **Finding 3**（`confidence` 50，`layer` `design`，`disposition` `fix-introduced`，`introduced_by`: Round 1 的 **W3**／Round 2 的 **F2**）：收緊側枚舉仍漏一種合乎設計的損失——`## Impact` 標題列的 `rstrip` 放寬在「真正的 `## Impact` 之前另有一行 rstrip 後才命中的標題列、且兩者之間隔著任一 `## ` 標題」時會使 section 提前終止（實測 `old = ['real/x.py']`、`new = []`）。四款皆不適用，會被判為實作缺陷。語料實測 29 份 `proposal.md` 每份都恰有一行逐字 `## Impact`，出現數 0。
- **Finding 4**（`confidence` 50，`layer` `text`，`disposition` `fix-introduced`，`introduced_by`: Round 2 的 **F1**）：tasks §1.3（a2）括號內「全形冒號…兩種順序下都會終止子清單」逐字為假——排在子清單開啟之前時 `in_list` 為 False，它不終止任何東西而只是被略過。結論正確、機制描述錯誤。
- **Finding 5**（`confidence` 50，`layer` `text`，`disposition` `fix-introduced`，`introduced_by`: Round 2 的 **F4**）：D1 的「已封存 artifact」逐字包含 `design.md` 與 `reviews/`，該範圍下實測為 7 個而非 4 個；限縮到抽取語料（`proposal.md` + `tasks.md`）時 4 個完全正確。

## Rating

- post-filter 累積阻塞集合 Critical：0
- post-filter 累積阻塞集合 Warning：0
- 非阻塞 triaged finding：5
- `critical_gap`：`false`
- `round_type`：`micro`

Round 2 的 2 個成員皆由 Reviewer V 以原型實測驗證為 `resolved` 並離開累積阻塞集合；本輪新增的 5 個 finding 全部通過 confidence filter 後為 `Suggestion`，依規則不進入累積阻塞集合。post-filter 累積阻塞集合為空，`critical_gap` 為 `false`，符合通過條件，決定為 `passed`。

5 個非阻塞 finding 中，Finding 1 為 `confidence` 100 的事實錯誤（會誤導實作者查證後不信任整條要求），Finding 2、3 會在語料變動後使正確實作被判為缺陷，Finding 4、5 為逐字為假的措辭。五項的修法都限於 artifact 的理由文字與判定輔助說明，不改變任何交付行為、Implementation Contract 的實作要求或 delta 的規範句，因此本輪一併修復並記錄於下。

## Fix Actions

**Finding 1** — 修改 `tasks.md` §1.1 第二段與 `design.md` Contract 5：刪除 `relpath`／`expanduser`／`resolve` 這個已證為假的理由，改以單一且經實測的反例——把 2.1／Contract 1 誤讀為「濾掉不合格的路徑段」而非「整個值回傳 `None`」（`[s for s in value.split("/") if s not in ("", ".", "..") and not s.startswith("~")]` 再重組）。該實作對（a）（b）（c）（e）四個 case 全部產生落在 repo 內的合法值，實測依序為 `outside/x.py`、`a/b.py`、`a/b.py`、`outside/x.py`，因此單一反例即涵蓋四個 case，原本「理由分兩類且 MUST NOT 互相代用」的結構連帶簡化為一句註記（`os.path.normpath` 只對 `.` 段與連續斜線成立，MUST NOT 被引為 `../` 與 `~/` 的理由）。

**Finding 2** — 修改 `tasks.md` §3.4（b）第四款：位置判準增加「位於同一份檔案中一個已命中的 `- Affected code:` 標籤列之後」，使子清單尚未開啟的情形被排除在該款之外。

**Finding 3** — 修改 `tasks.md` §3.4（b）：收緊側增列第五款，涵蓋 `## Impact` 標題列 `rstrip` 放寬造成的 section 提前終止；並把收尾句由「無法歸入任一側的差異即為實作缺陷」改為明示該列舉是**判定輔助而非封閉集合**——MUST NOT 被當成「不在列舉內即為實作缺陷」的自動判準，也 MUST NOT 讓一個位置上恰好符合某款、實際成因卻是別的實作錯誤的差異被自動歸為合乎設計；（a）出現任何差異時 MUST 停下並逐項人工判定成因。此修法同時消除 Finding 2 與 Finding 3 各自的失敗模式，使枚舉不再需要宣稱封閉。

**Finding 4** — 修改 `tasks.md` §1.3（a2）括號：改為「兩種順序下都不會使其下的路徑進入 `code`——排在已開啟子清單之後時它終止該子清單，排在子清單開啟之前時它本身即不被掃描」。

**Finding 5** — 修改 `design.md` D1：把「已封存 artifact」限定為「已封存 change 的 `proposal.md` 與 `tasks.md`（即 D3 定義的抽取語料）」。

**修復後的機械自檢**：註解平衡（四份 artifact 皆 0／0、無裸 `---`）；delta 的 `### Requirement:` 標題與 master 逐 byte 相符；scenario 數維持 21；已否定的 `relpath`／`expanduser` 反例在 tasks 與 design 皆無殘留；濾段反例、非封閉列舉、全形冒號措辭、`~` token 範圍限定四項修正在對應 artifact 皆已到位。

**修復後的重新驗證**：`cash validate harden-trace-path-containment-and-label-shape` 通過。Finding 1 的替代反例已由主 agent 獨立實測確認（濾段型實作對四個 case 依序產生 `outside/x.py`、`a/b.py`、`a/b.py`、`outside/x.py`），原引用的三個函式則確認不產生 repo 內的值。

**本輪 Fix Actions 修改的檔案**（全部位於 `openspec/changes/` 之下，依 touched record 規則不需呼叫 Cash CLI）：`design.md`、`tasks.md`。

## Decision

passed

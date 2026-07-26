## Context

前一個 change `harden-spec-trace-path-extraction` 已於 2026-07-26 封存（`openspec/changes/archive/2026-07-26-harden-spec-trace-path-extraction/`），其條文已合併進 `openspec/specs/cash-cli/spec.md` 的 requirement `Atomic park、sync 與 archive`，且該 requirement 的 `@trace` footer 的 `source` 為 `harden-spec-trace-path-extraction`。本變更的 delta 因此對現行 master spec 撰寫，不存在與未封存 sibling change 爭奪同一 requirement 的排序風險。

`.cash-skills/lib/cash_cli/spec_merge.py` 目前的三個相關單元：

- `_canonical_path(value)`：反覆剝除 `./` 前綴與結尾 `/`，然後在值以 `/` 起首或不含斜線時回傳 `None`，否則回傳該值。`code` 與 `tests` 兩條抽取路徑共用它。
- `_paths_in_section(workspace, path, heading, list_label)`：以 `line == heading` 定位 `## Impact`、以 `line == list_label` 定位 `- Affected code:` 子清單起點、以 `line.startswith("- Affected ")` 終止子清單、以 `line.startswith("## ")` 終止 section；範圍內每行先取 code span、再對 `_CODE_SPAN.sub(" ", line)` 套用 `_PLAIN_PATH`。
- `_verification_path(value)`：兩個裸檔名映射、字元集 `fullmatch`、`_canonical_path`、測試形狀判準。

`_with_trace` 仍以 `_TRACE.sub("\n", block)` 無條件移除既有 trace 後才接上新的，因此任一欄位抽取落空都會連帶抹除該 requirement 先前已填好的 provenance，且沒有任何訊號。本變更不改變這個行為（見 proposal `## Non-Goals`），這正是為什麼落空面本身值得收斂。

## Goals / Non-Goals

Goals：

- 以 `../` 逃逸或以 `~` 為 home-relative 起點的值、以及含非 canonical 路徑段的值，都不進入 `code` 與 `tests`。
- `- Affected code:` 標籤帶前後空白或帶 colon 之後的行內內容時，子清單仍能被定位，且該行內內容本身的路徑也被收集。
- 上述兩項對現行語料的抽取結果零影響。

Non-Goals：

- 沿用 proposal `## Non-Goals` 的全部條目，其中與本設計最相關的三項：不新增診斷或輸出面、不對含 `..` 段的值做路徑解析、不容忍粗體等 markdown 強調標記與全形冒號形式的標籤列。
- 不改變 `- Affected code:` 子清單內部的收集規則（code span 分支、`_PLAIN_PATH` 字元集、去重與 byte 排序）。
- 不改變 `## Impact` 之下 `- Affected code:` 子清單「延伸到下一個同層 `- Affected ` 標籤列或下一個 `## ` 標題為止」這個既有範圍定義。該定義使子清單之後、`## Impact` 之內的散文仍在掃描範圍內（已封存 proposal 的 `runtime/install` 偽陽性即由此而來）；那是前一個 change 已具名接受的取捨，本變更不重新開啟。

## Decisions

**D1：`_canonical_path` 以「拒絕」而非「解析」處理非 canonical 路徑段。**

在既有兩個回傳 `None` 的條件之外，增加兩個：剝除後的值以 `/` 切分後，（i）任一段為 `""`、`.` 或 `..` 時回傳 `None`；（ii）第一段以 `~` 起首時回傳 `None`。四種形態各自對應一個實測可重現的漏網值——`..` 對應 `../outside/x.py` 與 `../tests/test_a.py`，`.` 對應 `a/./b.py`，`""` 對應內部連續斜線的 `a//b.py`（結尾的 `//` 已由既有的反覆剝除處理，但內部的不會），`~` 對應 `~/outside/x.py` 與 `~user/x.py`。

`~` 必須一併處理，否則本決策宣稱的 root containment 不成立：`~` 在 `_PLAIN_PATH` 與 `_verification_path` 共用的字元集之內，而 home-relative 路徑的每一段都不是 `""`、`.` 或 `..`，因此只加條件（i）時 `~/outside/x.py` 會原樣寫入 `code`、`~/outside/tests/test_a.py` 會原樣寫入 `tests`（皆已實測）。條件（ii）只判定第一段：`~` 在其後的路徑段中是合法檔名字元，`a/~b/c.py` MUST 維持被接受，實測確認不受影響。

語料量測的範圍必須寫清楚，否則會被查證推翻：現行語料**受本條件影響的條目為 0**，但語料中並非沒有以 `~` 起首的 token——本 change 以外、已封存 change 的 `proposal.md` 與 `tasks.md`（即 D3 定義的抽取語料）的 code span 內有 4 個（`~/.claude/plans/` 三處、`~/Library/LaunchAgents` 一處）。它們不受影響的原因是位置而非形狀：都不在 `- Affected code:` 子清單內，且都不滿足 `tests` 側的 `/tests/` 與 `test_` 判準，因此新舊規則下都不會進入任一欄位。

判定的邊界到此為止：條件（i）（ii）涵蓋的是 repo-relative 形狀本身可判別的逃逸形式。判別不出的形式——例如 symlink 指向 repo 之外、或宣告一個實際不存在的路徑——不在本變更範圍，因為兩者都需要檔案系統存取，而以存在性判定路徑已在 proposal `## Alternatives Considered` 具名否決。

選擇拒絕而非解析的理由有二。其一，trace 的用途是逐字對回 proposal 與 tasks 的宣告；把 `a/../b` 寫成 `b` 會使 trace 的值在原始 artifact 中根本不存在，稽核時無法比對。其二，解析無法單獨成立：`../x` 解析後仍在 repo 之外，仍需要一個拒絕條件，等於兩套規則並存而非一套。拒絕是既有 helper 已經在用的失敗形式（`/` 起首與不含斜線都回傳 `None`），新增條件與既有形狀一致。

此規則對 `code` 與 `tests` 同時生效，因為兩者共用 `_canonical_path`；`tests` 側的裸檔名映射在 `_canonical_path` 之前判定，不受影響。實測現行語料受影響條目為 0：`- Affected code:` 子清單含 `../` 的行 0 個；驗證子句 code span 內含 `..` 段而**且**滿足測試判準的 token 0 個（本 change 自身的 tasks.md 有數個含 `..` 的示例 token，但它們不在驗證子句的 code span 位置或不滿足測試判準，故不進入 `tests`——語料等價性實測差異為 0 即為此事實的驗證）。

**D2：標籤列比對改為「strip 後前綴相等」，容忍面明確界定為兩個維度。**

改動有四處，互為前提：

1. `- Affected code:` 的定位由 `line == list_label` 改為 `line.strip().startswith(list_label)`。這同時涵蓋縮排與尾隨空白。
2. 命中的標籤列，其 colon 之後的殘餘字串以與一般內容行相同的方式收集（code span 分支與 `_PLAIN_PATH` 分支都套用）。若不收集，`- Affected code: path/to/x.py` 這種形式會定位成功但漏掉該行自己的路徑。
3. 同層終止條件由 `line.startswith("- Affected ")` 改為 `line.strip().startswith("- Affected ")`。這一項是 1 的必要配套而非獨立改動：若只放寬起點而不放寬終點，一份把兩個標籤都縮排書寫的 proposal 會在 `- Affected code:` 起點命中後永遠不終止，使 `- Affected specs:` 的 spec 路徑重新進入 `code`——正好逆轉前一個 change 的範圍收斂。
4. `## Impact` 的定位由 `line == heading` 改為 `line.rstrip() == heading`。這是同一個整行相等比對的失敗類別，落空後果也相同。只正規化尾端而不 strip 前端，因為 markdown ATX 標題必須位於行首，容忍縮排標題不對應任何合法書寫形式。

**容忍面為何停在這裡。** 語料證據（基數為本 change 以外的 28 份 proposal）：其 `- Affected code:` 全部是精確形狀，缺口本身的出現數為 0；但同一份模板的 sibling 標籤 `- Affected specs:` 有 22 份帶 colon 之後的行內內容、僅 6 份為純標籤。

**這項證據支持什麼、不支持什麼，必須分開陳述。** 逐份檢視那 22 份的行內內容，其實際形態是 capability 名稱與中文說明散文（如 `- Affected specs: \`cash-cli\`` 或後接括號說明），**沒有任何一例是把檔案路徑寫在標籤列上**。因此證據支持的命題是「這個標籤位置的作者慣例會在 colon 之後續寫內容」，而不是「會在 colon 之後續寫路徑」。行內**路徑**形式的語料出現數為 0，與缺口本身的出現數同為 0。

據此，放寬起點定位（容忍行內內容存在）由 22/28 的慣例直接支撐；而收集該行殘餘內容（Contract 3）則是為了讓「定位成功但漏收該行自己的路徑」這個不一致不存在，其必要性來自規則的自洽而非語料頻率。前後空白則是任何手寫編輯都可能引入的零語意差異，與語料頻率無關。粗體與全形冒號兩者語料證據皆為 0，且剝除 markdown 強調標記會開啟不封閉的正規化面——一旦接受 `- **Affected code:**`，`- *Affected code:*`、`- __Affected code:__`、`- \`Affected code:\`` 等形式都會成為下一個要不要接受的問題，而每接受一種都擴大「散文行被誤判為子清單起點」的面。前綴相等加上明確列舉的兩個維度是可界定的最小集合。

**前綴相等不會誤命中相鄰標籤。** colon 屬於比對前綴的一部分，因此 `- Affected codebase:` 這類字串不會命中 `- Affected code:`。散文行只要不以該標籤逐字起首就不會被誤判為起點；本專案既有 proposal 中提及 `- Affected code:` 的散文行都以編號或其他 bullet 文字起首，實測不受影響。

**D3：以語料等價性作為本變更的主要迴歸判準。**

兩項改動都是護欄，正確性的第一判準是「對現行語料零影響」。以原型對現行實作逐檔比對（基數為含本 change 自身在內的全語料，量測時為 29 份 `proposal.md` 與 29 份 `tasks.md`）：`code` 結果差異 0 份、`tests` 結果差異 0 份，兩側皆無任何檔案需要排除。tasks 因此 MUST 以新舊實作對全語料比對並斷言逐檔完全相等——這與前一個 change 的超集斷言不同：本變更兩側都不預期有任何增減，任何一處差異都是實作偏離設計的訊號。

語料是會變動的基數：後續 change 新增的 artifact 會改變份數，實作時的實際份數 MUST 以執行當下枚舉為準，MUST NOT 以本文件記錄的數字作為斷言條件。本文件的份數只用於說明量測基礎。

## Implementation Contract

1. `.cash-skills/lib/cash_cli/spec_merge.py` 的 `_canonical_path` 在既有兩個 `None` 條件之後、`return value` 之前，增加兩條：剝除後的值以 `/` 切分，（i）任一段屬於 `{"", ".", ".."}` 時回傳 `None`；（ii）第一段以 `~` 起首時回傳 `None`。（ii）MUST 只判定第一段，使 `a/~b/c.py` 這類在後續路徑段含 `~` 的合法路徑維持被接受。既有的反覆剝除迴圈與兩個既有條件 MUST NOT 改動。
2. 同檔 `_paths_in_section` 的四處定位條件改為：`## Impact` 以 `line.rstrip() == heading` 判定；`- Affected code:` 起點以 `line.strip().startswith(list_label)` 判定；同層終止以 `line.strip().startswith("- Affected ")` 判定；`## ` section 終止條件維持 `line.startswith("## ")` 不變（ATX 標題必位於行首）。
3. 同檔 `_paths_in_section` 在標籤列命中時，MUST 對 `line.strip()` 去除 `list_label` 前綴後的殘餘字串套用與一般內容行相同的收集流程（先 `_CODE_SPAN.findall` 取含斜線的值，再對 `_CODE_SPAN.sub(" ", 殘餘)` 套用 `_PLAIN_PATH`，兩組各自經 `_canonical_path`）。為避免收集邏輯在標籤列與內容行兩處重複，MUST 將其抽為單一個區域 helper 或等價的單一呼叫點。
4. `_verification_path`、`_task_paths`、`_PLAIN_PATH` 字元集、`_VERIFICATION_CLAUSE`、去重與 byte 排序 MUST NOT 改動。`tests` 側的行為變化 MUST 只來自共用的 `_canonical_path`。
5. `scripts/cash-cli/tests/test_sync_archive_transaction.py` 新增涵蓋以下情形的 case：`code` 側 `../` 路徑、`~/` 路徑、`.` 段路徑、內部連續斜線各不入結果，且第一段不以 `~` 起首而後續段含 `~` 的路徑仍入結果；`tests` 側 `../` 與 `~/` 測試路徑不入結果；`- Affected code:` 標籤帶尾隨空白、帶縮排、帶 colon 之後行內路徑三種形式都能定位且收集到路徑；`- **Affected code:**` 粗體形式與 `- Affected code：` 全形冒號形式維持不被定位（明示不容忍的兩個護欄）；縮排的 `- Affected specs:` 能終止縮排的 `- Affected code:` 子清單；`## Impact ` 帶尾隨空白仍能定位。既有全部 case MUST 維持綠燈，特別是 `test_trace_path_extraction_never_crosses_lines` 與 `test_sync_applies_fixed_phases_and_is_idempotent`。

   拒絕類 case 的斷言 MUST 為集合相等（例如 `code == ["a/b.py"]`）而非僅斷言「該值不在結果中」，使解析後的形式也必然被偵測到，否則 D1「拒絕而非解析」的核心決策完全未被固定。理由：把 Contract 1 誤讀為「濾掉不合格的路徑段」而非「整個值回傳 `None`」是實作者真的會寫出來的形態，而該實作對 `../`、`.` 段、內部連續斜線、`~/` 四者全部產生落在 repo 內的合法值（實測依序為 `outside/x.py`、`a/b.py`、`a/b.py`、`outside/x.py`），會通過僅斷言「不含原字面值」的 case。（`os.path.normpath` 不摺疊開頭的 `..`、也不展開 `~`，因此它只對 `.` 段與連續斜線造成同類問題，MUST NOT 被引為 `../` 與 `~/` 的理由。）

   粗體與全形冒號兩個護欄 case 的 fixture，其精確形狀子清單 MUST 置於該兩個標籤列之後。`- **Affected code:**` 經 strip 後既不成為子清單起點也不成為同層終止條件，因此排在一個已開啟的子清單之後時，它與其下的路徑會被當成一般內容行收進 `code`——那是既有範圍定義的結果而非實作缺陷，順序約束是 fixture 的必要條件。
6. `cash-skills.version` MUST 以相對方式提升：實作時讀取工作區當下值與 `git show HEAD:cash-skills.version`，寫入嚴格大於兩者的下一個版本並維持單行 LF 結尾。MUST NOT 寫死常數。之後在 project root 執行 `./install-cash-skills.fish --self` 重建 receipt。
7. 全語料等價性 MUST 以獨立驗證確認：對全部 `proposal.md` 與 `tasks.md` 以新舊兩版抽取器比較，斷言兩側結果逐檔完全相等。取得舊版的方式——把整個 `.cash-skills/lib/cash_cli` 套件複製到暫存目錄、以 `git show HEAD:.cash-skills/lib/cash_cli/spec_merge.py` 覆寫其中的 `spec_merge.py`、加入 `sys.path` 後 import。複製後的套件目錄 MUST 改名（例如 `cash_cli_old`）：同一個直譯器內不可能同時存在兩個 `cash_cli`，若沿用原名，`sys.path` 先命中者會同時充當新舊兩側，比較必得 0 差異而使斷言空洞地通過。以 `git worktree add` 取得完整 HEAD 樹時有同一個問題，或改以兩個 subprocess 分別執行兩版。

   退化守衛 MUST 為行為 sentinel 而非僅比對檔案 bytes：先斷言 `old.__file__ != new.__file__`，再斷言 `old._canonical_path("../x/y") == "../x/y"` 且 `new._canonical_path("../x/y") is None`，兩者任一不成立即以明確訊息失敗。bytes 比較（`git show HEAD:` 的內容與工作區內容不同）MAY 保留為輔助，但 MUST NOT 作為唯一守衛——它檢查的是檔案而不是實際被 import 的兩個模組物件。語料枚舉 MUST 以 `os.walk` 或 `find` 進行以涵蓋隱藏目錄。

## Risks / Trade-offs

- **縮排容忍使巢狀清單中的標籤也成為起點**：若某份 proposal 在 `## Impact` 之下寫了巢狀結構，其中縮排出現一個 `- Affected code:` 字樣，該處會被當成子清單起點。語料出現數 0，且該書寫本身即表示作者意圖宣告 affected code，誤判方向與作者意圖一致。
- **行內內容納入收集範圍會擴大 ASCII 散文偽陽性的面**：`- Affected code: 見下方清單` 這類散文若含以斜線分隔的 ASCII 片語，會與既有的 `runtime/install` 偽陽性同類。這是前一個 change 已具名接受的取捨的自然延伸，不是新的取捨類別。
- **標籤列殘餘內容的 code span 分支會收進「被引述而非被修改」的路徑，且嚴重度高於上一項**：sibling 標籤的實測行內形態是夾雜 backtick 引用的中文說明散文（例如在括號說明中引用 `scripts/spectra-plus/rules.yaml` 作為對照）。作者若比照該慣例把說明寫在 `- Affected code:` 標籤列上，其中被引述的檔案會被逐字寫進 `code`。這與 `runtime/install` 不同層級：`runtime/install` 一望即知不是檔案，而被引述的路徑是一條完全合法的真實路徑，稽核時無從分辨它是「宣告要改」還是「順帶提到」。以字元集或 ASCII 判準都無法區分兩者——能區分的只有作者意圖。本變更接受此代價，因為替代方案（標籤列只定位、不收集其行內內容）會讓「定位成功卻漏收該行路徑」成為新的靜默落空，比偽陽性更難察覺。
- **同層終止條件放寬引入了一個新的提前終止面**：`strip().startswith("- Affected ")` 是純粹的擴張，因此 `- Affected code:` 子清單內任何縮排且以 `- Affected ` 起首的 bullet 都會提前終止子清單，其後的路徑被靜默丟棄。語料出現數 0，且該書寫與模板規定的 `- New:`／`- Modified:`／`- Removed:` 三個巢狀標籤不相容，但方向與起點側的擴張相反，一併記錄使 Risks 對稱。
- **拒絕而非解析會靜默丟棄 `a/../b` 這種可解析的寫法**：作者若真的這樣書寫，該條目不會進入 `code` 且沒有訊號。這與既有的「repo root 層級、不含斜線的宣告永遠不入 `code`」屬同一類已知靜默丟棄，可見性同屬後續 change 的範圍。
- **粗體與全形冒號標籤仍是落空面**：本變更明示不容忍，因此 `- **Affected code:**` 與 `- Affected code：` 都仍得到空 `code`。這是為了讓容忍面可界定而付出的代價，兩者各以一個測試 case 固定該行為，避免日後被誤認為疏漏而隨手放寬。
- **實際容忍的空白類別比「前後空白」字面更寬**：`str.strip()` 與 `str.rstrip()` 依 Python `isspace()` 判定，因此 U+3000（全形空格）、U+00A0（NBSP）等 Unicode 空白也會被吞掉，實測 `　- Affected code:` 與 `## Impact　` 都會命中。此擴張為零語意且封閉（空白就是空白），與全形冒號屬不同類——後者改變的是標籤本身的 token 而非其周邊空白，因此「拒絕全形冒號、接受全形空格」不是雙重標準。此處記錄是為了讓「容忍面可界定」這個論證的實際邊界與宣告一致。
- **receipt 失效區間**：`spec_merge.py` 屬 receipt 受管的 runtime 記錄，自第一次寫入起每個 Cash 指令都會以 `receipt_invalid` 失敗，直到執行 `./install-cash-skills.fish --self` 重建為止；tasks MUST 據此安排順序與 `task done` 的補標時機。
- **版本號與並行 change 相撞**：`cash-skills.version` MUST 以執行當下讀到的工作區值與 `git show HEAD:cash-skills.version` 兩者的最大值決定下一個版本，不得寫死常數。兩者相等是合法狀態（前一個 change 已提交時即為如此），MUST NOT 據此推斷環境異常；兩者不等也是合法狀態（有 sibling change 已在工作區提升而尚未提交）。以最大值為基準使兩種狀態都得到嚴格遞增的結果。

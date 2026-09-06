# Cash Propose Review — Round 3

## Reviewer Findings

本輪為本次執行的第三輪。依位置推導（第三輪、非第四輪）為 `micro` 輪，由一位全新的 Reviewer V 進行差異驗證。

### 累積 blocking 集合逐成員裁定

Reviewer V 對 Round 2 留下的 3 個成員各回傳明確裁定，主 agent 逐條覆核。

**verified resolution（3 項，全部移出集合）**

- F1 — `resolved`。design.md `## Goals / Non-Goals` 現存四項 Non-Goal，已無「不調升 `cash-skills.version`」子句；跨全部 artifact grep `不調升` 為 0 命中，與 D7、tasks 1.1、proposal `## Impact` 一致。修正參照：Round 2 `## Fix Actions` F1。驗證 reviewer：Reviewer V。
- F2 — `resolved`。design.md `## Implementation Contract` 的 `--hook` 介面條目與 specs/cash-cli/spec.md 的 scenario 均已改為 D3 的列舉措辭，且 cash-cli scenario 新增 `.parked` 本身不被當成 change 的斷言；跨檔 grep「非 archive 的目錄」為 0 命中。修正參照：Round 2 F2。驗證 reviewer：Reviewer V。
- F3 — `resolved`。design.md D6 與 R7、round-gate spec 的 Stop hook requirement、tasks 1.6 與 1.7 均已改為「仍執行判定並輸出當次未解決失敗項」；grep `上一次` 僅餘 design 與 spec 中刻意的 MUST NOT 排除條款。修正參照：Round 2 F3。驗證 reviewer：Reviewer V。惟該修正在 scenario 標題留下一處殘留，以 V1 形式回報並重新進入集合。

### Warning（blocking）

**V1** — `severity`: Warning｜`confidence`: 90｜`layer`: design｜`disposition`: `unresolved-prior`（F3 的殘留出現處）｜`location`: specs/cash-round-gate/spec.md `#### Scenario: 重入時立即結束`
`summary`: F3 的修正把「立即」自 D6 與 requirement 正文移除，但重入 scenario 的標題仍是「重入時立即結束」，與同一 scenario 的 GIVEN／THEN 及 D6 的「仍執行判定」直接相反。
`recommendation`: 標題改為「重入時仍執行判定後放行」或等義措辭。
主 agent 覆核：成立。全檔 grep `立即` 唯一命中即此處。Round 2 `## Fix Actions` 的 F3 條目載明「重入 scenario 的 GIVEN 與 THEN 由『上一次判定』改為『當次判定』」——只列了 GIVEN 與 THEN，標題再次成為同一概念未被傳播到的出現處。這是本迴圈連續第三輪出現同一失效模式。

### Warning（非 blocking，`new`）

**V2** — `severity`: Warning｜`confidence`: 80｜`layer`: design｜`disposition`: `new`｜`location`: design.md D4；specs/cash-round-gate/spec.md `### Requirement: Grader immutability 以三方比對判定`；D3 與 Stop hook requirement 的列舉語意
`summary`: 變更集合是 repository 全域（工作區相對 `HEAD` 加 untracked），但 structured scope declarations 逐字限定為「該 change」的，而 `--hook` mode 對每個被列舉 change 各自判定且任一 fail 即 exit `2`。兩個以上 active change 並存時，change A 合法宣告的受保護路徑改動會在 change B 的比對中判為未宣告，使阻擋型 hook 對合法工作每個 turn 產生偽陽性；被列舉進來的 parked change 其最後一輪 `## Decision` 常正是 `next_round`，使該情形更易成立。R3 只涵蓋宣告解析器過寬／過嚴，R2 只涵蓋歷史違規 round file，兩者都未涵蓋這條跨 change 歸屬問題。
`recommendation`: 明訂涵蓋判定取全部被列舉 change 宣告的聯集，或以 Risk 逐字記錄該偽陽性。
主 agent 覆核：成立，且屬設計層而非實作層缺口。目前 repo 僅有本 change 故尚未觸發。依既有通過條件，`new` 且不符 Safety exception 者為非 blocking——本 finding 無資料遺失或安全邊界違反的具體證據，屬可用性偽陽性，不適用 Safety exception。以 triage 註記處理，並納入 signals 寫入步驟。

### Suggestion（非 blocking）

- **V3**（reviewer 給 Warning 75，經信心過濾降為 Suggestion）｜`disposition`: `new`｜`location`: specs/cash-round-gate/spec.md 的「`openspec/specs/` MUST 視為目錄型宣告」與「目錄型宣告 MUST 涵蓋其下全部檔案」；tasks.md 1.4
  `summary`: 這兩條 MUST 是 D4 路徑集合語意中唯一具展開行為的規則，但兩份 spec delta 都沒有能區分「有無正確實作目錄型展開」的 scenario，tasks 1.4 的 case 列表也無對應 case，形狀與 Round 1 被判 blocking 的 W3 相同。
- **V4**（Suggestion 50）｜`disposition`: `new`｜`location`: tasks.md 1.5 與 1.7 的 `red` 欄位
  `summary`: 兩者的 `red` 描述「若實作錯誤則會失敗」的假設條件，而非 task 開始前 primary target 上實際可觀察的紅燈；正確形狀見 1.3。Round 1 的 S3 只修了當時的 1.3。
- **V5**（Suggestion 50）｜`disposition`: `new`｜`location`: tasks.md 1.4 與 1.6 的 `verification` 與 `success` 欄位
  `summary`: `verification` 以 `-k` 過濾，`success` 卻寫「全部新增 case」，被過濾掉的 case 在該 primary target 的執行結果中不可觀察，`success` 觀察面寬於 verification target。

## Rating

- post-filter 累積 blocking 集合 `Critical` 數：0
- post-filter 累積 blocking 集合 `Warning` 數：1
- 非 blocking triaged finding 數：4
- `critical_gap`：`false`
- `round_type`：`micro`

理由：Round 2 的 3 個成員全部經 Reviewer V 以當前 artifact 原文驗證解決並移出集合，集合因此清空；F3 的一處殘留以 V1 重新進入，`disposition` 為 `unresolved-prior` 故為 blocking。V2 雖為 `confidence` 80 的 `Warning`，但 `disposition` 為 `new` 且不符 Safety exception——它是可用性偽陽性，無資料遺失或安全邊界違反的具體證據——依既有通過條件為非 blocking。V3 經信心過濾由 `Warning` 降為 `Suggestion`。集合僅含 V1 一筆 `Warning`，不含 `Critical`，故 `critical_gap` 為 `false`，但集合非空，本輪仍不通過。

## Fix Actions

本輪修正 1 筆 blocking finding 與 4 筆非 blocking finding。修改檔案 4 個：`proposal.md`、`design.md`、`specs/cash-round-gate/spec.md`、`tasks.md`。`specs/cash-cli/spec.md` 本輪未修改。

**V1**（blocking，修正）：specs/cash-round-gate/spec.md 的 scenario 標題由「重入時立即結束」改為「重入時仍執行判定後放行」。修正後全部 artifact grep `立即` 為 0 命中。

**V2**（非 blocking `new`，triage 註記並一併修正）：triage 註記——跨 change 歸屬問題屬設計層缺口，目前 repo 僅有本 change 故未觸發，但 `--hook` mode 的多 change 列舉使其必然在日後成立。本輪採 recommendation 的第一個選項而非僅記 Risk：design.md D4 新增一段，明訂變更集合為 repository 全域而宣告為 per-change、兩者粒度不同，因此涵蓋判定 MUST 取全部被列舉 change 宣告的聯集，並逐字說明逐 change 各自比對會造成的偽陽性與 parked change 使其更易成立的理由；specs/cash-round-gate/spec.md 的對應 requirement 同步加入該段並改為「受保護路徑只要被任一被列舉 change 的 structured scope declaration 涵蓋即 MUST NOT 判 `fail`」；proposal.md 的機制描述同步。新增 scenario「另一個 change 的宣告涵蓋該路徑」。本 finding 仍依既有規定納入 signals 寫入步驟。

**V3**（非 blocking Suggestion，triage 註記並一併修正）：triage 註記——目錄型展開缺 distinguishing scenario 與 backing test。新增兩個 scenario：「目錄型宣告涵蓋其下檔案」（宣告 `openspec/specs/` 後其下 master spec 改動判 `pass`）與「未宣告即修改 master spec」（無任何被列舉 change 宣告時判 `fail`）；tasks 1.4 的 case 列表補上這兩項與 V2 的跨 change case。

**V4**（非 blocking Suggestion，triage 註記並一併修正）：triage 註記——`red` 欄位形狀不一致。tasks 1.5 的 `red` 改為「1.4 的全部 immutability case 在 D3 的活動判定與 D4 的三方比對實作之前失敗」，1.7 改為「1.6 的全部 hook case 在 `--hook` mode 實作之前失敗」，與 1.3 的形狀對齊。

**V5**（非 blocking Suggestion，triage 註記並一併修正）：triage 註記——`success` 觀察面寬於 verification target。tasks 1.4 與 1.6 的 `success` 改為「該過濾條件下的全部新增 case 被蒐集且無 collection error」。

**修正後重跑的檢查**：`validate` 通過；pre-round mechanical self-check 全數重跑通過——annotation lint 兩份 delta 的 `<!--`／`-->` 皆為 0 且無 stray `---`；spec delta title-identity 確認 `### Requirement: Cash workflow command surface` 逐位元組存在於 master spec；tasks 九項的五個欄位無缺漏、無 `TBD`／`TODO` 佔位；delivery 路徑與 proposal `## Impact` 雙向對應 9 對 9；signal-derived checks 中仍無任何 signal 定義 `check` 欄位。round-gate spec 現有 6 個 requirement 與 26 個 scenario。

**針對連續三輪同一失效模式的強化傳播檢查**：本迴圈連續三輪都出現「修正只套用在 reviewer 指名處、未傳播到同概念其他出現處」。本輪對每個修正概念改以全 artifact 全文 grep 逐字確認而非僅檢查旗標位置：`立即` 0 命中；`聯集` 在 proposal、design、round-gate spec 各 1 處且語意一致；`red` 與 `success` 欄位以程式化檢查逐 task 驗證五欄位齊備。此外把 scenario 標題明確納入檢查面——V1 正是標題未被視為「出現處」而漏改。

**範圍外或未修復事項**：無。本輪無 `未修復：裁判面保護` 紀錄，無 accepted-risks 降級。disposition 覆核：V1 的 `unresolved-prior` 經比對 Round 2 的 F3 成立；V2 至 V5 的 `new` 經比對前兩輪全部 blocking finding 與 triage 註記，均無對應項，標記成立。主 agent 另檢查 V2 至 V5 是否位於本迴圈 fix 動作觸及的位置：V3 至 V5 位於 Round 1 與 Round 2 修改過的 tasks 與 spec 區段，但其缺陷並非源自那些修正動作——V3 的目錄型條款自 Round 1 W6 加入時即無 scenario、V4 的 `red` 形狀問題在 Round 1 S3 只修 1.3 時即已存在於其他 task、V5 的 `-k` 過濾自 tasks 初版即如此——屬既有未被發現的缺陷而非修正引入，故維持 `new`，不更正為 `fix-introduced`。無 blocking 轉非 blocking 的更正。

## Decision

`next_round`

本輪 post-filter 累積 blocking 集合含 1 筆 `Warning`（V1），不含 `Critical`，不符通過條件。該筆與 4 筆非 blocking finding 均已在本輪 `## Fix Actions` 記錄對應修正並實際套用，修正後 `validate` 與 pre-round mechanical self-check 皆重跑通過。依位置推導，下一輪是本次執行的第四輪，故 MUST 為 `full` checkpoint 輪，由兩位全新獨立 reviewer 進行完整重新掃描，且兩位都 MUST 對累積 blocking 集合的每位成員回傳明確的 resolved／unresolved 裁定。

# Cash Propose Review — Round 3

本輪為 micro 輪，由單一 Reviewer V — Verification 對 round 2 的 cumulative blocking set 做 delta 驗證，並重點檢查 round 2 的改設計（錯誤訊息由內嵌清單改為指向 help）。

## Reviewer Findings

### Cumulative blocking set 逐項判定

round 2 的 4 個 blocking 成員與 2 個非阻斷項全數 `resolved`：

| member | verdict | 依據摘要 |
| --- | --- | --- |
| N1 | resolved | scenario WHEN 已為 `new bogus <artifact-id>`；核對 `create.py:114` 的 `len(arguments) < 2` 早於 `:120-121` 的 mode 判定，兩個 argument 確實抵達 `unknown_command` |
| N2 | resolved | IC4 與 tasks 1.1 皆為「逐元素等於排序後的 key 序列」；核對 `main.py:97-113` 插入序首項 `list`、排序後首項 `analyze`，該斷言可實際攔到 `list(COMMANDS)`，且期望值以獨立 `sorted` 導出而非恆真 |
| N3 | resolved | IC1 與 tasks 2.3 皆限定為內容接受集合並明文排除 mode／identity；核對 `installer.py:291-300` 與 `:147-170` 確認內容與 identity 為兩層，限定可達 |
| N4 | resolved（設計層），傳播有殘留 → F1 | 改設計在 spec、design D3／IC3、tasks、proposal 皆已到位 |
| N5 | resolved | spec 已改為「該LF條款由本requirement擁有……兩者 MUST一致」；核對 master `:899` 確認該 requirement 只定義格式、未提 LF |
| N6 | resolved | tasks 2.3 已補派生負面 fixture 的做法，與「全檔不含版本字面值」不再抵觸 |

### 改設計的專項查核（Reviewer V，以原始碼求證）

- **訊息穩定性成立**：新措辭只在既有訊息後附加固定的指向 help 文字，字串無任何分量取自 `COMMANDS`，增刪 key 不改變訊息。
- **fixture 更新確為一次性**：`test_negative_atomicity.py:437` 為整個 object 相等比對，訊息一變須同批改；但新訊息不含清單，後續 dispatch table 變動不再觸發它。
- **指向 `--help` 在 receipt gate 之下仍正確，且比 artifact 寫得更強**：核對 `.cash-skills/bin/cash:290-300` 的 `flock` → `validate_receipt` → `import main`，兩個 dispatch 層錯誤只可能在 receipt 已通過之後產生，使用者看到訊息時 `--help` 必定可達；fresh clone 根本不會走到這兩個錯誤。
- **可發現性目標未被掏空**：錯誤訊息由「不說有哪些」升級為「明確指出去哪裡看」，只多一次跳轉；列舉本身由 help 承擔。

### Warning

**F1**（confidence 100，`layer`: text，`fix-introduced`）design `## Risks / Trade-offs` 仍寫「該組合會走 `unknown_command`（訊息會列出可用 command）」，與同份 design 的 IC3「SHALL NOT 內嵌 command 清單」及 spec 的 `MUST NOT內嵌command清單` 直接衝突。`introduced_by`：propose-r2 `## Fix Actions` 的「**修 N4（改變設計，不只改敘述）** …… spec、design D3、IC3、tasks 1.1／2.1／2.2、proposal 全部同步改寫」——該清單未含 design 的 Risks 段，且同節自檢宣稱「舊措辭全 artifact 零殘留」與事實不符，正是本 repo 反覆出現的「Fix Actions 宣稱覆蓋大於實際施作」形狀。

### Suggestion（非阻斷）

- **F3**（80）scenario 標題仍為 `缺少 command 時揭露可用集合`，但其 AND 已改為「指向help flag，且不內嵌command清單」——標題宣稱揭露，內容規定不揭露。
- **F2**（60）tasks 2.3 的「fixture 須以 `0644` 建立，使拒絕理由唯一為形狀而非 mode」與同句稍前的「不得因此在本檔加入 mode 檢查」互相抵觸：驗證既然不看 mode，mode 就不可能成為拒絕理由。
- **F4**（50，`new`）tasks 1.1 要求在 `scripts/cash-cli/tests/test_runtime_and_errors.py` 斷言 `bootstrap_invalid`／`receipt_invalid`，但那兩個 code 只由 launcher 產生、需要真實安裝的 target，而該檔目前是零 subprocess 的純 unit test；任何 artifact 都未指出這項成本。

## Rating

- post-filter cumulative blocking set Critical count: **0**
- post-filter cumulative blocking set Warning count: **1**（F1）
- 非阻斷 triaged finding count: **3**（F2、F3、F4）
- `critical_gap`: **false**
- `round_type`: **micro**

rationale：round 2 的 4 個成員全部以 verified resolution 離開集合，缺陷密度續降（r1 為 1C+8W、r2 為 0C+4W、本輪 0C+1W），且本輪唯一的 blocking 是一句未清乾淨的舊敘述而非設計缺陷。Reviewer V 對 round 2 改設計的四項專項查核全部以原始碼證實成立，其中「使用者看到 dispatch 層錯誤時 `--help` 必定可達」比 artifact 原本的敘述更強——因為那兩個錯誤只可能在 receipt 驗證通過之後產生。

## Fix Actions

1 個 blocking 成員與 3 個非阻斷項全部修復。無 grader-protection 保留項，無 accepted-risks 條目。修改檔案共 4 個：`proposal.md`、`design.md`、`tasks.md`、`specs/cash-cli/spec.md`。

**修 F1** — design `## Risks / Trade-offs` 的括號改為「訊息會指向 help flag」，與 IC3 及 spec 一致。條目其餘部分（觸發規則只認第一個引數、日後擴張為相容變更）不受改設計影響，原樣保留。

**修 F3** — spec 的 scenario 標題改為 `缺少 command 時指向 help`，tasks 1.1 的具名清單同步，維持雙向對應。

**修 F2** — tasks 2.3 的 `0644` 理由改寫為「與 `source_inventory` 的安裝時前置條件一致，避免日後有人誤讀為本驗證放寬了 mode——本驗證本身不看 mode，因此 mode 不會成為拒絕理由」，消除同句內的矛盾。

**修 F4** — 把 receipt gate 的覆蓋從 tasks 1.1 移出，新增 task 1.2 置於 `scripts/cash-cli/tests/test_negative_atomicity.py`，並在該 task 寫明放置理由（兩個 code 只由 launcher 產生、需真實安裝 target，而 `test_runtime_and_errors.py` 是零 subprocess 的純 unit test；本檔的 `LauncherLockTests` 已有可沿用的安裝 setUp 樣板）。IC4 增列同一放置規則。proposal `## Impact` 加入 `scripts/cash-cli/tests/test_negative_atomicity.py`。tasks 由 7 個增為 8 個。

**修正後的機械自檢與驗證** — 4 份 artifact comment/annotation 平衡皆 0/0；兩個 MODIFIED 標題與 master 逐 byte 相符；7 個新增 scenario 與 tasks.md 雙向對應無缺漏；Impact 的 7 個含 `/` 路徑全部被 tasks 引用；ghost bold 為 0；無 lowercase `may`／`should`；舊措辭（`訊息會列出可用 command`、`揭露可用集合`）全 artifact 零殘留。重跑 `cash validate` 通過，`cash analyze` 非 Suggestion finding 為 0。

**Signal-derived checks** — 全部 open signal 無 `check` frontmatter，採 best-effort。本輪最相關者：`review-fix-propagation-incomplete`（F1、F3 —— 改設計未掃到 Risks 段與 scenario 標題）、`acceptance-criterion-unreachable-at-specified-point`（F4 —— 驗收指定在不具備該設施的測試檔）。

## Decision

next_round

post-filter cumulative blocking set 含 0 個 Critical 與 1 個 Warning（F1），未滿足 pass 條件。round 2 的 4 個成員已全部以 verified resolution 離開集合。F1 與 3 個非阻斷項皆已完成 fix 並記錄於 `## Fix Actions`。下一輪為本次執行的第四輪，依規則為 `full` 輪：spawn 兩個 fresh reviewer 平行執行完整重掃，並各自對 F1 給出 resolved/unresolved 判定。

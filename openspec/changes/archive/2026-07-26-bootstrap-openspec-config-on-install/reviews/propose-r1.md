# Cash Propose Review — Round 1

## Reviewer Findings

本輪為 unseeded run 的第一輪（`round_type: full`），兩位 reviewer 獨立審查後依 `location + summary` 聚合。第一輪全部 surviving `Critical`／`Warning` 皆為 blocking，故不標註 `disposition`。

### Critical

無。

### Warning

1. **FIFO 形狀判定會阻塞而非 fail closed**
   - `severity`: Warning｜`confidence`: 90｜`layer`: design
   - `location`: `design.md` D1；`specs/cash-cli/spec.md` preflight 段與 `#### Scenario: openspec config 的 unsafe shape 不被視為缺檔`
   - `summary`: delta spec 新宣告「非 regular file MUST 以 execution error 失敗」，但 D1 指定的 `optional_snapshot` → `read_regular` 路徑對 FIFO 會在 `os.open(O_RDONLY|O_NOFOLLOW)` 無限阻塞。
   - `recommendation`: 沿用 `ensure_regular_gitignore` docstring 已記載的作法，在任何 open 之前先以 `lstat` 判形狀。
   - reviewer 來源：A（F4，confidence 70）與 B（Finding 1，confidence 72，並實測 FIFO 5 秒 alarm 未返回、hard link 與 directory 正確報錯）獨立提出；合併後採 90，因為兩者提供的證據直接證明新條文與指定機制不相容。

2. **spec 以 MUST 要求回滾新建的 config，但零測試覆蓋**
   - `severity`: Warning｜`confidence`: 85｜`layer`: design
   - `location`: `specs/cash-cli/spec.md` config deployment 段；`tasks.md` 第 1 節
   - `summary`: 「該回滾 MUST 涵蓋新建的 `openspec/config.yaml`」沒有任何 task 觸發 publication failure，實作若改用 `atomic_write` 直寫也會全綠通過。
   - `recommendation`: 以既有 `TEST_CASH_INSTALL_FAIL_AFTER_PATH` fault-injection pattern 新增紅燈 task。
   - reviewer 來源：A（F2，85）與 B（Finding 2，78）。

3. **`cash-skills.version` 寫死 `2.6.0` 與 sibling change 衝突**
   - `severity`: Warning｜`confidence`: 90｜`layer`: design
   - `location`: `design.md` Implementation Contract 第 9 項；`tasks.md` 3.1
   - `summary`: `rightsize-cash-skills` 與 `support-multi-file-skill-payload` 兩個 in-flight change 也宣告要提升同一檔案，任一先落地都會使 `check_history` 因「不嚴格大於 HEAD」或「內容漂移」而失敗。
   - `recommendation`: 改為相對指令，執行時重新讀取工作區值與 `git show HEAD:cash-skills.version`。
   - reviewer 來源：A（F1，90），並引用已封存的 `2026-07-25-tolerate-versioned-legacy-guidance-marker` task 2.5 逐字記載的同類事故。

4. **baseline 綁定本 repository 的 `openspec/config.yaml` 自我矛盾且無守衛**
   - `severity`: Warning｜`confidence`: 85｜`layer`: design
   - `location`: `design.md` D2 與 Implementation Contract 第 2 項；`specs/cash-cli/spec.md` config deployment 段
   - `summary`: contract 要求常數與本 repo 的 project-owned 檔案逐 byte 相同，正是 D2 用來否決「從 source 複製」的那個危害；且 tasks 的斷言（regular file、`0644`、可解析）對「直接複製 source 檔案」的實作同樣全綠。
   - `recommendation`: 改以常數自身的性質定義（LF 結尾、首行 `schema: spec-driven`、其餘只有空行與 full-line 註解、parse 後 `context == ""` 且 `rules == {}`），並在 task 加上機械斷言。
   - reviewer 來源：A（F3，80）與 B（Finding 4，60）。A 另指出 IC2「其餘為 full-line `#` 註解」與實檔有三個空行不符（A-F7，text，55），本輪一併修正。

5. **`--register` 的語意在 spec 端不成立**
   - `severity`: Warning｜`confidence`: 85｜`layer`: design
   - `location`: `specs/cash-cli/spec.md` preflight 段；`design.md` Implementation Contract 第 6 項；`tasks.md` 1.5
   - `summary`: spec 把「缺檔由 config deployment 在同一 transaction 內建立」的主詞涵蓋 register，但 `--register` 分支只寫 registry、不開 transaction，讀 spec 者會得到錯誤結論；且成功且缺檔的 register 路徑無 scenario。
   - `recommendation`: 拆開主詞並補 `#### Scenario: 缺 openspec config 的 target 可被登錄`。
   - reviewer 來源：A（F5，70）與 B（Finding 7，55）；合併後採 85，因為這是本變更自身引入的條文內部矛盾。

6. **`current` 分類與「缺檔即建立」重疊而無優先序**
   - `severity`: Warning｜`confidence`: 80｜`layer`: design
   - `location`: `specs/cash-cli/spec.md` `#### Scenario: Current、newer 與 conflict 分類` 與 config deployment 段
   - `summary`: 已安裝但使用者刪除該檔的 target 同時滿足「全部一致 → MUST `current` 且零寫入」與「缺檔 MUST 建立」兩條 MUST。
   - `recommendation`: 於 scenario 條件補「`openspec/config.yaml` 存在」，並在條文明寫建立優先於 `current` 的零寫入契約；同時把「刻意刪除會被還原」記入 Risks。
   - reviewer 來源：B（Finding 3，62）；合併後採 80，因為 open signal `overlapping-classification-without-precedence` 正是同一 issue class，且兩條 MUST 的重疊可由條文直接證明。

7. **unsafe 形狀與 `--force` 的覆蓋不足**
   - `severity`: Warning｜`confidence`: 80｜`layer`: design
   - `location`: `tasks.md` 1.1、1.3；`specs/cash-cli/spec.md` unsafe shape scenario
   - `summary`: scenario 列舉三種形狀但 task 只測 symlink；hard link 是唯一依賴 `read_regular` 的 `st_nlink != 1` 檢查而非 `ensure_contained` 的形狀，實作若在缺檔分支改用寬鬆 `lstat` 判定會靜默通過；「invalid + `--force` 不繞過」與「MUST NOT 進入 receipt／MUST NOT 建立其他目錄」亦無斷言。
   - `recommendation`: 擴充 task 1.1 與 1.3 的斷言集合。
   - reviewer 來源：B（Finding 5，66）與 A（F6，60）。

8. **`-> bool` 回傳值與 `ensure_contained` 清單項為死碼**
   - `severity`: Suggestion（由 confidence 65 降級）｜`confidence`: 65｜`layer`: design
   - `location`: `design.md` Implementation Contract 第 3、6 項
   - `summary`: plan 一律由 `installation_inputs` 的 snapshot 導出，沒有任何呼叫點消費該 bool；`install_target` 開頭的 `ensure_contained` 清單在 `validate_target_prerequisites` 之後執行，先到先錯，不改變可觀察行為。
   - `recommendation`: 維持 `-> None` 並刪除該 contract 項。
   - reviewer 來源：B（Finding 6，70）與 A（F8，40）。

9. **dry-run scenario 的 `would-update` 措辭會誤導測試作者**
   - `severity`: Suggestion（由 confidence 60 降級）｜`confidence`: 60｜`layer`: text
   - `location`: `specs/cash-cli/spec.md` `#### Scenario: 缺 openspec config 的 dry run 零寫入`；`proposal.md` Proposed Solution 第 5 點
   - `summary`: `--target --dry-run` 實際輸出 `Result: update`，`would-update` 只是 batch mode 的 label。
   - reviewer 來源：B（Finding 10，42）；經主 agent 以 `installer.py:1594-1595` 與 `:1842` 直接查證後提高為 60。

10. **`main` 與 `run` 的位置指涉錯誤**
    - `severity`: Suggestion（由 confidence 78 降級為 text 類）｜`confidence`: 78｜`layer`: text
    - `location`: `design.md` Context 與 Implementation Contract 第 5 項；`tasks.md` 2.2
    - `summary`: `--register` 分支的 `validate_target_prerequisites` 位於 `run`，`main` 只是其錯誤包裝。
    - reviewer 來源：B（Finding 9，78）。

11. **跨版本死路診斷**
    - `severity`: Suggestion｜`confidence`: 52｜`layer`: design
    - `location`: `design.md` D5／Risks
    - `summary`: 舊版 installer 對「新版 bootstrap 中途崩潰」的 target 完成 recovery 後會撞回嚴格 preflight，得到無指引的訊息。
    - reviewer 來源：B（Finding 8，52）。以記入 Risks 處理，不擴張範圍。

## Rating

- post-filter 累積 blocking set Critical 數：0
- post-filter 累積 blocking set Warning 數：7
- 非 blocking triaged finding 數：0（本輪為 run 的第一輪，全部 surviving Critical／Warning 皆 blocking；編號 8–11 經 confidence filter 降級為 `Suggestion`，不計入 blocking set，但仍一併修正）
- `critical_gap`: false
- `round_type`: full
- 理由：兩位 reviewer 獨立指出七項阻斷性缺陷，其中三項（FIFO 阻塞、rollback 零覆蓋、版本寫死）具備直接的程式碼或歷史事故證據，兩項（register 語意、baseline 綁定）是本變更自身引入的條文內部矛盾，一項（`current` 重疊）命中既有 open signal 的 issue class，一項（unsafe 覆蓋不足）使 spec 明文 scenario 無測試背書。全部為 blocking，故 `decision: next_round`。

## Fix Actions

於 spawn 下一輪 reviewer 前完成，全部修改都在 change 目錄內，未觸及任何受保護的裁判面路徑。

1. **spawn reviewer 前的機械自我檢查（round 1 之前執行）**：抓到 `validate_target_prerequisites` 的第五個呼叫點（`installer.py:1810` 的 `--register` 分支）未被 `design.md` 與 `tasks.md` 涵蓋。修改 `design.md`（Context 段、Implementation Contract 第 5、10 項）與 `tasks.md`（新增 1.5、擴充 2.2）後才 spawn reviewer。
2. **Warning 1（FIFO）**：`design.md` D1 改寫為「先 `lstat` 判形狀、再 open」，新增 Implementation Contract 第 3 項定義 `ensure_regular_shape` 並讓 `ensure_regular_gitignore` 委派給它；`specs/cash-cli/spec.md` preflight 段新增「形狀判定 MUST 在任何 open 之前以 no-follow `lstat` 完成，FIFO MUST 以 execution error 失敗，MUST NOT 阻塞」；unsafe shape scenario 的 WHEN 改列 symlink／hard link／目錄／FIFO，THEN 補「不阻塞等待 writer」；`proposal.md` Proposed Solution 第 1 點同步；`tasks.md` 1.3 擴充三形狀並要求 `subprocess` 帶 `timeout=`。修改檔案：`proposal.md`、`design.md`、`specs/cash-cli/spec.md`、`tasks.md`。
3. **Warning 2（rollback 覆蓋）**：`tasks.md` 新增 1.6，以 `CASH_INSTALL_TEST_HOOKS=1` 與 `TEST_CASH_INSTALL_FAIL_AFTER_PATH=.gitignore` 注入 publication failure；`specs/cash-cli/spec.md` 新增 `#### Scenario: 缺 openspec config 的安裝失敗回滾該檔`；`design.md` Implementation Contract 第 10 項的測試清單補上該情形。修改檔案：`design.md`、`specs/cash-cli/spec.md`、`tasks.md`。
4. **Warning 3（版本寫死）**：`design.md` Implementation Contract 第 9 項與 `tasks.md` 3.1 改為相對指令並明列 MUST NOT 寫死的理由與兩個 sibling change 名稱；`design.md` Risks 中原本以 `2.6.0`／`2.5.0` 表述的跨版本情境改為「帶本變更的 installer」／「本變更之前的 installer」。已以 grep 查證兩個 sibling change 的 tasks 確實宣告遞增同一檔案。修改檔案：`design.md`、`tasks.md`。
5. **Warning 4（baseline 定義）**：`design.md` D2 補一段說明為何不綁定本 repo 檔案，Implementation Contract 第 2 項改以常數自身性質定義並明文 MUST NOT 綁定；`specs/cash-cli/spec.md` config deployment 段補 baseline 的形狀要求與 `context` 為空、`rules` 為空 mapping 的條件；`tasks.md` 1.1 加入「bytes 逐 byte 等於 `OPENSPEC_CONFIG_BASELINE`」斷言，2.1 的驗證指令加入 parse 結果與 LF 結尾的斷言。修改檔案：`design.md`、`specs/cash-cli/spec.md`、`tasks.md`。
6. **Warning 5（register 語意）**：`specs/cash-cli/spec.md` preflight 段把缺檔的後續處置依 mode 拆開，config deployment 段主詞限定為「執行安裝的 direct 與 batch mode」，並新增 `#### Scenario: 缺 openspec config 的 target 可被登錄`；`design.md` D5 標題與內容擴充；`proposal.md` Proposed Solution 結語改寫。修改檔案：`proposal.md`、`design.md`、`specs/cash-cli/spec.md`。
7. **Warning 6（`current` 優先序）**：`specs/cash-cli/spec.md` 的 `Current、newer 與 conflict 分類` scenario 首個 WHEN 補「且 `openspec/config.yaml` 存在」，config deployment 段新增優先序條款；`design.md` Risks 新增「刻意刪除的 config 會被還原」；`proposal.md` Proposed Solution 第 4 點同步。修改檔案：`proposal.md`、`design.md`、`specs/cash-cli/spec.md`。
8. **Warning 7（unsafe／`--force` 覆蓋）**：`tasks.md` 1.1 加入 `openspec/` entries 恰為 `{"config.yaml"}` 與 receipt 不含該路徑的斷言，1.3 加入 hard link、FIFO 與 invalid + `--force` 的斷言；`design.md` Implementation Contract 第 10 項同步擴充。修改檔案：`design.md`、`tasks.md`。
9. **Suggestion 8（死碼）**：`design.md` Implementation Contract 第 4 項改為 `-> None` 並說明理由，原第 6 項（`ensure_contained` 清單）刪除，改寫入第 7 項的說明；`tasks.md` 2.1、2.2 同步。修改檔案：`design.md`、`tasks.md`。
10. **Suggestion 9（`would-update` 措辭）**：`specs/cash-cli/spec.md` 的 dry run scenario 改為「`--target` 模式輸出 `Result: update`，batch 模式輸出 `would-update`」，`proposal.md` 第 5 點與 `tasks.md` 1.3 同步明列預期字串。修改檔案：`proposal.md`、`specs/cash-cli/spec.md`、`tasks.md`。
11. **Suggestion 10（`main`／`run`）**：`design.md` Context 與 Implementation Contract 第 6 項、`tasks.md` 2.2 全部改為 `run`。修改檔案：`design.md`、`tasks.md`。
12. **Suggestion 11（跨版本診斷）**：`design.md` Risks 新增該情境的說明，不擴張實作範圍。修改檔案：`design.md`。
13. **fix 後的機械自我檢查**：delta spec 的 `<!--`／`-->` 皆為 0；`### Requirement: Bundle 安裝與 runtime receipt` 與 master 逐 byte 相同；scenario 數由 34 增為 36（master 29 + 新增 7）；`OPENSPEC_CONFIG_PATH`、`OPENSPEC_CONFIG_BASELINE`、`ensure_regular_shape`、`openspec_config_plan`、`allow_missing_config`、`ensure_regular_gitignore` 六個識別字在 artifacts 間拼寫與語意一致；`installer.py` 內 `"openspec/config.yaml"` 字面值仍為三處，與 Implementation Contract 第 1 項相符；殘留的 `-> bool`、「逐 byte 相同」、「`ensure_contained` 清單加入」等舊敘述均已清除。
14. **驗證重跑**：`.cash-skills/bin/cash validate "bootstrap-openspec-config-on-install"` 通過。
15. `openspec/signals/` 下無任何帶 `check` frontmatter 欄位的 signal，故 signal-derived 機械檢查無可執行項目，走既有 best-effort 判斷。

## Decision

next_round

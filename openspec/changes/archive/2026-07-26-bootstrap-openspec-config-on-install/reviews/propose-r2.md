# Cash Propose Review — Round 2

## Reviewer Findings

本輪 `round_type: micro`，由單一 Reviewer V 對第 1 輪的累積 blocking set 與已記錄的 fix 做 delta 驗證。

### 累積 blocking set 逐一判定（Reviewer V）

| 成員（Round 1 Warning） | 判定 | 驗證依據 |
| --- | --- | --- |
| 1. FIFO 形狀判定會阻塞 | resolved | `design.md` D1／IC3、delta spec preflight 段與 unsafe shape scenario、`tasks.md` 1.3；並確認 `validate_target_prerequisites`（`installer.py:1328`）早於 `installation_inputs`（`:1502`），是唯一會先開檔的路徑 |
| 2. rollback 零測試覆蓋 | resolved | `tasks.md` 1.6、delta spec 新 scenario、`design.md` IC10；並確認 `TEST_` 前綴由 `install()` 剝除、`.gitignore` operation 固定晚於 config 且早於 receipt |
| 3. 版本寫死 | resolved | `design.md` IC9、`tasks.md` 3.1、Risks 中版本字面值已移除 |
| 4. baseline 綁定 repo 檔案 | resolved | `design.md` D2／IC2、delta spec baseline 形狀條款、`tasks.md` 1.1／2.1 的機械斷言 |
| 5. `--register` 語意 | resolved | delta spec preflight 段與 config deployment 段主詞、新 scenario、`design.md` D5／IC6、`tasks.md` 1.5 |
| 6. `current` 優先序 | resolved | delta spec `Current、newer 與 conflict 分類` 的 WHEN 與 config deployment 段優先序條款、`design.md` Risks |
| 7. unsafe／`--force` 覆蓋 | resolved | `tasks.md` 1.1／1.3、`design.md` IC10；hard link 仍落在 `read_regular` 的 `st_nlink != 1`，判序正確 |

Reviewer V 另確認：`ensure_regular_gitignore` 委派給 `ensure_regular_shape` 後邏輯逐行等價、錯誤訊息與呼叫點不變，master `### Requirement: Target 版控排除保護` 不被違反；delta spec 的 requirement 標題與 master 逐 byte 相同、master 既有 29 個 scenario 全數保留（新增 7 個共 36 個）；`-> bool`、「逐 byte 相同」、`main` 等舊敘述 grep 零命中。

### Warning

1. **task 1.6 的紅燈判準不成立，且無法區分 rollback 與 preflight 失敗**
   - `severity`: Warning｜`confidence`: 88｜`layer`: design｜`disposition`: fix-introduced｜`introduced_by`: Round 1 Fix Action 3（Warning 2 的 rollback 覆蓋）
   - `location`: `tasks.md` task 1.6
   - `summary`: 1.6 原本的四項斷言（exit 1、config 不存在、receipt 不存在、目錄殘留不計）在實作前全部成立，因此 Red 階段是綠燈；且實作後也無法區分「rollback 正確」與「preflight 又退回 fail closed」。
   - `recommendation`: 加入 stderr 含 `injected publication failure after .gitignore` 的斷言（`installer.py:1112` 的訊息），使該 case 在實作前必紅、實作後保證注入點被走到。

2. **`design.md` Goals 仍宣稱三種 mode 行為一致，與 D5／IC6 互相矛盾**
   - `severity`: Warning｜`confidence`: 85｜`layer`: design｜`disposition`: unresolved-prior（Round 1 Warning 5 的 fix propagation 未涵蓋 Goals 段）
   - `location`: `design.md` `## Goals / Non-Goals` 第 4 條 Goal
   - `summary`: Round 1 Fix Action 6 同步了 `proposal.md`、delta spec、D5 與 IC6，卻漏掉 Goals；實作者若以 Goals 為準會讓 `--register` 也建立該檔，直接違反 delta spec 的 `MUST NOT`。
   - `recommendation`: 改為與 D5 一致的表述。
   - 說明：Reviewer V 給 78；主 agent 提高為 85，因為這是同一份 artifact 內兩條敘述的直接矛盾，可由文字本身證明。

### Suggestion

3. **register 分支的 schema-invalid 情形無 task 背書**
   - `severity`: Suggestion｜`confidence`: 50｜`layer`: design｜`disposition`: fix-introduced｜`introduced_by`: Round 1 Fix Action 6
   - `location`: `tasks.md` 1.5 對照 delta spec 的 register scenario 第二組 WHEN／THEN
   - `summary`: scenario 涵蓋 unsafe 與 schema-invalid 兩種情形，1.5 只斷言 symlink；把 `return` 放得太早的實作會讓 register 分支完全略過 `parse_openspec_config`，而 1.3 的 invalid case 走的是另一個呼叫點無法背書。
   - `recommendation`: 在 1.5 補 schema-invalid case。

## Rating

- post-filter 累積 blocking set Critical 數：0
- post-filter 累積 blocking set Warning 數：2（第 1 輪的七個成員全部經 Reviewer V 驗證為 resolved 而離開集合；本輪新增 Warning 1 與 Warning 2）
- 非 blocking triaged finding 數：1（Suggestion 3）
- `critical_gap`: false
- `round_type`: micro
- 理由：Reviewer V 對七個 blocking 成員逐一給出 resolved 判定並附具體引用，故全部離開累積集合。但本輪發現兩項阻斷性問題：一項是第 1 輪 fix 自身引入的錯誤紅燈判準，一項是第 1 輪 fix propagation 漏掉的同檔矛盾敘述。兩者都必須修正，故 `decision: next_round`。

## Fix Actions

1. **Warning 1**：`tasks.md` 1.6 改用既有 `test_publication_failure_rolls_back_the_gitignore_operation` 的 env 寫法（`TEST_CASH_INSTALL_TEST_HOOKS` 與 `TEST_CASH_INSTALL_FAIL_AFTER_PATH`），並加入 stderr 含 `injected publication failure after .gitignore` 的斷言與明確的紅燈原因說明。修改檔案：`tasks.md`。
2. **Warning 2**：`design.md` `## Goals / Non-Goals` 第 4 條 Goal 改為「`--target` 與 `--all` 在 target 缺檔時建立該檔；`--register` 只放寬 preflight，接受缺檔的 target 但不建立該檔」，與 D5、IC6、delta spec 一致。修改檔案：`design.md`。
3. **Suggestion 3**（非 blocking，一併修正）：`tasks.md` 1.5 補 schema-invalid 的 register case，斷言 exit 1、stderr 含 `invalid target openspec/config.yaml`、registry 不變。修改檔案：`tasks.md`。
4. **confidence filter 降權紀錄**：Reviewer V Finding 4（`#### Scenario: Upgrade 與 force 只收斂 managed inventory` 的窮舉清單未納入新建的 config，`confidence` 42、`disposition: new`）低於 50，依 confidence filter 捨棄，不進入決策。Reviewer V 自身已說明 master 對 `.cash.yaml` 的三分支建立存在同一種既有不精確，本變更未擴大該縫隙，故不改寫該 master scenario。
5. **fix 後的機械自我檢查**：delta spec `<!--`／`-->` 皆為 0；requirement 標題與 master 逐 byte 相同；scenario 數維持 36；「三種 target mode 行為一致」在 artifacts 中僅存於 delta spec 明確區分三者處置的那句，`design.md` 的矛盾敘述已清除；`injected publication failure after .gitignore` 字面與 `installer.py:1112` 的 f-string 產出相符。
6. **驗證重跑**：`.cash-skills/bin/cash validate "bootstrap-openspec-config-on-install"` 通過。
7. 本輪 fix 全部落在 `openspec/changes/` 之下，過濾後候選路徑為空，因此不呼叫 `touched ensure`／`touched record`，亦不產生警告。未觸及任何受保護的裁判面路徑。

## Decision

next_round

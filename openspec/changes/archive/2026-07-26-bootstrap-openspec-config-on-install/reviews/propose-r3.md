# Cash Propose Review — Round 3

## Reviewer Findings

本輪 `round_type: micro`，由單一 Reviewer V 對第 2 輪產生的累積 blocking set 與已記錄的 fix 做 delta 驗證。

### 累積 blocking set 逐一判定（Reviewer V）

| 成員（Round 2） | 判定 | 驗證依據 |
| --- | --- | --- |
| 1. task 1.6 的紅燈判準不成立（`fix-introduced`） | resolved | `installer.py:1110-1112` 的 f-string 產出與 `tasks.md` 1.6 的 stderr 斷言字面相符；`validate_target_prerequisites`（`:1328`）早於 `hooks = test_hooks()`（`:1342`），故實作前首個失敗的正是 stderr 斷言，與 1.6 逐字寫的紅燈原因一致；實作後注入點必在 config 發布之後觸發，`rollback` 逆序 unlink 新建 config。env 寫法與 `install()` helper 的 `TEST_` 前綴剝除邏輯（`test_installer_runtime.py:49-53`）同形。 |
| 2. `design.md` Goals 與 D5／IC6 矛盾（`unresolved-prior`） | resolved | `design.md` Goals 第 4 條現與 D5、IC6、delta spec preflight 段與 register scenario、`proposal.md`、`tasks.md` 1.5 全部一致；`三種`／`行為一致` 的殘留掃描僅命中兩處無關句。 |

Reviewer V 另確認：第 2 輪為 Suggestion 3 新增的 register schema-invalid case 可行（`run` 的 `--register` 分支在 `write_registry` 之前呼叫 `validate_target_prerequisites`，`InstallerError` 預設 exit 1，stderr 含 `invalid target openspec/config.yaml`，registry 斷言可沿用既有 `run_installer(..., home=...)` pattern）；全域 propagation 一致（`ensure_regular_shape`、`OPENSPEC_CONFIG_BASELINE`、`OPENSPEC_CONFIG_PATH`、`allow_missing_config`、`openspec_config_plan` 的出現分佈符合分層，`-> bool` 零命中，`main` 僅存於「`main` 只是 `run` 的錯誤包裝」的說明，dry-run 字串三處一致，版本為相對指令）；`tasks.md` 2.1 的驗證指令可執行（`Snapshot` 首欄為 `exists`，`parse_openspec_config` 簽章相符）；Implementation Contract 第 1 項的「三處字面值」與第 4 項「錯誤訊息不變」互不衝突（第 4 處字面值在該訊息的 f-string 內）。

delta spec 形式複查通過：requirement 標題與 master 逐 byte 相同、master 既有 29 個 scenario 全數保留、`<!--` 與 `-->` 計數皆為 0、scenario 總數 36、`.cash-skills/bin/cash validate` 通過。

### Critical

無。

### Warning

無。

### Suggestion

無。

## Rating

- post-filter 累積 blocking set Critical 數：0
- post-filter 累積 blocking set Warning 數：0
- 非 blocking triaged finding 數：0
- `critical_gap`: false
- `round_type`: micro
- 理由：第 2 輪的兩個 blocking 成員都經 Reviewer V 以具體程式碼與 artifact 引用驗證為 resolved，並確認第 2 輪的三項 fix 未引入新缺陷；本輪零 finding，累積 blocking set 清空，故 `decision: passed`。

## Fix Actions

None; pass condition met.

- confidence filter 降權紀錄一：Reviewer V 觀察「`design.md` IC10 的測試清單未列入 1.5 新增的 register schema-invalid case」，`confidence` 40、`disposition: new`，低於 50 而捨棄。Reviewer V 自身指出該 case 已由 delta spec 的 WHEN／THEN 直接背書，且 IC10 為非窮舉清單，不構成矛盾。
- confidence filter 降權紀錄二：Reviewer V 觀察「若 1.5 的三個 sub-case 共用同一個已登錄的 target，`--register` 的 `if project not in records` 短路會使後兩個 case 的『registry 不變』斷言變成 vacuous」，`confidence` 42、`disposition: new`，低於 50 而捨棄。exit code 與 stderr 斷言仍保有守衛力，且該點屬測試撰寫細節而非 artifact 缺陷。
- 本輪無任何檔案修改，因此沒有需要記錄的 change 目錄外路徑，不呼叫 `touched ensure`／`touched record`，亦不產生警告。整個 loop 未觸及任何受保護的裁判面路徑，因此沒有 `未修復：裁判面保護` 紀錄。

## Decision

passed

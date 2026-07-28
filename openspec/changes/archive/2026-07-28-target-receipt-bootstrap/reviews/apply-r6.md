# Cash Apply Review — Round 6

本輪是 seeded re-run 的第三輪，依 run 內位置推導為 `micro`，由單一 Reviewer V 執行 delta 驗證。

## Reviewer Findings

### Critical

無。

### Warning

無。

### Suggestion

1. **severity**: `Suggestion`｜**confidence**: `100`｜**layer**: `design`｜**disposition**: `fix-introduced`｜**reviewer**: V — Verification
   - **location**: `specs/cash-cli/spec.md` — `#### Scenario: 失敗路徑零內容寫入`
   - **introduced_by**: round 4 Fix Actions 第 1 條（只在「Runtime inventory 缺檔時 fail closed」Scenario 新增 import-time 例外與在 requirement 本文新增段落，未涵蓋同檔另一個以 inventory 缺檔為 WHEN 的 Scenario）；round 5 Fix Actions 第 5 條宣稱的「全面 propagation sweep」對 import-time 概念只掃了五處計數與界定，未掃 spec 內其他以 inventory 缺檔為前提的全稱 Scenario
   - **summary**: 「失敗路徑零內容寫入」Scenario 的 WHEN 以全稱涵蓋「任一 inventory 檔案缺失」，THEN 卻要求「以對應的具名 error code 與統一 JSON 錯誤 shape 失敗」，對 4 個 import-time 相依成員為假，且與同一 requirement 本文段（import-time 相依「MUST NOT 期待具名 error code」）直接互斥
   - **recommendation**: 在該 Scenario 的 inventory 缺檔條件上比照加註 import-time 例外，使兩個 Scenario 與 requirement 本文對同一事實給出同一敘述
   - **evidence**: reviewer 實跑 `test_every_runtime_member_is_classified`（18 tests OK），其中屬 `import_time` 集合的 4 個成員斷言為 `result.stdout == ""` 且 stderr 含 `No module named`——exit 1、零 receipt，但沒有任何具名 error code 也沒有 JSON shape，與該 Scenario 的 THEN 不符
   - **failure_scenario**: 後續維護者或 `cash-verify` 依 spec Scenario 逐條產生機械驗收案例時，會由該全稱 WHEN 寫出「刪除 `config.py` → 斷言 stdout 含具名 error code JSON」的案例；該案例必然失敗，使驗收卡在一個 artifact 自相矛盾之處，或反向促使有人「修碼以符合 spec」——而 import 完成前根本不可能產生具名 code

### Cumulative blocking set 判定（Reviewer V）

| member | verdict | fix reference | 驗證要點 |
| --- | --- | --- | --- |
| M1 — `proposal.md` 部署敘述未同步 | `resolved` | round 5 Fix Actions 第 1 條 | reviewer 自行實測地面事實：版本檔、`BUNDLE_VERSION`（以 import 實際載入常數確認）、source receipt 皆為 `2.11.0`；8 個 registry target 逐一唯讀讀取皆為 `2.11.0`，且 `installer.py` digest 在 source 檔／source receipt／各 target receipt／各 target 現地檔四方全部相符。`proposal.md` 兩處已改為 2.11.0 與「重新部署過三次」，與 `design.md` D6 的第三次適用逐項對應；全檔僅餘 2 處 `2.10.0` 且皆為明確的歷史敘述，無「最終為 2.10.0」殘留 |

M1 經 Reviewer V 明確判定 `resolved` 並移出 cumulative blocking set。本輪唯一新 finding 為 `Suggestion`，不進入集合。

## Rating

- post-filter cumulative blocking set Critical count：`0`
- post-filter cumulative blocking set Warning count：`0`
- 非阻塞 triaged finding count：`1`
- `critical_gap`：`false`
- `round_type`：`micro`

**rationale**：M1 經地面事實實測與 artifact 逐處查證後判定 `resolved` 並移出集合。Reviewer V 新增的唯一 finding 經 confidence filter 後為 `Suggestion`（`confidence: 100`、`layer: design`；filter 不會把 `Suggestion` 上調為 `Critical`／`Warning`），依規則非阻塞，不構成 `next_round`。post-filter cumulative blocking set 因此為空，既無阻塞 `Critical` 也無阻塞 `Warning`，本輪 pass。

本輪同時確認前三輪反覆出現的同型缺陷（fix action 宣稱已同步全部位置而實際只改被指名檔案）已收斂：reviewer 對版本字串、步驟編號交叉引用、import-time 計數與界定三個概念做了跨全部 artifact／文件／測試／signals 的獨立掃描，除本輪這一處 Scenario 外全數一致——五處 import-time 計數一致為 4（15／4，總計 19，與 `len(BUNDLE_RUNTIME_PATHS)` 相符）、各處皆逐一標明四個成員的匯入來源且 `cash_cli/__init__.py` 正確歸於 15 側、步驟編號交叉引用與程式碼實際呼叫序相符且 `tasks.md` 與 signals 已改為不耦合編號的指稱、Contract 第 7 項限縮後可機械核對。

## Fix Actions

- **finding 1（Scenario 全稱敘述未收斂）已修復**：`specs/cash-cli/spec.md` 的「失敗路徑零內容寫入」Scenario，WHEN 的「或 `.cash-workspace.lock` 或任一 inventory 檔案缺失」改為「或 `.cash-workspace.lock` 或任一**非 import-time 相依**的 inventory 檔案缺失」，使該 Scenario 與「Runtime inventory 缺檔時 fail closed」Scenario 及 requirement 本文對同一事實給出同一敘述。雖為非阻塞 `Suggestion`，仍予修復——它是本 change 反覆出現的同型缺陷（全稱敘述未隨例外收斂）的又一實例，且屬 artifact 自相矛盾，成本極低。修改檔案：`specs/cash-cli/spec.md`。
- **post-fix propagation sweep**：對「以 inventory 缺檔為前提的全稱敘述」再做一次全 spec 掃描，確認僅餘的兩處（第 42 行 WHEN、第 57 行 GIVEN）都已帶 import-time 例外標註，spec 內 import-time 例外標註共 3 處且語意一致。
- **post-fix 驗證**：`"$cash_cli" validate` 通過；`cash analyze` non-Suggestion findings 為 `0`；`scripts/cash-skills/tests/test_init_receipt.py` 18 tests、`skill-checks.fish` 全套通過。
- **未觸及程式碼**：本輪修復為 spec 文字，`.cash-skills/lib/cash_cli/` 下無任何修改，不觸發 D6 部署時序規則，不需 bump 亦不需重新部署。地面事實維持 2.11.0。
- **變更目錄外的檔案記錄**：本輪 Fix Actions 僅修改 `openspec/changes/target-receipt-bootstrap/` 下的檔案，濾除後候選路徑為空，因此不呼叫 Cash CLI 的 `touched` 指令，亦不產生警告。

## Decision

passed

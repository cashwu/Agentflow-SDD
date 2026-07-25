# Cash Propose Review — Round 5

## Reviewer Findings

本輪為 micro round，spawn 一個 Reviewer V — Verification，context 含第 1 至 4 輪 round file 全文、累積 blocking 集合的唯一成員 M11、artifact 路徑與相關 `open` signals。`accepted-risks.md` 不存在。

### 累積 blocking 集合逐項裁決

| 成員 | 裁決 | 依據 |
| --- | --- | --- |
| M11 receipt 重建規則未隨變更出貨（Warning） | resolved | 四處落地：`design.md` C2 新增的 MUST（含「C4 的 receipt 常規只約束實作本變更的人、不會隨變更出貨，因此這條 MUST 寫進 SKILL 文字本身」的正面回應）、`specs/cash-skill-workflows/spec.md` 的 requirement 內文與新 scenario「fix actions 改到 runtime 檔時先重建 receipt」、C4 與 tasks 1.2 的逐檔字面句斷言、tasks 3.1／3.2／3.3。Reviewer V 另實地覆核 `validate_receipt()` 對 `runtime` 記錄（限 `.cash-skills/lib/cash_cli/**.py`）逐檔比對 digest，確認決策十二對失效機制的描述正確；並確認 `skill` 記錄不比對磁碟 digest，因此 fix action 改到 SKILL 檔不會觸發 `receipt_invalid`，C2 未把 SKILL 檔納入重建條件並非漏洞。 |

累積 blocking 集合在本輪清空。

### Suggestion

Reviewer V 未提出任何 `Critical` 或 `Warning`。四筆 findings 皆為 `Suggestion`，其中三筆 `confidence < 50` 依信心過濾規則丟棄（降級軌跡記於本節），一筆 `confidence` 恰為 50 而存活；四筆皆為非 blocking，且皆已於本輪修復：

- `confidence`: 50 / `layer`: design / `disposition`: `fix-introduced` / `introduced_by`: 第 4 輪新增的 C2 呼叫協定 — 觸發條件排除的是本 change 的目錄，而濾除規則涵蓋所有 change 的目錄，兩者相減後可能為空集合；「濾除後為空則不呼叫」沒有被任何一條寫出，依字面實作會發出不帶 `--path` 的呼叫、換得一則 `invalid_arguments` 假警告帶進最終完成輸出。
- `confidence`: 45（丟棄，降級軌跡）/ `layer`: design / `disposition`: `fix-introduced` — C2 把呼叫協定寫成與呼叫點無關的獨立條目，但 spec 把它併進以 fix actions 為主詞的段落、tasks 3.1 只折進 `**Fix actions**` 那一條，signals write step 那一條沒有協定指示。
- `confidence`: 45（丟棄，降級軌跡）/ `layer`: text / `disposition`: `fix-introduced` — `design.md` Risks 末條的字面句涵蓋列舉未併入第 4 輪新增的 `rebuild the receipt before the next cash command`，「仍只靠 spec 與 review 把關」的清單也未加入 step 6 三條例外與呼叫協定。
- `confidence`: 40（丟棄，降級軌跡）/ `layer`: design / `disposition`: `fix-introduced` — 5.1 改後的 pass 條件在判準被正確實作時必然為 0，驗收價值僅剩「判準有無被正確執行」，任務敘述未把這層意思講明。

Reviewer V 逐項確認並回報無 finding 的項目：MODIFIED 與 master 逐行 diff 僅差插入 `touched record` 與略去 `<!-- @trace -->`；11 個 C4 案例與 cash-cli delta 的 11 個 ADDED scenario 一一對應；九個字面句與 C2／C3 的 MUST 完全對應；紅燈判準正確；三段路徑驗證的順序可實作且必要（`_safe_source_path` 必須早於 `path_kind`，否則絕對路徑會先 raise `unsafe_path`）；每個任務的驗證目標在其時點皆可達（含 5.2 直接跑 `python3` 不經 launcher，因此版本提升後 receipt 尚未重建不構成死結）；`cash-propose.diff` 的兩個 hunk 早於插入點、`diff -U0` 行號不位移，manifest 確實不需更新；`## Impact` 的 10 條與實際改動集合一致；新規則之間無矛盾（逐路徑重試 × no-op × 原子性三者疊加行為明確；step 6 三條例外與既有三個選項的實際文字可對接）；`review-loop` 保留條目對其他 CLI 面安全；前四輪修掉的五處舊敘述在 artifacts 中零殘留。

## Rating

- 過濾後累積 blocking 集合 Critical 數：0
- 過濾後累積 blocking 集合 Warning 數：0
- 非 blocking triaged finding 數：4
- `critical_gap`：false
- `round_type`：micro
- 理由：唯一的累積 blocking 集合成員 M11 經 Reviewer V 裁定 `resolved` 並附實地機制覆核後離開集合，集合清空。本輪四筆 findings 全部為 `Suggestion`，其中三筆 `confidence < 50` 依規則丟棄、一筆為 50，皆為非 blocking，不造成 `next_round`。通過條件成立，決策為 `passed`。

## Fix Actions

本輪決策為 `passed`，通過條件已成立，四筆非 blocking 的 `Suggestion` 並非通過的前提；但它們皆為低風險的邊界補完與列舉同步（不引入新機制、不改變任何已定案的判定結構），故一併修復以免把已知缺口留給實作階段。修改檔案：`design.md`、`tasks.md`、`specs/cash-skill-workflows/spec.md`（共 3 個檔案）。

- 空集合終止語意：C2 呼叫協定補上「濾除後若無任何路徑則不呼叫，且不產生警告」並說明兩個範圍刻意不同的理由；spec 的 requirement 內文同步，新增 scenario「濾除後無路徑時不呼叫」。
- 協定範圍漂移：C2 明寫「此協定適用於兩個呼叫點」；tasks 3.1 的 signals write step 那一條補上同樣的協定指示。
- Risks 列舉未同步：字面句涵蓋列舉補入 `rebuild the receipt before the next cash command`（並更新為「九個字面句」），未被涵蓋清單補入 step 6／6a 的套用與呼叫協定。
- 5.1 檢查性質未說明：補一句說明本檢查驗證的是判準被正確執行而非資料性質，並給出可觀察的執行步驟（先以只比名稱的判準取候選集合，再確認加上存在性條件後全部落空）。

信心過濾降級軌跡：三筆 `confidence` 分別為 45、45、40 的 findings 依「Drop findings with `confidence < 50`」被丟棄，未計入 Rating 的 blocking 統計；其內容仍如上記錄並已一併修復。

fix 傳播：空集合終止、協定適用範圍、Risks 列舉、5.1 檢查性質四個概念，都同時檢查了 design C2／C4／Risks、tasks 3.1／5.1 與 delta spec。

fix 後重跑的 pre-round mechanical self-check：delta spec 註解配對（`<!--` 為 0）通過；數量一致性（決策 15 條、C4 案例 (a)–(k) 為 11 個、`## Impact` 的 Modified 為 10 條、cash-skill-workflows delta 18 個 scenario）通過；spec delta title-identity check 通過；`openspec/signals/` 下無帶 `check` frontmatter 欄位的 signal。

修復後重跑 `.cash-skills/bin/cash validate track-review-loop-outputs-in-allowlist`：通過。這些修復是在通過輪套用的，未再經另一個 reviewer 複驗，改以上述機械檢查把關。

## Decision

passed

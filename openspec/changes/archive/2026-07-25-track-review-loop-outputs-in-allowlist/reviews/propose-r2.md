# Cash Propose Review — Round 2

## Reviewer Findings

本輪為 micro round，spawn 一個 Reviewer V — Verification，context 含第 1 輪 round file 全文、七個累積 blocking 集合成員、artifact 路徑與相關 `open` signals。`openspec/changes/track-review-loop-outputs-in-allowlist/reviews/accepted-risks.md` 不存在。

### 累積 blocking 集合逐項裁決

| 成員 | 裁決 | 依據 |
| --- | --- | --- |
| M1 master lifecycle requirement 未修訂（Critical） | resolved | 改採「record 永不做第一次 access」路徑：`design.md` 決策二與 C1、`specs/cash-cli/spec.md` 的 requirement 內文與 scenario「未先 ensure 時失敗」、`specs/cash-skill-workflows/spec.md`、tasks 2.1／3.1、C4 案例 (i) 皆已落地。Reviewer V 另逐字 diff 確認 `Cash workflow command surface` 的 MODIFIED 除插入 `touched record` 外與 master 完全一致，且該 MODIFIED 仍屬必要。 |
| M2 紅燈判準與測試層級（Warning） | resolved | C4 明寫 chdir helper 與 `addCleanup(os.chdir, previous)`；紅燈預期改為「案例 (d) 會通過，其餘九個失敗」。Reviewer V 實地核對 `tasks.py:410-413` 的 fallback 確使 (d) 通過，並確認 `cli-checks.fish` 確為單一 process `unittest discover`。 |
| M3 `--json` 無背書（Warning） | resolved | 決策七直接移除；C1 與 spec 皆明寫 MUST NOT 提供。Reviewer V 另確認 master `統一 JSON 與錯誤契約` 只約束 `--json` 成功路徑的形狀，未強制每個 command 提供，無 contract 衝突。 |
| M4 共用判準誤判（Warning） | resolved | 決策九加入存在性條件、C3 字面句、spec 兩個 scenario、tasks 5.1 皆已落地。Reviewer V 獨立實跑判準複核：跨多個 change 者 35 個、跨多個仍進行中之 change 者 0 個。 |
| M5 legacy import 進入點（Warning） | resolved | C1 不再經 `load_or_import_touched`，改為「存在時以 `_validate_touched` 驗證後使用」；失敗模式不含 `legacy_touched_invalid`；spec scenario 明寫「command 不讀取也不匯入任何 legacy touched 檔」。 |
| M6 cash-propose 豁免前提（Warning） | **unresolved** | design 與兩份 delta spec 已改為條件式，但 `proposal.md` 的 `## Proposed Solution` 第二節**逐字保留**被推翻的原敘述（skill-conditional 判準與「實作檔」枚舉）。第 1 輪 `## Fix Actions` 宣稱三處已統一，實際未落到 proposal。 |
| M7 step 2a 繞過（Warning） | resolved | 決策十一、C3、spec scenario「封存後路徑同樣套用共用裁決」、tasks 4.1 皆已落地。Reviewer V 另對照 `cash-commit/SKILL.md` step 2a 與 `archive.py` 確認機制可行。 |

六個成員以「已驗證解決」離開累積 blocking 集合，verifying reviewer 為本輪的 Reviewer V；M6 留在集合中。

### Warning

- `severity`: Warning / `confidence`: 92 / `layer`: design / `location`: `proposal.md` `## Proposed Solution` 第二節 / `disposition`: `unresolved-prior`（即 M6）
  - `summary`: proposal 仍寫「cash-apply 的 fix actions 完成後，以該輪 `## Fix Actions` 記錄為已修改的**實作檔**路徑呼叫一次。cash-propose 的 fix actions 只動 change 目錄內的 artifacts……不需呼叫。」同時殘留 skill-conditional 判準與「實作檔」枚舉，與 design 決策八及 spec 的 `MUST NOT 以 skill 名稱判定` 直接矛盾。
  - `recommendation`: 改寫為與 design 決策八及 spec 一致的條件式敘述。

- `severity`: Warning / `confidence`: 88 / `layer`: design / `location`: `design.md` C2 fix actions 條；`tasks.md` 任務 3.1；`specs/cash-skill-workflows/spec.md` scenario「fix actions 改到 change 目錄外時記錄」 / `disposition`: `fix-introduced` / `introduced_by`: 第 1 輪新增的決策二與決策八
  - `summary`: 決策二的 ensure-before-record 只傳播到 signals write step 呼叫點，未傳播到 fix actions 呼叫點。但在 `cash-propose` 中 fix actions 呼叫點在時序上更早（`**Fix actions**` 在第 380 行、`<!-- SIGNALS-WRITE-STEP -->` 在第 453 行），且該 skill 全檔無任何其他 touched access，因此那才是 propose 迴圈第一次接觸 touched state 的位置；漏掉 ensure 會使該次 record 以 `touched_invalid` 失敗、依決策十二只印警告並繼續，檔案照樣漏記——正是本變更要消除的失效形態。C4 的字面句也未涵蓋 ensure（既有 consumer matrix 是對 `cash-*` 全域比對，任一 skill 含該句即通過）。
  - `recommendation`: 把 ensure-before-record 提升為兩個呼叫點共用的前置規則，並在 C4／tasks 1.2 對四個 SKILL 檔逐檔斷言。

- `severity`: Warning / `confidence`: 85 / `layer`: design / `location`: `design.md` 決策四第 2 段檢查、C1、C4 案例 (f)；`specs/cash-cli/spec.md` 前綴拒絕段與對應 scenario；`tasks.md` 1.1(f)／2.1 / `disposition`: `fix-introduced` / `introduced_by`: 第 1 輪新增的決策四
  - `summary`: 決策四要求以 `.cash-skills/` 開頭的 `--path` 一律失敗，理由「bundle 自身狀態，不屬來源檔」與事實不符：`_IGNORED_PREFIXES` 只含 `.cash-skills/state/`、`.cash-skills/receipt.tsv`、`openspec/changes/` 三項，而 `.cash-skills/lib/` 與 `.cash-skills/bin/` 之下有 20 個 git-tracked 來源檔，`mark_task_done` 至今一直能記錄它們。更嚴重的是它與同一份 design 的決策八、決策十二直接衝突——apply 迴圈最典型的 fix-action 目標 `.cash-skills/lib/cash_cli/`（含本變更自身要改的 `tasks.py`）會被永久排除在 record 之外，只落到警告路徑，等於把靜默漏檔換成有警告的漏檔。
  - `recommendation`: 前綴拒絕收斂為與 `_IGNORED_PREFIXES` 對齊。
  - 主 agent 覆核：實測 `_IGNORED_PREFIXES` 內容與 `git ls-files .cash-skills` 的 20 個 tracked 檔，宣稱成立。

- `severity`: Warning / `confidence`: 80 / `layer`: design / `location`: `proposal.md` `## Non-Goals` 末條 ↔ `design.md` 決策十、C3；`tasks.md` 任務 4.1 / `disposition`: `fix-introduced` / `introduced_by`: 第 1 輪新增的決策十
  - `summary`: 決策十要求被裁決排除的共用 signal 檔改列 Unrelated，但該檔仍在 tracking file 內，因此**確實改變了** step 4 的 Unrelated 判定規則；proposal Non-Goals 卻仍宣稱「不改變 Unrelated 判定的既有規則」，而 C3 與 tasks 4.1 只寫「其餘規則不變」。實作者依 Non-Goals 讀會得到相反結論，排除後的去向又回到懸空。
  - `recommendation`: 修正 Non-Goals，並把該例外在 C3 與 tasks 4.1 寫成正面規則。

### Suggestion

以下為信心過濾後降級為 `Suggestion` 的 findings，皆已於本輪修復：

- `confidence`: 78 / `layer`: text / `disposition`: `fix-introduced` — 決策九與 tasks 5.1 把「91 個帶 links 的 signal 檔」釘進敘述與驗收條件，但該總數會隨每次迴圈寫入而變動（本輪自身也會再寫入），Reviewer V 實測時已是不同數字；關鍵結論「跨多個仍進行中之 change 者為 0」不受影響。
- `confidence`: 62 / `layer`: design / `disposition`: `fix-introduced` — 存在性條件只寫 `openspec/changes/<other>/`，未涵蓋 parked 位置 `openspec/changes/.parked/<other>/`；parked change 未封存、其追加同樣可能尚未提交，會被判為非共用而靜默納入，正是決策九要避免的另一半誤判。
- `confidence`: 55 / `layer`: design / `disposition`: `new` — 決策十一只涵蓋 step 2a；step 6a 的 Updated Commit Plan 另有一份獨立列舉的區段範本，其中沒有 `### Review Loop Outputs`，review-loop 條目的檔案在 archive 後的更新版 plan 上沒有明確歸屬區段。

Reviewer V 另逐項確認並回報無 finding：MODIFIED 與 master 逐字一致且仍屬必要；C4 的十個案例與 cash-cli delta 的十個 scenario 一一對應；十二個任務的驗證目標在各自時點皆可達；`[P]` 的 1.1 與 1.2 無共用檔案；決策十四的 grader 區塊避讓成立；`## Impact` 的 10 條與實際改動集合一致，無漏列亦無過度宣告。

## Rating

- 過濾後累積 blocking 集合 Critical 數：0
- 過濾後累積 blocking 集合 Warning 數：4
- 非 blocking triaged finding 數：3
- `critical_gap`：false
- `round_type`：micro
- 理由：七個成員中六個經 Reviewer V 裁定 `resolved` 離開集合，M6 因 proposal 未同步而裁定 `unresolved` 留在集合中。本輪另新增三個 `fix-introduced` 的 blocking Warning，其中前綴拒絕過寬一項已由主 agent 實測 `_IGNORED_PREFIXES` 與 `git ls-files` 覆核成立。累積 blocking 集合含 4 個 Warning，未達通過條件，決策為 `next_round`。

## Fix Actions

修改檔案：`openspec/changes/track-review-loop-outputs-in-allowlist/proposal.md`、`design.md`、`tasks.md`、`specs/cash-cli/spec.md`、`specs/cash-skill-workflows/spec.md`（共 5 個檔案）。

blocking findings 的修復：

- M6／proposal 殘留（unresolved-prior）：`## Proposed Solution` 第二節改寫為「某一輪的 fix actions 完成後，若該輪 `## Fix Actions` 記錄了任何位於 `openspec/changes/<change>/` 之外的已修改檔案，以那些路徑再呼叫一次。此條件以『檔案是否在 change 目錄之外』判定，兩個 skill 一致，不以 skill 名稱判定。」並在同節補上兩個呼叫點皆須先 `touched ensure`。以 grep 確認舊敘述零殘留。
- ensure-before-record 未傳播：C2 新增「兩個呼叫點共用的前置規則」條目，並寫明 propose 的 `**Fix actions**` 在文件中早於 signals write step、該處才是 propose 迴圈第一次接觸 touched state 的位置；C2 的 fix actions 條、tasks 3.1／3.2 的驗證目標、spec scenario「fix actions 改到 change 目錄外時記錄」的 THEN 步驟同步；C4 與 tasks 1.2 新增對四個 SKILL 檔逐檔斷言 `"$cash_cli" touched ensure "<change-name>"`，並註明為何不能依賴全域 consumer matrix。
- 前綴拒絕過寬：決策四第 2 段改為與 `_IGNORED_PREFIXES` 對齊（`openspec/changes/` 與 `.cash-skills/receipt.tsv`），並明寫 MUST NOT 拒絕整個 `.cash-skills/` 前綴及其理由（20 個 git-tracked 來源檔、`.cash-skills/lib/cash_cli/` 是 apply fix-action 最典型目標、含本變更自身要改的 `tasks.py`）；C4 案例 (f) 改為同時斷言拒絕與成功兩側；spec 的前綴拒絕段與對應 scenario 各補上正向案例；tasks 1.1(f) 同步。
- Non-Goals 與決策十衝突：proposal Non-Goals 末條改寫為「不改變 artifact 集合的既有規則。Unrelated 判定僅新增一條例外……其餘判定不變」；C3 把該例外寫成正面規則（step 4 MUST 新增例外，不得只寫「其餘規則不變」）；spec 的 requirement 內文補上「此為對既有判定的明確例外」；tasks 4.1 同步。

非 blocking findings 的處置：三筆全部修復。

- 釘住總數：決策九與 tasks 5.1 移除會漂移的 signal 總數，只保留「跨越多個仍進行中之 change 者為 0」這個不變結論，並明寫 MUST NOT 把總數釘進驗收條件。
- parked 位置：決策九、C3 字面句要求、spec 的 requirement 內文與兩個 scenario、tasks 4.1／5.1 全部改為「`openspec/changes/<other>/` 或 `openspec/changes/.parked/<other>/` 其中之一仍存在」。
- step 6a 範本：C3 與 tasks 4.1 補上「step 6a 的 Updated Commit Plan 區段清單 MUST 同樣保留 `### Review Loop Outputs`，內容沿用 archive 前已確認的集合」。

fix 傳播：ensure-before-record、前綴拒絕收斂、Unrelated 例外、parked 位置、去釘住總數、step 6a 範本六個概念，都同時檢查了 proposal、design 決策段與 C1–C4、tasks 各任務與兩份 delta spec 五個位置。

fix 後重跑的 pre-round mechanical self-check：delta spec 註解配對（`<!--` 皆為 0）通過；數量一致性（決策 15 條、`## Impact` 的 Modified 為 10 條）通過；殘留舊敘述掃描（skill-conditional 原句、`91 個帶 links`、`.cash-skills/` 全前綴拒絕）零命中；`touched ensure`、`parked`、`receipt.tsv`、`Unrelated Changes`、`step 6a` 五個概念的跨 artifact 交叉比對一致；spec delta title-identity check：`### Requirement: Cash workflow command surface` 逐字存在於 master spec，通過；`openspec/signals/` 下無帶 `check` frontmatter 欄位的 signal。

修復後重跑 `.cash-skills/bin/cash validate track-review-loop-outputs-in-allowlist`：通過。

## Decision

next_round

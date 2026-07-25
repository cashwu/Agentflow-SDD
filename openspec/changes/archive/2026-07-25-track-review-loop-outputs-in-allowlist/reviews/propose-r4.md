# Cash Propose Review — Round 4

## Reviewer Findings

本輪為位置推導的 full round checkpoint，spawn 兩個獨立 reviewer（Reviewer A — Adherence、Reviewer B — Quality），在同一則訊息平行 spawn，各自收到相同 context 且互不傳遞輸出。`accepted-risks.md` 不存在。

### 累積 blocking 集合逐項裁決

| 成員 | 裁決 | 依據 |
| --- | --- | --- |
| M9 tasks 2.1 殘留舊前綴規則（Warning） | resolved（兩位 checkpoint reviewer 一致） | `tasks.md` 任務 2.1 已改為「前綴拒絕（`openspec/changes/` 與 `.cash-skills/receipt.tsv`，與 `_IGNORED_PREFIXES` 對齊；MUST NOT 拒絕整個 `.cash-skills/` 前綴）」，與 `design.md` 決策四第 2 段、C4 案例 (f)、`specs/cash-cli/spec.md` 與 1.1(f) 五處一致。兩位 reviewer 各自做了舊字串殘留掃描（artifacts 零命中，僅 round file 保留歷史敘述）並重新覆核 `_IGNORED_PREFIXES` 實際內容。R3 指出的「2.1 驗證目標不可達」已消除。 |

累積 blocking 集合在本輪清空後，因新發現的 `fix-introduced` finding 重新非空。

### Warning

- `severity`: Warning / `confidence`: 80 / `layer`: design / `location`: `design.md` 決策十二與 C4 receipt 常規 ↔ C2、`tasks.md` 3.1／3.2／3.3、`specs/cash-skill-workflows/spec.md` 第一條 requirement / reviewer: B / `disposition`: `fix-introduced` / `introduced_by`: 第 1 輪新增的決策十二與 C4 receipt 常規
  - `summary`: 決策十二自己指名的「最可能觸發條件」在出貨的 artifact 裡完全沒有對應緩解。C4 是本變更的 Implementation Contract，其 receipt 常規只約束實作本變更的人、不會隨變更出貨；C2、tasks 3.x 與兩份 delta spec 都沒有任何一條要求四個 SKILL 檔寫入 rebuild 指令。實測 `rg -n 'install-cash-skills|receipt' .claude/skills/*/SKILL.md` 在所有 SKILL 檔零命中。結果是出貨後任何一次 `cash-apply` review loop 的 fix action 改到 `.cash-skills/lib/cash_cli/`，其後的 `touched ensure` 與 `touched record` 都會以 `receipt_invalid` 失敗，只留下警告，該輪所有 change 目錄外檔案照樣漏記——本變更的旗艦情境恰好是它必然失效的情境。
  - `recommendation`: 把 receipt 重建規則寫進 SKILL 文字本身，並加入逐檔字面句斷言。

### Suggestion

以下為信心過濾後降級為 `Suggestion` 的 findings（`confidence ∈ [50, 80)`），皆已於本輪修復。合併紀錄：Reviewer A 第 1 筆與 Reviewer B 第 5 筆同屬「step 6 既有選項未與新區段調和」，機制不同（前者 `Commit as shown` 的字面枚舉不含新區段，後者 `Include all dirty files` 會靜默推翻裁決），合併為同一組修復。

- `confidence`: 78 / reviewer: B / `disposition`: `fix-introduced` — `tasks.md` 5.1 把 C4 的驗收量誤置換成另一個量：C4 要求「誤判數為零」，5.1 卻寫「跨越多個仍進行中之 change 的計數為 0」——那是真陽性計數，正是本變更存在的理由，一旦真的發生反而會擋住落地；且它與 R2 已拔掉的「91 個帶 links」屬同一類漂移量。
- `confidence`: 74 / reviewer: B / `disposition`: `fix-introduced` — 決策四宣稱收斂後「使 record 的可記錄集合與 `mark_task_done` 完全一致」，但第 3 段的存在性檢查打破該等價：`git_fingerprints` 會把刪除的 tracked 檔與 rename 來源路徑記入 touched，record 記不下。後果是 fix action 刪除或搬移 change 目錄外檔案時，commit 會少掉刪除側、rename 變成只有 add 的半套。
- `confidence`: 72 / reviewer: B / `disposition`: `fix-introduced` — 決策四的原子性（任一 path 失敗即整批零寫入）與決策十二的 warn-and-continue 疊在同一個呼叫協定上，而 C2 指示把該輪所有外部路徑放進一次呼叫：單一壞路徑會連坐掉同批全部合法路徑，只換到一則警告。而 fix actions 的路徑集合可以合法地含 CLI 必然拒絕的成員（另一個 change 的 `openspec/changes/<other>/…`、`.cash-skills/receipt.tsv`、已刪除路徑）。
- `confidence`: 72 / reviewer: A（第 1 筆）＋B（第 5 筆，合併）/ `disposition`: `new`（A 側）／`fix-introduced`（B 側，`introduced_by`: 第 1 輪決策十）— step 6 的 `Commit as shown` 說明只列 artifact 與 source files（既有 `### Spec Sync Changes` 的括號寫法證明新增區段時必須同步補），而 C3 反而明文凍結 step 6；另一方面 `Include all dirty files` 的定義正是「Add all unrelated files to the commit as well」，會把裁決排除的共用檔無聲帶回，直接違反同一份 spec 的 `MUST NOT 靜默納入共用檔`。
- `confidence`: 72 / reviewer: B / `disposition`: `new` — 十一個案例中，(b) 的 per-task 路徑與 record 路徑相異，聯集的**去重**分支不被觸發（該組合在 apply 是常態，以 list 串接取代 set 聯集的實作要到下一次載入才被 `_validate_touched` 攔下）；(e)(f)(g) 都只以單一壞路徑驅動，無法區分「零寫入」與「不寫入」，決策四末句的原子性 MUST 沒有任何案例覆蓋。
- `confidence`: 66 / reviewer: B / `disposition`: `fix-introduced` — R2 的逐檔斷言教訓只套用到 prose 字面句與 `touched ensure`，`touched record` 指令本身仍只在全域 matrix（`rg -Fq` 一次 glob、任一命中即通過，且只掃 `.agents` 側），四檔中只要一檔含該指令即綠燈。
- `confidence`: 65 / reviewer: A / `disposition`: `fix-introduced` — ensure 被提升為強制前置步驟，但失敗處理只定義給 record；`cash-commit` 對同一指令的既有處置是「ensure 失敗即 STOP」，套用會與「MUST NOT 使 workflow 失敗」抵觸，不套用則行為未定義。
- `confidence`: 52 / reviewer: A / `disposition`: `new` — spec 寫「symlink 不是既存一般檔案故回 `touched_invalid`」，但 C1 與 `path_kind` 實作是 `unsafe_path`（raise 而非回傳 kind），合併後 master spec 會對同一輸入宣告與實作不同的 error code。
- `confidence`: 50 / reviewer: A / `disposition`: `fix-introduced` — 決策十的納入分支寫「留在 `### Review Loop Outputs`」，但決策十一自己指出 step 2a 路徑不帶條目粒度、沒有該區段，納入分支在該路徑去向落空。
- `confidence`: 50 / reviewer: A / `disposition`: `new` — `## Fix Actions` 記錄的路徑形式不受任何 requirement 治理（本 change 自己的 r1–r3 就混用兩種形式），而 `--path` 要求 project-root-relative 並驗證存在性。

兩位 reviewer 另各自逐項確認並回報無 finding：MODIFIED 與 master 逐行 diff 僅差插入 `touched record`（7 個 scenario、2 個 Example 完整重現）；requirement／scenario ↔ contract ↔ task 三向對應完整；`## Impact` 的 10 條無多無少；各任務驗證目標在各自時點皆可達；`cash-propose.diff` 不需更新；`grader_hash` 不受影響；`[P]` 無共用檔；ADDED requirements 與 master 無衝突、重複或遮蔽；`review-loop` 條目與 `mark_task_done`／`archive.py` 的互動安全；並發安全。

## Rating

- 過濾後累積 blocking 集合 Critical 數：0
- 過濾後累積 blocking 集合 Warning 數：1
- 非 blocking triaged finding 數：11
- `critical_gap`：false
- `round_type`：full
- 理由：M9 經兩位 checkpoint reviewer 一致裁定 `resolved` 並離開集合。Reviewer B 新提出一個 `confidence 80` 的 `fix-introduced` Warning——receipt 重建規則只寫在 Implementation Contract 而未寫進會隨變更出貨的 SKILL 文字，使本變更的旗艦情境必然失效——依規則為 blocking。累積 blocking 集合含 1 個 Warning，未達通過條件，決策為 `next_round`。

## Fix Actions

修改檔案：`design.md`、`tasks.md`、`specs/cash-cli/spec.md`、`specs/cash-skill-workflows/spec.md`（共 4 個檔案）。

blocking finding 的修復：

- receipt 規則未出貨：C2 新增一條 MUST——fix actions 呼叫點若該輪改到 `.cash-skills/` 之下的 runtime 檔，MUST 先執行 `./install-cash-skills.fish --self` 再呼叫 ensure／record，並逐字包含 `rebuild the receipt before the next cash command`，同時寫明「C4 的 receipt 常規只約束實作本變更的人、不會隨變更出貨，因此這條 MUST 寫進 SKILL 文字本身」；`specs/cash-skill-workflows/spec.md` 第一條 requirement 補上對應句與 scenario「fix actions 改到 runtime 檔時先重建 receipt」；C4 與 tasks 1.2 把該字面句加入逐檔斷言；tasks 3.1／3.2／3.3 同步。

非 blocking findings 的處置：十一筆（合併後十組）全部修復。

- 5.1 驗收量：C4 與 tasks 5.1 改為「誤判數為 0，即不存在僅因指向已封存 change 的歷史 link 而被判為共用的 signal 檔」，並明寫真陽性計數與總數皆 MUST NOT 作為 pass 條件、只記入 `implementation-notes.md`。
- 「完全一致」宣稱：決策四改為子集關係並說明 `git_fingerprints` 會記入刪除與 rename source 而 record 不會；Risks 新增一條記下該缺口與後果，並說明為何刻意保留嚴格檢查（放寬到接受 `missing` 會讓打錯的檔名重新變成靜默失效）。
- 原子性與 warn-and-continue 交互：C2 新增呼叫協定條目——呼叫前 MUST 濾除 `openspec/changes/` 之下的路徑、整批失敗時 MUST 逐路徑重試取最大合法子集、警告只列真正記不進去者、`--path` MUST 為 project-root-relative（同時涵蓋 `## Fix Actions` 路徑形式那一筆）；spec 補上對應句與 scenario「單一無法記錄的路徑不連坐」。
- step 6 選項調和：C3 新增兩條例外規則（`Commit as shown` 說明 MUST 明示涵蓋 `### Review Loop Outputs`；`Include all dirty files` 與 `Customize` 的加回路徑 MUST 先告知會推翻裁決並取得確認，`Customize` 移除已裁決納入者 MUST 移入 Unrelated 並沿用註記）；spec 補上對應句與兩個 scenario；tasks 4.1 同步。
- 測試組合缺口：C4 案例 (b) 改為要求 record 路徑之一與 per-task 條目重疊並斷言頂層 `files` 無重複項；新增案例 (k) 混合合法與非法路徑；案例數 10 → 11，design、tasks 與 cash-cli delta 的 scenario（新增「混合合法與非法路徑時零寫入」）同步。
- `touched record` 逐檔斷言：加入 C4 與 tasks 1.2 的逐檔清單，並註明全域 matrix 的實際實作為何不足。
- ensure 失敗處理未定義：決策十二改為涵蓋「`touched ensure` 或 `touched record` 任一失敗」，並明寫 MUST NOT 沿用 `cash-commit` 的「ensure 失敗即 STOP」語意；C2 與 spec 的 requirement 內文及 scenario WHEN 同步。
- symlink error code：決策四第 3 段與 spec 明寫 symlink MUST 以 `unsafe_path` 失敗。
- 納入分支去向：決策十改為「留在其所屬的來源檔區段——一般路徑為 `### Review Loop Outputs`，step 2a 路徑為該路徑的單一未分組清單」。

fix 傳播：receipt 出貨規則、呼叫協定、step 6 例外、ensure 失敗處理、symlink code、案例數與去重／原子性覆蓋、驗收量七個概念，都同時檢查了 design 決策段與 C1–C4、tasks 各任務與兩份 delta spec。

fix 後重跑的 pre-round mechanical self-check：delta spec 註解配對（`<!--` 為 0）通過；數量一致性（決策 15 條、C4 案例 (a)–(k) 為 11 個且與 tasks 1.1 及 design 的「十一個」敘述一致、`## Impact` 的 Modified 為 10 條、cash-cli delta 18 個 scenario、cash-skill-workflows delta 17 個 scenario）通過；九個字面句在 design C4 與 tasks 1.2 之間一一對應；spec delta title-identity check 通過；`openspec/signals/` 下無帶 `check` frontmatter 欄位的 signal。

修復後重跑 `.cash-skills/bin/cash validate track-review-loop-outputs-in-allowlist`：通過。

## Decision

next_round

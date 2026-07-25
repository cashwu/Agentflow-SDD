# Cash Propose Review — Round 3

## Reviewer Findings

本輪為 micro round，spawn 一個 Reviewer V — Verification，context 含第 1、2 輪 round file 全文、四個累積 blocking 集合成員、artifact 路徑與相關 `open` signals。`accepted-risks.md` 不存在。

### 累積 blocking 集合逐項裁決

| 成員 | 裁決 | 依據 |
| --- | --- | --- |
| M6 proposal 殘留 skill-conditional 判準（Warning） | resolved | `proposal.md` `## Proposed Solution` 第二節已改為條件式並與 `design.md` 決策八、`specs/cash-skill-workflows/spec.md` 的 `MUST NOT 以 skill 名稱判定` 逐字對齊。Reviewer V 全 artifact 掃描確認「實作檔」只剩兩處泛稱敘述，非枚舉判準。 |
| M8 ensure-before-record 未傳播（Warning） | resolved | C2 新增「兩個呼叫點共用的前置規則」並寫明 propose 的 `**Fix actions**`（第 380 行）早於 `<!-- SIGNALS-WRITE-STEP -->`（第 453 行）；spec 的兩個 scenario THEN 皆補上先執行 `touched ensure`；C4 與 tasks 1.2 新增逐檔斷言。Reviewer V 實測確認該字面句目前只存在於 `cash-commit/SKILL.md`，全域 consumer matrix 確會被單一檔案滿足，逐檔斷言的必要性成立。 |
| M9 前綴拒絕過寬（Warning） | **unresolved** | 決策四、C1、C4 案例 (f)、兩份 spec、tasks 1.1(f) 都已收斂，**但唯一的實作任務 `tasks.md` 任務 2.1 逐字保留舊規則**「前綴拒絕（`openspec/changes/`、`.cash-skills/`）」。第 2 輪 `## Fix Actions` 只列了 1.1(f) 同步而漏了 2.1。原缺陷未消除，且使 2.1 自身的驗證目標不可達——1.1(f) 斷言 `.cash-skills/lib/` 之下的檔案 MUST 記錄成功，依 2.1 文字實作則必然 `touched_invalid`。 |
| M10 Non-Goals 與 Unrelated 例外衝突（Warning） | resolved | `proposal.md` Non-Goals、`design.md` C3（寫成正面規則並明文「不得只寫『其餘規則不變』」）、`tasks.md` 4.1、spec requirement 內文四處皆已落地。Reviewer V 另確認與 master 既有的封存後復原條款無衝突。 |

三個成員以「已驗證解決」離開累積 blocking 集合，verifying reviewer 為本輪的 Reviewer V；M9 留在集合中。

### Warning

- `severity`: Warning / `confidence`: 92 / `layer`: design / `location`: `tasks.md` 任務 2.1 / `disposition`: `unresolved-prior`（即 M9）
  - `summary`: 實作任務 2.1 仍指示「前綴拒絕（`openspec/changes/`、`.cash-skills/`）」，與收斂後的決策四／spec／測試案例直接矛盾，並使 2.1 的驗證目標在依其文字實作時必然失敗。
  - `recommendation`: 2.1 的前綴拒絕改為 `openspec/changes/` 與 `.cash-skills/receipt.tsv`，並補「MUST NOT 拒絕整個 `.cash-skills/` 前綴」。
  - 主 agent 覆核：實測 `_IGNORED_PREFIXES` 與 `git ls-files .cash-skills`（20 個 tracked 檔），宣稱成立。

### Suggestion

以下為信心過濾後降級為 `Suggestion` 的 findings，皆已於本輪修復：

- `confidence`: 60 / `layer`: design / `disposition`: `fix-introduced` / `introduced_by`: 第 2 輪的「step 6a 範本」修復 — 該規則只落到 `design.md` C3 與 `tasks.md` 4.1，delta spec 沒有對應句或 scenario；封存後該規則不存在於 master spec，未來可被移除而不違反任何 requirement。
- `confidence`: 55 / `layer`: text / `disposition`: `fix-introduced` — `tasks.md` 3.3 的驗證目標漏了 `"$cash_cli" touched ensure "<change-name>"` 字面句，與平行的 3.1／3.2 不對稱。
- `confidence`: 50 / `layer`: text / `disposition`: `fix-introduced` — `design.md` C3 共用判定條的主句仍只寫 `openspec/changes/<other>/`，parked 位置由末尾追加句補回，是半更新的殘留敘述。
- `confidence`: 50 / `layer`: text / `disposition`: `fix-introduced` — 收斂後的正向規則以「git-tracked」為限定語，但三段驗證中沒有任何一段檢查 git 追蹤狀態，該限定語既非可實作判準，也可能誘導實作者加入逾越範圍邊界的 `git ls-files` 檢查；測試 helper 的 temp git root 中新建檔案本質上也非 tracked。
- `confidence`: 50 / `layer`: text / `disposition`: `new` — `proposal.md` Summary 寫「把追蹤到的 `openspec/signals/` 檔案獨立成一個區段」，但實際定義的是 `review-loop` 條目的全部檔案；第 2 輪放寬 `.cash-skills/lib/` 可被記錄後，該條目會含非 signal 檔，Summary 的窄化敘述與實際集合不符。

Reviewer V 另逐項確認並回報無 finding：MODIFIED 與 master 逐行 diff 僅差插入 `touched record` 與略去 `<!-- @trace -->`；`_safe_source_path` 與收斂後的前綴拒絕無重疊亦無缺口；紅燈判準正確；除 2.1 外各任務驗證目標皆可達（含 `cash-propose.diff` 不需更新、`grader_hash` 不受影響）；C4／tasks 1.2 的八個字面句與 C2／C3 的 MUST 一一對應；`## Impact` 的 10 條與實際改動集合一致；以現況重跑決策九判準，跨越多個仍進行中之 change 者為 0。

## Rating

- 過濾後累積 blocking 集合 Critical 數：0
- 過濾後累積 blocking 集合 Warning 數：1
- 非 blocking triaged finding 數：5
- `critical_gap`：false
- `round_type`：micro
- 理由：四個成員中三個經 Reviewer V 裁定 `resolved` 離開集合；M9 因實作任務 2.1 未同步而裁定 `unresolved`，且該遺漏使 2.1 的驗收在其時點不可達，屬實質未解而非措辭問題。累積 blocking 集合含 1 個 Warning，未達通過條件，決策為 `next_round`。依位置推導，下一輪為本次執行的第四輪，MUST 為 full round。

## Fix Actions

修改檔案：`proposal.md`、`design.md`、`tasks.md`、`specs/cash-cli/spec.md`、`specs/cash-skill-workflows/spec.md`（共 5 個檔案）。

- M9（blocking）：`tasks.md` 任務 2.1 的前綴拒絕改為「`openspec/changes/` 與 `.cash-skills/receipt.tsv`，與 `_IGNORED_PREFIXES` 對齊；MUST NOT 拒絕整個 `.cash-skills/` 前綴」。以 grep 確認舊字串零殘留。
- step 6a 規則未進 spec：`specs/cash-skill-workflows/spec.md` 第二條 requirement 內文補上「封存子流程後產出的更新版 commit plan MUST 同樣保留 `### Review Loop Outputs` 區段」，並新增 scenario「封存子流程後的更新版 plan 保留區段」。
- 3.3 驗證目標不對稱：補上 `"$cash_cli" touched ensure "<change-name>"` 字面句。
- C3 主句半更新：直接改寫為「`openspec/changes/<other>/` 或 `openspec/changes/.parked/<other>/` 其中之一仍存在」，刪去末尾補充句。
- 「git-tracked」限定語：`specs/cash-cli/spec.md` 的正向規則與 scenario、`design.md` C4 案例 (f)、`tasks.md` 1.1(f) 四處改為「既存一般檔案」，並在 C4 註明驗證依據是決策四第 3 段的存在性與型別檢查，不引入未被任何檢查背書的判準。決策四第 2 段的理由段落保留「20 個 git-tracked 來源檔」的敘述——該處是事實佐證而非判準。
- Summary 窄化：改為「把 `review-loop` 條目的檔案獨立成一個區段，並在其中位於 `openspec/signals/` 者標示出被多個進行中 change 共同修改、無法乾淨拆分者」。

fix 傳播：前綴拒絕收斂、step 6a 規則、ensure 字面句、parked 並列寫法、「既存一般檔案」措辭五個概念，都同時檢查了 proposal、design 決策段與 C1–C4、tasks 各任務與兩份 delta spec。

fix 後重跑的 pre-round mechanical self-check：delta spec 註解配對（`<!--` 為 0）通過；數量一致性（決策 15 條、`## Impact` 的 Modified 為 10 條、cash-cli delta 17 個 scenario、cash-skill-workflows delta 13 個 scenario）通過；殘留掃描（`前綴拒絕（openspec/changes/、.cash-skills/）`、判準用的 `git-tracked`）僅命中決策四理由段落的事實佐證，非判準，不需修改；八個字面句在 design C4 與 tasks 1.2 之間一一對應；spec delta title-identity check 通過；`openspec/signals/` 下無帶 `check` frontmatter 欄位的 signal。

修復後重跑 `.cash-skills/bin/cash validate track-review-loop-outputs-in-allowlist`：通過。

## Decision

next_round

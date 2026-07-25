# Cash Apply Review — Round 1

## Reviewer Findings

本輪為 full round，spawn 兩個獨立 reviewer（Reviewer A — Adherence、Reviewer B — Quality），各自收到相同 context 且互不傳遞輸出。兩者皆讀過 `implementation-notes.md`：檔案存在、只有初始化註解、無條目，依規則視為確認為空，不因此產生 finding。findings 依 `location + summary` 聚合後套用信心過濾。

合併紀錄：Reviewer A 第 1 筆與 Reviewer B 第 2 筆聚合為同一缺陷——`2a` 的 spec sync 集合可能既不在 Unrelated、也不進提交集合而被靜默丟掉。兩者的 `location` 都落在 `.claude|.agents/skills/cash-commit/SKILL.md` step 5 的同一句，缺陷機制相同（spec sync 集合的承接斷鏈），只是各自指出斷鏈的不同一段：A 指出區段產生被多綁了一個「來源為 archive manifest」條件，B 指出全文沒有任何一句把該集合放進提交集合。合併後取較高的 `severity` 與 `confidence`。

### Warning

- `severity`: Warning / `confidence`: 85 / `layer`: design / `location`: `.claude/skills/cash-commit/SKILL.md:132-134` 與 `.agents/skills/cash-commit/SKILL.md:132-134`（step 5），另涉 `:92`（`2a` 的 Spec sync set 定義）與 `:141`（step 6 的 `Commit as shown`）/ reviewer: A（第 1 筆）＋B（第 2 筆，合併）
  - `summary`: `### Spec Sync Changes` 區段的產生被綁在「allowlist 來源為 archive manifest」這個額外條件上，且全文沒有任何一句宣告 spec sync 集合屬於提交集合；於是在「舊封存無 `touched_files` 而走備援路徑」與「區段僅供顯示」兩種情形下，通過 digest 比對的 `openspec/specs/` 路徑會被 step 4 排除於 Unrelated 之外卻無人承接，從 commit plan 上整個消失或顯示但不 stage。
  - `recommendation`: 把 step 5 那句拆成兩句——只要 `2a` 成立就產生 `### Spec Sync Changes` 區段，單一未分組的 Source Files 呈現才額外要求來源為 archive manifest；並在 `2a` 明文宣告三個集合屬於提交集合、在 step 6 的 `Commit as shown` 指明 as shown 涵蓋該區段。
  - 主 agent 覆核：`design.md` 決策七第三段寫的是「偵測成立時 step 5 MUST 增加一個獨立的 `### Spec Sync Changes` 區段」，未附來源條件；`specs/cash-skill-workflows/spec.md` 的 scenario「spec sync 檔案以 manifest digest 判定歸屬」其 GIVEN 只有三條偵測條件加 `specs_synced` 為 true。實作確實多綁了條件，宣稱成立。此缺陷與本變更要消滅的靜默漏檔同型。

### Suggestion

以下為信心過濾後降級為 `Suggestion` 的 findings（`confidence ∈ [50, 80)`），皆已於本輪修復或記錄：

- `confidence`: 72 / `layer`: design / reviewer: B / `introduced_by`: 本次 diff 在 `.claude|.agents/skills/cash-commit/SKILL.md:132` 追加的 `When step 2a applies, use its artifact set and its resolved source allowlist as the inputs to this check.` — step 5 的 STOP 守衛在 `2a` 路徑上以允許清單（而非其 dirty 子集）為輸入，於是恆不觸發；對已提交過的封存 change 再跑一次 `cash-commit` 會走到 `git commit` 才以 "nothing added to commit" 收場，而非既有的 `## Nothing to Commit` 出口。
- `confidence`: 68 / `layer`: design / reviewer: B — `skill-checks.fish` 的十個字面句中，決策七最關鍵的 `specs_synced` gate 只由泛詞 `master_digests` 一個斷言守著，把「`specs_synced` 為 false 時全部留在 Unrelated」整句刪掉仍會綠燈，與 design Risks「刪除任一條判定都會紅燈」的宣稱不符。
- `confidence`: 65 / `layer`: text / reviewer: B / `introduced_by`: 本次 diff 在 `.claude|.agents/skills/cash-apply/SKILL.md:419` 追加的 `— the change's source files then fall through to Unrelated and are silently left out of the commit.` — 該因果句斷言 `cash-commit` 會靜默漏檔，與同一版本內 `2a` 的 `NEVER fall through to classifying every dirty source file as Unrelated` 直接矛盾，且沒有傳達真正殘存的風險。
- `confidence`: 58 / `layer`: text / reviewer: B / `introduced_by`: 本次 diff 新增的 `.claude|.agents/skills/cash-commit/SKILL.md:87` 第二個 bullet — `If touched_files is absent or empty (an archive created before that field existed)` 把括號內的成因說明套到「空陣列」上，但依決策九，空陣列之後的唯一意義是「該 change 確實沒有追蹤來源檔」，該警告文字對此為事實錯誤。
- `confidence`: 55 / `layer`: design / reviewer: B — `test_archive_manifest_other_fields_unchanged` 以兩個 hex 常數釘死 `make_workspace` 的 fixture 內文，對「新增欄位是否影響其他欄位」的鑑別力有限，卻讓 14 個共用 fixture 的測試承擔改動成本；另 `state.parent.mkdir(parents=True)` 未帶 `exist_ok=True`。
- `confidence`: 60 / `layer`: design / reviewer: B — 跨 change 風險：另一個進行中的 change `tolerate-versioned-legacy-guidance-marker` 的 IC7 與任務 2.5 仍硬編碼「由 `2.3.1` 調升為 `2.3.2`」，本變更落地為 `2.4.0` 後，該 change 依其 artifact 寫入 `2.3.2` 會以 `bundle version must strictly increase` 失敗。屬另一個 change 的 artifact，不在本次 diff 範圍。
- `confidence`: 50 / `layer`: design / reviewer: A — C2 把「決策六的五項改寫」列為「`2a` 的內容 MUST 包含」，但實作把其中四項寫在 step 4／5／6／7 各自的指向句中；C2 另有一條「step 3–7 MUST 各加一句指向 `2a`」正好涵蓋同樣四項，判定為 C2 條列的重複描述而非真缺口。

## Rating

- 過濾後累積 blocking 集合 Critical 數：0
- 過濾後累積 blocking 集合 Warning 數：1
- 非 blocking triaged finding 數：7
- `critical_gap`：false
- `round_type`：full
- 理由：本輪為本次執行的第一輪且未 seed，因此所有通過信心過濾的 `Critical` 與 `Warning` 皆為 blocking。過濾後只有一個 Warning 存活（spec sync 集合承接斷鏈，由兩個 reviewer 從不同角度獨立指出後合併），已由主 agent 對照 `design.md` 決策七與 delta spec scenario 覆核成立。未達通過條件，決策為 `next_round`。Reviewer B 的每個 `Critical`／`Warning` 都附了可驗證的 `introduced_by`，沒有任何 finding 因 introduced-by 不可驗證而被降到 `confidence ≤ 25`。

## Fix Actions

修改檔案：`.claude/skills/cash-commit/SKILL.md`、`.agents/skills/cash-commit/SKILL.md`、`.claude/skills/cash-apply/SKILL.md`、`.agents/skills/cash-apply/SKILL.md`、`scripts/cash-skills/tests/skill-checks.fish`、`scripts/cash-cli/tests/test_sync_archive_transaction.py`、`openspec/changes/guard-post-archive-commit-allowlist/design.md`、`tasks.md`、`specs/cash-skill-workflows/spec.md`（共 9 個檔案）。

blocking finding 的修復：

- step 5 那句拆成兩句：`When step 2a applies, add a ### Spec Sync Changes section listing its spec sync set.` 與獨立的「來源為 archive manifest 時 Source Files 以單一未分組清單呈現」句，使區段產生不再被多綁條件。
- 在 `2a` 的「Rebuild the change's file sets」之後新增一句，明文宣告 artifact 集合、來源允許清單、spec sync 集合三者皆屬提交集合而非僅供顯示，並指明會在 step 8 被 stage。
- step 6 的 `Commit as shown` 選項補上 `(when step 2a applies, "as shown" also includes the Spec Sync Changes section)`。
- design C2 的 step 5 改寫項與新增的「三個集合屬提交集合」要素同步；spec scenario「spec sync 檔案以 manifest digest 判定歸屬」新增一條 AND 步驟「被納入的路徑屬於提交集合，在使用者未於確認步驟移除時會被 stage」。

非 blocking findings 的處置：七筆中六筆已修復，一筆記為 triage note。

- STOP 守衛：step 5 改為以「artifact 集合與來源允許清單的 dirty 子集」為判定輸入，並補上「re-run against an already-committed archived change leaves both empty and must reach this STOP, not an empty commit」的理由句。
- 斷言強度：新增第十一個字面句 `` every `openspec/specs/` path stays in Unrelated Changes ``，使 `specs_synced` 為 false 時的保護句被機械斷言涵蓋；design C2／C4、tasks 1.2／3.1／3.2 的字面句清單與「十個」→「十一個」的數量敘述同步；design Risks 最後一條改寫為與實際斷言集合一致的敘述。首次以無反引號形式加入斷言時 `skill-checks.fish all` 紅燈，實測後改以 SKILL.md 的實際文字（含反引號）為準，三處同步修正。
- cash-apply 因果句：改寫為 `leaving it to fall back to the archive manifest's point-in-time snapshot — which does not include anything changed after archiving, and does not exist at all in archives created before that field was added.`，消除與 `2a` 的矛盾並改為陳述真正的殘餘風險；受斷言的字面句 `deletes the touched state that` 逐字保留。
- 空陣列成因誤述：改為 `If touched_files is absent (an archive created before that field existed) or present but empty, …`，使括號只描述缺席的成因。未改變「缺席或為空都要警告」的判定本身——那是 spec 已定案的 contract，變更需回 `cash-ingest`。
- 測試健壯性：`state.parent.mkdir(parents=True, exist_ok=True)`。固定期望值斷言依 C1 (c) 的明文要求保留不動。
- 跨 change 版本硬編碼：`未修復（範圍外）` triage note——該缺陷位於另一個 change `tolerate-versioned-legacy-guidance-marker` 的 `design.md` 與 `tasks.md`，不在本變更的 structured scope declarations 內，依 Surgical Changes 不予改動；已列入完成輸出提醒使用者。
- C2 條列重複描述：不改動。四項改寫的實質內容全部到位，C2 另一條「step 3–7 MUST 各加一句指向 `2a`」已涵蓋同樣四項，複製兩份會在同一文件內製造重複權威。

fix 傳播：`### Spec Sync Changes` 區段的無條件產生、三個集合屬提交集合、STOP 的 dirty 子集輸入、第十一個字面句、cash-apply 因果句五個概念，都同時同步到兩個 skill 變體、`skill-checks.fish`、design 決策段與 C2／C4、tasks 任務 1.2／3.1／3.2 與 spec scenario。兩個 `.agents` 變體以 `/cash-` → `$cash-` 正規化自 `.claude` 變體整檔轉寫，`variant-parity` 通過。

fix 後重跑的 pre-round mechanical self-check：delta spec 註解配對（`<!--`／`-->` 皆為 0）通過；數量一致性（決策 10 條、C1–C4 連號、design 與 tasks 的「十一個」敘述一致、`## Impact` 的 Modified 為 8 條）通過；第十一個字面句在兩個 SKILL 變體、`skill-checks.fish`、design、tasks 五處交叉比對一致；delta 皆為 `## ADDED Requirements`，spec delta title-identity check 不適用；`openspec/signals/` 下無任何帶 `check` frontmatter 欄位的 signal，改採既有 best-effort 判斷。

fix 後重跑驗證：`scripts/cash-skills/tests/skill-checks.fish all`（76 + 4 tests）OK、`scripts/cash-cli/tests/cli-checks.fish all`（103 tests）OK、`.cash-skills/bin/cash validate guard-post-archive-commit-allowlist` 通過。

## Decision

next_round

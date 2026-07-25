# Cash Propose Review — Round 2

## Reviewer Findings

本輪為 micro round，spawn 一個 Reviewer V — Verification，context 含第 1 輪 round file 全文、五個累積 blocking 集合成員、artifact 路徑與相關 `open` signals。`openspec/changes/guard-post-archive-commit-allowlist/reviews/accepted-risks.md` 不存在，本 change 沒有任何經同意的接受風險。

### 累積 blocking 集合逐項裁決

| 成員 | 裁決 | 依據 |
| --- | --- | --- |
| M1 未提升 `cash-skills.version`（Critical） | resolved | `proposal.md` `## Impact` 已含該路徑；`design.md` 決策十與 C4；`tasks.md` 任務 5.1。Reviewer V 另實測 `check_history` 在 `current != head` 且 `version_greater` 成立時直接 `return`，確認提升確實消除該關卡。 |
| M2 未重建 `.cash-skills/receipt.tsv`（Critical） | resolved | `design.md` 決策十與 C4；`tasks.md` 任務 2.1 收尾步驟與 2.2 常規。Reviewer V 另確認 `installer.py` 的 `bootstrap_source` 只重寫 receipt，不會覆蓋回 `archive.py` 的編輯，`--self` 是正確手段。 |
| M3 step 5／step 7 仍指向已移走路徑（Critical） | resolved | `design.md` 決策六；C2 的 step 3／4／5／6／7 改寫要求；spec scenario「封存後的 artifact 與 commit message 來源取自封存目錄」。 |
| M4 任務 3.1 驗收在指定時點不可達（Warning） | resolved | `tasks.md` 任務 3.1 驗證目標已改為單一檔案的 `rg -F` 逐字檢查。 |
| M5 step 2 絕對句矛盾（Warning） | resolved | `design.md` C2 要求改寫該句並逐字包含 `except when step 2a establishes a post-archive recovery source`，該字面句同時進入 C4 與任務 1.2 的斷言集合。 |

五個成員全部以「已驗證解決」離開累積 blocking 集合，verifying reviewer 為本輪的 Reviewer V。

### Warning

- `severity`: Warning / `confidence`: 88 / `layer`: design / `location`: `tasks.md` 任務 3.2 驗證目標 / `disposition`: `fix-introduced` / `introduced_by`: 第 1 輪對 M4 的修復（把整組 `codex-command-matrix` 通過改由任務 3.2 承接），以及第 1 輪在任務 1.2 把 cash-apply 的兩個字面句也放進 `assert_command_matrix`
  - `summary`: `assert_command_matrix` 同時檢查 cash-commit 與 cash-apply 四個 SKILL 檔的字面句，而 cash-apply 要到任務 4.1／4.2 才修改，因此任務 3.2 引用整組 `codex-command-matrix` 作為驗收，在該時點必然失敗——與 M4 同型的缺陷只是被搬到下一個任務。
  - `recommendation`: 任務 3.2 的驗證目標縮為單一檔案的逐字 `rg -F` 檢查加上 `variant-parity`，整組 `codex-command-matrix` 通過改由任務 4.2 單獨承接。

### Suggestion

以下為信心過濾後降級為 `Suggestion` 的 findings（`confidence ∈ [50, 80)`），皆已於本輪修復：

- `confidence`: 78 / `layer`: design / `disposition`: `fix-introduced` / `introduced_by`: 第 1 輪對 M2 的修復（新增獨立任務 2.2） — receipt 重建被排成 2.1 之後的獨立任務，但標記任務 2.1 完成所用的 `task done` 正是「下一次執行的 cash 指令」，該規則在自己的任務切分下無法被滿足。
- `confidence`: 70 / `layer`: design / `disposition`: `fix-introduced` / `introduced_by`: 第 1 輪新增的決策七 — 決策七只規定了 spec sync 檔案的判定規則，但 C2 的 step 改寫清單沒有任何步驟把通過判定的路徑真的放進提交集合，依 step 4 現行句它們仍會落回 Unrelated，且主流程 step 5 沒有可容納它們的區段。
- `confidence`: 62 / `layer`: design / `disposition`: `fix-introduced` / `introduced_by`: 第 1 輪把斷言集合由 5 個擴充為 10 個並改寫 Risks 該條 — Risks 宣稱斷言涵蓋「三條偵測條件」與 fall-through，但實際只涵蓋條件 2、3 的路徑字面句，宣稱與 C4 內容不一致。
- `confidence`: 58 / `layer`: design / `disposition`: `new` → 經主 agent 更正為 `fix-introduced` / `introduced_by`: 第 1 輪新增的任務 5.1 — 版本值寫死為 `2.4.0`，未比對 HEAD；同一 workspace 另一個進行中的 change `tolerate-versioned-legacy-guidance-marker` 的任務 2.5 也要提升該檔，寫死常數在並行落地時可能退化成 `current == head`。

## Rating

- 過濾後累積 blocking 集合 Critical 數：0
- 過濾後累積 blocking 集合 Warning 數：1
- 非 blocking triaged finding 數：4
- `critical_gap`：false
- `round_type`：micro
- 理由：第 1 輪的五個 blocking 成員全部經 Reviewer V 逐項裁定 `resolved` 並離開累積集合。本輪新增一個 `confidence 88` 的 `fix-introduced` Warning（任務 3.2 驗收不可達），依規則 `fix-introduced` 為 blocking，因此累積 blocking 集合非空，未達通過條件，決策為 `next_round`。四個降級為 `Suggestion` 的 finding 為非 blocking，不影響決策，但已一併修復。

## Fix Actions

修改檔案：`openspec/changes/guard-post-archive-commit-allowlist/design.md`、`tasks.md`、`specs/cash-skill-workflows/spec.md`（共 3 個檔案）。`proposal.md` 與 `specs/cash-cli/spec.md` 未修改。

- 任務 3.2 驗收不可達（blocking Warning）：驗證目標改為對 `.agents/skills/cash-commit/SKILL.md` 單一檔案的十個字面句逐字 `rg -F` 檢查加上 `skill-checks.fish variant-parity`，並明寫整組 `codex-command-matrix` 的通過由任務 4.2 承接。同時在 design C4 增列一條通則：因兩組斷言同屬 `assert_command_matrix`，整組只有在四個 SKILL 檔全部改完之後才會通過，在此之前的每個 task MUST 以單一檔案的 `rg -F` 作為驗證目標——把個案修法升級為規則，避免同型缺陷再次被搬到下一個任務。
- receipt 重建時點（非 blocking）：把首次重建併入任務 2.1 的收尾步驟並明寫「標記本任務完成之前 MUST 先重建」，任務 2.2 改為只承載可重複常規與最後一次重建的時點約束；design 決策十同步加上「MUST 併入該 task 本身的收尾步驟，不得排成後續獨立 task」的理由句。
- spec sync 判定無承接步驟（非 blocking）：design 決策七增列「被納入的路徑必須真的進入提交集合」與獨立 `### Spec Sync Changes` 區段的要求；決策六增列 step 4 的 Unrelated 判定以 artifact 集合、來源允許清單、spec sync 集合三者聯集為排除依據；C2 的 step 4／step 5 改寫項同步展開；tasks 任務 3.1 內容清單同步；spec scenario「spec sync 檔案以 manifest digest 判定歸屬」增加一條 AND 步驟。
- 斷言涵蓋與 Risks 宣稱不一致（非 blocking）：新增兩個字面句 `parsed files array is empty` 與 `keep the existing behavior and continue to step 3`，使偵測條件 1 與 fall-through 也被機械斷言涵蓋；cash-commit 字面句由八個增為十個，同步更新 design C2 要素清單、C4 斷言清單、tasks 任務 1.2／3.1／3.2；Risks 最後一條改寫為與實際斷言集合一致的敘述，並明說哪些部分仍未被字面句覆蓋。
- 版本值寫死（非 blocking）：任務 5.1 改為「讀取當下的 `cash-skills.version` 與 `git show HEAD:cash-skills.version`，寫為嚴格大於 HEAD 值的下一個 minor 版本」，並記載並行 change 的具體名稱與其目標值來源；design 決策十與 C4 同步改為由 HEAD 推導而非寫死常數。

disposition 更正紀錄：Reviewer V 將「版本值寫死」標為 `new`，但該缺陷所在的任務 5.1 是第 1 輪對 M1 的修復所建立，依規則該 finding 源自本迴圈的 fix 動作，主 agent 將其更正為 `fix-introduced` 並補上 `introduced_by`。該 finding 的 `confidence` 為 58，過濾後為 `Suggestion`，本更正不改變其非 blocking 狀態，因此沒有 blocking-to-non-blocking 的降級需要列入完成輸出。

fix 傳播：`Spec Sync Changes` 區段、三者聯集的 Unrelated 判定、兩個新字面句、由 HEAD 推導的版本值、receipt 併入收尾這五個概念，都同時同步到 design 決策段、C2／C4 清單、tasks 任務與 spec scenario，未只改被指出的單一位置。

fix 後重跑的 pre-round mechanical self-check：delta spec 註解配對（`<!--`／`-->` 皆為 0、無殘留 `---` 分隔線）通過；數量一致性（決策共 10 條、cash-commit 十個字面句在 design C2／C4 與 tasks 1.2／3.1／3.2 一致、`## Impact` 的 Modified 為 8 條）通過；新增字面句與 `Spec Sync Changes`、`install-cash-skills.fish --self`、`codex-command-matrix` 的跨 artifact 交叉比對一致；delta 皆為 `## ADDED Requirements`，spec delta title-identity check 不適用；`openspec/signals/` 下無任何帶 `check` frontmatter 欄位的 signal，改採既有 best-effort 判斷。

修復後重跑 `.cash-skills/bin/cash validate guard-post-archive-commit-allowlist`：通過。

## Decision

next_round

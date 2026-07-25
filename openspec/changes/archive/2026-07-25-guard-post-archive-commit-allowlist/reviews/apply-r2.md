# Cash Apply Review — Round 2

## Reviewer Findings

本輪為 micro round，spawn 一個 Reviewer V — Verification，context 含第 1 輪 round file 全文、累積 blocking 集合的唯一成員 M1、changed-file 清單、artifact 路徑與相關 `open` signals。`openspec/changes/guard-post-archive-commit-allowlist/reviews/accepted-risks.md` 不存在。Reviewer V 依 Implementation Notes Protocol 讀過 `implementation-notes.md`：檔案存在、只有初始化註解、無條目，視為確認為空，不因此產生 finding；Reviewer V 另逐項確認第 1 輪的修復皆屬「回填 artifacts 使實作與 artifacts 相符」，實作未偏離已定案的 artifacts，因此不需補 `deviation` 條目。

### 累積 blocking 集合逐項裁決

| 成員 | 裁決 | 依據 |
| --- | --- | --- |
| M1 `2a` 的 spec sync 集合承接斷鏈（Warning） | resolved | 兩處斷鏈都被消除：`.claude|.agents/skills/cash-commit/SKILL.md:136` 已拆成兩個獨立句，區段產生不再與「來源為 archive manifest」相連；同檔 `:94` 新增 `All three sets … are part of the commit set, not display-only.`；`:143` 的 `Commit as shown` 同步。artifact 端 `design.md` C2、`specs/cash-skill-workflows/spec.md:63` 的新 AND 步驟一致。Reviewer V 另實測兩變體正規化後 `diff` 為空、`skill-checks.fish all`（76 + 4）、`cli-checks.fish all`（103）、`validate` 皆通過。 |

M1 以「已驗證解決」離開累積 blocking 集合，verifying reviewer 為本輪的 Reviewer V。累積 blocking 集合在本輪清空。

### Suggestion

本輪五筆 findings 在信心過濾後全部為 `Suggestion`（`confidence ∈ [50, 80)`），皆為非 blocking，且皆已於本輪修復：

- `confidence`: 62 / `layer`: design / `disposition`: `fix-introduced` / `introduced_by`: 第 1 輪修復「STOP 守衛：step 5 改為以『artifact 集合與來源允許清單的 dirty 子集』為判定輸入」新增於 SKILL `:134` 的句子 — 新的 STOP 判定輸入漏掉同一輪剛宣告為提交集合成員的 spec sync 集合；當 artifact 集合與允許清單的 dirty 子集皆空、而 spec sync 集合非空時（例如使用者上次以 `Customize` 移除 Spec Sync 區段後只提交了其餘部分），流程會走到 `## Nothing to Commit` 並靜默丟掉一個已通過 digest 判定、依 `:94` 應被 stage 的路徑——與本變更要消滅的靜默漏檔同型，且是修復引入的行為回歸。
- `confidence`: 66 / `layer`: design / `disposition`: `fix-introduced` / `introduced_by`: 同上一筆的第 1 輪 STOP 修復（該修復只改了 C2 與兩份 SKILL） — STOP 概念未回填 `design.md` 決策六第三項、`tasks.md` 任務 3.1 與 spec scenario，使同一份 `design.md` 內決策段與 Implementation Contract 對同一個判定給出寬窄不同的定義；第 1 輪 `## Fix Actions` 宣稱該概念「都同時同步到 design 決策段、C2／C4、tasks 與 spec scenario」與事實不符。
- `confidence`: 55 / `layer`: text / `disposition`: `fix-introduced` / `introduced_by`: 第 1 輪新增的「三個集合屬提交集合」宣告 — `Every path in them is staged in step 8` 把來源允許清單當成提交集合本身，但它實際上是對 dirty 檔案的過濾器；逐字照做會對 clean 路徑執行無害的 `git add`，對已刪除的路徑則以 `pathspec did not match` 失敗。
- `confidence`: 52 / `layer`: design / `disposition`: `new` — 「Source Files 以單一未分組清單呈現」仍被綁在「來源為 archive manifest」上，但 `2a` 的三條允許清單來源（manifest、proposal `## Impact` 備援、手動逐檔選取）都不含 task 粒度，step 5 範例的 `**Task 1: …**` 分組在另外兩條路徑上同樣不可產出。此條件綁定自 propose 階段即存在於 C2，非第 1 輪引入。
- `confidence`: 50 / `layer`: text / `disposition`: `new` — step 2 末句 `An empty files array means there are no tracked source files.` 仍是無條件斷言，正是 `2a` 要否定的結論；C2 要求改寫相鄰的 `Cash state is the only allowlist authority after this point.` 就是為了避免同檔內的絕對指令互相矛盾，這一句漏了同樣處理。

Reviewer V 另逐項確認並回報無 finding 的檢查：四組第 1 輪概念（`### Spec Sync Changes` 無條件產生、三集合屬提交集合、第十一個字面句、cash-apply 因果句）在兩個 SKILL 變體、`skill-checks.fish`、design、tasks、spec 之間全部一致；全篇無殘留「十個字面句」；step 6 的 `Include all dirty files` 與 `Customize` 在 `2a` 路徑下語意仍成立；`:94` 的三集合宣告與 step 4 的 Unrelated 判定為互補而非矛盾；保留固定 hex 常數符合 C1 (c) 的明文要求，`exist_ok=True` 屬測試健壯性不涉 C1；`## Impact` 的 8 條 Modified 與實際 changed files 完全一致；14 個 delta spec scenario 逐條有實作落點，無孤兒。

## Rating

- 過濾後累積 blocking 集合 Critical 數：0
- 過濾後累積 blocking 集合 Warning 數：0
- 非 blocking triaged finding 數：5
- `critical_gap`：false
- `round_type`：micro
- 理由：唯一的累積 blocking 集合成員 M1 經 Reviewer V 裁定 `resolved` 並附實測依據後離開集合，集合清空。本輪五筆新 findings 的 `confidence` 全部落在 `[50, 80)`，過濾後皆降級為 `Suggestion`，依規則為非 blocking，不造成 `next_round`。通過條件成立，決策為 `passed`。所有 `fix-introduced` findings 都附了可驗證的 `introduced_by`，沒有任何 finding 因 introduced-by 不可驗證而被降到 `confidence ≤ 25`。

## Fix Actions

本輪決策為 `passed`，通過條件已成立，五筆非 blocking 的 `Suggestion` 並非通過的前提。但其中第一筆是第 1 輪修復引入的**行為回歸**，且其失效形態正是本變更存在的理由（靜默漏檔），把它留給實作階段不可接受；其餘四筆為低風險的對齊性修正。因此五筆全部修復。修改檔案：`.claude/skills/cash-commit/SKILL.md`、`.agents/skills/cash-commit/SKILL.md`、`openspec/changes/guard-post-archive-commit-allowlist/design.md`、`tasks.md`、`specs/cash-skill-workflows/spec.md`（共 5 個檔案）。

- STOP 判定漏掉 spec sync 集合：step 5 改為 `STOP only when all three of its sets are empty of dirty paths — its artifact set, the dirty subset of its resolved source allowlist, and its spec sync set.`，並補上「a still-dirty spec sync path must keep the flow going rather than be dropped here」的理由句。
- STOP 概念傳播缺口：`design.md` 決策六第三項、C2 的 step 5 改寫項、`tasks.md` 任務 3.1、`specs/cash-skill-workflows/spec.md` 的對應 AND 步驟全部改為三集合的一致敘述。修正後以 grep 確認三處舊敘述（`以上述 artifact 集合為判定輸入`、`以該 artifact 集合作為 STOP`、`的判定以該 artifact 集合為輸入`）零殘留。
- 允許清單被當成待 stage 清單：`:94` 改為 `Every dirty path in them is staged in step 8 …`，並加上 `The allowlist is a filter over dirty files, not a list of paths to stage blindly: touched_files is a snapshot, so it can name paths that are already clean or no longer exist.`
- 未分組呈現多綁來源條件：改為只要 `2a` 成立即以單一未分組清單呈現（理由句改為「none of step 2a's allowlist sources carry task granularity」），僅「標明來源與時點快照性質」保留給 archive manifest 來源；`design.md` C2 同步。
- step 2 末句無條件斷言：改為 `An empty files array means there are no tracked source files, unless step 2a establishes a post-archive recovery source.`

第 1 輪 `## Fix Actions` 的傳播宣稱不準確一事：完成的 round file 在迴圈進行中不可變更，因此該更正記錄於本輪而不回改 apply-r1.md。

fix 傳播：STOP 三集合定義、dirty 過濾語意、未分組呈現的無條件化三個概念，都同時檢查了兩個 skill 變體、design 決策段與 C2、tasks 任務 3.1 與 spec scenario 五個位置。`.agents` 變體以 `/cash-` → `$cash-` 正規化自 `.claude` 變體整檔轉寫。

fix 後重跑的 pre-round mechanical self-check：delta spec 註解配對（`<!--` 為 0）通過；數量一致性（決策 10 條、design 與 tasks 的「十一個」敘述一致、`## Impact` 的 Modified 為 8 條）通過；舊 STOP 敘述殘留掃描零命中；`spec sync 集合`／`spec sync set` 在五個檔案皆有對應敘述；delta 皆為 `## ADDED Requirements`，title-identity check 不適用；`openspec/signals/` 下無帶 `check` frontmatter 欄位的 signal。

fix 後重跑驗證：`scripts/cash-skills/tests/skill-checks.fish all`（76 + 4 tests）OK、`scripts/cash-cli/tests/cli-checks.fish all`（103 tests）OK、`.cash-skills/bin/cash validate guard-post-archive-commit-allowlist` 通過。這些修復是在通過輪套用的，未再經另一個 reviewer 複驗，改以上述機械檢查與全量回歸把關。

## Decision

passed

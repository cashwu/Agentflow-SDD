# Cash Apply Review — Round 1

## Reviewer Findings

### Critical

（無）

### Warning

1.
- `severity`: Warning
- `confidence`: 95
- `layer`: design
- `location`: `design.md` IC1 第 6 點；`.claude/skills/cash-archive/SKILL.md` 步驟 5 新增的失敗處置行（`.agents` 對應行同）
- `summary`: 新增的失敗指引把「明確要求跳過同步後重跑」列為 delta parse／`requirement_identity_mismatch`／`validation_failed` 三類錯誤的出路，但 `--skip-specs` 對這三者全部無效。
- `recommendation`: 改為只給實際有效的出路——delta parse 與 `requirement_identity_mismatch` 只能修正 delta specs 後重跑；`validation_failed` 的閘門是 `--no-validate`。同步修正 `design.md` IC1 第 6 點的逐字內容。
- reviewer source: Reviewer A — Adherence
- 主 agent 獨立複核：`.cash-skills/lib/cash_cli/commands/archive.py` 無條件呼叫 `build_sync_plan()`，且該呼叫排在 `skip_specs` 判斷之前；`requirement_identity_mismatch` 由 `.cash-skills/lib/cash_cli/spec_merge.py:261` 拋出；`validation_failed` 由 `validate_change()` 拋出且以 `no_validate` 為閘門。finding 成立。

2.
- `severity`: Warning
- `confidence`: 95
- `layer`: design
- `location`: `proposal.md` `## Impact`；`design.md` `## Implementation Contract`
- `summary`: 實作實際修改了 `cash-skills.version`、`.cash-skills/lib/cash_cli/installer.py`、`.cash-skills/manifest.tsv`，但 `## Impact` 只列四個 `SKILL.md`，design 亦無對應 IC；兩筆 `deviation` 已記錄卻未回填。
- `recommendation`: 把三個檔案加入 `## Impact` 的 `Modified:`，並在 `design.md` 新增一條 IC 描述 bump 機制，使 diff 每一行可回溯到 tasks 或 Implementation Contract。
- reviewer source: Reviewer A — Adherence
- 附註：Reviewer A 判定兩筆 `deviation` 本身正當（`openspec/specs/cash-cli/spec.md` 既有 contract 已把 bundle version bump、`BUNDLE_VERSION` 恆等、manifest 一致性定為要求），屬機制替換分支，缺口只在宣告完整性。

3.
- `severity`: Warning
- `confidence`: 90
- `layer`: design
- `location`: `tasks.md` `## 1. Implementation`；`design.md` D7
- `summary`: bundle version bump 未被排入任何 task，實作只能在 task 2.1 驗證失敗後才補做，與「MUST 在第一個受 guard 的 artifact 改動前調升」的順序要求相反。
- `recommendation`: 在 `tasks.md` 新增一條排在 1.1 之前的 bump 任務，並修正 D7——D7 只論證「不需修改 `skill-checks.fish`」，未指出「執行它需要先完成 bump」。
- reviewer source: Reviewer A — Adherence
- 附註：最終工作樹狀態本身合規（bump 與 skill 變更同一 commit 落地，first-parent history test 已通過），缺口在 sequencing 與宣告完整性。

### Suggestion

4.
- `severity`: Suggestion
- `confidence`: 70
- `layer`: design
- `location`: `.claude/skills/cash-commit/SKILL.md` 6a-ii；`.claude/skills/cash-archive/SKILL.md` 步驟 4（`.agents` 同）
- `summary`: 改寫時把「delta specs 存在」的唯一判準定義 `(directory is empty or absent)` 一併刪除，使空的 `specs/` 目錄可能被記為 `synced` 而非 `no delta specs`，正好觸發 D4 要防的無關 dirty spec 掃入。
- `recommendation`: 在兩個入口的檢查句補回 emptiness 定義。
- reviewer source: Reviewer B — Quality
- `introduced_by`: `git diff .claude/skills/cash-commit/SKILL.md` hunk `@@ -181,15 +181,15 @@` 刪除的 `- If **no delta specs exist** (directory is empty or absent): skip to 6a-iii.`
- 過濾紀錄：原報 `Warning`／`confidence: 70`，落在 `[50, 80)`，依 confidence filter 降為 `Suggestion`。

5.
- `severity`: Suggestion
- `confidence`: 60
- `layer`: design
- `location`: `.claude/skills/cash-archive/SKILL.md` `**Output On Success With Warnings**` 模板的 Warnings 清單（`.agents` 同）
- `summary`: fenced 輸出模板內混入撰寫指示 `— include only when the outcome is `skipped``，且未使用佔位標記，agent 有機率連指示一起逐字輸出給使用者。
- `recommendation`: 把條件性移到模板之外，由步驟 6 承載；模板內只保留純輸出文字。
- reviewer source: Reviewer A — Adherence 與 Reviewer B — Quality 獨立提出，依 `location + summary` 合併（A 報 `Suggestion`／55、B 報 `Warning`／60，取較高 confidence，`layer` 兩者皆 `design`）
- `introduced_by`: `git diff .claude/skills/cash-archive/SKILL.md` hunk `@@ -134,12 +138,12 @@` 把純輸出文字改為夾帶指示的行。
- 過濾紀錄：合併後 `confidence: 60` 落在 `[50, 80)`，降為 `Suggestion`。

6.
- `severity`: Suggestion
- `confidence`: 55
- `layer`: design
- `location`: `.claude/skills/cash-archive/SKILL.md` 步驟 6 與 `**Output On Success With Warnings**` 模板（`.agents` 同）
- `summary`: 新的模板選擇規則讓「outcome=`skipped` 但 artifacts 全 done、tasks 全 `[x]`」這條乾淨路徑首次落進 With Warnings 模板，但該模板另兩行 warnings 沒有條件註記，且結尾 `Review the archive if this was not intentional.` 與「使用者明確要求」矛盾。
- `recommendation`: 把另兩行 warnings 與結尾句也標成條件性輸出。
- reviewer source: Reviewer B — Quality
- `introduced_by`: `git diff .claude/skills/cash-archive/SKILL.md` hunk `@@ -84,19 +85,22 @@` 新增的模板選擇規則行。
- 過濾紀錄：原報 `Warning`／`confidence: 55`，落在 `[50, 80)`，降為 `Suggestion`。

7.
- `severity`: Suggestion
- `confidence`: 55
- `layer`: design
- `location`: `.claude/skills/cash-archive/SKILL.md` 步驟 4 的 Explicit skip bullet；`.claude/skills/cash-commit/SKILL.md` 6a-ii 同（`.agents` 同）
- `summary`: 明確跳過的偵測範圍自相矛盾——同一句先限定 `in this invocation`，隨即把 `saying so directly in this session` 列為合格形式，而下一行又 `MUST NOT infer a skip request ... from an earlier archive`；session 範圍嚴格大於 invocation。
- `recommendation`: 把合格形式收斂為「本次呼叫發起後、針對本次封存所說的話」，並明文排除引用／示例中出現的 `--skip-specs` 字面值。
- reviewer source: Reviewer B — Quality
- `introduced_by`: `git diff .claude/skills/cash-archive/SKILL.md` hunk `@@ -64,19 +64,20 @@` 新增的 Explicit skip bullet 與其下一行的不推論規則。
- 過濾紀錄：原報 `Warning`／`confidence: 55`，落在 `[50, 80)`，降為 `Suggestion`。

8.
- `severity`: Suggestion
- `confidence`: 55
- `layer`: design
- `location`: `.claude/skills/cash-commit/SKILL.md` 6a-iii 的檔案收集清單（`.agents` 同）
- `summary`: 6a-iii 的 `synced` 分支以「整個 `openspec/specs/` 目錄的 dirty 狀態」納入 commit set，缺少同檔步驟 2a 已有的 `master_digests` 逐路徑 digest 比對防線；提問移除後這條分支成為常見路徑的預設。
- `recommendation`: 讓 6a-iii 沿用步驟 2a 的 `master_digests` 判準，使兩條封存路徑對「哪些 spec 路徑屬於本次封存」使用同一個可稽核判準。
- reviewer source: Reviewer B — Quality
- `introduced_by`: `git diff .claude/skills/cash-commit/SKILL.md` hunk `@@ -211,13 +211,15 @@` 的納入條件改寫，配合同一 diff 中 6a-ii 的 **AskUserQuestion** 移除。
- 過濾紀錄：原報 `Suggestion`／`confidence: 55`，維持 `Suggestion`。

## Rating

- post-filter cumulative blocking set Critical count: `0`
- post-filter cumulative blocking set Warning count: `3`
- 非 blocking 的 triaged finding 數：`5`
- `critical_gap`: `false`
- `round_type`: `full`

rationale：本輪是未 seeded run 的第一輪，全部通過 confidence filter 的 `Critical` 與 `Warning` 皆為 blocking。三筆 blocking `Warning`（IC1 第 6 點的無效出路、bundle version 三檔未納入宣告範圍、bump 未排入 task 且序位在受 guard 編輯之後）都有直接的 artifact 或程式碼證據，因此不能 pass。無 blocking `Critical`，故 `critical_gap` 為 `false`。五筆非 blocking finding 依規則以 triage 處理，不影響本輪決定。

## Fix Actions

**confidence filter 降級與丟棄紀錄**

- Reviewer B finding「6a-ii 遺失 emptiness 定義」：`confidence: 70` ∈ `[50, 80)`，降為 `Suggestion`。
- Reviewer A finding「warnings 模板夾帶條件說明」（`confidence: 55`）與 Reviewer B 同一 finding（`confidence: 60`）依 `location + summary` 合併，取 `confidence: 60`，`layer` 皆為 `design`；`confidence: 60` ∈ `[50, 80)`，降為 `Suggestion`。
- Reviewer B finding「With Warnings 模板另兩行與結尾句未條件化」：`confidence: 55` ∈ `[50, 80)`，降為 `Suggestion`。
- Reviewer B finding「explicit skip 偵測範圍 invocation 與 session 矛盾」：`confidence: 55` ∈ `[50, 80)`，降為 `Suggestion`。
- Reviewer B finding「6a-iii 缺 `master_digests` 防線」：原為 `Suggestion`，`confidence: 55`，維持。
- 丟棄（`confidence < 50`）：`--skip-specs` token 解析規則未明訂（`45`）；模板選擇規則被放進摘要欄位清單（`40`）；兩個入口的判定結果標籤不一致（`45`）。三者的 downgrade trace 保留於本節。
- Reviewer B 的每一筆 `Critical`／`Warning` 皆附可驗證的 `introduced_by`，無因缺乏 `introduced_by` 證據而降至 `confidence ≤ 25` 的 finding。

**blocking finding 的修復**

- finding 1（IC1 第 6 點無效出路）：修改 `design.md`（IC1 第 6 點改為只列實際有效的出路，並記錄 `--skip-specs` 對三類錯誤無效的程式碼依據）、`.claude/skills/cash-archive/SKILL.md`（步驟 5 失敗處置拆為兩段：delta parse／`requirement_identity_mismatch` 只能修正 delta specs 後重跑；`validation_failed` 可修正後重跑或以 `--no-validate` 重跑，兩段都明寫 `--skip-specs` 不繞過）、`.agents/skills/cash-archive/SKILL.md`（重新生成）、`tasks.md`（1.1 新增兩條正向判準釘住新措辭）。
- finding 2（宣告範圍缺三個檔案）：修改 `proposal.md`（`## Impact` 的 `Modified:` 加入 `cash-skills.version`、`.cash-skills/lib/cash_cli/installer.py`、`.cash-skills/manifest.tsv`；`## Proposed Solution` 加第 7 點）、`design.md`（新增 `**IC6 — bundle version bump**`）。
- finding 3（bump 未排入 task 且序位錯誤）：修改 `tasks.md`（新增排在 1.1 之前的 `1.0 依 IC6 調升 bundle version`，含三條判準與範圍界定；1.3 的相依改為「相依 1.0、1.1 與 1.2」）、`design.md`（D7 補上「執行該套件的前置條件是 bump 必須排在第一個 `SKILL.md` 編輯之前」）。

**非 blocking finding 的處置**

- finding 4（emptiness 定義遺失）：triage note——雖為非 blocking，但屬 D4 直接關心的錯誤模式且修復成本低，本輪一併修復。修改 `design.md`（IC1 第 2 點與 IC2 第 2 點的逐字內容補回 `— they do not exist when the directory is empty or absent —`）、`.claude/skills/cash-archive/SKILL.md`、`.claude/skills/cash-commit/SKILL.md`、兩份 `.agents` 對應檔（重新生成）、`tasks.md`（1.1 與 1.2 各加一條正向判準）。
- finding 5（模板夾帶條件說明）：triage note——兩個 reviewer 獨立提出且失敗模式是把撰寫指示外洩給使用者，本輪一併修復。修改 `design.md`（IC1 第 8 點改為新增兩條步驟 6 規則、第 9 點改為模板內只留純輸出文字；D5 敘述同步）、`.claude/skills/cash-archive/SKILL.md`、`.agents/skills/cash-archive/SKILL.md`（重新生成）、`tasks.md`（1.1 的正向判準改為兩條，並新增一條負向判準釘住舊夾帶措辭必須消失）。
- finding 6（With Warnings 模板另兩行與結尾句未條件化）：triage note，本輪不修復。`design.md` D5 明訂「另外兩個 Output 模板與 Warnings 區段的行組成 MUST NOT 改動」，依該 decision 此修改超出本變更宣告範圍；且結尾句 `Review the archive if this was not intentional.` 是本變更未修改的既有行。列為後續 change 的候選。
- finding 7（explicit skip 偵測範圍矛盾）：triage note，本輪不修復。`design.md` D2 已明文把「在本次 session 中直接說明這次封存不要同步 specs」定義為 `cash-archive` 的合格形式之一，屬已於 design 記錄的刻意決策；收斂該範圍會改變 D2 與 spec delta 的判定契約，超出本變更範圍。列為後續 change 的候選。
- finding 8（6a-iii 缺 `master_digests` 防線）：triage note，本輪不修復。該建議等同為 6a-iii 新增一層 contract 未要求的防護，且 `proposal.md` `## Non-Goals` 明列「不改動 `cash-commit` 步驟 2a 的封存後復原路徑」；將 2a 的判準搬到 6a-iii 屬新範圍。列為後續 change 的候選。

**post-fix mechanical self-check 結果**

- comment/annotation lint：delta spec 的 `<!--` 與 `-->` 皆為 `0`，無未閉合區塊、無殘留 `---` 分隔線。
- count-consistency：`tasks.md` 宣稱的「IC1 的九點」「IC2 的六點」與 `design.md` 實際條目數（`9`／`6`）相符；delta spec 的 `## ADDED Requirements` 與 `## MODIFIED Requirements` 各 `1` 條，與 `design.md` IC4 相符。
- identifier cross-grep：新引入的 `they do not exist when the directory is empty or absent`（四檔各 `1`）、`Include the skipped warning line only when the outcome is`（兩個 archive 變體各 `1`）、`does NOT bypass either check`（兩個 archive 變體各 `1`）拼寫與語意一致；被移除的 `— include only when the outcome is` 四檔皆為 `0`。
- spec delta title-identity：`## MODIFIED Requirements` 下的 `### Requirement: cash-commit 的 archive-first 允許清單` 與 `openspec/specs/cash-skill-workflows/spec.md` 逐位元相符；無 `## RENAMED Requirements` 條目。
- signal-derived checks：`openspec/signals/` 下無任何帶 `check` frontmatter 欄位的 signal，全部落入 best-effort 判斷分支，無 `範圍外 check 失敗` 與 fallback 紀錄。
- self-check 修正：本輪 fix actions 後的自檢另外抓到兩處並已修正——`design.md` 中 `**IC6 — bundle version bump**` 被插在 `**IC5 — 驗證**` 之前，已重排為 IC5 之後；D5 仍敘述「跳過警告行改為佔位形式」，與 finding 5 修復後的實作不符，已同步改寫。
- `tasks.md` 判準自身的缺陷：新增的 `rg -Fq -- 'bundle_version\t2.14.0'` 無法比對真實 tab（`-F` 下 `\t` 為字面反斜線加 t），已改為 `rg -q -- '^bundle_version\t2\.14\.0$'`。

**fix 後的重新驗證**

- 由 `tasks.md` 直接抽出的全部 `55` 條 `rg` 判準逐條執行，`0` 失敗（正向與保留守則 exit 0、負向 exit 1）。
- `.claude` 與 `.agents` 兩對檔案在 invocation 前綴正規化後全檔零差異。
- `./scripts/cash-skills/tests/skill-checks.fish` exit `0`（`PASS: bundle version history`、`PASS: exact live include-root namespace scan`、`PASS: all`）。
- `.cash-skills/bin/cash validate default-spec-sync-on-archive` 通過。
- `.cash-skills/bin/cash analyze default-spec-sync-on-archive` 無 `Critical`。

**本輪 Fix Actions 修改的檔案（`openspec/changes/` 之外）**

- `.claude/skills/cash-archive/SKILL.md`
- `.claude/skills/cash-commit/SKILL.md`
- `.agents/skills/cash-archive/SKILL.md`
- `.agents/skills/cash-commit/SKILL.md`
- `.cash-skills/manifest.tsv`

無 `未修復：裁判面保護` 紀錄；本輪未修改任何裁判面保護路徑下的檔案。

## Decision

next_round

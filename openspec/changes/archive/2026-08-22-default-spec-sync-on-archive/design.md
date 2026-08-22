## Context

Cash 有兩個封存入口，兩者都在呼叫 `.cash-skills/bin/cash archive` 之前，用一次 **AskUserQuestion** 決定要不要同步 delta specs：

- `.claude/skills/cash-archive/SKILL.md` 的步驟 4，標題為 `4. **Choose spec sync behavior**`，以散文句 `If delta specs exist, ask whether to sync them.` 發問，提供 Sync／Do not sync／Cancel 三個選項。
- `.claude/skills/cash-commit/SKILL.md` 的步驟 `**6a-ii. Delta spec sync check**`，提問 `"Delta specs found. Sync to main specs before archiving?"`，Yes／No 兩個選項。

兩份檔案在 `.agents/skills/` 下各有一份對應輸出。依 `openspec/specs/cash-skill-workflows/spec.md` 的 `Cash skill 清單與所有權` requirement，`.claude/skills/` 是人工維護的權威源頭，`.agents/skills/` 是 `scripts/cash-skills/generate.fish` 依 `scripts/cash-skills/variant-rules.yaml` 產生的輸出。`scripts/cash-skills/variant-rules.yaml` 的 `skills:` 區段只為 `cash-audit`、`cash-ingest`、`cash-propose` 定義 per-skill patches，`cash-archive` 與 `cash-commit` 只套用 `universal:` 規則（invocation 前綴置換、移除 `context`／`agent`／`disallowedTools` frontmatter key、移除 `## Claude fork context` 區段），因此本變更不需要改動生成規則。

Cash CLI 這一側不需要任何改動：`openspec/specs/cash-cli/spec.md` 的 archive requirement 已經定義「未帶 `--skip-specs` 時驗證既有 sync manifest 或執行一次 sync，帶 `--skip-specs` 時 MUST NOT merge」。本變更只改變兩個 skill 決定是否帶上該旗標的方式。

## Goals / Non-Goals

**Goals**

- 有 delta specs 時，封存預設同步且不發問。
- 保留跳過同步的能力，並讓它成為一條有明示入口、可被字面偵測的分支，而不是靠 agent 主觀推測。
- 兩個入口的判定規則一致，`.claude` 與 `.agents` 兩個變體在正規化 invocation 前綴後完全相同。
- master spec 與兩個 skill 中與新行為矛盾的敘述一併修正，不留殘留引用。

**Non-Goals**

- 不改動 Cash CLI、`--skip-specs` 旗標語意、archive transaction 或 `archive-manifest.json` schema。
- 不改動 6a-i 的未完成 task 提問，也不改動步驟 2 與步驟 3 的未完成 artifact／task 警告與確認。
- 不改動 `cash-commit` 步驟 2a 的封存後復原路徑。
- 不新增設定項，也不引入跨呼叫的偏好持久化。
- 不恢復 `cash-archive` 步驟 4 的 Cancel 出口。

## Decisions

**D1：判定取代提問，而非把提問加上預設值。**
兩個入口都把「選擇」段落改寫為「判定」段落，不保留任何 **AskUserQuestion** 呼叫，段落內也不得留下原有的散文提問句或選項清單。判定規則本身以禁止式措辭表述不發問（例如 `without asking the user`、`do NOT ask the user to choose`），這些措辭不在禁止之列。理由：保留提問並附預設值仍然會中斷流程，無法解決使用者回報的症狀。

**D2：跳過與預設之間以明訂的優先序組合，且跳過有明示入口。**
判定規則為兩條、有先後：

1. **Explicit skip 優先**——使用者在本次呼叫中明確要求跳過時，MUST 帶 `--skip-specs`。明確要求的形式依入口而異：對 `cash-archive` 是在 invocation 後附上 `--skip-specs`，或在本次 session 中直接說明這次封存不要同步 specs；對 `cash-commit` 的 archive-first 子流程只有後者——該子流程是在對話中途由使用者選擇 archive-first 才進入的，沒有自己的 invocation 可掛旗標。
2. **否則為預設 sync**——不帶 `--skip-specs`，且不論是否存在 delta specs 都適用，也不發問。

MUST NOT 從 change 看起來像 tooling／文件變更、從先前的封存或任何其他間接訊號推論出跳過要求。第一條優先於第二條，因此「沒有 delta specs 且使用者明確要求跳過」有唯一解：帶旗標。`cash-archive` 的 `**Input**` 段 MUST 承認 `--skip-specs` 這個 invocation 形式，讓這條分支有可到達的入口。

**D3：`cash-archive` 步驟 4 的 Cancel 選項隨提問一併移除。**
該選項的作用是「在尚未 mutation 前中止」。移除後在「artifacts 全 done、tasks 全 `[x]`、且以 invocation 直接指定 change 名稱」的常見路徑上，將不再有任何互動式確認。這是刻意取捨：呼叫封存 skill 本身即為封存意圖的明確表達。殘餘風險見 `## Risks / Trade-offs`，MUST NOT 以「步驟 2、步驟 3 的確認仍在」作為緩解敘述——那兩處只在 artifact 或 task 未完成時觸發。

**D4：判定結果是三值紀錄，`cash-commit` 6a-iii 依它決定納入。**
6a-ii MUST 把判定結果記為 `synced`、`skipped`、`no delta specs` 三者之一，且 MUST 依序判定：先 `skipped`（帶了旗標），再 `synced`（存在 delta specs 且未帶旗標），最後 `no delta specs`（沒有 delta specs 且未帶旗標）。順序是必要的：`skipped` 與 `no delta specs` 在「沒有 delta specs 且使用者明確要求跳過」同時成立，沒有順序就會把該情形誤記為 `no delta specs`，使完成回報漏掉「出於使用者明確要求」這件事。6a-iii 的 `openspec/specs/` 納入條件 MUST 是「6a-ii 記為 `synced`」。
不能改寫成「封存未帶 `--skip-specs`」：沒有 delta specs 時封存同樣不帶旗標，該條件恆真，會把無關的 dirty `openspec/specs/` 路徑掃進 archive-first 提交集合——這正是舊條件（使用者從未「明確選擇」故排除）擋下的情形。三值紀錄使新條件與舊條件在無 delta specs 與跳過兩種情形下行為完全相同，只在「確實同步」時為真。

**D5：完成回報義務依兩個入口各自既有的輸出面分配。**
- `cash-archive` 已有 `**Specs:**` 欄位可以承載回報，但三個 Output 模板並非依判定結果選擇：模板由「有沒有 warnings」決定，而 `**Output On Success With Warnings**` 的 `**Specs:**` 行硬寫為 `Sync skipped (user chose to skip)`。因此「判定結果為 `synced`、但有未完成 artifact 或 task」這個真實可達的組合無模板可用——用無 warnings 模板會丟掉 warnings，用 warnings 模板會把 `synced` 誤報為跳過。處置是把 warnings 模板的 `**Specs:**` 行改為依判定結果填值的佔位形式，並在步驟 6 明訂三個判定結果各自對應的 `**Specs:**` 字串。跳過警告行則維持純輸出文字，其條件性由步驟 6 的規則承載而非寫在模板 fence 內——fence 內容會被逐字輸出給使用者，夾帶條件說明會讓該說明一起外洩。另外兩個 Output 模板與 Warnings 區段的行組成 MUST NOT 改動。
- `cash-commit` 的 `**Output On Success**` 只有 Commit／Files／Tasks 三行，沒有任何 spec sync 欄位，`### Spec Sync Changes (if sync was performed)` 是 commit plan 的區段而非完成摘要，且跳過時整段消失，看不出跳過與無 delta specs 的差別。因此 `cash-commit` 的回報義務落在 archive-first 的 **updated commit plan**：MUST 在該計畫加入一行標明本次判定結果。這是本變更唯一允許的模板追加。

**D6：spec 面同時做 MODIFIED 與 ADDED。**
`cash-commit 的 archive-first 允許清單` requirement 以「使用者在封存子流程中明確選擇 spec sync 時」描述納入條件，與新行為矛盾，MUST 以 MODIFIED 改寫；同時 ADDED 一條新 requirement 定義判定契約本身，涵蓋兩個入口、優先序、回報義務與兩個變體的對等。

**D7：不新增測試檔，不修改既有測試。**
`scripts/cash-skills/tests/skill-checks.fish` 重新執行生成並比對 committed 輸出，已經覆蓋 `.agents` 兩份檔案與 `.claude` 源頭的一致性。它對 spec sync 的唯一斷言是 consumer matrix 中的字面值 `'"$cash_cli" archive <name> --skip-specs'`，該字面值位於 `cash-archive` 步驟 5 的 bash 範例中，本變更 MUST 保留它，因此既有斷言不需修改。這也讓 `scripts/cash-skills/tests/skill-checks.fish` 維持在本變更的宣告範圍之外，不觸及 grader 保護路徑。行為驗證改以 tasks 中的正向與負向字面值判準完成。但執行該套件有一個前置條件：它包含 bundle version history contract，任何 `SKILL.md` 位元改變都要求 `cash-skills.version` 嚴格領先 HEAD，因此 IC6 的 bump MUST 排在第一個 `SKILL.md` 編輯之前，否則在 bump 之前的任何時點執行本套件都必然失敗。

**D8：驗收判準同時釘住正向契約與負向殘留。**
只斷言舊機制字面值消失，無法區分「改成預設同步」與「改成一律跳過」，也擋不住把散文提問原樣留下的實作。因此 IC1 與 IC2 逐字指定要寫入的判定句，tasks 對每一句加正向 exit 0 判準，並對每一個被移除的舊字面值加負向 exit 1 判準。

## Implementation Contract

**IC1 — `.claude/skills/cash-archive/SKILL.md`**

1. `**Input**` 段落 MUST 承認明示跳過語法，改為逐字包含 `optionally followed by `--skip-specs` to explicitly request skipping delta spec sync (see step 4)`。
2. 把標題為 `4. **Choose spec sync behavior**` 的整個步驟替換為下列逐字內容：

   ```
   4. **Determine spec sync behavior**

      Check for delta specs at `openspec/changes/<name>/specs/` — they do not exist when the directory is empty or absent — then resolve the flag without asking the user.

      - **Explicit skip**: pass `--skip-specs` only when the user asked to skip delta spec sync in this invocation — either by appending `--skip-specs` to the invocation, or by saying so directly in this session. This takes precedence over the default below.
      - **Default — sync**: otherwise run archive without `--skip-specs`, whether or not delta specs exist, and do NOT ask the user to choose.
      - MUST NOT infer a skip request from the change looking tooling-only or doc-only, from an earlier archive, or from any other indirect signal.
      - Record the resolved outcome by evaluating in order: `skipped` (the flag is set), then `synced` (delta specs exist and the flag is not set), then `no delta specs` (no delta specs and the flag is not set); step 6 reports it.

      Do not invoke another skill or delete touched state directly. The Cash CLI owns touched import, sync state, legacy cleanup diagnostics, transaction flags, and cleanup.
   ```

3. 步驟 4 段落 MUST NOT 含 `AskUserQuestion`，也 MUST NOT 殘留原有的散文提問 `If delta specs exist, ask whether to sync them.` 與 Sync／Do not sync／Cancel 三個選項 bullet。第 2 點逐字內容中的禁止式措辭（`without asking the user`、`the user asked to skip`、`do NOT ask the user to choose`）不在此限。
4. 步驟 5 的 Optional flags 清單中 `--skip-specs` 那一行 MUST 改寫為指向步驟 4 的判定規則，逐字為 `- `--skip-specs` — skip delta spec application; use only on the explicit request described in step 4`。措辭 `(for tooling/doc-only changes)` MUST 消失——它是檔內唯一還在以 change 性質描述旗標使用時機的句子，與第 2 點的不推論規則直接矛盾。
5. 步驟 5 的 `adding the selected flags` MUST 改為 `adding the resolved flags`，移除被廢除機制的殘留措辭。
6. 步驟 5 的失敗處置 MUST 增加一條：delta parse 失敗、`requirement_identity_mismatch` 或 `validation_failed` 時，報告確切錯誤並給出該錯誤實際有效的出路。`--skip-specs` 對這三者都無效：`.cash-skills/lib/cash_cli/commands/archive.py` 無條件呼叫 `build_sync_plan()`（delta parse 失敗與 `requirement_identity_mismatch` 皆由 `.cash-skills/lib/cash_cli/spec_merge.py` 於此路徑拋出），且該呼叫排在 `skip_specs` 判斷之前；`validation_failed` 由 `validate_change()` 拋出，其閘門是 `--no-validate`。因此有效出路為：delta parse 失敗或 `requirement_identity_mismatch` → 修正 delta specs 後重跑；`validation_failed` → 修正 validation findings 後重跑，或在確認可接受時以 `--no-validate` 重跑。MUST NOT 把「明確要求跳過同步後重跑」列為這三類錯誤的出路。
7. 步驟 5 的 bash 範例 MUST 原樣保留 `"$cash_cli" archive <name> --skip-specs` 這一行；`--mark-tasks-complete` 與 `--no-validate` 兩條 Optional flags 說明 MUST NOT 改動。
8. 步驟 6 的摘要 MUST 與三個判定結果同名，並 MUST 明訂模板選擇規則。既有的 `- Spec sync status (synced / sync skipped / no delta specs)` MUST 改為 `- Spec sync status: `synced`, `skipped`, or `no delta specs` — the `**Specs:**` line reports `✓ Synced to main specs`, `Sync skipped (explicitly requested by the user)`, or `No delta specs` respectively`，消除同一份檔案裡 `sync skipped` 與 `skipped` 兩套名稱。模板選擇與條件輸出的規則 MUST 放在該 bullet list **之外**，於清單下方另起一段，逐字為 `**Template selection**: use the **Output On Success With Warnings** template whenever there is at least one warning; an outcome of `skipped` is itself a warning. Include the skipped warning line only when the outcome is `skipped`.`。這一段 MUST 緊接在該 bullet list 的最後一項之後（中間只隔一個空行），使「於清單下方」成為可機械比對的相鄰關係而非僅靠敘述。這一段承載第 9 點原本寫在模板 fence 內的條件說明。位置是規範的一部分：`Show archive completion summary including:` 底下的 bullet list 每一項都是「摘要要顯示的欄位」，把撰寫指示混進該清單只是把「指示與輸出混雜」從模板 fence 搬到欄位清單，並未消除 agent 逐字輸出指示的風險。同一步驟的最後一項 `- Note about any warnings (incomplete artifacts/tasks)` MUST 改為 `- Note about any warnings (incomplete artifacts/tasks, or a `skipped` outcome)`：原括號把 warning 的外延窮舉為未完成 artifact／task，與 `**Template selection**` 段的 `an outcome of `skipped` is itself a warning` 對同一步驟內的同一概念給出兩個外延，只讀清單的 agent 會在乾淨路徑上判定零 warning 而繞過模板選擇規則。沒有這條規則，「判定結果為 `skipped` 且 artifacts 全 done、tasks 全 `[x]`」這個乾淨路徑會落到硬寫 `**Specs:** ✓ Synced to main specs` 的 `**Output On Success**`，把跳過誤報為已同步；第 9 點把 warnings 模板的該行改為佔位形式之後，原本靠內容線索消歧的方式已不復存在，選擇規則必須寫成明文。
9. `**Output On Success With Warnings**` 模板的 `**Specs:** Sync skipped (user chose to skip)` MUST 改為 `**Specs:** <✓ Synced to main specs | Sync skipped (explicitly requested by the user) | No delta specs>`，其 Warnings 清單中的 `- Delta spec sync was skipped (user chose to skip)` MUST 改為 `- Delta spec sync was skipped (explicitly requested by the user)`，且該行 MUST NOT 夾帶條件說明——條件由第 8 點新增的步驟 6 規則承載。`**Output On Success**`、`**Output On Success (No Delta Specs)**`、`**Output On Error (Archive Exists)**` 與 Guardrails 區段 MUST NOT 改動。步驟 1 的 change 選單與 Guardrails 的 **AskUserQuestion** fallback 句 MUST 保留。

**IC2 — `.claude/skills/cash-commit/SKILL.md`**

1. 6a 開頭的 `This sub-flow executes three checks in sequence` MUST 改為 `This sub-flow executes three steps in sequence`——改寫後 6a-ii 不再是 check。
2. 把 `**6a-ii. Delta spec sync check**` 的整個段落替換為下列逐字內容。6a-i 與 6a-iii 的每一行都縮排 4 空格，因為 6a 是一個 numbered list item，其子段落屬於該 item 的內文；下列 fence 內容已含該 4 空格縮排，插入時 MUST 原樣沿用，MUST NOT 拉齊到 column 0——那會把 6a-ii 抽出 6a 的內文而破壞區塊結構，並使 tasks 1.2 的段落級判準因 awk 起點失配而變成空真。

   ```
       **6a-ii. Delta spec sync determination**

       Check whether delta specs exist at `openspec/changes/<name>/specs/` — they do not exist when the directory is empty or absent — then resolve the flag without asking the user.

       - **Explicit skip**: set the `--skip-specs` flag only when the user asked to skip delta spec sync in this invocation. This takes precedence over the default below.
       - **Default — no flag**: otherwise do not add `--skip-specs`, whether or not delta specs exist, and do NOT ask the user to choose.
       - MUST NOT infer a skip request from the change looking tooling-only or doc-only, from an earlier archive, or from any other indirect signal.

       Record the resolved outcome by evaluating in order: `skipped` (the flag is set), then `synced` (delta specs exist and the flag is not set), then `no delta specs` (no delta specs and the flag is not set). 6a-iii uses that recorded outcome, and only `synced` admits `openspec/specs/` paths into the commit set.
   ```

3. 6a-iii 檔案收集清單中的 `- Changes under `openspec/specs/` only if the user explicitly selected spec sync in 6a-ii` MUST 改為 `- Changes under `openspec/specs/` only when 6a-ii recorded the outcome `synced``。
4. 6a-iii 的 updated commit plan 模板 MUST 在標題行下方加入一行 `**Spec sync:** <synced | skipped (explicitly requested) | no delta specs>`。這是本變更唯一允許的模板追加。
5. 6a-i、6a-iii 的其餘內容、步驟 2a 的 spec sync 集合定義，以及 `### Spec Sync Changes (if sync was performed)` 這一行 MUST NOT 改動。
6. 改寫後的 6a-ii 段落 MUST NOT 含 `AskUserQuestion`，也 MUST NOT 殘留提問字串 `Delta specs found. Sync to main specs before archiving?`。

**IC3 — 變體重新生成**

- `.agents/skills/cash-archive/SKILL.md` 與 `.agents/skills/cash-commit/SKILL.md` MUST 由在專案根執行 `scripts/cash-skills/generate.fish` 產生，MUST NOT 手工編輯。
- 生成後兩個變體在正規化 invocation 前綴後，被改寫的段落 MUST 完全相同。

**IC4 — spec delta**

- capability `cash-skill-workflows` 的 delta 含一個 `## ADDED Requirements` 條目與一個 `## MODIFIED Requirements` 條目。
- ADDED 的新 requirement 定義判定契約：優先序、明示跳過入口、不推論規則、三值判定結果、兩個入口各自的回報義務與兩變體對等。
- MODIFIED 的 `### Requirement: cash-commit 的 archive-first 允許清單` 標題 MUST 從 `openspec/specs/cash-skill-workflows/spec.md` 逐字複製。區塊內改動限於 spec sync 納入條件相關的文字，其餘 scenario 逐字沿用；此外 MAY 新增一條描述「判定結果不是 `synced` 時不納入任何 `openspec/specs/` 路徑」的負向 scenario，因為新條件的錯誤模式正是在該情形下才顯現。

**IC5 — 驗證**

- 在專案根執行 `scripts/cash-skills/tests/skill-checks.fish`，MUST 全數通過。該套件需要 `rg`（ripgrep）與 `fish`；環境缺少 `rg` 時 MUST 先安裝，MUST NOT 以「環境不可執行」略過此驗證。
- 執行 `.cash-skills/bin/cash validate default-spec-sync-on-archive`，MUST 通過。

**IC6 — bundle version bump**

- 本變更修改四個 `SKILL.md`，而 `openspec/specs/cash-cli/spec.md` 既有的 bundle version history contract 要求任何 `.claude/skills/cash-*/SKILL.md` 或 `.agents/skills/cash-*/SKILL.md` 位元改變時 `cash-skills.version` MUST 嚴格領先 HEAD 的值。因此 `cash-skills.version` MUST 由 `2.13.0` 調升為 `2.14.0`（行為變更沿用 minor bump 慣例）。
- `.cash-skills/lib/cash_cli/installer.py` 的 `BUNDLE_VERSION` 常數 MUST 與 `cash-skills.version` 一致，否則 installer runtime contract test 失敗。
- `.cash-skills/manifest.tsv` MUST 以 `PYTHONPATH=.cash-skills/lib python3 -s -P -B -m cash_cli.installer --self` 重建，使 `bundle_version`、`runtime_generation` 與各 record digest 與工作樹一致；否則 `.cash-skills/bin/cash` 以 `manifest_invalid` fail closed。
- 這三個檔案 MUST 出現在 `proposal.md` 的 `## Impact` Modified 清單中。本項不改變任何要交付的觀察行為或 contract，只是讓既有落地機制成為本變更的宣告範圍。

## Risks / Trade-offs

- **常見路徑上將沒有任何互動式確認。** 步驟 1 的選單只在未給 change 名稱時出現，步驟 2 與步驟 3 的確認只在 artifact 或 task 未完成時觸發。因此在「artifacts 全 done、tasks 全 `[x]`、且直接以 change 名稱呼叫」的常見路徑上，本變更之後從呼叫到不可逆 mutation 之間零確認。該 mutation 包含移動 change 目錄、改寫 master specs、以及刪除 `.cash-skills/state/` 下的 touched／snapshots／sync 狀態。前兩者可由 git 還原，第三者不行：`.gitignore` 第 3 行忽略 `.cash-skills/state/`。`.claude/skills/cash-apply/SKILL.md` 的 Archive guidance timing 已經警告單獨執行封存會刪掉 `cash-commit` 所需的 touched state，本變更使該陷阱更容易踩到。這是 D3 的已知取捨，未提供緩解。
- **delta spec 內容寫錯會被直接合併進 master spec，且無防線。** `.cash-skills/bin/cash archive` 的 preflight 只涵蓋 delta parse 失敗與 `requirement_identity_mismatch`，攔不住「格式正確但內容寫錯」的 delta。舊行為下的提問並非有效防線（使用者一向選 Sync），但它確實是唯一會讓人停下來看一眼的時機。殘餘風險為：發現時 master spec 已被合併，需人工反推還原。IC1 第 6 點的失敗指引只覆蓋 preflight 會攔下的錯誤，不覆蓋內容錯誤。
- **跳過分支的可到達性在兩個入口不對稱。** `cash-archive` 由 IC1 第 1 點的 `**Input**` 明示語法提供字面入口；`cash-commit` 的 archive-first 子流程沒有自己的 invocation，只能靠 agent 判讀 session 內的自然語言，可到達性因此較低。這是入口形態造成的差異，未提供緩解——需要明示旗標的使用者可改走 `cash-archive`。若 `cash-archive` 側也未落實 IC1 第 1 點，兩個入口都會退化成只能靠主觀判讀。
- **權衡：跳過同步變得較不顯眼。** 使用者必須主動說出來或附上旗標，而不是被問到。這是刻意的取捨：把成本從常見路徑移到例外路徑。

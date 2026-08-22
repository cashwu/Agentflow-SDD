## 1. Implementation

- [x] 1.0 依 IC6 調升 bundle version

  交付目標：`cash-skills.version`、`.cash-skills/lib/cash_cli/installer.py`、`.cash-skills/manifest.tsv`

  MUST 排在 1.1 之前執行。bundle version history contract 要求任何 `SKILL.md` 位元改變時 `cash-skills.version` 嚴格領先 HEAD，因此在第一個 `SKILL.md` 編輯之前先完成：把 `cash-skills.version` 由 `2.13.0` 改為 `2.14.0`；把 `.cash-skills/lib/cash_cli/installer.py` 的 `BUNDLE_VERSION` 常數同步為 `"2.14.0"`；在專案根執行 `PYTHONPATH=.cash-skills/lib python3 -s -P -B -m cash_cli.installer --self` 重建 `.cash-skills/manifest.tsv`。此後每次修改 `SKILL.md` 都 MUST 重跑該 `--self` 指令，使 manifest digest 與工作樹一致。

  判準（MUST 全部成立）：

  ```
  test (cat cash-skills.version | string trim) = '2.14.0'
  rg -Fq -- 'BUNDLE_VERSION = "2.14.0"' .cash-skills/lib/cash_cli/installer.py
  rg -q -- '^bundle_version\t2\.14\.0$' .cash-skills/manifest.tsv
  ```

  範圍界定：本任務只改版本值與由其衍生的 manifest 內容，MUST NOT 改動 `installer.py` 的其他部分。

- [x] 1.1 [P] 依 IC1 改寫 `.claude/skills/cash-archive/SKILL.md` 的 spec sync 步驟

  交付目標：`.claude/skills/cash-archive/SKILL.md`

  依 IC1 的九點逐項施作：`**Input**` 承認 `--skip-specs` 語法；步驟 4 以 IC1 第 2 點的逐字內容整段替換；移除散文提問與三個選項 bullet；改寫 Optional flags 的 `--skip-specs` 說明並消除 `(for tooling/doc-only changes)`；把 `adding the selected flags` 改為 `adding the resolved flags`；步驟 5 的失敗處置拆為兩段（delta parse 與 `requirement_identity_mismatch` 只能修正 delta specs 後重跑，`validation_failed` 另給 `--no-validate`），兩段都明寫 `--skip-specs` 不繞過；步驟 6 的 spec sync 摘要行改用三個判定結果的名稱；步驟 6 最後一項的 warning 外延補上 `skipped`；warnings 模板的 `**Specs:**` 行改為依判定結果填值的佔位形式，跳過警告行改為 `- Delta spec sync was skipped (explicitly requested by the user)` 並維持純輸出文字，其條件性由步驟 6 清單下方的 `**Template selection**` 段承載。步驟 5 的 bash 範例、`--mark-tasks-complete` 與 `--no-validate` 說明、另外三個 Output 模板與 Guardrails 區段不得改動。

  正向判準（實作前 exit 1，實作後 MUST exit 0）：

  ```
  rg -Fq -- '4. **Determine spec sync behavior**' .claude/skills/cash-archive/SKILL.md
  rg -Fq -- 'then resolve the flag without asking the user' .claude/skills/cash-archive/SKILL.md
  rg -Fq -- 'they do not exist when the directory is empty or absent' .claude/skills/cash-archive/SKILL.md
  rg -Fq -- '**Explicit skip**: pass `--skip-specs` only when the user asked to skip delta spec sync in this invocation' .claude/skills/cash-archive/SKILL.md
  rg -Fq -- '**Default — sync**: otherwise run archive without `--skip-specs`, whether or not delta specs exist, and do NOT ask the user to choose.' .claude/skills/cash-archive/SKILL.md
  rg -Fq -- 'MUST NOT infer a skip request from the change looking tooling-only or doc-only, from an earlier archive, or from any other indirect signal.' .claude/skills/cash-archive/SKILL.md
  rg -Fq -- 'Record the resolved outcome by evaluating in order: `skipped` (the flag is set), then `synced`' .claude/skills/cash-archive/SKILL.md
  rg -Fq -- 'to explicitly request skipping delta spec sync (see step 4)' .claude/skills/cash-archive/SKILL.md
  rg -Fq -- 'skip delta spec application; use only on the explicit request described in step 4' .claude/skills/cash-archive/SKILL.md
  rg -Fq -- 'adding the resolved flags' .claude/skills/cash-archive/SKILL.md
  rg -Fq -- 'requirement_identity_mismatch' .claude/skills/cash-archive/SKILL.md
  rg -Fq -- '`--skip-specs` does NOT bypass either check.' .claude/skills/cash-archive/SKILL.md
  rg -Fq -- 're-run with `--no-validate` once the findings are judged acceptable' .claude/skills/cash-archive/SKILL.md
  rg -Fq -- 'the `**Specs:**` line reports `✓ Synced to main specs`, `Sync skipped (explicitly requested by the user)`, or `No delta specs` respectively' .claude/skills/cash-archive/SKILL.md
  rg -Fq -- '**Specs:** <✓ Synced to main specs | Sync skipped (explicitly requested by the user) | No delta specs>' .claude/skills/cash-archive/SKILL.md
  rg -Fq -- '- Delta spec sync was skipped (explicitly requested by the user)' .claude/skills/cash-archive/SKILL.md
  rg -Fq -- '**Template selection**: use the **Output On Success With Warnings** template whenever there is at least one warning; an outcome of `skipped` is itself a warning. Include the skipped warning line only when the outcome is `skipped`.' .claude/skills/cash-archive/SKILL.md
  rg -q -- '^   \*\*Template selection\*\*: use the' .claude/skills/cash-archive/SKILL.md
  rg -Fq -- '- Note about any warnings (incomplete artifacts/tasks, or a `skipped` outcome)' .claude/skills/cash-archive/SKILL.md
  rg -Uq -- '- Note about any warnings \(incomplete artifacts/tasks, or a `skipped` outcome\)\n\n   \*\*Template selection\*\*: use the' .claude/skills/cash-archive/SKILL.md
  ```

  負向判準（實作前 exit 0，實作後 MUST exit 1）：

  ```
  rg -Fq -- 'Choose spec sync behavior' .claude/skills/cash-archive/SKILL.md
  rg -Fq -- 'If delta specs exist, ask whether to sync them.' .claude/skills/cash-archive/SKILL.md
  rg -Fq -- '**Sync**: archive without' .claude/skills/cash-archive/SKILL.md
  rg -Fq -- '**Do not sync**: pass' .claude/skills/cash-archive/SKILL.md
  rg -Fq -- '**Cancel**: stop without mutation' .claude/skills/cash-archive/SKILL.md
  rg -Fq -- '(for tooling/doc-only changes)' .claude/skills/cash-archive/SKILL.md
  rg -Fq -- 'adding the selected flags' .claude/skills/cash-archive/SKILL.md
  rg -Fq -- '**Specs:** Sync skipped (user chose to skip)' .claude/skills/cash-archive/SKILL.md
  rg -Fq -- '- Delta spec sync was skipped (user chose to skip)' .claude/skills/cash-archive/SKILL.md
  rg -Fq -- '- Spec sync status (synced / sync skipped / no delta specs)' .claude/skills/cash-archive/SKILL.md
  rg -Fq -- '- Note about any warnings (incomplete artifacts/tasks)' .claude/skills/cash-archive/SKILL.md
  ```

  段落級判準（實作後才具鑑別力；awk 起點在實作前不存在，故實作前為空範圍空真，MUST 於實作後重新確認）：

  ```
  awk '/^4\. \*\*Determine spec sync behavior\*\*/,/^5\. \*\*Perform the archive\*\*/' .claude/skills/cash-archive/SKILL.md | rg -Fq -- 'AskUserQuestion'    → MUST exit 1
  ```

  註：不得改用 `ask|prompt|confirm` 的正則作為此判準。IC1 第 2 點的逐字內容本身就以 `without asking the user`、`the user asked to skip`、`do NOT ask the user to choose` 三處禁止式措辭表述「不發問」，正則會把這些命中為違規。「不發問」的鑑別力由此處的 `AskUserQuestion` 段落檢查與上方對舊散文提問的負向判準共同提供。

  回歸守則（實作前後皆 MUST exit 1；兩個字串都不存在於 HEAD baseline，故非負向判準，其作用是防止 review round 中曾短暫出現的中間態措辭回歸）：

  ```
  rg -Fq -- '— include only when the outcome is `skipped`' .claude/skills/cash-archive/SKILL.md
  rg -Fq -- '- Include the skipped warning line' .claude/skills/cash-archive/SKILL.md
  ```

  保留守則（實作前後皆 MUST exit 0）：

  ```
  rg -Fq -- '"$cash_cli" archive <name> --skip-specs' .claude/skills/cash-archive/SKILL.md
  rg -Fq -- 'The Cash CLI owns touched import, sync state' .claude/skills/cash-archive/SKILL.md
  rg -Fq -- '`--mark-tasks-complete` — mark all incomplete tasks as complete before archiving' .claude/skills/cash-archive/SKILL.md
  rg -Fq -- '**Specs:** No delta specs' .claude/skills/cash-archive/SKILL.md
  rg -Fq -- '**Specs:** ✓ Synced to main specs' .claude/skills/cash-archive/SKILL.md
  ```

  註：`**Template selection**` 的三條正向判準 MUST 一併成立。單靠字面值判準只證明該段文字存在，把整段原樣改寫成 `- **Template selection**: …` 塞回步驟 6 的欄位清單內它仍然 exit 0；IC1 第 8 點把位置訂為規範的一部分，該位置義務由三條判準共同承擔：字面值判準證明該段文字存在；`^   \*\*Template selection\*\*: use the` 錨定行首與 3 空格內文縮排，行首無 `- ` 即證明它不在清單內；`rg -U` 的相鄰性判準釘住它緊接在清單最後一項之後，涵蓋 IC1 第 8 點「於清單下方」這一半——只有前兩條時，把該段移到 `Show archive completion summary including:` 與清單之間仍會全數通過。

  範圍界定：**AskUserQuestion** 在本檔另有兩處合法用途——步驟 1 的 change 選單與 Guardrails 的 fallback 句——兩者 MUST 保留，因此段落級判準只針對步驟 4。

- [x] 1.2 [P] 依 IC2 改寫 `.claude/skills/cash-commit/SKILL.md` 的 6a 段落與 6a-iii 納入條件

  交付目標：`.claude/skills/cash-commit/SKILL.md`

  依 IC2 的六點逐項施作：6a 開頭改為 `three steps`；6a-ii 以 IC2 第 2 點的逐字內容整段替換，並原樣沿用其 4 空格縮排；6a-iii 的 `openspec/specs/` 納入條件改為以判定結果 `synced` 為準；updated commit plan 標題行下方加入 `**Spec sync:**` 一行。6a-i、6a-iii 其餘內容、步驟 2a 的 spec sync 集合定義，以及 `### Spec Sync Changes (if sync was performed)` 這一行不得改動。

  正向判準（實作前 exit 1，實作後 MUST exit 0）：

  ```
  rg -Fq -- '**6a-ii. Delta spec sync determination**' .claude/skills/cash-commit/SKILL.md
  rg -q -- '^    \*\*6a-ii\. Delta spec sync determination\*\*$' .claude/skills/cash-commit/SKILL.md
  rg -Fq -- 'then resolve the flag without asking the user' .claude/skills/cash-commit/SKILL.md
  rg -Fq -- 'they do not exist when the directory is empty or absent' .claude/skills/cash-commit/SKILL.md
  rg -Fq -- '**Explicit skip**: set the `--skip-specs` flag only when the user asked to skip delta spec sync in this invocation' .claude/skills/cash-commit/SKILL.md
  rg -Fq -- '**Default — no flag**: otherwise do not add `--skip-specs`, whether or not delta specs exist, and do NOT ask the user to choose.' .claude/skills/cash-commit/SKILL.md
  rg -Fq -- 'MUST NOT infer a skip request from the change looking tooling-only or doc-only, from an earlier archive, or from any other indirect signal.' .claude/skills/cash-commit/SKILL.md
  rg -Fq -- 'Record the resolved outcome by evaluating in order: `skipped` (the flag is set), then `synced`' .claude/skills/cash-commit/SKILL.md
  rg -Fq -- 'only `synced` admits `openspec/specs/` paths into the commit set' .claude/skills/cash-commit/SKILL.md
  rg -Fq -- 'only when 6a-ii recorded the outcome `synced`' .claude/skills/cash-commit/SKILL.md
  rg -Fq -- '**Spec sync:** <synced | skipped (explicitly requested) | no delta specs>' .claude/skills/cash-commit/SKILL.md
  rg -Fq -- 'This sub-flow executes three steps in sequence' .claude/skills/cash-commit/SKILL.md
  ```

  負向判準（實作前 exit 0，實作後 MUST exit 1）：

  ```
  rg -Fq -- '**6a-ii. Delta spec sync check**' .claude/skills/cash-commit/SKILL.md
  rg -Fq -- 'Delta specs found. Sync to main specs before archiving?' .claude/skills/cash-commit/SKILL.md
  rg -Fq -- 'only if the user explicitly selected spec sync in 6a-ii' .claude/skills/cash-commit/SKILL.md
  rg -Fq -- 'This sub-flow executes three checks in sequence' .claude/skills/cash-commit/SKILL.md
  ```

  段落級判準（實作前 exit 0，實作後 MUST exit 1）：

  ```
  awk '/^    \*\*6a-ii\./,/^    \*\*6a-iii\./' .claude/skills/cash-commit/SKILL.md | rg -Fq -- 'AskUserQuestion'
  ```

  註：此判準的 awk 起點要求 4 個前導空格，若 6a-ii 被拉齊到 column 0，範圍會為空而 exit 1，判準即淪為空真。上方正向判準中的 `^    \*\*6a-ii\. Delta spec sync determination\*\*$` 正是為此把縮排本身釘住，兩條 MUST 一併成立才算通過。

  保留守則（實作前後皆 MUST exit 0）：

  ```
  rg -Fq -- '### Spec Sync Changes (if sync was performed)' .claude/skills/cash-commit/SKILL.md
  rg -Fq -- '**6a-i. Incomplete task handling**' .claude/skills/cash-commit/SKILL.md
  rg -Fq -- 'Spec sync set: only when the manifest records' .claude/skills/cash-commit/SKILL.md
  ```

- [x] 1.3 依 IC3 重新生成 `.agents` 變體

  交付目標：`.agents/skills/cash-archive/SKILL.md`、`.agents/skills/cash-commit/SKILL.md`

  相依 1.0、1.1 與 1.2，不可與其並行。在專案根執行生成器產生兩份輸出，MUST NOT 手工編輯生成結果：

  ```
  ./scripts/cash-skills/generate.fish
  ```

  判準：1.1 與 1.2 的每條字面值判準，在對應的 `.agents` 檔案上把 `/cash-` 正規化為 `$cash-` 後同樣成立；且本任務造成的 `git status --porcelain` 變動只有 `.agents/skills/cash-archive/SKILL.md` 與 `.agents/skills/cash-commit/SKILL.md` 兩個路徑。

## 2. Verification

- [x] 2.1 執行 skill 套件檢查

  相依 1.3。該套件需要 `fish` 與 `rg`（ripgrep）。若環境缺少 `rg`，MUST 先安裝再執行，MUST NOT 以「環境不可執行」略過本任務。在專案根執行，MUST 通過（exit code 0）：

  ```
  ./scripts/cash-skills/tests/skill-checks.fish
  ```

  該套件會重新執行生成並與 committed 的 `.agents` 輸出比對，因此同時驗證 1.3 沒有手工編輯痕跡；它對 spec sync 的既有斷言是 consumer matrix 中的字面值 `"$cash_cli" archive <name> --skip-specs`，由 1.1 的保留守則覆蓋。

- [x] 2.2 執行 change 驗證

  相依 1.3。在專案根執行，MUST 通過（exit code 0）：

  ```
  ./.cash-skills/bin/cash validate default-spec-sync-on-archive
  ```

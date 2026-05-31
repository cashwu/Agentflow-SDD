# 05-usage-r1 — 獨立審查

- **角色**：Agentflow SDD step 5（Usage）獨立審查者（R1）
- **變更**：auto-restore-commit-guard-source
- **審查目標**：`agentflow/changes/auto-restore-commit-guard-source/agentflow/05-usage.md`

## 審查輸入

- `agentflow/.../agentflow/05-usage.md`（審查標的）
- `agentflow/.../design.md`
- `agentflow/.../spec.md`
- 真實程式碼（輸出慣例驗證）：
  - `install-spectra-plus.fish`：`fail()`（:40-43）、`assert_contains` fail 字串（:65）、dry-run `+ …` echo 慣例（:104,119,290,…）、`ensure_commit_guard`/`validate_commit_guard`（:75-110）、`write_launch_agent_plist`（:499-534，`StandardOutPath`/`StandardErrorPath` 皆導向 `launch_agent_log`）
  - `scripts/spectra-plus/repair-all.fish`（log_path = `~/Library/Logs/spectra-plus-repair.log`）
  - per-target summary：`[success]/[skipped]/[failed]`（install-spectra-plus.fish :420-470）

## Rubric Checklist 與發現

### 1. 精確字串與既有 `+ …` dry-run 慣例一致性

- `restored <relpath> from HEAD`（stdout）：新字串，無既有衝突，風格與既有純文字 echo 行一致。**通過**。
- `+ would restore <relpath> from HEAD`：與既有 `+ verify spectra-commit guard in …`、`+ update spectra-commit guard in …`（:104,119）的 `echo "+ …"` 慣例一致。注意既有這些 dry-run 訊息採**直接 `echo "+ …"`**（非 `run_cmd` 的 `string escape` 路徑），usage 文件描述「採既有 `+ …` 慣例」與此相符。**通過**。
- **[medium] HEAD-也壞 的 fail 字串不精確**：05-usage.md :15 寫 `錯誤：<desc> 缺少內容：<marker>`，design.md :56 寫 `… source 缺少內容：…`。但真實程式碼 `assert_contains`（install-spectra-plus.fish :65）輸出為 `錯誤：$description 缺少必要內容：$text` —— 實際字串為 **`缺少必要內容`**，usage 與 design 皆漏掉 `必要` 二字。鑑於本步驟自我宣稱「精確字串於本 usage 文件與 design.md 固化」，此處與真實 CLI 慣例不一致。

### 2. stdout 路由宣稱正確性

- usage :21 宣稱：restore 行走 stdout → 因 plist 將 stdout/stderr 都導向 log → 會寫入 `~/Library/Logs/spectra-plus-repair.log`。
- 核對 `write_launch_agent_plist`（:528-531）：`StandardOutPath` 與 `StandardErrorPath` **皆**設為 `(launch_agent_log)` = `~/Library/Logs/spectra-plus-repair.log`。`repair-all.fish` 為 plist 的 `ProgramArguments` entrypoint。
- 因此 restore 行（stdout）確實會進入該 log。**宣稱正確，通過**。

### 3. 失敗模式對應 spec scenario / 不改 spec.md 的理由

- usage 失敗模式 1（HEAD 也壞）→ spec scenario「HEAD source is also invalid」。**對應**。
- usage 失敗模式 2（非 git/未追蹤/空 repo 無 HEAD）→ spec scenario「Source is not in a git work tree」（spec 括號明列 no git/untracked/no HEAD）。**對應**。
- usage 失敗模式 3（dry-run 不 mutate）→ spec scenario「Dry-run reports restore without mutating」。**對應**。
- 自癒成功 → 「Self-heal stripped source from valid HEAD」；單檔限制 → 「Restore is limited to the single source file」。五情境全覆蓋。**對應完整，無遺漏**。
- 不改 spec.md 的決定：spec scenario 以行為層級（不綁精確字串）描述，精確字串於 usage/design 固化並由測試斷言 —— 此分工合理、避免脆弱斷言，**理由成立**。惟見發現 1：既然 usage/design 自任「固化精確字串」之責，字串就必須與真實程式碼一致，否則固化失去意義。

### 4. 矛盾 / 遺漏

- stdout-vs-stderr 正確性：restore/would-restore 走 stdout、fail-loud 走 stderr（`fail()` :41 `>&2`），usage :21/:23 描述正確。**無矛盾**。
- 與既有輸出整合（usage :27-28）：restore 行出現在 `正在套用 spectra-commit guard...` 之後、`[success]` 之前，符合 `ensure_commit_guard` 在 install 子流程內、per-target summary（:468）之前的執行順序。**一致**。
- design 呼叫點（restore 在 `validate_commit_guard "$source_path"` :99 之前）與 usage 因果順序描述一致。**無矛盾**。
- 無 scope creep：usage 僅描述 source 還原與既有輸出，未觸及 target patch、index、非 HEAD 來源（與 spec/design Out-of-scope 一致）。**通過**。

## 發現（含嚴重度）

- **[medium] F1**：HEAD-也壞 fail 字串不精確 —— usage :15 與 design :56 寫 `缺少內容`，真實程式碼為 `缺少必要內容`（install-spectra-plus.fish :65）。違反「精確字串固化」與 rubric「exact message strings consistency」。非 critical：行為/exit code 正確，且 design 標示為「既有」字串、實作不會新造此字串（沿用既有 `assert_contains`），故不致誤導實作；但作為 usage 契約文件的精確性瑕疵應修。
- **[low] F2**：usage :15 用佔位符 `<desc>` / `<marker>`，未點明 `<marker>` 實為 `<!-- SPECTRA-COMMIT-GUARD: archive-first allowlist + plus deletion protection -->`（design :56 用 `...` 省略亦不完整）。屬可選的精度提升，不阻擋。

## 必要修正（fixes required）

- 修正 05-usage.md :15 的 fail 字串為真實字串：`錯誤：<desc> 缺少必要內容：<marker>`（補回 `必要`）。
- 同步修正 design.md :56 範例為 `… source 缺少必要內容：…` 以保持兩文件一致（usage 自稱與 design 共同固化精確字串）。

## Blockers / Critical Gaps

- 無 critical gap。F1 為 medium 文件精確性瑕疵，可於不重跑下游的情況下快速修。

## 決定

- **fix-and-rerun**（quality_score 未 > 9 且存在 medium 精確字串不一致）。修正 F1 後 re-rate 即可通過。

## quality_score

- **8 / 10**

## Next Action

- 套用 F1 修正（usage + design 字串補 `必要`），由新的獨立 sub-agent 進行 R2 re-rate。

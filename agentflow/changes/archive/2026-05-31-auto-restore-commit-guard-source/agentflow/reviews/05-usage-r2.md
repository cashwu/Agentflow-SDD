# 05-usage-r2 — 獨立審查（Round 2）

- **角色**：Agentflow SDD step 5（Usage）獨立審查者（R2，全新獨立 sub-agent）
- **變更**：auto-restore-commit-guard-source
- **審查目標**：`agentflow/changes/auto-restore-commit-guard-source/agentflow/05-usage.md`
- **同步檢查**：`agentflow/changes/auto-restore-commit-guard-source/design.md`（精確字串同步）
- **前次審查**：`reviews/05-usage-r1.md`（8/10，要求修正 `缺少內容` → `缺少必要內容`）

## 審查輸入

- `agentflow/.../agentflow/05-usage.md`（審查標的）
- `agentflow/.../design.md`（字串同步）
- `reviews/05-usage-r1.md`（前次發現）
- 真實程式碼（ground truth 與輸出慣例驗證）：
  - `install-spectra-plus.fish`：`fail()`（:40-43，`>&2`）、`assert_contains` fail 字串（:65 `fail "$description 缺少必要內容：$text"`）、`validate_commit_guard` marker（:76）、dry-run `+ …` echo 慣例（:104,:119）、per-target summary `[success]/[skipped]/[failed]`（:457,:463,:468,:470）、`write_launch_agent_plist` stdout/stderr 皆導向 `launch_agent_log`（:487-489,:528-531）

## R1 修正驗證（focus）

- **F1（medium）— 已修正且正確**：
  - 05-usage.md :15 現為 `錯誤：<desc> 缺少必要內容：<marker>`，含 `必要`。**通過**。
  - design.md :56 現為 `… (Claude) source 缺少必要內容：<!-- SPECTRA-COMMIT-GUARD: archive-first allowlist + plus deletion protection -->`，含 `必要`。**通過**。
  - 對照真實程式碼 install-spectra-plus.fish :65 `fail "$description 缺少必要內容：$text"`，加上 `fail()` :41 前綴 `錯誤：` → 實際輸出為 `錯誤：<description> 缺少必要內容：<text>`。兩文件字串與真實 CLI 完全一致。**精確字串修正確認無誤。**
- **F2（low）**：design.md :56 已將 `<marker>` 展開為完整 marker（與 :76 一字不差），usage 仍用佔位符 `<marker>` —— 屬合理分工（usage 表格保持精簡、design 提供完整範例），不阻擋。

## Rubric Checklist 與發現

### 1. usage/API 契約清晰度

- CLI 契約表（:10-16）以「情境 / 觸發 / stdout / 變更 / exit」五欄完整覆蓋五情境，欄位語意清楚。**通過**。

### 2. 精確字串保真度（exact-string fidelity）

- `restored <relpath> from HEAD`（stdout，:13）：新字串，無既有衝突。**通過**。
- `+ would restore <relpath> from HEAD`（:14）：與既有 `+ verify spectra-commit guard in …`（:104）、`+ update spectra-commit guard in …`（:119）的 `echo "+ …"` 直接 echo 慣例一致。**通過**。
- HEAD-也壞 fail 字串（:15）：`缺少必要內容`，與 :65 一致。**通過**（R1 F1 已修）。
- marker（design :56）：`<!-- SPECTRA-COMMIT-GUARD: archive-first allowlist + plus deletion protection -->` 與 :76 一字不差。**通過**。
- per-target summary（usage :28）`[success]/[skipped]/[failed]`：與 :457/:463/:468/:470 一致。**通過**。
- 未發現其他精確字串宣稱錯誤。

### 3. stdout/stderr 正確性

- restore / would-restore 走 stdout（:21）；fail-loud 走 stderr（`fail()` :41 `>&2`，usage :23）。**正確**。
- usage :21 宣稱 restore 行因 plist 將 stdout/stderr 皆導向 log → 寫入 `~/Library/Logs/spectra-plus-repair.log`。核對 :528-531 `StandardOutPath`/`StandardErrorPath` 皆 `(launch_agent_log)`，:488 = `$HOME/Library/Logs/spectra-plus-repair.log`。**宣稱正確**。

### 4. 失敗模式 → scenario 對應

- 失敗模式 1（HEAD 也壞）→ spec scenario「HEAD source is also invalid」→ fail-loud（exit 非 0）。**對應**。
- 失敗模式 2（非 git / 未追蹤 / 空 repo 無 HEAD）→ scenario「Source is not in a git work tree」。**對應**。
- 失敗模式 3（dry-run 不 mutate）→ scenario「Dry-run reports restore without mutating」。**對應**。
- 自癒成功、單檔限制兩情境亦覆蓋（CLI 表 :13、驗收 :38）。五情境完整、無遺漏。**對應完整**。

### 5. 一致性 / 無新增 gap

- 與既有輸出整合（:27-28）：restore 行於 `正在套用 spectra-commit guard...` 之後、`[success]` 之前，符合 `ensure_commit_guard` 在 install 子流程內、per-target summary 之前的執行順序。**一致**。
- design 呼叫點（restore 於 `validate_commit_guard "$source"` 之前）與 usage 因果順序一致。**無矛盾**。
- 無 scope creep：usage 僅描述 source 還原與既有輸出，未觸及 target patch / index / 非 HEAD 來源（與 spec/design Out-of-scope 一致）。**通過**。
- 兩文件字串同步：唯一 ground-truth 字串（fail 訊息）已在 usage 與 design 同步為正確值。**無漂移**。
- 未引入新 gap。

## 發現（含嚴重度）

- **無 medium 以上發現。** R1 F1 已正確修正並通過獨立驗證。
- **[low] 殘留 F2（不阻擋）**：usage :15 沿用 `<marker>` 佔位符；可選地點明完整 marker，但 design :56 已提供完整範例，分工合理，不影響契約精確性。

## 必要修正（fixes required）

- 無。

## Blockers / Critical Gaps

- 無。

## 決定

- **pass**（quality_score > 9 且無 critical gap；R1 唯一 medium 已修正，所有精確字串、stdout/stderr 路由、失敗模式對應皆獨立核對通過）。

## quality_score

- **10 / 10**

## Next Action

- 進入 step 6（Ticket）`/sdd-ticket`。usage 契約已穩定，無待修項。

# 04 — Spec Review R1：auto-restore-commit-guard-source

## 目標（Target）

獨立審查 step 4（Spec）產出，驗證 spec.md 的 requirement/scenario 是否可測、是否忠於上游（explore/prototype）、與 proposal/design 是否一致，以及 spec delta 是否符合 master spec 的 requirement+scenario 格式。

## 已審查輸入（Inputs reviewed）

- `agentflow/changes/auto-restore-commit-guard-source/proposal.md`
- `agentflow/changes/auto-restore-commit-guard-source/design.md`
- `agentflow/changes/auto-restore-commit-guard-source/spec.md`
- `agentflow/changes/auto-restore-commit-guard-source/agentflow/04-spec.md`
- 上游：`agentflow/.../02-explore.md`、`03-prototype.md`
- master spec：`openspec/specs/spectra-plus-skills/spec.md`（格式與既有 commit-guard requirement）
- 真實程式：`install-spectra-plus.fish`（`validate_commit_guard` :75-86、`ensure_commit_guard` :88-129，含 :99 source 驗證）
- 測試檔：`scripts/spectra-plus/tests/installer-commit-guard-checks.fish`（確認存在）

## Rubric Checklist 與發現

### 1. Spec 可測性（scenario 客觀可驗）— PASS

- 5 個 scenario 皆以 GIVEN/WHEN/THEN 描述可觀測狀態：還原動作、log 訊息、退出碼（zero/non-zero）、檔案內容含 guard、未相關 dirty 檔不變、無 git mutation/lock/cache/throttle 寫入。皆為測試 fixture 可斷言之項。
- 「Self-heal」scenario 的 THEN 含「logs a message naming the restored file and that it was restored from HEAD」「the restored source file again contains a valid guard」「run reports success」——三項皆客觀可驗。
- 「Dry-run」scenario 明確斷言「source file is not modified」「no git mutation, lock, cache, or throttle state is written」——對應 explore R6/R11，可由「執行前後檔案 hash + lock/cache 檔不存在/不變」驗證。
- 「Single source file」scenario 設置旁置 unrelated dirty 檔並斷言其不變——對應 R2/R14，可測。

### 2. 前置條件集合一致性 — PASS（有一處措辭可加強）

spec requirement 列出的 MUST 條件：
- working-tree source fails `validate_commit_guard`（= R1）
- source resides inside a git work tree（= R3）
- HEAD version passes full `validate_commit_guard`（= R4）
- respect `--dry-run`（= R6）
- single file path / no unscoped restore / no index modification（= R2/R12/R14）

與 design.md「Implementation Contract」之四連檢（1 已壞 / 2 in-git / 3 HEAD blob 通過完整驗證 / 4 非 dry-run）逐項對應一致；與 explore R1/R3/R4/R6/R12/R13/R14 對應一致。R13（toplevel-relative relpath）屬實作層推導，spec 以「HEAD version of that exact file」「single source file path」抽象涵蓋，未顯式提 toplevel——可接受（spec 不應綁定實作細節，design 已承載 relpath 推導）。

### 3. 矛盾／缺漏 failure mode／不可測 scenario／scope creep — PASS

- 無矛盾：spec 之 fail-loud 回退（non-zero）與 design「無法自癒」usage contract、explore 根因描述一致。
- failure mode 覆蓋：HEAD 也壞（R4）、非 git/未追蹤/無 HEAD（R3）皆有獨立 scenario。
- 無 scope creep：spec 未提 index 還原、非 HEAD 來源、target patch 行為——與 proposal non-goals、design Out-of-scope、explore R12/R14 一致。
- 無發明需求：requirement 全部可追溯至 explore 風險或 proposal 驗收範例，未引入未授權需求。

### 4. @trace block 準確性 — PASS

- `code: install-spectra-plus.fish` — 正確；變更檔即此（新增 `restore_source_guard_if_needed`，於 `ensure_commit_guard` :99 前呼叫）。
- `tests: scripts/spectra-plus/tests/installer-commit-guard-checks.fish` — 檔案確實存在，且為既有 commit-guard 安裝測試的自然歸屬；master spec 既有兩條 commit-guard requirement 亦以同檔為 trace test。準確。
- `source/updated` 欄位格式與 master spec 既有 @trace 一致。

### 5. Master spec 格式一致性 — PASS

- 標題 `### Requirement: <名>`、`#### Scenario: <名>`、bold `**GIVEN/WHEN/THEN/AND**` 條列、結尾 `<!-- @trace ... -->`——與 master spec（如 :537「plus installer updates spectra-commit guard」、:580 @trace）格式完全一致。
- requirement 句首採 `The system SHALL ...`、內文用 MUST/MUST NOT，符合 master spec 慣例。

### 6. Proposal 5 驗收範例 ↔ spec scenario 對應 — PASS（1:1）

| Proposal 驗收範例 | spec.md scenario |
|---|---|
| 1 自癒 | Self-heal stripped source from valid HEAD |
| 2 HEAD 也壞 | HEAD source is also invalid |
| 3 dry-run | Dry-run reports restore without mutating |
| 4 非 git | Source is not in a git work tree |
| 5 單檔限制 | Restore is limited to the single source file |

五項全數有對應可測 scenario。

## Findings（含嚴重度）

- **[low] R1 自癒 scenario 之 GIVEN 與 master spec 既有風格的混用**：本 delta 採 GIVEN/WHEN/THEN，master spec 既有 scenario 多為 WHEN/THEN（無 GIVEN）。本 delta 用 GIVEN 更精確，且 task 要求 GIVEN/WHEN/THEN 保英文，無格式違規；屬風格差異，非缺陷。
- **[low] R13 toplevel-relative relpath 未在 spec 顯式出現**：spec 以「that exact file」「single source file path」抽象表達，未提 toplevel/relpath 推導。屬正確抽象（避免實作耦合），design 已承載；不需在 spec 補充，僅記錄。
- **[low] dry-run scenario 缺少 `--target` 路徑入口的對稱描述**：Self-heal scenario 寫「via `--target` or `--repair-all`」，dry-run scenario 僅寫「runs the installer with `--dry-run`」。語意無歧義（dry-run 即 `--target ... --dry-run` 或 `--repair-all --dry-run`），可測性不受影響；屬 usage 階段可細化的訊息精度（04-spec.md 已列為待 usage 細化項）。
- **[info] design 引用 :99 而真實程式為 `validate_commit_guard "$source_path"`**（非 `"$source"`）：design「避免行號耦合」段已聲明以語句為錨點、:99 僅概念說明；無實質偏差。

## 需修正項（Fixes required）

無阻擋性修正。以下為可選的非阻擋性微調（不影響 PASS）：

- （optional）dry-run scenario 的 WHEN 可補一句註明涵蓋 `--target` 與 `--repair-all` 兩入口，與 Self-heal scenario 對稱——但此屬 usage 階段已規劃細化範圍，spec 層可不動。

## 阻擋／重大缺口（Blockers / critical gaps）

無。

## 決策（Decision）

**pass**

- quality_score：**9.4 / 10**
- 無 critical gap；spec 可測、忠於上游、格式與 master spec 一致、@trace 準確、proposal 5 驗收範例 1:1 對應、前置條件集合與 design/explore 完全一致。
- 扣分集中於數個 low/info 級風格與訊息精度項，均非阻擋且已被 04-spec.md 標為「待 usage 細化」。

## 下一步（Next action）

進入 step 5（Usage / `/sdd-usage`），固化 log / dry-run 精確訊息字串、stderr/stdout 去向，及 `--target` / `--repair-all` 輸出整合呈現（04-spec.md「待 usage 階段細化」項）。

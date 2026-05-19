## Context

目前 `install-spectra-plus.fish` 只負責產生並驗證 `spectra-propose-plus` 與 `spectra-apply-plus`。但使用 plus workflow 後，使用者仍會呼叫既有 `$spectra-commit` 來 archive-first commit。現有 `spectra-commit` 的 archive sub-flow 在 archive 後重新讀整個 `git status --porcelain`，規則沒有要求比對 archive 前後差異，也沒有保護 generated plus skill deletion。因此 workspace 內既有的 `.agents/skills/spectra-*-plus/` 或 `.claude/skills/spectra-*-plus/` deletion 可能被誤納入 commit set。

這個變更要修的是既有 commit 路徑，不是要求使用者記得改叫另一支 skill。

## Goals / Non-Goals

**Goals:**

- 讓既有 `spectra-commit` archive-first 流程只收集明確屬於該 change 的 archive 變更。
- 讓 plus generated skills 的 deletion 預設受保護，不會因 unrelated dirty state 被一起 stage。
- 讓 `install-spectra-plus.fish` 在安裝 plus skills 時同步安裝或驗證 `spectra-commit` guard。
- 保持實作簡單：明確文字規則與安裝檢查即可，不引入新的大型 generator 或 dependency。

**Non-Goals:**

- 不新增 `spectra-commit-plus` 作為主要入口。
- 不改變 `spectra archive` CLI 的實際 archive 行為。
- 不改變 `git add` 逐檔 stage 的既有 guardrail。
- 不處理所有 unrelated dirty file；本變更聚焦 archive-first collection 與 plus skill deletion 保護。

## Decisions

### 修改既有 `spectra-commit` 而不是新增 `spectra-commit-plus`

新增 `spectra-commit-plus` 只有在使用者每次都明確呼叫它時才有效；一旦使用者或 AI 繼續呼叫 `$spectra-commit`，原本的誤納入 deletion 風險仍然存在。這次問題發生在 commit 的預設工作流，所以主修正必須落在既有 `spectra-commit` skill。

替代方案是像 `spectra-propose-plus` 一樣產生 `spectra-commit-plus`。這可以作為未來延伸，但它會增加入口分歧，且無法保護原始 commit 路徑，因此不作為本變更的主要解法。

### archive-first collection 必須以允許清單為準

archive 前後的 `git status --porcelain` 只能用來觀察 workspace，不應把 archive 後的全量 dirty state 直接視為 archive 產物。`spectra-commit` 必須只把下列路徑加入 archive-related commit set：

- `openspec/changes/<change>/` 底下該 change 被 archive 後產生的 deletion。
- `openspec/changes/archive/<date>-<change>/` 底下該 change 被 archive 後產生的 addition 或 modification。
- 使用者在 delta spec sync check 明確選擇 sync 時，`openspec/specs/` 底下由 sync 造成的變更。

tracked source files 仍來自 archive 前已確認的 tracking file commit set；archive-first 流程只額外加入 allowlist 內的 archive 與 spec sync 變更，不能用 post-archive status 重新吸入 source dirty state。

其他 dirty files 必須繼續列在 Unrelated Changes，而不是被加入 commit set。

### plus generated skill deletion 預設受保護

`.agents/skills/spectra-*-plus/` 與 `.claude/skills/spectra-*-plus/` 是 generated plus skill output。`spectra-commit` 必須把這些路徑的 deletion 標為 protected deletion，預設排除於 commit set，即使使用者選了 archive-first。只有在 Customize 流程中，使用者明確指定要加入這些 deletion，才允許 stage。

### `install-spectra-plus.fish` 負責安裝與驗證 commit guard

plus installer 已經是使用者導入 plus workflow 的入口，因此它必須確保目標專案的 `.agents/skills/spectra-commit/SKILL.md` 與 `.claude/skills/spectra-commit/SKILL.md` 包含 archive-first guard 與 protected deletion guard。實作可以採用小型 marker 檢查與 deterministic patch：

- 若目標缺少必要的 `spectra-commit` skill，沿用現有 `require_file` 風格失敗並顯示明確錯誤。
- 若目標存在但未含 guard marker，安裝腳本套用固定文字區塊或替換指定 section。
- 安裝後驗證兩個 target skill 都含 guard marker 與 plus skill deletion patterns。

## Implementation Contract

**Observable behavior:**

- 使用者執行 plus installer 後，目標專案的 Codex 與 Claude `spectra-commit` skill 都具備 archive-first allowlist 與 plus generated skill deletion guard。
- 使用者呼叫 `$spectra-commit <change>` 並選擇 archive-first 時，commit plan 不得把 `.agents/skills/spectra-*-plus/SKILL.md` 或 `.claude/skills/spectra-*-plus/SKILL.md` deletion 放進預設 commit set。
- 這些 protected deletion 必須出現在 Unrelated Changes 或等效的 protected/excluded section，讓使用者看得到但不會被默默 stage。
- 若使用者真的要提交 plus skill deletion，只能透過 Customize 明確加入。
- archive location 必須統一使用 `openspec/changes/archive/<date>-<change>/`，不能保留舊的 `openspec/archived/` 文案。

**Interface / data shape:**

- `install-spectra-plus.fish` 仍維持既有 CLI：`./install-spectra-plus.fish --target <專案目錄> [--dry-run]` 與 `./install-spectra-plus.fish <專案目錄> [--dry-run]`。
- `install-spectra-plus.fish --dry-run` 必須印出將檢查或更新 `spectra-commit` guard 的動作，不實際寫檔。
- `spectra-commit` skill 仍使用原有輸入格式，不新增必要參數。

**Failure modes:**

- 目標專案缺少 `.agents/skills/spectra-commit/SKILL.md` 或 `.claude/skills/spectra-commit/SKILL.md` 時，installer 必須失敗並指出缺少哪個檔案。
- installer 無法找到預期 section 進行 patch 時，必須失敗並提示檢查 target skill 形狀，不能安靜略過。
- installer 重跑必須保持 idempotent，不能重複插入相同 guard block。
- `spectra-commit` 在 archive-first 後看見 protected plus deletion 時，必須排除該 deletion 並在 commit plan 顯示它未被納入。

**Acceptance criteria:**

- 執行 `./install-spectra-plus.fish --target <repo> --dry-run` 會列出 plus skill generation 與 `spectra-commit` guard 檢查/更新。
- 對測試 target 執行 installer 後，`rg` 能在 `.agents/skills/spectra-commit/SKILL.md` 與 `.claude/skills/spectra-commit/SKILL.md` 找到 guard marker 與 `.agents/skills/spectra-*-plus/`、`.claude/skills/spectra-*-plus/` patterns。
- 針對 `spectra-commit` skill 的內容檢查能確認 archive-first collection 使用 allowlist，且 protected plus deletion 只能透過 Customize 明確加入。
- `spectra validate harden-spectra-commit-plus-skills` 必須通過。

**Scope boundaries:**

- In scope: `install-spectra-plus.fish`、Codex/Claude `spectra-commit` skill 文字規則、相關 spec 與測試。
- Out of scope: 新增 `spectra-commit-plus`、改寫 `spectra archive` CLI、引入新 dependency、改變一般非 archive commit flow 的 staging model。

## Risks / Trade-offs

- [Risk] 目標專案的 `spectra-commit` skill 形狀與本 repo 不同，installer patch 失敗。→ Mitigation：使用明確 section/marker 驗證，失敗時中止並要求更新基礎 Spectra skills。
- [Risk] allowlist 過窄，漏掉合法的 spec sync 變更。→ Mitigation：只在使用者明確選擇 sync 時納入 `openspec/specs/`，並在 commit plan 分區顯示 Spec Sync Changes。
- [Risk] 使用者確實想刪 plus skills。→ Mitigation：保留 Customize 明確加入路徑，不做永久禁止。
- [Risk] installer 同時修改 generated plus skills 與 base commit skill，責任變多。→ Mitigation：只新增 commit guard 的 deterministic patch 與驗證，不把整個 `spectra-commit` 納入 plus generator。

# Design：auto-restore-commit-guard-source

## Explore Findings（驅動設計的重大風險）

| 風險 | 設計回應 |
|------|----------|
| R1 誤蓋使用者合法編輯 | invariant：僅當 working-tree source 已 `validate_commit_guard` **失敗**時才考慮還原；guard 完好者永不觸碰。 |
| R2 還原範圍過大 | 僅以單一檔案 pathspec 還原；禁止無 pathspec 的 `git restore`。 |
| R3 非 git / git 不可用 / 未追蹤 | 任一前置不成立 → 不還原 → 回退既有 fail-loud。 |
| R4 HEAD 版本也壞 | 取 HEAD blob 後對其跑完整 `validate_commit_guard`；不通過 → 不還原 → fail-loud。 |
| R6 dry-run | dry-run 僅印「would restore」，不呼叫任何 git mutation。 |
| R12 index vs working tree | 採 working-tree 還原語意即可（repair 讀 working-tree 檔）；index 非目標。 |
| R13 toplevel-relative relpath | 以 `git -C <dir> rev-parse --show-toplevel` 取 toplevel，source 相對 toplevel 之路徑同時用於 `show` 與 restore。 |
| R14 範圍 | 僅還原 source；target patch fail-loud 不變。 |

## Prototype Findings

spike 已**刻意跳過**（見 03-prototype.md）。git `show`/`restore` 確定性高，手動 `git restore` 已驗證端到端可行；風險低到不需拋棄式實驗。

## Working Backwards — Usage Contract（未來使用者可見行為）

### 一般情境（來源完好）

```
$ ./install-spectra-plus.fish --repair-all --force
[success] /path/to/project: repaired
```

行為與今日相同——還原邏輯不介入完好來源。

### 自癒情境（來源 guard 被剝、HEAD 完好）

```
$ ./install-spectra-plus.fish --repair-all --force
restored .claude/skills/spectra-commit/SKILL.md from HEAD
restored .agents/skills/spectra-commit/SKILL.md from HEAD
[success] /path/to/project: repaired
```

repair log（LaunchAgent 路徑）亦含上述 `restored … from HEAD` 行。

### dry-run

```
$ ./install-spectra-plus.fish --target /path --dry-run
+ would restore .claude/skills/spectra-commit/SKILL.md from HEAD
...
```

不修改任何檔案、lock、cache。

### 無法自癒（HEAD 也壞 / 非 git）

```
$ ./install-spectra-plus.fish --repair-all --force
錯誤：spectra-commit guard (Claude) source 缺少必要內容：<!-- SPECTRA-COMMIT-GUARD: archive-first allowlist + plus deletion protection -->
[failed] /path/to/project: repair failed
```

與今日一致的 fail-loud；exit code 非零。

## Implementation Contract

### 區域：`restore_source_guard_if_needed`（新函式，install-spectra-plus.fish）

- **可觀測行為**：給定來源 commit skill 路徑與 description，當且僅當下列**全部成立**時，從 git HEAD 還原該單一檔案並印出 `restored <relpath> from HEAD`：
  1. working-tree source 未通過 `validate_commit_guard`（已壞）；
  2. source 所在目錄屬於某 git 工作樹（`git -C <dir> rev-parse --show-toplevel` 成功）；
  3. `git -C <toplevel> show HEAD:<relpath>` 取得內容，且該內容寫入暫存檔後**通過完整 `validate_commit_guard`**；
  4. 非 dry-run。
- **dry-run**：上列 1–3 成立但 `dry_run==1` 時，印 `+ would restore <relpath> from HEAD` 並返回，不呼叫 git mutation。
- **資料型態**：輸入兩個字串參數（source 絕對路徑、description）；無回傳值（以 side-effect 還原 + log）。relpath 為 source 相對 toplevel 的路徑。
- **失敗模式**：任一前置（1–3）不成立 → 函式直接返回、不 mutate、不報錯；交由後續既有 `validate_commit_guard "$source"` 決定 fail-loud。函式本身**不**改變既有退出碼語意。
- **呼叫點**：`ensure_commit_guard` 內、`validate_commit_guard "$source_path"`（:99）**之前**呼叫，傳入同一 source 路徑與 `$description source`。涵蓋 Claude 與 Codex 兩份來源（各經 `ensure_commit_guard` 一次）。
- **驗收準則**：proposal 五個驗收範例全數成立。
- **驗證目標**：`scripts/spectra-plus/tests/` 新增 git fixture 測試（見下）。
- **Out of scope**：index 還原、非 HEAD 來源還原、target patch 行為變更。

### 區域：`git show HEAD:<relpath>` 的 relpath 推導

- **可觀測行為**：以 `git -C (dirname source) rev-parse --show-toplevel` 取得 toplevel；relpath = source 去除 toplevel 前綴後的相對路徑（必要時先 realpath 解析 symlink 以消歧義，見 explore r2 F5）。`show` 與 restore 共用同一 relpath。
- **失敗模式**：`rev-parse` 或 `show` 非零退出 → 視為前置不成立 → 不還原。

## 測試策略（git fixture）

- 在臨時目錄建立 git repo，commit 一份**含合法 guard** 的 `spectra-commit/SKILL.md`（Claude + Codex），再於 working tree 覆寫為**剝除 guard** 版本。
- 案例：自癒成功、HEAD 也壞→fail-loud、dry-run 零變更、非 git→fail-loud、單檔限制（旁邊放一個無關 dirty 檔，斷言未被動到）。
- 隔離：遵守 SPECTRA-PLUS.md 警告，勿與會改寫 rules.yaml 的 generator 測試並行；使用獨立 `HOME`/`TMPDIR` 沙箱。

## 避免行號耦合

實作以函式名、行為契約描述，不以行號綁定；唯一引用的 :99 為「概念上的呼叫點」說明，實作時以 `validate_commit_guard "$source"` 該語句為錨點插入。

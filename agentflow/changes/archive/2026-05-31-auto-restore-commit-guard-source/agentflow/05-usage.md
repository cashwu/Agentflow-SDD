# 05 — Usage：auto-restore-commit-guard-source

## 使用者故事

- 作為維護者，當 Spectra.app reset 掉本 repo 的 `spectra-commit` skill，我希望排程的 `--repair-all` 能自動把來源從 git HEAD 還原並完成修復，而不是一直 `[failed]`，讓我不必每次手動 `git restore`。
- 作為謹慎的使用者，我希望先用 `--dry-run` 看清楚「會還原哪個檔」，且 dry-run 絕不動我的檔案。

## CLI 契約（精確訊息）

| 情境 | 觸發 | 輸出（stdout） | 變更 | exit |
|------|------|----------------|------|------|
| 來源完好 | `--target` / `--repair-all` | 同今日（不印 restore 行） | 無額外 | 0 |
| 自癒 | source 壞 + in-git + HEAD 有效 + 非 dry-run | `restored <relpath> from HEAD`（每還原一份印一行） | 還原該單一檔案（working tree） | 隨後續 repair（成功為 0） |
| dry-run 自癒 | 同上但 `--dry-run` | `+ would restore <relpath> from HEAD` | 無（檔案/lock/cache/throttle 皆不動） | 0 |
| HEAD 也壞 | source 壞 + HEAD 無效 | 既有 `錯誤：<desc> 缺少必要內容：<marker>`（stderr） | 無 | 非 0 |
| 非 git | source 壞 + 非 git 工作樹 | 既有 fail-loud 訊息（stderr） | 無 | 非 0 |

### 訊息規範

- `<relpath>`：source 相對 git toplevel 的路徑，例如 `.claude/skills/spectra-commit/SKILL.md`、`.agents/skills/spectra-commit/SKILL.md`。
- 還原訊息（`restored … from HEAD`）走 **stdout**，因此在 LaunchAgent 路徑會一併寫入 `~/Library/Logs/spectra-plus-repair.log`（plist 將 stdout/stderr 都導向該 log）。
- dry-run 訊息採既有 `+ …` 慣例（與 `+ verify spectra-commit guard in …`、`+ update spectra-commit guard in …` 一致），維持 dry-run 輸出風格統一。
- fail-loud 維持既有 `fail` 行為與字串，不更動既有 stderr 契約。

## 與既有輸出整合

- 自癒情境的 `restored …` 行會出現在 `正在套用 spectra-commit guard...` 之後、`[success] <target>: repaired` 之前，呈現「先還原、後修復成功」的因果順序。
- `--repair-all` 對每個 target 仍輸出單行 per-target summary（`[success]`/`[skipped]`/`[failed]`）；restore 行屬該 target install 子輸出。

## 失敗模式（使用者可見）

1. HEAD 也壞 → 無法自癒 → fail-loud（同今日），使用者需自行修復 HEAD（罕見）。
2. 非 git / 未追蹤 / 空 repo 無 HEAD → 不還原 → fail-loud。
3. dry-run 下永不 mutate；若使用者期待 dry-run「順便修好」屬誤解——dry-run 僅報告。

## 驗收行為（對應 spec scenario）

- 自癒成功、HEAD 也壞、非 git、dry-run、單檔限制 五情境均由 `scripts/spectra-plus/tests/` 的 git fixture 測試斷言；訊息字串納入斷言。

## 對 spec 的更新

spec.md 之 scenario 以行為層級描述（不綁精確字串）已足夠且避免脆弱；精確字串於本 usage 文件與 design.md 固化，並由測試斷言。**不修改 spec.md 內容**（scenario 已完備）。

## 審查

見 `reviews/05-usage-r*.md`。

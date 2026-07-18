# Cash Apply Review — Round 4

## Reviewer Findings

### Critical

1. `severity`: Critical；`confidence`: 100；`layer`: design；`location`: `install-cash-skills.fish:516-525,624-631`；`summary`: clean receipt-based upgrade 以 `cp` 原地覆寫既有 managed destination；若 destination 是指向專案外檔案的 hard link，正常非 force 升級會改寫外部 inode；`recommendation`: 在 destination directory 建立受邊界驗證的 temporary file，寫完後以 atomic rename 取代 destination，並加入 hard-link regression fixture；`introduced_by`: 本次單一 installer 寫入流程保留 in-place `cp`，change diff 直接涵蓋該寫入路徑；reviewer source: Reviewer B — Quality。

### Warning

1. `severity`: Warning；`confidence`: 100；`layer`: design；`location`: `scripts/cash-skills/tests/skill-checks.fish:442-469,501-532`；`summary`: test-side `compare_bundle_versions` 依賴未檢查狀態的外部 `seq`，且 `cash_inventory_digest_at` 的最終 `string join | shasum | awk` pipeline 未驗證完整 `$pipestatus`，execution error 可將 regressed version 或 digest failure 偽裝成成功；`recommendation`: 改用 Fish `while`，檢查最終 pipeline 全部 status，並加入 hostile `seq` 與只在最終 shasum call 失敗的 fixtures；`introduced_by`: 本次 version-governance test helper 新增了上述未受控 execution paths；reviewer source: Reviewer A — Adherence、Reviewer B — Quality。
2. `severity`: Warning；`confidence`: 100；`layer`: design；`location`: `scripts/cash-skills/tests/skill-checks.fish:406-412`；`summary`: dry-run persistent-state assertion helper 只 hash regular-file contents，忽略空目錄、symlink、special entry、mode 與 link target，可能讓禁止的持久狀態變化漏過；`recommendation`: 以完整 tree manifest/digest 取代內容-only digest，並加入 empty-directory 與 symlink mutation oracle；reviewer source: Reviewer B — Quality。
3. `severity`: Warning；`confidence`: 100；`layer`: design；`location`: `scripts/cash-skills/tests/skill-checks.fish:990-1070`；`summary`: batch matrix 沒有實際 `would-update` dry-run target，且 `--all --force` 沒有驗證 newer target 維持不變；`recommendation`: 在 non-dry update 後新增獨立 older target 供 dry-run，並把 newer target 納入 force batch 且比對完整 tree digest；reviewer source: Reviewer A — Adherence。
4. `severity`: Warning；`confidence`: 100；`layer`: text；`location`: `openspec/changes/add-versioned-cash-skill-batch-update/implementation-notes.md:3`；`summary`: implementation note 使用不符合允許格式的自由文字 bullet，且仍引用已移除的 updater；`recommendation`: 移除無 deviation/open-question 意義的 bullet，保留 initialized header；reviewer source: Reviewer A — Adherence。

### Suggestion

無。

## Rating

- post-filter cumulative blocking Critical: 1
- post-filter cumulative blocking Warning: 4
- non-blocking triaged findings: 0
- `critical_gap`: true
- `round_type`: full
- rationale: 第一輪所有 confidence 100 findings 都直接影響 filesystem boundary、fail-loud governance、dry-run 零寫入證據或 review protocol，因此全部進入 cumulative blocking set；其中 hard-link 外部 inode mutation 為可重現的 Critical。

## Fix Actions

- 修改 `install-cash-skills.fish`：每個 changed managed file 都在同 destination directory 建立經 `is_below` 與 symlink 驗證的 temporary file，成功複製後以 atomic `mv` 取代 destination；任何 copy/publish failure 都清理 temporary file 並 fail loud。
- 修改 `scripts/cash-skills/tests/skill-checks.fish`：加入 clean hard-link upgrade fixture，確認外部 inode digest 不變且 managed destination 安裝 source bytes。
- 修改 `scripts/cash-skills/tests/skill-checks.fish`：以 Fish `while` 取代 test comparator 的 `seq`，檢查 final inventory digest pipeline 全部 `$pipestatus`，並加入 hostile `seq` 與第 25 次 final `shasum` failure fixtures。
- 修改 `scripts/cash-skills/tests/skill-checks.fish`：將 `tree_digest` 升級為涵蓋 file content、directory、symlink target、special entry 與 mode 的完整 manifest digest，並加入 empty-directory / symlink mutation oracle。
- 修改 `scripts/cash-skills/tests/skill-checks.fish`：加入真正的 `would-update` dry-run branch，以及 `--all --force` 對 newer target 的狀態與完整 tree 不變 assertions。
- 修改 `openspec/changes/add-versioned-cash-skill-batch-update/implementation-notes.md`：移除不符合 deviation/open-question protocol 且內容過時的 bullet。
- Post-fix validation：`fish scripts/cash-skills/tests/skill-checks.fish`、Fish syntax、`spectra validate add-versioned-cash-skill-batch-update`、`spectra analyze add-versioned-cash-skill-batch-update --json`、`git diff --check` 全部通過；analyze 僅保留 9 個非阻塞 Example Suggestions。

## Decision

next_round

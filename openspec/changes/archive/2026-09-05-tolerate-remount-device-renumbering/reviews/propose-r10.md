# Cash Propose Review — Round 10

本輪是第 9 輪 `passed` 後因 IC-15 時序測試協定再修改而啟動的新 full review run。由 Reviewer A（Adherence）與 Reviewer B（Quality）平行獨立執行；cumulative blocking set 起始為空。

## Reviewer Findings

### Warning

- `severity`: Warning / `confidence`: 100 / `layer`: design / `location`: `design.md` IC-15「未修復的 target 不因 identity drift 被自動改寫」列；`tasks.md` 1.1 / `summary`: 該列把 identity drift 分類與取鎖前失敗標為 red，但現行 `validate_installed_receipt` 已在 `acquire_lock` 前以 identity drift raise，三項斷言實作前全數成立，會形成假的 red evidence / `recommendation`: 全列改為 guard；新訊息與完整指令由既有 red scenarios 覆蓋 / 來源：Reviewer A
- `severity`: Warning / `confidence`: 100 / `layer`: design / `location`: `design.md` IC-15 最後一列；`.cash-skills/lib/cash_cli/installer.py` 的 direct 與 vendor 取鎖後 hold call sites / `summary`: 時序協定未禁止 `--dry-run`，但真實 call site 只在 `hooks.hold and not dry_run` 時呼叫 `wait_for_test_hold`；dry-run 即使取得 lock 也不建立 `.ready`，仍可 false green / `recommendation`: 明訂使用不帶 `--dry-run` 的 real run，並把模式列入驗收協定 / 來源：Reviewer A 與 Reviewer B 獨立提出
- `severity`: Warning / `confidence`: 90 / `layer`: design / `location`: `design.md` IC-15 最後一列；`scripts/cash-skills/tests/test_installer_runtime.py` 既有 Popen／hold 模式 / `summary`: 協定未完整規定 deadline、assertion 中途失敗與 `communicate` timeout 時的 child 回收，可能遺留 process 與 workspace lock，並以 cleanup error 遮蔽主要 regression / `recommendation`: 以 `try/finally` 管理完整 lifecycle；必要時 release、terminate、kill 並有限等待，且保留主要失敗原因 / 來源：Reviewer B

## Rating

- post-filter cumulative blocking set Critical count：0
- post-filter cumulative blocking set Warning count：3
- 非 blocking triaged finding count：0
- `critical_gap`: false
- `round_type`: full

rationale：本輪三筆 Warning confidence 皆至少 80；依 unseeded first-round 規則全部進入 cumulative blocking set。三筆皆已在同一處完成修正，但仍需下一輪 Reviewer V 給出 verified resolution，因此本輪決定 `next_round`。

## Fix Actions

修改 `openspec/changes/tolerate-remount-device-renumbering/design.md`：

1. 將 IC-15 最後一列整體改為 `guard`，明載三項行為在實作前已成立，MUST NOT 作為 red evidence；新增訊息行為仍由既有 red scenarios 驗證。
2. 明訂時序驗證使用不帶 `--dry-run` 的 direct real run，且同時設定 `CASH_INSTALL_TEST_HOOKS=1` 與 `CASH_INSTALL_HOLD_FILE=<hold>`。
3. 明訂以 `Popen`、有限 deadline 與 `try/finally` 管理 child；`.ready` 出現時立即建立 `.release`，所有退出路徑以有限 timeout 回收，必要時依序 `terminate`、`kill`，並不得以 cleanup error 遮蔽主要失敗原因。

fix propagation 後確認 `tasks.md` 1.1 已以 IC-15 表格的 red／guard 類型作為單一分類來源，不需另改；spec scenario 本身只規範產品行為，不應納入 test-hook 機制。重新執行 comment／annotation lint、scenario／table count、identifier cross-grep、MODIFIED requirement title identity、`cash analyze` 與 `cash validate`；結果為 Validation passed，Consistency 與 Gaps 均為 Clean。Relevant open signals 無 `check` frontmatter，沒有 signal-derived command 需要執行。本輪修改檔案全在 change directory 內，因此不記 touched。

## Decision

next_round

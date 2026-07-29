# Cash Apply Review — Round 1

## Reviewer Findings

### Critical

- severity: Critical
  confidence: 99
  layer: design
  location: `.cash-skills/lib/cash_cli/installer.py:2301`
  summary: `--vendor` 的 source／target publication plan 未與取鎖前 snapshot 對回；等鎖期間的變更可能使 stale plan 覆寫 project-owned內容，或發布與 manifest digest 不一致的 runtime。
  recommendation: 保存完整鎖前 source／target inputs，取得 exclusive lock後先重驗，並在排程每個 source record時再次核對 digest。
  reviewer source: Reviewer A

### Warning

- severity: Warning
  confidence: 99
  layer: design
  location: `.cash-skills/lib/cash_cli/installer.py:578`
  summary: 舊 manifest parser 被綁定現行 source inventory，且 transaction不會移除只存在於舊版的 runtime path，導致 runtime inventory新增或移除後無法升級。
  recommendation: 依舊 manifest自身的 canonical規則解析 baseline，並以可rollback的 managed delete收斂obsolete runtime。
  reviewer source: Reviewer A、Reviewer B（合併重複 finding）

- severity: Warning
  confidence: 100
  layer: text
  location: `.cash-skills/bin/cash:591`
  summary: portable mode在開啟 launcher／lock時仍使用 `bootstrap_invalid`，不符合 manifest inventory drift的 `manifest_invalid`具名錯誤契約。
  recommendation: 讓 stable open依所選trust mode使用對應error code，receipt mode維持既有行為。
  reviewer source: Reviewer A

- severity: Warning
  confidence: 96
  layer: design
  location: `.cash-skills/lib/cash_cli/installer.py:1308`
  summary: vendor Git preflight的 `ls-files`未禁用 target `core.fsmonitor`，且未區分untracked與Git index query failure。
  recommendation: 對target index query設定 `-c core.fsmonitor=`，只接受明確tracked／untracked結果，其餘fail closed。
  introduced_by: `.cash-skills/lib/cash_cli/installer.py:1308` 新增的 `git_excluded_paths`。
  reviewer source: Reviewer B

- severity: Warning
  confidence: 92
  layer: design
  location: `.cash-skills/lib/cash_cli/installer.py:1265`
  summary: installer runtime列舉忽略symlink directory，可能對launcher會拒絕的portable tree回報 `Result: current`。
  recommendation: installer與launcher採用相同的runtime directory shape規則並加入current分類測試。
  introduced_by: `.cash-skills/lib/cash_cli/installer.py:1265` 的portable target inventory validator。
  reviewer source: Reviewer B

### Suggestion

無。

## Rating

- Critical: 1
- Warning: 4
- non-blocking triaged findings: 0
- critical_gap: true
- round_type: full
- 理由：第一輪所有通過信心與證據過濾的 Critical／Warning均進入 cumulative blocking set；已完成修正，但依規則須由下一輪 Reviewer V驗證後才能移除。

## Fix Actions

- 修正 `.cash-skills/lib/cash_cli/installer.py`：保存鎖前 source／target snapshots，exclusive lock後重驗 `source_inventory`與所有plan inputs，並在transaction排程時重新核對source digest；新增lock-wait source runtime與target guidance競態測試。
- 修正 `.cash-skills/lib/cash_cli/installer.py`：讓舊portable manifest依自身canonical inventory解析；新增journal schema v3 `delete` operation，在manifest cutover前安全移除obsolete runtime並可rollback；新增runtime inventory新增／移除升級測試。
- 修正 `.cash-skills/bin/cash`：`open_regular`接受trust-mode error code，portable launcher／lock drift統一回報 `manifest_invalid`；同步更新 `.cash-skills/manifest.tsv`與exact launcher transition digest。
- 修正 `.cash-skills/lib/cash_cli/installer.py`：所有vendor target Git index query禁用 `core.fsmonitor`，Git query error fail closed；新增惡意fsmonitor與corrupt index測試。
- 修正 `.cash-skills/lib/cash_cli/installer.py`：以 `os.walk(..., followlinks=False)`明確拒絕runtime symlink directory；新增不可被誤報current的測試。
- 過濾 Reviewer A的recovery-gate finding：`test_recovery_reclassifies_unrelated_drift_as_conflict`與 `test_journal_diagnostic_precedes_all_dry_and_real_classifications`明示journal recovery須先完成並清除journal，再把transaction外的managed drift重新分類為conflict；在cleanup前要求整份舊gate無drift會違反此既有契約，因此不列入post-filter findings。
- 完整驗證通過：history 10 tests、installer runtime 114 tests、init receipt 21 tests、`skill-checks.fish`全部檢查、`cash validate`與 `git diff --check`。
- post-fix mechanical self-check通過：annotation、count／identifier cross-grep、MODIFIED requirement title identity與signal check欄位均無失敗。

## Decision

next_round

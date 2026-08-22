<!-- cash-apply implementation notes | change: default-spec-sync-on-archive | initialized: 2026-08-22 17:25 | no entries below means no deviations or open questions were recorded -->

## 2026-08-22 17:52 — 補上 cash-skills.version bump 與 manifest 重建

- 類別：deviation
- 任務：2.1
- 內容：`design.md` 的 IC1–IC3 與 `tasks.md` 只宣告修改四個 `SKILL.md`，但 `scripts/cash-skills/tests/test_bundle_version_history.py` 的 bundle version history contract 要求任何 `.claude/skills/cash-*/SKILL.md` 或 `.agents/skills/cash-*/SKILL.md` 變動時 `cash-skills.version` MUST strictly increase；`.cash-skills/manifest.tsv` 的 skill digest 與 `bundle_version` 亦 MUST 與工作樹一致，否則 `.cash-skills/bin/cash` 以 `manifest_invalid` fail closed。因此本次額外修改 `cash-skills.version`（`2.13.0` → `2.14.0`，沿用歷史上行為變更採 minor bump 的慣例）並執行 `PYTHONPATH=.cash-skills/lib python3 -s -P -B -m cash_cli.installer --self` 重建 manifest。
- 原因：這是專案既有且已定義的落地機制，不是新增的 contract；要交付的觀察行為、interface／資料形狀、失敗模式與驗收標準都沒有改變，且 task 2.1 明訂 `./scripts/cash-skills/tests/skill-checks.fish` MUST 通過（exit code 0），不做此步驟該驗證目標無法達成。

## 2026-08-22 17:58 — bump 連帶需要同步 installer.py 的 BUNDLE_VERSION

- 類別：deviation
- 任務：2.1
- 內容：承上一筆。只改 `cash-skills.version` 後 `./scripts/cash-skills/tests/skill-checks.fish` 仍以 `AssertionError: '2.13.0' != '2.14.0' : BUNDLE_VERSION='2.13.0' but cash-skills.version='2.14.0'` 失敗，因為 installer runtime contract 要求 `.cash-skills/lib/cash_cli/installer.py` 的 `BUNDLE_VERSION` 常數與 `cash-skills.version` 一致。因此一併把該常數改為 `"2.14.0"`，並重新執行 `--self` 讓 `.cash-skills/manifest.tsv` 的 `runtime_generation` 一起更新。修改後套件全數通過（exit code 0）。
- 原因：與上一筆同源——這是既有 runtime contract 對版本 bump 的一致性要求，不改變任何本變更要交付的觀察行為或 contract；不做則 task 2.1 的驗證目標無法達成。

## 2026-08-22 19:34 — 上述兩筆 deviation 已於 review round 1 回填為 IC6 與 task 1.0

- 類別：deviation
- 任務：1.0
- 內容：本檔前兩筆條目（`2026-08-22 17:52`、`2026-08-22 17:58`）記錄的偏離已於 Sub-Agent Review/Rating/Fix Loop 的 round 1 被吸收進 artifacts：`design.md` 新增 `**IC6 — bundle version bump**`，`tasks.md` 新增排在 1.1 之前的 `1.0 依 IC6 調升 bundle version`，`proposal.md` 的 `## Impact` `Modified:` 加入 `cash-skills.version`、`.cash-skills/lib/cash_cli/installer.py`、`.cash-skills/manifest.tsv`。原條目所述「artifacts 只宣告修改四個 `SKILL.md`」的前提自 round 1 起不再成立，但依 Implementation Notes Protocol 保留不改寫，以本條記錄其解決。
- 原因：原條目是歷史紀錄，回填後仍需保留以維持可稽核性；同時必須明確標示其前提已失效，避免後續 reviewer 依過期前提判讀。

## 2026-08-22 19:34 — task 1.0 的順序要求為事後補記，本次執行的實際順序不符

- 類別：open-question
- 任務：1.0
- 內容：`tasks.md` 的 task 1.0 載明「MUST 排在 1.1 之前執行」，且該 checkbox 標為 `[x]`。但在本次執行中，bump 實際發生於 1.1、1.2、1.3 完成之後——它是在 task 2.1 執行 `./scripts/cash-skills/tests/skill-checks.fish` 失敗（`HistoryError: .agents/skills/cash-archive/SKILL.md changed without a strictly greater cash-skills.version`）後才補做的。task 1.0 是 review round 1 為修復 blocking finding 3 而回頭新增的，其順序要求對**後續**執行有效，對本次已完成的執行則是事後補記。最終工作樹狀態合規（bump 與 skill 變更會在同一 commit 落地，bundle version history contract 以 first-parent commit 為比對基準，套件現已 exit 0）。
- 原因：需要使用者確認這樣的處置可接受——若要求 checkbox 的 `[x]` 嚴格代表「依宣告順序執行過」，則本次紀錄不實，應改由重跑或在 task 1.0 內文明記本次為補做；若 `[x]` 只代表「該交付目標的最終狀態已達成且判準通過」，則現況即為正確，本條可逕行關閉。

## 2026-08-22 19:52 — open-question 已由使用者裁決：[x] 為最終狀態語意

- 類別：deviation
- 任務：1.0
- 內容：前一筆 `open-question`（`2026-08-22 19:34`，task 1.0 的順序要求為事後補記）已在本 session 中由使用者明確裁決：`tasks.md` 的 `- [x]` 代表「該 task 的交付目標已達成且其判準通過」，不宣稱執行順序。依此語意，task 1.0 標為 `[x]` 為正確——其三條判準（`cash-skills.version` 為 `2.14.0`、`installer.py` 的 `BUNDLE_VERSION` 為 `"2.14.0"`、`manifest.tsv` 的 `bundle_version` 為 `2.14.0`）實測全部成立。task 1.0 內文的「MUST 排在 1.1 之前執行」對後續執行仍然有效，不因本次為事後補做而失效。該 `open-question` 就此關閉，不再阻擋 review round。
- 原因：使用者裁決確立了 checkbox 的語意邊界，使「完成宣告」與「執行順序紀錄」成為兩件分開的事——前者由判準證明，後者由本檔的歷史條目保存。

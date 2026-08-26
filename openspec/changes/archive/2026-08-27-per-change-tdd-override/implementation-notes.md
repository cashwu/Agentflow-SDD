<!-- cash-apply implementation notes | change: per-change-tdd-override | initialized: 2026-08-27 06:09 | no entries below means no deviations or open questions were recorded -->

## 2026-08-27 06:14 — 受守衛 skill 變更缺少版本提升範圍
- 類別：open-question
- 任務：1.1
- 內容：`fish scripts/cash-skills/tests/skill-checks.fish` 因 `.agents/skills/cash-apply/SKILL.md changed without a strictly greater cash-skills.version` 失敗；若要滿足既有 bundle version history contract，artifacts 需明確納入 `cash-skills.version`，並同步評估 `.cash-skills/lib/cash_cli/installer.py` 的 `BUNDLE_VERSION` 與 manifest 更新義務。
- 原因：目前 proposal `## Impact`、design Implementation Contract 與 tasks delivery 均未宣告 `cash-skills.version` 或 installer 常數；直接修改會擴張 structured scope 與可觀察的 bundle version metadata，需先由使用者透過 `$cash-ingest per-change-tdd-override` 更新 artifacts。

## 2026-08-27 06:14 — Bundle version scope 已由 ingest 補齊
- 類別：open-question
- 任務：0.1
- 內容：使用者同意先更新 artifacts 再繼續開發；proposal `## Impact`、design C6 與 task 0.1 已納入 `cash-skills.version`、`.cash-skills/lib/cash_cli/installer.py`、manifest 同步及既有 version-history verification，原 open question 已解決。
- 原因：將既有 bundle 發布契約明確納入 structured scope，使後續版本提升可被 task、contract 與 reviewer 完整追溯。

## 2026-08-27 06:19 — Ingest 驗證先於新增版本 task 執行
- 類別：deviation
- 任務：0.1
- 內容：`cash-ingest` 在新增 task 0.1 後，依其 artifact workflow 先執行 `status`、`analyze` 與 `validate`，才由後續 `cash-apply` 將 bundle version 提升至 `2.18.0`；除此之外，版本檔仍先於 `BUNDLE_VERSION` 修改，且所有後續 Cash CLI 呼叫前均已重建 manifest。
- 原因：新增 task 自身必須先經 ingest 的 CLI 驗證才能成為有效 handoff，無法在同一次 ingest 中要求尚未進入 apply 的 implementation task 反向先於該驗證執行；當時 manifest 已與 skill bytes 一致，未形成 fail-closed 或內容漂移窗口，交付 contract 與驗收結果不變。

## 2026-08-27 10:05 — 版本提升幅度與 C6 原措辭不符，措辭已對齊
- 類別：deviation
- 任務：0.1
- 內容：實際版本由 `2.17.0` 提升至 `2.18.0`（minor），與 design C6 原措辭「嚴格提升下一個 patch version」不符；受治理的 `test_bundle_version_history.py` 僅斷言 strictly greater，測試通過、交付結果與驗收不變。已將 proposal 第 6 點、design Decision 7／C6／Risks 與 task 0.1 的措辭統一對齊為「嚴格提升為更大的版本（strictly greater）」，與實際被 checker 治理的約束一致。
- 原因：patch-bump 幅度從未被任何 checker 或 master spec 治理，保留該措辭會在 artifacts 留下一條無人執行的規則；對齊為 strictly greater 使 contract 與可驗證行為一致（cash-verify review 的 Warning 處置）。

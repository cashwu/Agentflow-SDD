# 08 — Review：auto-restore-commit-guard-source

## 審查閘門結果

整體審查（artifact 一致性 + drift + 安全）由獨立 sub-agent 執行，見 `reviews/08-review-r1.md`。

- **quality_score**：9.3/10，decision：**pass**，無 critical gap。
- **測試**：`auto-restore-checks.fish` PASS（exit 0）；`fish -n` installer + repair-all 皆 OK。
- **一致性**：18 個 artifact 齊備；9 個必要 review round 檔齊備；status.yaml 中標記 passed 的步驟皆有對應 review 檔。
- **drift**：實作函式名 `restore_source_guard_if_needed` 與 proposal/design/tasks 一致；live code/spec/proposal/design/tasks 無殘留舊名（唯一出現於 `07-dev-task-T7-r1.md` 凍結稽核紀錄，不更動）。
- **scenario 覆蓋**：5 個 spec scenario 皆有實作與對應測試（A1 dry-run、A2 自癒、A3 單檔、B HEAD 壞、C 非 git）。
- **T5**：`SPECTRA-PLUS.md` 自癒疑難排解已加入；master spec 同步明確 defer 到 wrap（非靜默丟棄，已於 07-dev/tasks/06-ticket 記錄）。
- **安全**：T7 audit 已覆蓋（誤蓋防護、單檔 pathspec、dry-run 零變更、不動 index、HEAD 驗證、temp 清理、return-2 不外洩），全清。

## 已修正

- spec.md `@trace` 的 `tests:` 由 `installer-commit-guard-checks.fish` 更正為 `auto-restore-checks.fish`（自癒測試實際所在）。

## 進入 Wrap 的待辦

1. 將新 requirement 併入 master spec `openspec/specs/spectra-plus-skills/spec.md`（含已更正的 @trace）。
2. 歸檔 change。
3. 殘留風險摘要。

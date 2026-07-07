<!-- apply-plus implementation notes | change: add-review-loop-discipline | initialized: 2026-07-07 22:38 | no entries below means no deviations or open questions were recorded -->

## 2026-07-07 22:51 — 收斂 Codex slash-command substitution
- 類別：deviation
- 任務：n/a
- 內容：Round 1 review 發現四個 generated plus skill 必須包含 verbatim protected path set，但既有 Codex variant 的全域 `/spectra-` substitution 會把 `scripts/spectra-plus/...` 與 `.agents/skills/spectra-...` 這類 path 改壞成 `$`。修復時同步調整 `scripts/spectra-plus/rules.yaml`，把 substitution 收斂成只處理 backtick command 形式 `` `/spectra-``，並在 generator checks 中補上 literal protected path 與 corrupted path 反向斷言。
- 原因：若只在模板中拆字串可避開 substitution，但 generated artifacts 不再含 project-root-relative path verbatim，直接違反 spec 與 task 的保護路徑契約；調整 substitution scope 是最小且可測的修復。

## 2026-07-07 22:51 — 補回 rules.yaml 範圍宣告
- 類別：deviation
- 任務：n/a
- 內容：Round 2 review 指出 `scripts/spectra-plus/rules.yaml` 已被實作修改，但 proposal、design、tasks 尚未把這個窄化 substitution 的修復列入 scope。已將 proposal `## Impact`、design scope/non-goals 與 tasks 4.1 補回，讓實作範圍與 artifacts 對齊。
- 原因：原本的 deviation 說明只解釋技術必要性，未更新 authoritative artifacts；補回 scope 後 reviewer 可用 artifacts 判定此修改是此 change 的明確實作內容。

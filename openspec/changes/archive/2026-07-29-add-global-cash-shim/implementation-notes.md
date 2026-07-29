<!-- cash-apply implementation notes | change: add-global-cash-shim | initialized: 2026-07-29 10:44 | no entries below means no deviations or open questions were recorded -->
## 2026-07-29 10:53 — 以隔離 HOME 執行 deletion test
- 類別：deviation
- 任務：4.1
- 內容：端到端 deletion test 不移動真實 `$HOME/.local/bin/cash`；改在覆寫 `HOME` 的暫存 fixture 安裝 shim，移開該 fixture 的 `$HOME/.local/bin/cash` 後直接執行本專案 `.cash-skills/bin/cash list --json`，再將 shim 還原。
- 原因：驗證開始時真實 `$HOME/.local/bin/cash` 已不存在；隔離 fixture 能交付相同的 deletion-test 觀察行為、interface、失敗模式與驗收證據，且避免為測試改動使用者家目錄。
## 2026-07-29 10:56 — deletion test deviation 已回填
- 類別：deviation
- 任務：5.3
- 內容：`design.md` C12 與新增 task 5.3 已將 deletion test 固化為條件式 contract：真實 shim 存在時可暫移並還原；不存在時使用隔離 `HOME` fixture 執行等價流程。
- 原因：保留原 task 4.1 的完成歷史，同時讓 durable handoff 明確包含已驗證且不觸碰真實 HOME 的替代機制，解決 apply-r1 Finding 1。
## 2026-07-29 11:02 — 抑制 fish 啟動期 HOME 寫入
- 類別：deviation
- 任務：5.4
- 內容：`install-cash-shim.fish` 的 shebang 將 `XDG_CONFIG_HOME`、`XDG_DATA_HOME`、`XDG_CACHE_HOME` 設為 `/dev/null`，contract tests 改為直接執行入口並斷言隔離 HOME 只有 `.local/` 內的預期輸出。
- 原因：fish 即使使用 `--no-config`，啟動時仍會在覆寫 `HOME` 建立 `.config/fish`、`.local/share/fish` 與 `.cache/fish`；shebang 層的 XDG suppression 保留既定 installer interface、destination、失敗模式與驗收標準，且不需要新增同步、identity type 或 state machine。
## 2026-07-29 11:08 — fish XDG suppression 已回填
- 類別：deviation
- 任務：5.4
- 內容：`design.md` Decision 7／C8 與 `specs/cash-global-shim/spec.md` 的安裝入口 requirement 已固化 shebang XDG suppression 與 caller `HOME` 寫入邊界。
- 原因：讓 durable artifacts 明確包含實作期間採用且已由 contract test 驗證的 contract-preserving 機制替換。

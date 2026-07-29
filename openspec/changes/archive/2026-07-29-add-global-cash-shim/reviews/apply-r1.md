# Cash Apply Review — Round 1

## Reviewer Findings

### Critical

無。

### Warning

1. severity: Warning｜confidence: 100｜layer: text｜location: `openspec/changes/add-global-cash-shim/tasks.md` task 4.1；`openspec/changes/add-global-cash-shim/implementation-notes.md`「以隔離 HOME 執行 deletion test」｜summary: 已記錄且合理的 deletion-test deviation 尚未回填 durable task；task 4.1 仍要求移開真實 `$HOME/.local/bin/cash`，但實際驗證在該路徑原本不存在時改用隔離 `HOME`｜recommendation: 將 task 4.1 改為條件式驗證契約：真實 shim 存在時可暫移，不存在時使用隔離 `HOME` fixture，並明定兩者驗證相同的 project-local launcher deletion property；保留既有 deviation 作為歷史紀錄｜來源: Reviewer A — Adherence
2. severity: Warning｜confidence: 100｜layer: design｜location: `scripts/cash-shim/tests/shim-checks.fish:81-103,156-195`；`openspec/changes/add-global-cash-shim/specs/cash-global-shim/spec.md`「引數逐字透傳」與「旗標映射」Examples｜summary: Contract tests 未逐列覆蓋高精度 Examples：dispatch fixture 缺少 `--limit 10`，旗標映射也未分別驗證 `cash init`、`cash init --target`、`cash init --dry-run`、`cash init --target --force` 四列｜recommendation: 增加 exact-argv fixtures，逐列執行並斷言兩個 Example blocks 的完整輸入、預期 argv 與順序｜來源: Reviewer A — Adherence、Reviewer B — Quality｜introduced_by: `scripts/cash-shim/tests/shim-checks.fish:81-103,156-195`
3. severity: Warning｜confidence: 100｜layer: design｜location: `scripts/cash-shim/cash-shim.sh:11-13,33-35,41-43,58-64,68-70`｜summary: 內部 shell 變數會保留同名 inherited environment variable 的 export attribute，違反 C9 零環境污染契約｜recommendation: 使用隔離命名並在賦值前清除其 inherited export attribute，或採用不產生 exported shell-variable side effect 的等價方式；新增 hostile inherited environment fixture，斷言 exec 後未收到 shim 內部值｜來源: Reviewer B — Quality｜introduced_by: `scripts/cash-shim/cash-shim.sh:11-13,33-35,41-43,58-64,68-70`
4. severity: Warning｜confidence: 90｜layer: design｜location: `install-cash-shim.fish:25-36,42-47,61-85`｜summary: `.local`／`bin` 的 shape 驗證與後續 `mkdir`、`mktemp`、`mv` 是分離的 pathname 操作；目錄在驗證後被替換為 symlink 時，可能在 `$HOME/.local/bin/` 實體邊界外建立或發布檔案｜recommendation: 在 mutation 前 canonicalize 並 no-follow 驗證 `HOME` 與每個 parent component，且讓 temporary creation、publish、cleanup 綁定同一個已驗證 directory identity；加入 parent-swap fault-injection fixture與 target 外 sentinel 斷言｜來源: Reviewer B — Quality｜introduced_by: `install-cash-shim.fish:25-36,61-85`

### Suggestion

無。

## Rating

- post-filter cumulative blocking Critical: 0
- post-filter cumulative blocking Warning: 4
- non-blocking triaged finding: 0
- critical_gap: false
- round_type: full
- rationale: 本輪為未 seeded run 的第一輪，4 個 confidence ≥ 80 的 Warning 全部進入 cumulative blocking set。Finding 4 的修復需要 `design.md` 未定義的 verified directory identity／handle 機制，觸發 cash-apply Fix-loop design circuit breaker，因此不能進入 fix round，決策為 `aborted`。

## Fix Actions

- needs-design：Finding 4 需要讓 temporary creation、publish 與 cleanup 綁定同一個 verified directory identity／handle；這屬於 `a synchronization primitive, identity/generation type, or state machine not defined in design.md`，本輪不得自行實作，必須先以 `$cash-ingest add-global-cash-shim` 更新 design／scope。
- bucket 1 — Finding 1：回填隔離 `HOME` deletion-test 的 durable task 契約；尚未修復，作為後續 re-run seed。
- bucket 1 — Finding 2：逐列補齊兩個 spec Examples 的 exact-argv fixtures；尚未修復，作為後續 re-run seed。
- bucket 1 — Finding 3：消除 inherited export 污染並補 hostile-environment fixture；尚未修復，作為後續 re-run seed。
- bucket 1 — Finding 4：先由 ingest 定義 verified directory identity／handle 與 parent-swap 驗收，再實作；尚未修復，作為後續 re-run seed。
- bucket 2：無。
- bucket 3：無。

## Decision

aborted

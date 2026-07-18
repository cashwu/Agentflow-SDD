# Cash Apply Review — Round 1

## Reviewer Findings

### Critical

1. **location:** `.agents/skills/spectra-commit/SKILL.md`、`.claude/skills/spectra-commit/SKILL.md`
   **summary:** 兩份 Spectra-owned `spectra-commit` 尚未 byte-for-byte 恢復成目前 `spectra update --force` 產生的 baseline，仍殘留 archive-first custom allowlist 與 cash 範例。
   **recommendation:** 在隔離 fixture 產生當前 Spectra baseline，完整恢復兩份檔案並用 `cmp` 驗證。
   **confidence:** 100
   **layer:** design

2. **location:** `scripts/cash-skills/tests/skill-checks.fish`
   **summary:** propose/apply review branches 主要以靜態 literal 檢查，只有一個 mutation fixture，未逐條證明 full、micro、seeded rerun、retry/failure、disposition、accepted risk、signal、ledger、abort、action obligation 與 commit dirty-worktree contract 會 fail loud。
   **recommendation:** 建立逐項 governed-branch mutation matrix，每個 mutation 都在隔離 fixture 回傳非零並指出 project-relative path。
   **confidence:** 100
   **layer:** design

### Warning

1. **location:** `scripts/cash-skills/tests/skill-checks.fish` 的 variant parity
   **summary:** parity 以整份 unified diff 的 opaque digest 作 allowlist，雖能偵測位元組變動，卻隱藏 `cash-audit` 等大段 tool-capability 差異，無法直接審閱允許內容。
   **recommendation:** 改為 invocation normalization 後逐行比對 readable exact per-skill manifests，並在 artifacts 宣告允許的 tool-capability 差異。
   **confidence:** 100
   **layer:** design

2. **location:** `uninstall-spectra-plus-repair.fish` registry preflight
   **summary:** registry 存在時未先驗證 readable regular file 與完整讀取結果，讀取失敗仍可能繼續卸載並刪除 registry/cache，遺失尚未遷移的 target inventory。
   **recommendation:** 在任何 launchctl 前完成 registry 型態與讀取 preflight；錯誤時 fail closed 且零刪除。
   **confidence:** 99
   **layer:** design

3. **location:** `uninstall-spectra-plus-repair.fish` service-absence classifier
   **summary:** `not found`／`not-loaded` 的寬鬆 regex 可能把不相關的 launchctl 錯誤誤判為 service 已不存在，進而刪除 legacy state。
   **recommendation:** 只接受與完整 queried service identity 相符的已知 absent 訊息，其他錯誤一律 fail closed。
   **confidence:** 95
   **layer:** design

4. **location:** `install-cash-skills.fish`、`uninstall-spectra-plus-repair.fish`
   **summary:** mutating scripts 使用一般 Fish startup，使用者 `config.fish` function 可覆寫 launchctl、realpath、cmp 等關鍵命令並改變安全判斷。
   **recommendation:** executable shebang 使用 `fish --no-config`，關鍵外部命令明確以 `command` 呼叫，並用 hostile startup config fixture 驗證。
   **confidence:** 93
   **layer:** design

### Suggestion

None.

## Rating

- post-filter cumulative blocking set: 2 Critical, 4 Warning
- non-blocking triage: 0
- `critical_gap: true`
- `round_type: full`
- rationale: 兩位 full-round reviewers 的重複 baseline finding 已依 location + summary 聚合；六個 confidence ≥ 80 findings 在未 seeded 的第一輪全部為 blocking，必須修正並由 Reviewer V 逐項驗證。

## Fix Actions

- 修正 Spectra baseline finding：修改 `.agents/skills/spectra-commit/SKILL.md` 與 `.claude/skills/spectra-commit/SKILL.md`，並與隔離執行 `spectra update --force` 的輸出逐檔 `cmp`，兩份皆 byte-identical。
- 修正 behavioral fixture finding：修改 `scripts/cash-skills/tests/skill-checks.fish`，加入 26 個逐項 governed mutation cases，涵蓋 first/full、fourth/full、micro、seeded rerun、retry/failure、disposition、accepted risk、signal check/matching/write、ledger、abort、action obligation、propose termination、apply archive/needs-design 與 commit allowlist；每個 case 必須非零且輸出 project-relative path。同步修改 `design.md`、`specs/cash-skill-workflows/spec.md` 與 `tasks.md` 明示完整 mutation coverage。
- 修正 readable parity finding：移除 digest allowlist；修改 `scripts/cash-skills/tests/skill-checks.fish`，新增 `scripts/cash-skills/variant-parity/cash-analyze.diff`、`cash-ask.diff`、`cash-audit.diff`、`cash-drift.diff`、`cash-ingest.diff`、`cash-propose.diff`、`cash-verify.diff` 七份逐行可讀 manifest；修改 `proposal.md`、`design.md`、`specs/cash-skill-workflows/spec.md` 與 `tasks.md` 宣告精確 tool-capability 差異與 Impact。
- 修正 registry preflight finding：修改 `uninstall-spectra-plus-repair.fish`，在 launchctl 前要求 registry 為 readable regular file 並確認完整讀取成功；修改 `scripts/cash-skills/tests/skill-checks.fish` 加入 non-regular/read-failure fail-closed fixture；同步修改 `design.md`、`specs/cash-skill-workflows/spec.md` 與 `tasks.md`。
- 修正 service classifier finding：修改 `uninstall-spectra-plus-repair.fish`，只接受 queried service-specific 的 stub/native absent 訊息與精確 bootout race 訊息；修改 `scripts/cash-skills/tests/skill-checks.fish` 加入 misleading generic `not found` error fixture；同步修改 `design.md`、`specs/cash-skill-workflows/spec.md` 與 `tasks.md`。
- 修正 Fish startup finding：修改 `install-cash-skills.fish` 與 `uninstall-spectra-plus-repair.fish` 使用 `#!/usr/bin/env -S fish --no-config`，並以 `command` 呼叫關鍵外部工具；修改 `scripts/cash-skills/tests/skill-checks.fish` 加入兩個 hostile `config.fish` direct-executable fixtures；同步修改 `design.md`、`specs/cash-skill-workflows/spec.md` 與 `tasks.md`。
- Post-fix mechanical self-check：open signals 中沒有 `check` 欄位需要執行；`fish_indent --check`、`git diff --check` 通過；完整 cash suite 通過，26 個 governed mutations、installer/cleanup branch matrices 與 isolated `spectra update --force` fixture 全部通過。
- Post-fix validation：`spectra validate fork-spectra-skills-to-cash` 通過；`spectra analyze fork-spectra-skills-to-cash` 的 Coverage、Consistency、Gaps clean，僅有 non-blocking Suggestions。

## Decision

next_round

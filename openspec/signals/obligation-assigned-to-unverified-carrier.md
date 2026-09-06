---
id: obligation-assigned-to-unverified-carrier
type: recurring-finding
status: open
occurrences: 4
first_seen: 2026-08-22
last_seen: 2026-09-06
links:
  - openspec/changes/default-spec-sync-on-archive/reviews/propose-r1.md
  - openspec/changes/default-spec-sync-on-archive/reviews/propose-r2.md
  - openspec/changes/strengthen-cash-tdd-evidence/reviews/propose-r1.md
  - openspec/changes/add-host-derived-round-lint/reviews/propose-r2.md
  - openspec/changes/add-host-derived-round-lint/reviews/propose-r4.md
  - openspec/changes/add-host-derived-round-lint/reviews/propose-r7.md
---

# Obligation assigned to an unverified carrier

A change adds a normative obligation (a MUST to report, record, or surface something) and assigns it to an entry point without first checking that the entry point has an output surface able to carry it — or it names an existing surface as sufficient without checking that the surface is actually selected under the conditions the obligation covers. The obligation then cannot be satisfied at implementation time, and because the same change usually freezes the surface as MUST NOT change, the implementer has no legal way out. The fix is to inspect the concrete carrier for every entry the obligation names, enumerate the input combinations that reach it, and either scope the obligation per entry or open the minimum edit the carrier needs.

## Occurrences

- 2026-08-22 — default-spec-sync-on-archive — cash-propose rounds 1–2 — round 1：新 requirement 要求「兩者的完成摘要 MUST 回報判定結果」，但 `cash-commit` 的 `**Output On Success**` 只有 Commit／Files／Tasks 三行、沒有任何 spec sync 欄位，而 design 又明文禁止改動模板；修法是依兩個入口既有的輸出面分配義務，並開放一處最小模板追加。round 2：為修前者而寫的「`cash-archive` 三個 Output 模板恰好對應三個判定結果」被查出不成立——模板由「有沒有 warnings」選擇，warnings 模板的 `**Specs:**` 行硬寫為跳過，因此「已同步但有未完成 task」無模板可用。兩次都是先寫下義務、後才查驗承載面。
- 2026-08-24 — strengthen-cash-tdd-evidence — cash-propose round 1 — canonical test-quality 首次載入被指派給尚不存在的 resource，canonical TDD evidence 又被綁在 `cash-debug` 不具備的 `tasks.md`；修法是提供只限自舉 task 的有界 carrier，並讓 `cash-debug` Phase 3 notes承載 primary／regression／success／failure evidence。

- 2026-09-05 — add-host-derived-round-lint — cash-propose rounds 2、4 — 兩次都是先寫下 MUST、後才發現承載面不存在。round 2：spec 要求重入放行時輸出「上一次判定」的失敗項，但同一 design 規定 command 唯讀且不寫任何檔案，沒有任何 host-derived 管道可保存前次結果，該 MUST 不可實作且連 fixture 都建不出來。round 4：要求 `--hook` mode 自帶取鎖時間上限，但 launcher 的 `fcntl.flock` 發生在 manifest 驗證與 runtime import **之前**，而同一份 design 的 Goals 明文不修改 launcher，因此 command 內的任何逾時機制都涵蓋不到該段阻塞；其對應 scenario 的 fixture（他人持 `LOCK_EX`）反而會使 hook 無限阻塞，正是該規則要避免的情形。兩次的共同成因是為了關閉一個 fail-open 缺口而加碼義務時，未回頭查該義務的執行位置。
- 2026-09-06 — add-host-derived-round-lint — cash-propose round 7（seeded re-run）— spec 與 tasks 把「fail open 以 exit 0 並在 stderr 輸出 `gate_unavailable`」的 MUST 套到「每個」分支，包含 `.cash-skills/bin/cash` 缺席與 launcher 信任 gate 失敗，但 hook command 直接執行 launcher、design 明文不存在可插入 wrapper 的位置：CLI 缺席時 shell 以 127 結束、launcher 的 `fail()` 以 exit 1 結束，皆早於 `lint_round.py` 進入點，沒有任何程式能承載該診斷。修法是把義務限定為進入點之後可攔截的分支，其餘併入 Risk 為「由 host／shell 決定終止方式」。

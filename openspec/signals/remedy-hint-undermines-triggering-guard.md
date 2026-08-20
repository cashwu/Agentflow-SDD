---
id: remedy-hint-undermines-triggering-guard
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-08-20
last_seen: 2026-08-20
links:
  - openspec/changes/tolerate-remount-device-renumbering/reviews/propose-r4.md
---

# Actionable remedy hint undermines the very guard whose failure triggers it

A change makes a fail-closed diagnostic actionable by attaching the command that resolves it. But some guards fail closed precisely to stop a state the remedy would launder, and that state is indistinguishable from the benign one at the point the diagnostic is emitted. The hint then fires hardest on exactly the case the guard exists to block, converting a fail-closed protection into a fail-closed-with-a-one-step-bypass. It gets worse when the hint or the deployed guidance enumerates the benign acquisition paths as legitimate reasons to run the remedy, because that language is itself the endorsement. Conditioning the hint on a runtime query is usually the wrong fix — the query is unavailable at the surface the guard actually names, or absent on some call paths. Put the precondition in the hint text so it holds uniformly, and never enumerate an acquisition path as an unconditional justification.

## Occurrences

- 2026-08-20 — tolerate-remount-device-renumbering — cash-propose round 4 — 變更為 identity drift 附上可執行的 `--init-receipt` 指令，但 `Target 版控排除保護` requirement 守護的情境（receipt 被誤納入版控後在別台機器 clone）正好落在 digest 相符、只有 inode 不符的 identity drift，而該 requirement 明白指名的執行面就是 launcher。更嚴重的是 hint 文字與部署到每個 target 的 guidance 逐字把 `fresh clone` 列為可以重簽的正當理由。曾嘗試以 installer 的唯讀 version-control 查詢作為分支條件，但 launcher 無法在不新增每次啟動一次查詢的前提下判定、該查詢也只由部分呼叫點執行。修法是移除整套查詢分支，改為把版控前提寫進指引文字並禁止背書任何取得方式。

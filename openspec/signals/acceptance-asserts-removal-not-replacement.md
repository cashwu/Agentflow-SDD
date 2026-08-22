---
id: acceptance-asserts-removal-not-replacement
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-08-22
last_seen: 2026-08-22
links:
  - openspec/changes/default-spec-sync-on-archive/reviews/propose-r1.md
---

# Acceptance criteria assert the removal, not the replacement

A change that replaces a mechanism writes acceptance criteria only as absence checks on the old mechanism's literals. Every such criterion passes for an implementation that removes the old behavior and installs the opposite of the intended one, so the positive contract — the thing the change exists to deliver — has zero mechanical coverage. A second failure mode hides inside the same pattern: the old mechanism's prose form (a sentence rather than a marker) often has no absence check at all, so leaving it in place passes too. The fix is to pin the replacement text verbatim in the implementation contract and add a positive criterion per pinned sentence, alongside an absence criterion per removed literal including the prose ones.

## Occurrences

- 2026-08-22 — default-spec-sync-on-archive — cash-propose round 1 — tasks 的判準只斷言「舊標題消失」「三個選項 bullet 消失」「舊提問字串消失」，對「預設不帶旗標」「僅在明確要求時帶旗標」「不得從間接訊號推論」零覆蓋——一個把步驟 4 改成「一律帶 `--skip-specs`」的實作會全數通過。同時步驟 4 的散文提問 `If delta specs exist, ask whether to sync them.` 沒有任何 absence 斷言，只改標題、刪 bullet 卻原樣保留該句的實作同樣通過。修法是在 IC 逐字釘住要寫入的整段內容，並把判準分為正向、負向、段落級、保留守則四類。

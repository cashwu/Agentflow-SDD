---
id: diagnostic-channel-not-surfaced-by-host
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-09-06
last_seen: 2026-09-06
links:
  - openspec/changes/add-host-derived-round-lint/reviews/propose-r7.md
---

# Diagnostic written to a channel the host does not surface

A design mitigates a silent-bypass or auditability risk by requiring a diagnostic to be emitted, and names an output channel (stderr, stdout, a log line) plus an exit code, without checking how the hosting runtime actually routes that channel under that exit code. The obligation is satisfiable and testable in isolation, yet the host discards or hides the output on the chosen path, so the mitigation the risk section relies on is void in production while every unit test passes. Distinct from `design-claim-unverified-against-code`: the unverified premise is a host or platform contract, not a fact about this repository's code.

## Occurrences

- 2026-09-06 — add-host-derived-round-lint — cash-propose round 7（seeded re-run）— D6 與 spec 規定每個 fail-open 分支「以 exit 0 結束並向 stderr 輸出 `gate_unavailable`」、重入放行「將未解決失敗項輸出至 stderr 後 exit 0」，並以此作為 R7／R8 的「可稽核」緩解；但 Claude Code 對 Stop hook 的行為是 exit 0 時 stderr 只進 debug log、exit 2 時 stderr 回饋給 Claude、其餘非零 exit 時 stderr 顯示給使用者，因此該診斷在 host 上實際不可見，形同靜默。修法是 fail-open 與有失敗項的放行改為 exit 1，並把 host 的 exit 語意逐字寫入 design 與 spec。

---
id: remedy-trigger-matches-composed-diagnostic
type: recurring-finding
status: open
occurrences: 2
first_seen: 2026-08-20
last_seen: 2026-08-20
links:
  - openspec/changes/tolerate-remount-device-renumbering/reviews/apply-r2.md
  - openspec/changes/tolerate-remount-device-renumbering/reviews/apply-r3.md
  - openspec/changes/tolerate-remount-device-renumbering/reviews/apply-r4.md
---

# Deployed guidance keys a remedy on a classification string that a composed diagnostic also contains

A change classifies a gate's failures and writes deployed guidance that keys a remedy on one classification's literal text. The same change also emits a richer diagnostic for the case where the remedy's precondition does *not* hold — and that richer message is built by prefixing the classification string, so it contains the trigger verbatim. The gate itself is correct: it withholds the remedy on the composed form. The guidance is not, because a reader or agent matching on the trigger string reaches the remedy on both forms, and the composed form is exactly the state the precondition gate exists to block. The defect is invisible while reading the gate's code, since the code never offers the remedy; it only appears when the guidance is applied to the real message text. Two things make it likely: the classification prefix is chosen for machine legibility and then reused as human guidance, and the precondition lives in the implementation contract while the guidance clause is specified separately. Fix by scoping the guidance trigger to the exclusive form ("only when the diagnostic names that record alone") and naming the composed form's substrings explicitly, then pin the operative half — not just the qualifier — with a literal assertion so it cannot be deleted behind a recomputed baseline digest.

## Occurrences

- 2026-08-20 — tolerate-remount-device-renumbering — cash-apply round 2 — 受管 guidance 以字面分類 `stable record identity drift` 作為 `--init-receipt` 的入口條件，而 IC-4 前提不成立時的第三支訊息（launcher `stable record identity drift: <stable>; runtime record drift: <path>. …`、installer `stable receipt identity drift: <stable> in <target>; {runtime|skill} record drift: <path>. …`）逐字含有同一子字串。三位獨立 reviewer 各自提出。修法是回到 `/cash-ingest` 在 IC-12 與 spec requirement 追加限定款，再實作 guidance 補句、literal 斷言與重算 baseline；round 3 兩位 reviewer 以實際訊息做封閉性測試後判定 resolved。過程中另發現只釘住限定半段的 literal 不足——刪掉規範半段並重算 baseline 仍會全綠，因此兩個半段都要釘死。
- 2026-08-20 — tolerate-remount-device-renumbering — cash-apply round 4 — 分離的 trigger 與 remedy assertions 仍允許兩者被搬到無關條款後通過；修正改以單一連續 literal 綁定 `runtime`／`skill` composed diagnostic、還原／可信重裝處置與 `MUST NOT 重新簽發`。

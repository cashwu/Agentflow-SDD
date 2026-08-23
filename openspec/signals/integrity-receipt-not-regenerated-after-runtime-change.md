---
id: integrity-receipt-not-regenerated-after-runtime-change
type: recurring-finding
status: open
occurrences: 4
first_seen: 2026-07-25
last_seen: 2026-08-23
links:
  - openspec/changes/align-cli-skill-contracts/reviews/propose-r1.md
  - openspec/changes/guard-post-archive-commit-allowlist/reviews/propose-r1.md
  - openspec/changes/rightsize-cash-apply-tdd-discipline/reviews/propose-r1.md
  - openspec/changes/add-minimal-solution-discipline/reviews/propose-r1.md
---

# Integrity receipt not regenerated after runtime change

A change edits files whose digests are recorded in an integrity manifest that the launcher verifies on every invocation, but the task list never regenerates the manifest. The first edit disables the very CLI the remaining tasks depend on, including the command the workflow uses to mark its own progress.

## Occurrences

- 2026-07-25 — align-cli-skill-contracts — cash-propose round 4 與 round 5 — 本次改動四個 replaceable runtime 檔卻無重建 receipt 的步驟；補上後又發現排在版本提升之後，實測任務 1.1 落地起 14 個任務期間 cash-apply 的 task done 全部停擺，最終改為每次 runtime 改動後即重建且可重複執行。

- 2026-07-25 — guard-post-archive-commit-allowlist — cash-propose round 1 — 改動 `.cash-skills/lib/cash_cli/commands/archive.py` 卻無重建 `.cash-skills/receipt.tsv` 的步驟，launcher 會以 `receipt_invalid: runtime record drift` 擋下所有後續指令；round 2 再發現重建被排成獨立後續 task 仍不夠，因為標記該 task 完成的 `task done` 就是下一個要執行的 CLI 指令，最終改為併入該 task 自身的收尾步驟。

- 2026-07-26 — rightsize-cash-apply-tdd-discipline — cash-propose round 1 — managed runtime／skill bytes、version bump 與 source receipt 重建原本分屬相鄰 tasks，使第一個修改 task 在 receipt 重建前呼叫 `task done` 時必然收到 `receipt_invalid`；修正為由同一 task 在自身完成前一併 bump 並執行 `./install-cash-skills.fish --self`。

- 2026-08-23 — add-minimal-solution-discipline — cash-propose round 1 — managed `SKILL.md` source edit、variant generation 與 portable manifest publication 原本分屬不同 tasks，且 source edits 被標成 `[P]`；第一個 edit 後的 `task done` 與兄弟 task 的任何 Cash CLI invocation都會因 manifest digest drift fail closed。修正為單一不可分割 task，在任何下一次 Cash CLI invocation 前完成 generation 與 `--self` publication。

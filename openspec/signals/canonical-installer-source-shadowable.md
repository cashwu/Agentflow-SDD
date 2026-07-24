---
id: canonical-installer-source-shadowable
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-24
last_seen: 2026-07-24
links:
  - openspec/changes/replace-spectra-cli-with-cash-cli/reviews/apply-r3.md
---

# Canonical installer source shadowable

An installer derives trusted code or content from a source location that caller arguments or runtime module-search precedence can override, allowing execution to escape the canonical bundle trust boundary.

## Occurrences

- 2026-07-24 — replace-spectra-cli-with-cash-cli — cash-apply rounds 3–5 — Hidden source override 與 hostile cwd Python module shadowing 可取代 canonical installer source；移除 caller-controlled source argument並以 Python safe-path mode 啟動。

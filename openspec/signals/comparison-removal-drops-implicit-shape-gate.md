---
id: comparison-removal-drops-implicit-shape-gate
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-08-20
last_seen: 2026-08-20
links:
  - openspec/changes/tolerate-remount-device-renumbering/reviews/propose-r1.md
---

# Removing a comparison drops the shape gate it was silently providing

A change removes an equality comparison on a persisted field because the comparison itself is unsound. The analysis covers what the comparison was nominally for, but not what else it was incidentally enforcing. When the field is parsed permissively — a bare `int()`, a lenient cast, a regex looser than the documented format — the equality check against a freshly observed value was the only thing rejecting malformed stored values. Delete it and the field loses both gates at once, so values the spec says are illegal now pass. The tell is a spec sentence asserting the field is still validated when the only surviving validation is the permissive parse. Before removing a comparison, enumerate every property that currently fails because of it, not just the property it was written for.

## Occurrences

- 2026-08-20 — tolerate-remount-device-renumbering — cash-propose round 1 — 變更把 `st_dev` 從 receipt stable identity 的比對條件移除。installer 的 receipt parsing 本來就有 `device < 0 or inode <= 0` 的範圍檢核，但 launcher 只有 `int(row[4])`——`-1` 這種值今天之所以被擋，唯一機制就是即將被移除的等值比對。spec delta 同時寫了一條「形狀不合法仍 fail closed」的 scenario，移除後該 scenario 立即不成立。修法是讓 launcher 補上與 installer 相同的範圍判準，並要求該失敗以形狀專屬訊息回報，使該行為有可鑑別的驗證判準。

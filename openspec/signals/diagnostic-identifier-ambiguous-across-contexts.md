---
id: diagnostic-identifier-ambiguous-across-contexts
type: recurring-finding
status: open
occurrences: 1
first_seen: 2026-07-25
last_seen: 2026-07-25
links:
  - openspec/changes/tolerate-versioned-legacy-guidance-marker/reviews/propose-r4.md
---

# Diagnostic identifier ambiguous across contexts

A fix improves a failure diagnostic by attaching an identifier, but that identifier is not unique across the contexts that can raise the same error, so the diagnostic still cannot tell the user which one failed. The fix looks correct in isolation because each call site does pass "its own" value; the ambiguity only appears when the same value is reachable from two different origins.

## Occurrences

- 2026-07-25 — tolerate-versioned-legacy-guidance-marker — cash-propose round 1 的 W7 與 round 4 的 Q5 — IC4 要求 `marker_span` 的例外附上 guidance 相對路徑並由兩個呼叫端「各傳入其 `relative`」，但 `canonical_guidance` 與 `render_guidance` 的 `relative` 是同一組 `AGENTS.md` 與 `CLAUDE.md`，前者指 source bundle 的檔案、後者指 target 的檔案，加上路徑後兩側訊息逐字相同。更嚴重的是 `--all` 批次路徑以 target 路徑為前綴印出錯誤，因此一個 source 端的 marker 失敗會被印成 N 行、每行指控一個不同且無辜的 target。修法是把引數語意由「相對路徑」改為「能唯一識別該 guidance 的標籤」，並要求 source 側傳入帶限定詞的形式。

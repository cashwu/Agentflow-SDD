---
id: detection-criterion-false-positive-on-legitimate-form
type: recurring-finding
status: open
occurrences: 2
first_seen: 2026-07-25
last_seen: 2026-07-25
links:
  - openspec/changes/align-cli-skill-contracts/reviews/propose-r1.md
  - openspec/changes/track-review-loop-outputs-in-allowlist/reviews/propose-r1.md
---

# Detection criterion false positive on legitimate form

A new mechanical check is specified by describing the defect's shape, but the description also matches a legitimate construct that shares that shape, so the check fails on correct files. The criterion is written from the defect alone without enumerating the legitimate forms it must not match, and is adopted without running it against the real corpus.

## Occurrences

- 2026-07-25 — align-cli-skill-contracts — cash-propose round 1 與 round 2 — 空 code span 判準先後兩版都誤判 markdown 合法的雙反引號跳脫；第二版經對 24 個 canonical SKILL.md 實跑後才改為 run 計數形式並取得零偽陽性。

- 2026-07-25 — track-review-loop-outputs-in-allowlist — cash-propose round 1 與 round 2 — 兩個判準都只由缺陷形狀寫成、未列舉必須排除的合法形式：(1) 共用 signal 判定只比對 change 名稱不比對存在性，而 signal 的 `links` 在封存時不會改寫，實測 35 個 signal 檔的 links 跨越多個 change，會把例外裁決訓練成無條件按過；(2) 路徑前綴拒絕寫成整個 `.cash-skills/`，而 `_IGNORED_PREFIXES` 實際只排除 `.cash-skills/state/` 與 `receipt.tsv`，該前綴下有 20 個 git-tracked 來源檔且正是 apply fix-action 最典型的目標。兩者的修法都是把判準對真實 corpus 實跑後收斂。

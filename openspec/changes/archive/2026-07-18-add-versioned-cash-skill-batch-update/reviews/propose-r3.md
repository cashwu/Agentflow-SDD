# Cash Propose Review — Round 3

## Reviewer Findings

### Critical

(none)

### Warning

1. **severity:** Warning  
   **confidence:** 100  
   **layer:** design  
   **location:** `specs/cash-skill-workflows/spec.md`「Only older bundles are updated」與「Equal-version source mutation is an integrity failure」  
   **summary:** Round 2 W1 已修正 installer drift/force scenarios，但 batch 的 equal-version current scenario 未要求 source hashes 符合 receipt，仍可能同時要求 current 與 failed。  
   **recommendation:** batch current scenario 加入 equal-version source/target digests 都符合 receipt 的前置條件，並為 updater 加入 equal-version source mismatch → failed fixture。  
   **disposition:** unresolved-prior  
   **reviewer source:** Reviewer V — Verification

### Suggestion

(none)

## Rating

- Cumulative blocking Critical: 0
- Cumulative blocking Warning: 1
- Non-blocking triaged findings: 0
- `critical_gap`: `false`
- `round_type`: `micro`
- rationale: Reviewer V 已確認 W2、W8、W9 完整解決並自 cumulative blocking set 移除；W1 尚有一個 batch scenario 傳播缺口，因此修正後必須進入位置固定的第 4 輪 full checkpoint。

## Fix Actions

- Verified resolution removal：W2 經 Reviewer V 確認 version introduction commit、unrelated commit spec 與 tasks fixtures 已完整傳播。
- Verified resolution removal：W8 經 Reviewer V 確認 mutation input LF rejection 與 existing retained-control validation 已限縮成可實作契約。
- Verified resolution removal：W9 經 Reviewer V 確認 persisted partial write 與 zero-write clean retry 已分流並有 tasks coverage。
- W1：修改 `specs/cash-skill-workflows/spec.md`，在 batch current scenario 加入 equal-version source/target digests 均符合 receipt 的前置條件，並新增 equal-version source integrity failure 必須回報 failed、零寫入且 aggregate non-zero 的 scenario。
- W1：修改 `tasks.md` 1.2，加入 updater equal-version source/receipt mismatch → failed 的獨立 fixture。
- Post-fix mechanical self-check：spec forbidden-word scan 無結果、equal-version identifiers 已跨 design/spec/tasks grep、`git diff --check` 通過；所有 open signals 均無 `check` 欄位。
- Post-fix validation：`spectra validate add-versioned-cash-skill-batch-update` 通過。

## Decision

next_round

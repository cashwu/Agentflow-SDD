# Cash Propose Review — Round 7

## Reviewer Findings

### Seeded Cumulative Blocking Set Verification

1. **Receipt-less identical 24-skill target adoption — resolved**
   - Reviewer A與Reviewer B皆確認fresh、0/24 receipt-less adoption、partial/conflict，以及known-old receipt migration已由design、Cash CLI delta spec與task fixtures承接。
2. **Touched-state single-source transition — resolved**
   - Reviewer A與Reviewer B皆確認第一次合法import後Cash state成為workflow唯一權威；legacy不再參與allowlist、attribution或merge。
3. **Known-old bootstrap stable-lock recovery — resolved**
   - Reviewer A與Reviewer B皆確認stable lock/launcher發布後永不unlink，lock-only與lock+launcher recovery維持同一inode。

### Critical

1. **Legacy touched cleanup缺少原始檔案identity provenance**
   - severity: Critical
   - confidence: 99
   - layer: design
   - location: `design.md`「Cash-owned touched-state 追蹤 source allowlist」、`specs/cash-cli/spec.md`「Change 與 artifact lifecycle」
   - summary: seeded Round 7新增的single-source cleanup只記錄legacy path與digest；同路徑、同bytes但不同inode的替換檔可能被誤刪，而且「不再讀legacy」與archive cleanup所需的digest reread沒有切清楚。
   - recommendation: import時記錄`st_dev/st_ino`，cleanup以held parent FD、no-follow FD、single-link regular identity、digest及unlink前pathname/FD revalidation驗證；不同inode一律保留。
   - disposition: fix-introduced
   - introduced_by: seeded Round 7 touched single-source cleanup
   - reviewer: adherence

### Independent Quality Review

- Reviewer B未發現其他Critical或Warning，並獨立確認三個seeded blockers均已解決。
- 依full-round disagreement規則，Reviewer A的高信心Critical保留為blocking finding，必須修正後交由下一輪micro-review驗證。

## Rating

- Critical: 1
- Warning: 0
- non-blocking triaged: 0
- critical_gap: true
- round_type: full
- rationale: 三個seeded blockers皆已解決，但本輪修正引入legacy cleanup identity缺口；依規則修正後進入下一輪驗證。

## Fix Actions

- 更新`design.md`與`specs/cash-cli/spec.md`：`legacy_import`精確記錄safe project-relative path、lowercase SHA-256、decimal `st_dev/st_ino`。
- 明確切分workflow authority與cleanup-only reread：Cash state仍是唯一workflow輸入；archive成功後僅能為destructive cleanup執行受限legacy reread。
- cleanup必須使用held parent-directory FD、no-follow open、`fstat` single-link regular file、device/inode/digest match及unlink前pathname/FD revalidation；same-path/same-bytes/different-inode、pathname swap或digest drift皆保留並記錄`legacy_cleanup: preserved_drift`。
- 更新`tasks.md` 2.2 fixtures，覆蓋matching cleanup、same-path/same-bytes/different-inode preserve、pathname swap與digest drift diagnostic。
- Post-fix validation：`spectra validate replace-spectra-cli-with-cash-cli`、`git diff --check`及關鍵契約搜尋皆通過。
- fixed_files: 3

## Decision

next_round

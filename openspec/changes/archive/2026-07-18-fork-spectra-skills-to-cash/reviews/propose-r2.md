# Propose Plus Review — Round 2

## Reviewer Findings

### Verified Resolutions

- `C1` resolved：19 條 retained quality-gate requirements 已完整搬入 cash capability，task 2.4 覆蓋 full/micro、confidence、disposition、accepted risk、signals、ledger 與 abort branches。
- `C2` resolved：Impact 與 live-doc requirement/task 已納入 `CASH-SKILLS.md` 新增及 `SPECTRA-PLUS.md` 移除。
- `C3` resolved：proposal 宣告 `signals-shared-layer`，delta 完整 MODIFY 三條 requirements，README 也有具名 scope/task。
- `W1` resolved：cash override 明定放在 `<!-- SPECTRA:END -->` 後，forced-update fixture 驗證 effective precedence。
- `W2` resolved：cash-commit 保留 tracked sources、confirmed customizations、archive files、explicit spec sync 與 unrelated-file exclusion。
- `W3` resolved：variant parity 使用 exhaustive allowlist normalization 後比較完整 governed bodies。
- `W4` resolved：installer/cleanup 具 canonicalization、unsafe root/HOME、symlink 與 containment fail-closed contract。
- `W5` resolved：cleanup 對兩個 label query/bootout，loaded-without-plist 亦處理，確認 absent 後才刪 registry/cache。

### Critical

None.

### Warning

1. **location:** `specs/cash-skill-workflows/spec.md` 的 signals、ledger 與 deterministic-check requirements
   **summary:** Round 1 完整 contract 遷移仍留下不存在的 `shared review-loop template` 作為 normative implementation target，與 direct canonical files 的 ownership 決策衝突。
   **recommendation:** 改由四份 canonical cash proposal/apply skill files 各自承載相同 governed sections，不再使用 extend/consume shared-template 措辭。
   **confidence:** 100
   **layer:** text
   **disposition:** fix-introduced
   **introduced_by:** Round 1 Fix Actions「完整搬移 19 條 retained quality-gate requirements」。

2. **location:** `specs/cash-skill-workflows/spec.md` 的 round-file example 與 ingest guidance
   **summary:** Round 1 遷移殘留 `Propose Plus Review — Round 2` 範例，並在共同 variant contract 固定使用 `/cash-ingest`，分別違反 cash provenance 與 Claude/Codex invocation 差異規則。
   **recommendation:** heading 改為 `Cash Propose Review — Round 2`；ingest guidance 使用 variant-appropriate `cash-ingest` invocation。
   **confidence:** 100
   **layer:** text
   **disposition:** fix-introduced
   **introduced_by:** Round 1 Fix Actions「完整搬移 19 條 retained quality-gate requirements」。

### Suggestion

None.

## Rating

- unresolved-prior: 0
- fix-introduced: 2 Warning
- genuinely new: 0
- post-filter cumulative blocking set: 0 Critical, 2 Warning
- `critical_gap: false`
- `round_type: micro`
- rationale: Round 1 的八個 blocking members 都有直接 resolution evidence；兩個 confidence 100 的 fix-introduced Warning 依 contract 進入 cumulative blocking set，必須修正並由下一位 Reviewer V 驗證。

## Fix Actions

- Verified-resolution removals：從 cumulative blocking set 移除 Round 1 的 `C1`、`C2`、`C3`、`W1`、`W2`、`W3`、`W4`、`W5`。
- 修改 `specs/cash-skill-workflows/spec.md`：將 signals write、ledger 與 deterministic checks 改成四份 canonical cash skills 直接持有；將 round heading 更新為 cash provenance；把固定 slash command 改成 variant-appropriate `cash-ingest` invocation。
- Post-fix bounded grep：不存在 `shared review-loop template`、`consume this template`、`Propose Plus Review` 或固定 `/cash-ingest` 殘留。
- Post-fix validation：`spectra validate fork-spectra-skills-to-cash` 通過。

## Decision

next_round

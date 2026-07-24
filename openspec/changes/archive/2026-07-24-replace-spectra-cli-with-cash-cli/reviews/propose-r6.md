# Cash Propose Review — Round 6

## Reviewer Findings

### Cumulative Blocking Set Verification

1. master requirements migration — **unresolved** — 舊master「完全相同但無receipt的24-skill legacy target認養」仍未被承接；新adoption要求target已具有Cash launcher、lock與runtime。
2. nested cwd launcher — **resolved**
3. apply/analyze/drift schema — **resolved**
4. touched-state/legacy migration — **unresolved** — lazy import後legacy touched仍保留；`task done`更新Cash state後，下一次ensure會把正常演進誤判成Cash/legacy不等價衝突。
5. sync/archive idempotency/no-sync — **resolved**
6. legacy removal identity — **resolved**
7. launcher mode — **resolved**
8. multi-file transaction/read consistency — **unresolved** — known-old migration rollback會unlink已公開的stable lock；等待程序可能仍持有舊inode，新installer則建立另一inode，破壞單一同步邊界。
9. outer guidance identity — **resolved**
10. `@trace` — **resolved**
11. `spec_dir` — **resolved**
12. lexical symlink containment — **resolved**
13. installer Git/config prerequisites — **resolved**
14. archive flags/transaction — **resolved**
15. MODIFIED+RENAMED phase order — **resolved**
16. fresh config source — **resolved**
17. list/status/artifact instruction schemas — **resolved**
18. live namespace scan boundary — **resolved**
19. existing Cash config validation — **resolved**
20. known-old receipt cutover — **unresolved** — old receipt的精確schema已由本輪機械自我檢查修正並經Reviewer V確認，但bootstrap rollback的double-inode race仍使cutover不安全。
21. fresh lock parent — **resolved**
22. YAML grammar/parser version — **resolved**
23. unsupported active legacy config keys — **resolved**

### Critical

1. **Receipt-less identical 24-skill target的認養契約遺失**
   - severity: Critical
   - confidence: 96
   - layer: design
   - location: `openspec/specs/cash-skill-workflows/spec.md:682-689`, `specs/cash-cli/spec.md`「Receipt-less identical target 被認養」
   - summary: master仍承諾認養只有24個完全相同skills且沒有receipt的legacy target，新契約卻要求新bootstrap/runtime已存在，合併後行為不可達。
   - recommendation: 明確MODIFIED或承接該legacy shape，從read-only 24-skill identity進入與known-old receipt相同的stable bootstrap transaction。
   - disposition: unresolved-prior
   - reviewer: verification

2. **Lazy touched migration沒有建立單一source-of-truth**
   - severity: Critical
   - confidence: 99
   - layer: design
   - location: `design.md`「Cash-owned touched-state 追蹤 source allowlist」, `specs/cash-cli/spec.md`「Change 與 artifact lifecycle」
   - summary: ensure匯入legacy後保留原檔；Cash state的正常後續更新會使兩份資料不等價，下一次ensure永久fail closed。
   - recommendation: 匯入時記錄legacy digest/origin並transactionally retire legacy，或只在未遷移狀態比較；加入`ensure → task done → ensure/commit/archive`fixture。
   - disposition: fix-introduced
   - introduced_by: Round 5 `touched ensure` lazy migration fix
   - reviewer: verification

3. **Known-old bootstrap rollback可能產生兩個lock inode**
   - severity: Critical
   - confidence: 97
   - layer: design
   - location: `design.md`「Installer transaction 同時治理 runtime、skills 與 legacy removal」, `specs/cash-cli/spec.md`「Bundle 安裝與 runtime receipt」
   - summary: rollback移除已公開的project-root lock時，等待程序可能持有舊inode；後續installer可建立新inode，兩群process不再互斥。
   - recommendation: stable lock一旦公開即不得unlink；定義old-receipt加recoverable-lock狀態、pathname/inode revalidation與後續recovery transaction。
   - disposition: fix-introduced
   - introduced_by: Round 5 known-old receipt bootstrap migration fix
   - reviewer: verification

## Rating

- Critical: 3
- Warning: 0
- non-blocking triaged: 0
- critical_gap: true
- round_type: micro
- rationale: 第六輪仍有receipt-less adoption、touched單一來源與stable lock rollback三個blocking Critical；依max-round規則不可繼續下一輪。

## Fix Actions

- 本輪機械自我檢查比對`install-cash-skills.fish`現行receipt parser後，修正`design.md`、`specs/cash-cli/spec.md`與`tasks.md`：known-old schema現為一筆`version<TAB>SemVer`加24筆`sha256<TAB>digest<TAB>path`，Reviewer V follow-up已確認該schema mismatch resolved。
- Post-fix validation：`spectra validate replace-spectra-cli-with-cash-cli`通過；analyzer Coverage、Consistency、Gaps皆Clean。
- Abort triage bucket 1 — remains this change's obligation：receipt-less identical 24-skill adoption、lazy touched single-source transition、known-old bootstrap rollback stable-inode recovery。後續seeded re-run必須以這三項作cumulative blocking set。
- Abort triage bucket 2 — newly discovered non-blocking issues：none。
- Abort triage bucket 3 — accepted trade-offs：none。
- fixed_files: 3

## Decision

aborted

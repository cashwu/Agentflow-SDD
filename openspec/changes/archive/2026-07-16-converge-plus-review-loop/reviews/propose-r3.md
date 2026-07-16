# Propose Plus Review — Round 3

## Reviewer Findings

### Critical

- **C1**（A）severity: Critical｜confidence: 100｜layer: design｜location: proposal.md `## Impact`／tasks.md 1.1、4.2／design 驗收標準 vs scripts/spectra-plus/tests/repair-all-checks.fish
  - summary: spectraPlusVersion bump 至 1.5.0 必然弄壞 repair-all-checks.fish（斷言與 staleness fixture 兩處硬編碼 "1.4.0"/"2026-07-11"），但該檔不在 Impact 清單、task 1.1 只更新 generator-checks.fish 的版本變數、task 4.2 卻斷言它原樣通過——驗收標準不可達。
  - recommendation: Impact Modified 加入該檔，task 1.1 擴充兩檔版本變數更新，task 4.2 措辭同步。

### Warning

（無——其餘 findings 均為 confidence 50–75，依 filter 降為 Suggestion。）

### Suggestion

- **S1**（B，75）re-run 首輪沿用「無 surviving finding 即 pass」條件，seeded cumulative set 成員未被再報告即靜默通過，種子機制在最關鍵處失效。
- **S2**（B，75）abort triage 桶 2 收留未解決的 unresolved-prior findings，成為無需同意的第三出口（種子只含桶 1）。
- **S3**（B，75）出口 (a) 在第 4 輪 checkpoint 無定義——A/B 無驗證義務，r3 修復的成員在 r4 無移除路徑。
- **S4**（A+B，75/50）出口 (a) 移除無留痕義務，與「不留痕即漂白」原則矛盾，集合成員資格無法由 round files 重建。
- **S5**（B，75）confidence < 50「不得出現在 round file」與降分 trace 必須記名衝突，需限縮至 `## Reviewer Findings` 段。
- **S6**（A，75）failure-abort 記 0 計數的 scenario 與 cumulative 計數語意衝突（帶 carryover 的失敗中止應記非零）。
- **S7**（A，75）「裁判面保護成員無迴圈內出口」與出口 (b)（同意接受）矛盾；短路條件未排除可得的同意出口。
- **S8**（A，75）disposition 三值不窮盡：僅匹配前輪分流 note 的 re-report 無值可標。
- **S9**（A，50）action obligation 只覆蓋本輪 surviving findings，未覆蓋 carryover 成員——零動作空轉輪可回歸。
- **S10**（B，50）模板「Round-1 claim verification」按全域編號鎖 round 1，re-run 首輪（如 r7）會跳過 design claim 驗證。
- **S11**（B，50）critical_gap 定義仍為輪內 filter 語言，carryover 輪會出現 criticals=1 卻 critical_gap=false。
- **S12**（B，50）摘錄 fallback 觸發無註記義務，稽核無法得知 reviewer 實際所見。
- **S13**（B，50）全保護短路在 fix 階段才成立時的 round file 寫法未定義。
- **S14**（A，50）proposal/design 的 triage 觸發列舉漏「全裁判面保護短路」。
- **S15**（A，50）round file outline 欄位清單漏 introduced_by。

## Rating

- surviving Critical count: 1
- surviving Warning count: 0
- critical_gap: true
- round_type: full
- rationale: 機制設計經兩輪修復後，僅存的高信度 finding 是具體的測試檔遺漏（repair-all-checks.fish 版本硬編碼），可直接以 repo 現況佐證（confidence 100）；其餘 15 條均為 50–75 信度的邊界收斂項，依 filter 降為 Suggestion。1 Critical → next_round。收斂軌跡 5C/6W → 2C/4W → 1C/0W。

## Fix Actions

- proposal.md：C1 Impact Modified 加入 scripts/spectra-plus/tests/repair-all-checks.fish；S14 triage 觸發列舉補全裁判面保護短路；S2 桶 1 重定義（仍屬本 change 義務者＝fix 回歸＋未經同意的 unresolved-prior）；S1 re-run 首輪採 cumulative set pass 條件。
- specs/spectra-plus-skills/spec.md：S1 首輪 pass 條件於 seeded re-run 改用 cumulative set（兩個 gate＋Graded convergence＋新 scenario「Seeded member blocks a re-run's first round」）；S2 桶 1/桶 2 重定義；S3 第 4 輪 A/B 增 per-member resolved/unresolved 判定義務（scenario 同步）；S4 出口 (a) 移除留痕（成員＋修復引用＋驗證 reviewer）；S5 丟棄條款限縮至 `## Reviewer Findings` 段並明示 trace 例外；S6 failure-abort scenario 增「且 cumulative set 為空」；S7 裁判面保護改「無自主出口、僅同意出口適用」、短路條件加「無可得同意出口」；S8 new 桶涵蓋僅匹配分流 note 者（不重複產生 note 與 signal）；S9 action obligation 擴及計入決策的 carryover 成員；S11 critical_gap 重定義為 cumulative set 含 Critical；S12 摘錄 fallback 使用留一行註記；S13 fix 階段短路時當輪直接記 aborted；S15 outline 補 introduced_by。
- design.md：C1 驗收標準補 repair-all-checks.fish 版本變數；S1–S4、S7–S13 決策同步；S10 Round-1 claim verification 改 run 首輪措辭納入驗收標準。
- tasks.md：C1 task 1.1 擴充兩檔版本變數與 Round-1 claim verification 斷言、task 4.2 措辭；S1/S3/S4/S9/S11/S12/S13 併入 task 2.2 細則；S10 併入 task 2.1。
- 全部 15 條 Suggestion 一併修復。
- 修復後重跑 spectra validate：通過。post-fix self-check：annotation 平衡、repair-all-checks 三 artifact 交叉引用齊備、new 桶定義三 artifact 一致。

## Decision

next_round

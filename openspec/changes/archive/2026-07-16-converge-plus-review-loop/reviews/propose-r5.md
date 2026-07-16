# Propose Plus Review — Round 5

## Reviewer Findings

### Critical

- **C1**（A+B）severity: Critical｜confidence: 100｜layer: text｜location: tasks.md task 2.5 vs proposal／design／specs delta「Abort triage」
  - summary: task 2.5 仍寫「取捨桶無法取得同意時退回 signals 桶」——與其餘三個 artifact 一致規定的「退回桶 1（留在 change、seed 進 re-run）」直接矛盾，照任務實作會把無同意漂白出口寫回模板。
  - recommendation: task 2.5 改寫為桶 1 fallback＋桶 2 排他句。
- **C2**（B）severity: Critical｜confidence: 80｜layer: design｜location: specs delta「Graded convergence」短路條款＋「Abort triage」seeding 條款
  - summary: 全裁判面保護＋無同意的 seeded re-run 不具迴圈安全性：短路條件在零輪次 run 的判定時點未定義（不得 spawn vs triage 必須寫進最終 round file 的義務互相矛盾），且無出口指引，每次 re-run 注定重複 abort。
  - recommendation: 短路於 spawn 前判定、寫一個續號 round file（無 findings、aborted、含 triage）＋一列 ledger，完成輸出導向取得同意或 /spectra-ingest 擴充 scope。

### Warning

- **W1**（A+B）severity: Warning｜confidence: 100｜layer: text｜location: tasks.md task 2.5 觸發列舉與桶 1 措辭
  - summary: task 2.5 觸發清單漏「全裁判面保護短路」、桶 1 仍是修復前的窄定義（fix 回歸），與 proposal／design／spec 的「每個未經同意接受的集合成員」脫節。
  - recommendation: 補列三種觸發、桶 1 改集合成員定義。
- **W2**（A）severity: Warning｜confidence: 100｜layer: design｜location: specs delta scenario「Fully grader-protected blocking set short-circuits to abort」
  - summary: scenario 的 WHEN 只寫「全為裁判面保護」，漏掉規範文字的第二條件「且無可得同意出口」——照 scenario 會在同意出口可用時也強制 abort，與出口 (b) 矛盾。
  - recommendation: WHEN 補上條件，proposal 短句同步。
- **W3**（A+B）severity: Warning｜confidence: 100｜layer: text｜location: proposal「曾分流的 finding 不回升」／specs delta 不回升 scenario／task 2.2
  - summary: 不回升規則的 fix-introduced 證據例外只寫進規範段與 design，scenario 仍是無條件版本、proposal 與 task 2.2 是絕對化表述——artifacts 對自己引入的規則表述矛盾。
  - recommendation: scenario WHEN 加「無新歸因證據」條件，proposal 與 task 2.2 補例外。

### Suggestion

- **S1**（A+B，75/50）cumulative set 成員清單只寫在規範段，V 的 context 列舉、checkpoint scenario、design contract、task 2.2 都漏列。
- **S2**（A，75）proposal 的無動作輪動作選單仍是扁平四選一，未反映 blocking 成員限三種動作的 per-class 拆分。
- **S3**（A+B，50/75）new 標記的 fix-touched location 檢查義務只涵蓋「本 loop」，seeded re-run 中前一 run 的 fix 回歸會漏網；re-run context 只附前 run 最終 round file，前 run fix actions 無從驗證。
- **S4**（B，75）前 run 已記錄修復的種子在 re-run 首輪無出口也無合法動作（首輪 reviewer 原無 per-member 判定義務）。
- **S5**（A，50）checkpoint 判定義務與分歧規則只在 scenario，未入規範句與 task 1.2 斷言。
- **S6**（B，50）new 檢查義務與不回升例外未列入 task 2.2 內容清單與 task 1.2 斷言（TDD 網未鎖住最新條款）。

## Rating

- surviving Critical count: 2
- surviving Warning count: 3
- critical_gap: true
- round_type: full
- rationale: 本輪 findings 全部是前四輪 fix passes 造成的跨 artifact 傳播缺口（task 2.5 滯留舊規則為最典型）與最新條款的邊界情形（零輪次短路），核心機制本體未再出現新缺陷；2 Critical + 3 Warning → next_round。這批 findings 本身即為本 change 要解決的 fix-propagation 問題的實例。

## Fix Actions

- tasks.md：C1/W1 task 2.5 全面改寫（桶 1 fallback＋桶 2 排他、三種觸發、桶 1 集合成員定義、re-run context 全部 round files、首輪 per-member 判定、spawn 前短路與出口指引）；S5/S6 task 1.2 斷言清單與 task 2.2 內容清單補最新條款。
- specs/spectra-plus-skills/spec.md：C2 零輪次短路判定時點、單一續號 round file＋ledger 列、完成輸出出口指引（同意或 /spectra-ingest 擴充 scope）＋新 scenario「Fully protected seeded re-run aborts before spawning reviewers」；W2 短路 scenario WHEN 補「no consented exit obtainable」；W3 不回升 scenario WHEN 補「without new evidence」；S1 V context 列舉與 checkpoint scenario 補成員清單；S3 new 檢查義務擴及前 run fix actions、re-run context 改全部 round files（或摘錄）；S4 seeded re-run 首輪 reviewer 增 per-member 判定義務（出口 (a) 於首輪可用）；S5 checkpoint 判定與分歧規則入規範句。
- proposal.md：W2 短路句補條件；W3 不回升句補例外；S2 動作選單 per-class 改寫；C2 re-run 規則同步。
- design.md：C2 零輪次短路與出口指引；S1 成員清單入 contract；S3 檢查義務擴前 run；S4 首輪判定。
- 全部 6 條 Suggestion 一併修復。
- 修復後重跑 spectra validate：通過。post-fix self-check：annotation 平衡（4/4）、「退回桶 1」四 artifact 一致、tasks 中「signals 桶」殘留清零。

## Decision

next_round

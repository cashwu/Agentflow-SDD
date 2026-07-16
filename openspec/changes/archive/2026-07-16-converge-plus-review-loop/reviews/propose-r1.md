# Propose Plus Review — Round 1

## Reviewer Findings

### Critical

- **C1**（A）severity: Critical｜confidence: 90｜layer: design｜location: specs delta「Graded convergence and micro-verification round」blocking 定義 (a)
  - summary: 曾被分流為 non-blocking 的 finding 在下一輪會經 clause (a)（「前輪尚未解決的 surviving finding」）回升為 blocking，分流機制自我失效。
  - recommendation: 明文排除曾分流 finding 再進入 blocking set，並同步 design 與 tasks。
- **C2**（A）severity: Critical｜confidence: 100｜layer: design｜location: specs delta「Accepted-risks ledger」「Apply-plus introduced-by evidence」vs master「Confidence-scored findings and filter」
  - summary: 新增的 ≤ 25 強制降分與未修改的 master 不變式「direct artifact violation MUST score 100 / SHALL NOT be downgraded below 100」直接矛盾，無優先權宣告。
  - recommendation: 增列 MODIFIED「Confidence-scored findings and filter」宣告降分優先權，並將模板 rubric 句納入任務範圍。
- **C3**（A+B）severity: Critical｜confidence: 100｜layer: design｜location: master「Review loop grader immutability」（宣告範圍例外句與 scenario）；模板 GRADER-IMMUTABILITY 段
  - summary: 本 change 刪除 re-derivation 機制，但未修改的 master requirement 仍規範「remains subject to the existing next-round re-derivation rules」，archive 後成懸空引用；模板對應句也不在任何任務範圍。
  - recommendation: 增列 MODIFIED「Review loop grader immutability」並擴充 task 2.1 涵蓋模板段落。
- **C4**（A）severity: Critical｜confidence: 100｜layer: design｜location: tasks.md task 1.1；design.md 驗收標準 vs scripts/spectra-plus/tests/generator-checks.fish 行 439、441
  - summary: 「移除三條舊斷言」清點不完整——另有兩條 re-derivation 附屬斷言（post-decision 文字同步不確定性、re-derivation note 格式）未列入，驗收標準「全綠」不可達。
  - recommendation: 任務與驗收標準擴充為五條移除清單。
- **C5**（A+B）severity: Critical｜confidence: 85｜layer: design｜location: specs delta blocking 定義 (b) vs「Apply-plus introduced-by evidence」（does not apply to propose-plus）
  - summary: blocking clause (b) 依賴 introduced_by 證據，但該欄位僅 apply-plus Reviewer B 有義務提供——Reviewer V 與 propose-plus reviewers 無標記通道，fix 引入的回歸在這些輪次結構上無法成為 blocking。
  - recommendation: 引入 per-finding disposition 標記（unresolved-prior／fix-introduced／new）適用兩個 skill 的首輪之後所有 reviewer，並提供 prior round files 作為判定依據。

### Warning

- **W1**（A）severity: Warning｜confidence: 100｜layer: design｜location: tasks.md task 3.2 vs generator-checks.fish fingerprint 協定與 plus_version 變數
  - summary: 「--fingerprints 輸出含 1.5.0」驗證不可達（fingerprint 輸出不含版本字串），且版本 bump 會使測試內 plus_version "1.4.0"／plus_updated 變數轉紅而未列入任務。
  - recommendation: 驗證改為生成 frontmatter 斷言；任務補測試變數更新。
- **W2**（A）severity: Warning｜confidence: 90｜layer: design｜location: 模板「Decision record requirements」vs delta pass 語意
  - summary: 模板「do not pass a round that has a surviving Critical or Warning finding」與新語意（non-blocking 存在仍可 pass）矛盾，該段不在任何任務範圍。
  - recommendation: task 2.2 擴充改寫該句為 blocking 版本。
- **W3**（A+B）severity: Warning｜confidence: 100｜layer: design｜location: specs delta「Review round action obligation」vs「Fix-loop design circuit breaker」
  - summary: action obligation 將 needs-design note 列為 next_round 合法動作，但斷路器規定記錄該 note 的輪次必為 aborted——兩需求互斥，留下持續 looping 的文字依據。
  - recommendation: 自 next_round 動作清單移除 needs-design 並明文互斥。
- **W4**（A+B）severity: Warning｜confidence: 100｜layer: design｜location: master「Review loop ledger output」append 時序句
  - summary: ledger requirement 與模板仍以「any re-derivation note」定序 append 時點，本 change 廢除該 note 類型後成懸空引用。
  - recommendation: 增列 MODIFIED「Review loop ledger output」刪除該片語。
- **W5**（A）severity: Warning｜confidence: 100｜layer: text｜location: specs delta MODIFIED「spectra-apply-plus quality gate」archive 指引 scenario
  - summary: MODIFIED block 未宣告改寫：master「may suggest archiving the change」被靜默改為「is permitted to suggest」。
  - recommendation: 還原 master 原文。
- **W6**（B）severity: Warning｜confidence: 100｜layer: design｜location: proposal.md 無動作輪 bullet vs specs delta「Review round action obligation」動作清單
  - summary: proposal 將 accepted-risk 分流列為合法動作，spec 清單卻未含，artifacts 對「該輪能否前進」定義不一致。
  - recommendation: spec 動作清單納入「經同意記錄的 accepted-risks 條目」，兩處對齊。

### Suggestion

- **S1**（A+B，降分自 Critical/Warning 75）斷路器未限定 apply-plus，propose-plus 中觸發即自我指涉。
- **S2**（B，75）blocking 不具黏性：裁判面保護或未被 V 再報告的 blocking finding 會漏出集合導致靜默 pass。
- **S3**（B，75）passed 輪可帶 non-blocking Critical，critical_gap／ledger 計數語意未定義，不可稽核。
- **S4**（A，70）accepted-risks 治理僅涵蓋建立，未防 loop 中修改／刪除條目。
- **S5**（B，75）accepted-risks 降分套用無留痕即漂白通道。
- **S6**（B，75）abort triage 只存在於暫態完成輸出，re-run 會覆寫 round files 摧毀分流記錄。
- **S7**（B，75）跨輪 finding 身分匹配規則未定義，blocking 判定落入無記錄的主觀判斷。
- **S8**（A，60）critical_gap: true 併 passed 的新狀態無 artifact 承認。
- **S9**（B，50）accepted-risks location 行號揮發，後續修改使匹配靜默失效。

## Rating

- surviving Critical count: 5
- surviving Warning count: 6
- critical_gap: true
- round_type: full
- rationale: 兩位 reviewer 獨立指出 delta 機制的四個結構性漏洞（分流回升、blocking 漏出、證據通道缺口、降分優先權衝突）與兩處 master spec 懸空引用，均可直接引用 artifact 條文或 repo 現況佐證（confidence ≥ 85），依機械規則 5 Critical + 6 Warning → next_round。

## Fix Actions

- specs/spectra-plus-skills/spec.md：全面重寫——C1/C5/S2/S7 以 disposition 欄位（unresolved-prior／fix-introduced／new，同檔＋同機制匹配、行號 advisory）與 cumulative blocking set 重新定義 blocking，曾分流 finding 明文不回升，首輪之後 reviewer context 必附全部 prior round files；C2 增列 MODIFIED「Confidence-scored findings and filter」宣告降分優先權；C3 增列 MODIFIED「Review loop grader immutability」改寫宣告範圍例外句與 scenario；W4 增列 MODIFIED「Review loop ledger output」刪除 re-derivation note 引用並定義 blocking 計數；W2/S3/S8 增列 MODIFIED「Round file output contract」（Rating 記 blocking 計數＋non-blocking 分流數、disposition 欄位入 outline）；W3/W6 修正「Review round action obligation」動作清單（納入 accepted-risks 條目、needs-design 明文互斥）；W5 還原「may suggest archiving the change」原文；S1 斷路器限定 apply-plus 並增 propose-plus scenario；S4/S5/S9 accepted-risks 增修刪同意、fix action 禁改、降分留痕、行號 advisory；S6 abort triage 寫入最終 round file、re-run 續號不覆寫。
- design.md：同步全部上述決策（輪型推導 run 內位置化、blocking/disposition 決策改寫、斷路器 scoping、abort triage 持久化與 re-run 規則、動作清單、驗收標準五條移除清單與 frontmatter 驗證、風險節新增 disposition 誤標風險）。
- proposal.md：What Changes 六個 bullet 同步（disposition／cumulative blocking set、斷路器限 apply-plus、triage 持久化與 re-run 續號、動作清單、降分優先權與留痕）。
- tasks.md：task 1.1 擴為五條移除清單＋plus_version/plus_updated 變數；task 2.1 涵蓋 GRADER-IMMUTABILITY／LOOP-LEDGER-STEP 殘留句；task 2.2 涵蓋 disposition／cumulative set／Rating 計數／Decision record requirements；task 2.3 涵蓋治理與留痕與 rubric 優先權句；task 2.4 scoping；task 2.5 持久化與 re-run；task 2.7 動作清單；task 3.2 驗證改 frontmatter 斷言（C4/W1/W2/W3/W6 對應）。
- 所有 9 條 Suggestion 均一併修復（S1–S9 對應上述條目）。
- 修復後重跑 spectra validate "converge-plus-review-loop"：通過。post-fix mechanical self-check：annotation 平衡（4/4）、disposition 值拼寫四 artifact 一致、五條／15 門檻／1.5.0 計數一致。

## Decision

next_round

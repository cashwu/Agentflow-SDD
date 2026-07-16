# Propose Plus Review — Round 2

## Reviewer Findings

### Critical

- **C1**（B）severity: Critical｜confidence: 85｜layer: design｜location: specs delta「Graded convergence and micro-verification round」disposition 定義與不回升規則
  - summary: 「unresolved-prior 需無已記錄修復」的定義讓「記錄一個無效 fix」把未解決的 blocking finding 洗進 `new` 桶並經不回升規則永久鎖為 non-blocking，loop 可帶著已知未修 Critical 通過。
  - recommendation: unresolved-prior 改為不看 fix 記錄（re-report 即證據）；new 桶排除匹配前輪 blocking finding 者；集合移除需下一輪驗證。
- **C2**（A+B）severity: Critical｜confidence: 80｜layer: design｜location: specs delta cumulative blocking set vs「Accepted-risks ledger」「Review round action obligation」
  - summary: cumulative set 唯一出口是「已記錄修復」，經同意的 accepted-risks 條目無法移除成員——同意接受的 finding 仍把 run 逼到 cap-abort，旗艦出口失效。
  - recommendation: 明定兩條移除事件（驗證解決／同意接受，每輪重比對 ledger 並留 trace），裁判面保護成員明文持續存在。

### Warning

- **W1**（A）severity: Warning｜confidence: 100｜layer: design｜location: tasks.md task 1.1／design 驗收標準 vs generator-checks.fish 行 440
  - summary: 移除清單漏第六條斷言 '(or, for apply-plus, any implementation-file modification)'（僅存在於被刪的 re-derivation 句），另 'surviving Critical'/'surviving Warning' 兩條字串斷言需按 blocking 措辭檢查。
  - recommendation: 清單擴為六條並列入兩條字串斷言檢查。
- **W2**（A+B）severity: Warning｜confidence: 100｜layer: design｜location: master「Fresh sub-agent per round」（未列 MODIFIED）
  - summary: 該 requirement 規定決策「from the filtered findings without any further sub-agent call」，與 cumulative blocking set 決策依據矛盾（未再報告的成員也計入決策），Reviewer V 描述亦停留在 fix verification；proposal 只宣告兩處殘留引用、漏此第三處。
  - recommendation: 增列 MODIFIED「Fresh sub-agent per round」，決策推導句改引 cumulative blocking set。
- **W3**（A+B）severity: Warning｜confidence: 80｜layer: design｜location: specs delta「Round file output contract」「Review loop ledger output」計數定義
  - summary: Rating/ledger 計數為輪內報告值而決策依據是 cumulative set——carryover 輪次會記出 criticals=0 卻 next_round 的自相矛盾 ledger 列。
  - recommendation: 計數改為 post-filter cumulative blocking set（決策依據本身）。
- **W4**（B）severity: Warning｜confidence: 80｜layer: design｜location: specs delta「Apply-plus introduced-by evidence」vs confidence filter 丟棄門檻
  - summary: introduced_by 降分（≤ 25 < 50）使被降的 Critical 完全消失無痕跡，且多 fix 交互回歸（第 4 輪 checkpoint 的核心目標）常無單一 hunk 可引，會被降分規則吞掉。
  - recommendation: 降分留痕於 Fix Actions＋完成輸出；introduced_by 允許引用 fix action 集合。

### Suggestion

- **S1**（A，75）兩個 quality gate 的修復義務例外句未涵蓋 accepted-risks 同意路徑。
- **S2**（A，75）prior round files 成為 gate input 但無回改防護，主 agent 可回填 fix 記錄竄改集合。
- **S3**（A+B，75）第 4 輪 checkpoint dedupe 時 disposition 分歧無合併規則，可任選 non-blocking 標記。
- **S4**（B，75）主 agent 更正 disposition 無留痕義務，blocking→non-blocking 更正即無痕漂白。
- **S5**（B，75）全裁判面保護的集合使結局註定仍空轉燒滿 6 輪，缺立即短路。
- **S6**（B，75）re-run 重置 cumulative set，bucket-1 findings 依賴首輪抽樣重新發現，可被洗成 new。
- **S7**（B，50）Round file language keep-verbatim 清單缺 disposition/introduced_by。
- **S8**（B，50）granularity 計數未定義 (none) 佔位行與目錄條目。
- **S9**（B，50）全 prior round files 的 context 成長無上限、無 fallback。
- **S10**（B，50）非互動環境 bucket 3 不可達，triage「exactly one of three buckets」不可滿足。

## Rating

- surviving Critical count: 2
- surviving Warning count: 4
- critical_gap: true
- round_type: full
- rationale: r1 修復把機制骨架補齊後，本輪 findings 集中在 cumulative blocking set 的出入口定義（無效 fix 洗白、accepted-risks 無移除路徑）與第三處 master 懸空引用；2 Critical + 4 Warning 依機械規則 next_round。相比 r1（5C/6W）明顯收斂。

## Fix Actions

- specs/spectra-plus-skills/spec.md：C1 重寫 disposition 定義（unresolved-prior 不看 fix 記錄、re-report 即證據、new 桶排除匹配前輪 blocking finding 者）＋新增「Ineffective fix keeps the finding blocking」scenario；C2 明定集合兩條移除事件（驗證解決／同意接受，每輪重比對、留 trace）＋新增移除 scenario；W2 增列 MODIFIED「Fresh sub-agent per round」（決策推導句改引 cumulative blocking set、Reviewer V 改 delta verification）；W3 Rating/ledger 計數改 post-filter cumulative blocking set＋新增 carryover ledger scenario；W4 introduced_by 降分留痕＋fix action 集合引用形式＋新增 interaction regression scenario；S1 兩個 gate 例外句補 accepted-risks 路徑；S2 新增 round file 不可回改規則＋scenario；S3 disposition 合併規則（blocking 值勝出）＋scenario；S4 更正留痕＋scenario；S5 全保護短路 abort＋scenario；S6 re-run 集合以 bucket-1 為種子（Abort triage）；S8 granularity 計數排除 (none)、目錄計 1；S9 context 摘錄 fallback；S10 同意不可得退 bucket 2＋scenario。
- design.md：同步全部上述決策（disposition 定義修正、集合出入口、短路、留痕、fallback、種子、第三處 master 引用、驗收標準六條斷言清單、keep-verbatim 清單、風險節三條新增）。
- proposal.md：Delta 收斂與 Pass 條件 bullet 同步（三處 master 引用、集合出口、短路、round file 不可回改、introduced_by 集合引用、bucket-1 種子、同意 fallback）。
- tasks.md：task 1.1 六條移除清單＋兩條字串斷言檢查；task 2.1 補「Fresh sub-agent per round」；task 2.2 補 disposition 細則／集合出入口／短路／不可回改／摘錄 fallback／keep-verbatim；task 2.5 補 fallback 與種子；task 2.6 補留痕與集合引用與 keep-verbatim；task 3.1 補計數定義。
- 全部 10 條 Suggestion 一併修復。
- 修復後重跑 spectra validate：通過。post-fix self-check：annotation 平衡（4/4）、disposition 拼寫一致、「Fresh sub-agent per round」四 artifact 交叉引用齊備。

## Decision

next_round

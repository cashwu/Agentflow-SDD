# Propose Plus Review — Round 4

## Reviewer Findings

（本輪首次 spawn 的兩個 reviewer 因 session limit 同時中斷，依 failure handling 視為單一角色失敗、重試一次成功。）

### Critical

- **C1**（A+B）severity: Critical｜confidence: 100｜layer: design｜location: specs delta「Abort triage」同意 fallback vs 桶 2 定義；design「Abort 強制 triage」；proposal bullet 5
  - summary: 「無法取得同意時退回 bucket 2」與桶 2 自身定義（從未 blocking）直接衝突，且桶 2 不進 re-run 種子——非互動 run 中主 agent 可單方面把 blocking finding 提名為「取捨」洗進 signals，形成無需同意的第三出口；design 的防護句（桶 2 不收 blocking）未寫進 delta spec。
  - recommendation: fallback 改指向桶 1（留在 change、seed 進 re-run）＋桶 2 排他句寫入 spec。

### Warning

- **W1**（A+B）severity: Warning｜confidence: 100｜layer: design｜location: specs delta「Fresh sub-agent per round」「Round file output contract」「Review loop ledger output」「Confidence-scored findings and filter」首輪括號句
  - summary: seeded re-run 首輪例外（採 cumulative set pass 條件、標 disposition）只寫進 Graded convergence 與兩個 gate，四個兄弟 requirement 的首輪語句仍假設「首輪 surviving 即 blocking／disposition 僅存在於首輪之後」，literal follower 會忽略未被再報告的種子。
  - recommendation: 四處括號句補 seeded re-run carve-out，disposition 欄位註記同步。
- **W2**（A）severity: Warning｜confidence: 100｜layer: text｜location: design.md 範圍邊界
  - summary: in-scope 清單漏 scripts/spectra-plus/tests/repair-all-checks.fish（proposal Impact 與 tasks 均已納入），以範圍邊界為約定的實作者會視其為 out of scope。
  - recommendation: 範圍邊界補列該檔。

### Suggestion

- **S1**（A，75）fix-introduced 依賴 apply-plus 專屬的 introduced_by 欄位，V 與 propose-plus reviewer 無標記通道，該值文字上不可達。
- **S2**（B，75）new/fix-introduced 邊界完全取決於 reviewer 是否附引用；漏附一次＋不回升規則＝fix 回歸永久洗進 signals。
- **S3**（B，75）re-run 的 fix-introduced 限定「本 loop」，前一 run 的 fix 回歸在 re-run 中只能標 new，種子外的 fix 損害不擋 pass。
- **S4**（B，70）per-member 判定協定未給 reviewer 集合成員清單、checkpoint 兩位 reviewer 判定分歧無合併規則。
- **S5**（B，70）action obligation 允許對 blocking 成員記 triage note 充當動作，空轉輪可以 note 換過關。
- **S6**（B，65）三輪 fix pass 新增的模板義務（per-member 判定、不可回改、摘錄註記、seeded 首輪條件、短路）未列入 tasks 1.1/1.2 斷言清單。
- **S7**（B，60）桶 1 用 disposition 詞彙定義，無 disposition 的族群（首輪 abort、carryover）字面上無桶可歸。
- **S8**（B，50）短路條件的「(or otherwise has no removal path)」括號未定義，可被拉伸為提前 abort 的藉口。
- **S9**（A，50）「repair-all-checks.fish 兩處硬編碼」措辭不精確（實為共用變數兩處取用）。

## Rating

- surviving Critical count: 1
- surviving Warning count: 2
- critical_gap: true
- round_type: full
- rationale: 本輪 findings 全部集中在前三輪 fix 新增的條款（同意 fallback、seeded re-run carve-out 傳播、範圍邊界同步），核心機制未再出現新漏洞；1 Critical + 2 Warning → next_round。軌跡 5C/6W → 2C/4W → 1C/0W → 1C/2W。

## Fix Actions

- specs/spectra-plus-skills/spec.md：C1 fallback 改桶 1＋「Bucket 2 MUST NOT receive any finding that was blocking」＋scenario 改寫（Unavailable consent keeps the finding with the change）；W1 四處首輪括號句補 seeded re-run carve-out、disposition 欄位註記同步；S1/S2 fix-introduced 改為「finding 內附 fix action 引用」（所有 reviewer 適用）＋主 agent 對 new 標記負「檢查 location 是否被 fix 改過」義務＋不回升規則加 fix-introduced 例外；S3 fix-introduced 於 seeded re-run 含前一 run 的 fix actions；S4 reviewer context 附集合成員清單＋任一 unresolved 即保留；S5 blocking 成員合法動作限三種（fix／裁判面保護／同意條目），triage note 對 blocking 成員無效；S7 桶 1 改集合成員定義；S8 刪除未定義括號（needs-design 由斷路器處理）。
- design.md：C1/S5/S7/S8 決策同步；W2 範圍邊界補 repair-all-checks.fish；S1–S4 決策同步；S6 驗收標準斷言清單擴充；S9 措辭修正。
- proposal.md：C1 fallback 與桶 1 定義同步。
- tasks.md：S6 task 1.2 斷言清單擴充；S9 task 1.1 措辭修正。
- 全部 9 條 Suggestion 一併修復。
- 修復後重跑 spectra validate：通過。post-fix self-check：annotation 平衡（4/4）、桶定義三 artifact 一致。

## Decision

next_round

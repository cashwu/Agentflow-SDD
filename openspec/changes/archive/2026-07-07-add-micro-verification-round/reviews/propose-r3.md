# Propose Plus Review — Round 3

## Reviewer Findings

### Critical

（無）

### Warning

1. severity: Warning｜confidence: 90｜reviewer: B
   - location: design.md「Risks / Trade-offs」第三點 vs 決策二「fix 後改判（單向）」、delta spec ADDED requirement 第二段
   - summary: Round 2 新增 fix 後改判規則後，Risks 第三點仍宣稱輪型判斷「純機械……不引入自由裁量」—— 輸入集合漏列「fix 的實際內容」這個主 agent 自由裁量判斷，屬 R2 Fix Action 的傳播缺口，且新裁量點（主 agent 既做 fix 又自評 fix 性質，有省 token 動機）未被任何 Risks 條目記載或緩解。
   - recommendation: 更新 Risks 第三點，承認唯一非機械裁量點並列出對應防線。

### Suggestion

1. severity: Suggestion｜confidence: 75｜reviewer: B（原 Warning，confidence ∈ [50, 80) 降級）
   - location: delta spec ADDED requirement 第二段、design 決策二、tasks 1.2
   - summary: fix 後改判判準（是否僅為文字同步）缺保守 tie-breaker —— layer 分類有「分不清楚一律 `design`」，結構同型的改判判準卻沒有對稱規則，省成本動機恰落在無 tie-breaker 的一側。
   - recommendation: 補「無法確定時 MUST 視同改動行為並改判 full」的對稱規則，task 3.1 加斷言。
2. severity: Suggestion｜confidence: 75｜reviewer: B（原 Warning，confidence ∈ [50, 80) 降級）
   - location: delta spec ADDED requirement 第一段、MODIFIED「Fresh sub-agent per round」（dedup by `location + summary`）、design 決策一
   - summary: A+B 對同一 finding 標出不同 `layer` 時合併取值無規則（主 agent 覆核只 scoped 到標 `text` 的 finding，合併分類正是未定義的一步；R1 實際出現 3 條 A+B finding）。
   - recommendation: 明文規定合併規則：任一 reviewer 標 `design` 即取 `design`。
3. severity: Suggestion｜confidence: 60｜reviewer: B
   - location: delta spec ADDED requirement 第二段「provisional until the round's fix actions complete」vs 模板 Fix actions 段（validate 重跑條款）
   - summary: 改判窗口以「fix actions 完成」為界，fix 後的機械自檢修正與 propose-plus validate 錯誤修正落在窗口外，若這些修正改動行為敘述則暫定 micro 輪不會被改判。
   - recommendation: 窗口改為「decision 記錄後至下一輪 reviewer spawn 前的任何 artifact 修改」。
4. severity: Suggestion｜confidence: 55｜reviewer: A
   - location: 模板「Reviewer output requirements」段首句 "Both reviewers" vs tasks 1.1/1.3
   - summary: 該段首句的雙 reviewer 假設措辭未被任何 task 點名改寫，微型輪下 Reviewer V 的 finding 分類義務有措辭真空（與 r2-S5 同類漏改風險）。
   - recommendation: task 1.1 明文涵蓋該句輪型中立化。
5. severity: Suggestion｜confidence: 55｜reviewer: A+B
   - location: proposal.md「What Changes」第 2 點 vs design/delta/tasks 的 iff 條件；delta spec Scenario「Text-only Warnings trigger a micro round」
   - summary: proposal 第 2 點漏列「且本輪為全量輪」條件（字面上與「微型輪不得連續」矛盾）；Text-only scenario 的 THEN 無條件斷言 micro，未帶改判暫定性限定。
   - recommendation: proposal 補條件；scenario THEN 改為 "derived as a micro round, provisional until the next round's reviewers are spawned"。
6. severity: Suggestion｜confidence: 50｜reviewer: B
   - location: design 決策二/決策三、delta spec、模板 Decision record requirements
   - summary: micro→full 改判事件無記錄要求，事後無法稽核 anti-gaming 規則是否被觸發或略過。
   - recommendation: 改判發生時在本輪 `## Fix Actions` 末尾記一行改判註記。

## Rating

- surviving Critical: 0
- surviving Warning: 1
- critical_gap: false
- round_type: full
- rationale: 本輪 Reviewer A 首次呼叫停滯失敗，依失敗處理規則同輪 fresh retry 一次成功（單一角色失敗，未達 abort 門檻）。Reviewer A（retry）確認前兩輪 17 條修正全部落地且傳播到位、6 個 MODIFIED 與 master 逐句一致、design 程式碼主張全數屬實，僅回報 3 條文字級 Suggestion。Reviewer B 抓到 1 條 confidence 90 的 Warning：R2 新增改判規則後 design Risks 的「純機械、無自由裁量」主張未同步（修正傳播缺口），另 5 條 Suggestion（2 條由 75 降級，均為規則洞補強：改判 tie-breaker、A+B layer 合併規則）。依機械規則 surviving Warning ≥ 1 即 `next_round`。

## Fix Actions

全部 1 條 Warning 與 6 條 Suggestion 均已修正：

1. （W1）design.md Risks 第三點改寫：承認 fix 後改判判準為唯一非機械裁量點（含主 agent 省成本動機），列出三道防線（保守 tie-breaker、micro→full 單向、改判註記強制記錄）。
2. （S1）delta spec ADDED requirement 補保守 tie-breaker 句與 Scenario「Uncertain fix nature escalates to a full round」；design 決策二、proposal、tasks 1.2、tasks 3.1 斷言清單同步。
3. （S2）delta spec ADDED requirement 補 A+B 合併取 `design` 規則與 Scenario「Divergent layer values merge conservatively」；design 決策一、tasks 1.1、tasks 3.1 斷言清單同步。
4. （S3）改判窗口改為「decision 記錄後至下一輪 reviewer spawn 前的任何 artifact 修改（fix action、機械自檢修正、validate 修正）」；delta spec 正文與 escalate scenario、design 決策二、proposal、tasks 1.2 同步。
5. （S4）tasks 1.1 明文涵蓋「Reviewer output requirements」段首句等雙 reviewer 假設措辭的輪型中立化；design 決策四同步。
6. （S5）proposal 第 2 點補「且本輪為全量輪」；delta spec Text-only scenario THEN 改為 "derived as a micro round, provisional until the next round's reviewers are spawned"。
7. （S6）改判註記要求寫入 delta spec ADDED requirement 正文與 escalate scenario、design 決策二、proposal、tasks 1.2。

修正後已重跑：`spectra validate` ✓、機械自檢（註解配對、計數 1 ADDED + 6 MODIFIED、tie-breaker／改判註記／合併規則在各 artifacts 的傳播檢查）✓。

## Decision

next_round

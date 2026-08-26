# Cash Propose Review — Round 1

## Reviewer Findings

### Critical

- severity: Critical；confidence: 90；layer: design；location: tasks.md（1.1、1.2、2.1 與 3.2 的排序）＋ design.md C5／Risks；summary: SKILL.md 修改與 manifest 重簽（原 task 3.2）之間存在 CLI fail-closed 窗口，期間任何 Cash CLI 呼叫（含 `task done`）都會以 manifest digest drift 失敗，任務排序保證觸發；recommendation: 在 tasks 1.1／1.2／2.1 各自的 generate 步驟後、任何下一次 Cash CLI 呼叫前內嵌 `./install-cash-skills.fish --self`，並於 design 記錄窗口規則；reviewer source: Reviewer B

### Warning

- severity: Warning；confidence: 85；layer: design；location: design.md C4／Decision 6 ＋ delta spec `cash-apply 品質關卡結束回報 loop-ledger 摘要`；summary: 「本次 loop run」的列在 ledger 中無可導出的邊界（schema 無 run 識別欄、`(skill, round)` 非唯一鍵、re-run 列同檔累積），N 與 M 的選取規則未定義；recommendation: 明定 N／M 以主 agent 本次 run 寫入的紀錄為權威來源，ledger 讀取僅作核對；reviewer source: Reviewer A ＋ Reviewer B（同一 defect mechanism 聚合）
- severity: Warning；confidence: 80；layer: design；location: proposal.md「Proposed Solution」第 2 點末句 vs design.md C2「下游」條款；summary: proposal 寫「後續 tasks 的 `red` 欄位依該值撰寫」與 design C2「`red` 欄位語意不變（toggle-independent）」矛盾，proposal 是孤立矛盾點；recommendation: 修 proposal 該句為與 design C2 一致的表述；reviewer source: Reviewer A
- severity: Warning；confidence: 80；layer: design；location: delta spec `cash-propose 記錄 change-level TDD 選擇` ＋ design.md C2；summary: propose 的 continue／再入路徑未定義——對已存在的 change 不重跑 `new change`，C2 觸發點永不成立，change 將永遠沒有 `tdd:` 行；「恰好一次」亦無跨 session 的機械判準；recommendation: 詢問前先檢查 `.openspec.yaml` 是否已有 `tdd:` 行，已有則跳過（機械判準），continue 路徑缺行時補問；reviewer source: Reviewer B

### Suggestion

- severity: Suggestion；confidence: 70；layer: design；location: delta spec ledger requirement 正文 vs scenario；summary: 警訊判準在正文（run 輪數）與 scenario（round 編號）間漂移，re-run 情境分歧；recommendation: 統一為 run 內位置計數並修正 scenario 措辭；reviewer source: Reviewer A（原 confidence 70，依過濾器降為 Suggestion）
- severity: Suggestion；confidence: 70；layer: design；location: design.md C3 ＋ delta spec MODIFIED requirement 解析順序；summary: 同檔多個 `tdd:` 行時的生效值未定義；recommendation: 明定 first-match wins（與 `_created` 前例一致）；reviewer source: Reviewer A ＋ Reviewer B（聚合，取較高 confidence 70，依過濾器為 Suggestion）
- severity: Suggestion；confidence: 65；layer: design；location: delta spec 兩個 ADDED requirements vs design C5(c)(d)；summary: 兩個 ADDED requirements 缺具名群組治理 scenario，「恰好一次」「不改 `.cash.yaml`」無對應 scenario；recommendation: 各加治理 scenario 並補條款對應；reviewer source: Reviewer A（降為 Suggestion）
- severity: Suggestion；confidence: 65；layer: design；location: delta spec ledger requirement 的 `/cash-ingest` literal ＋ design C5(d)；summary: 警訊文字含 invocation prefix literal，`.agents` 變體經 generate 轉換後與 requirement 字面衝突，且 ledger 段不在 parity SECTIONS 錨點內；recommendation: 改用 prefix-中立表述並約束斷言字串；reviewer source: Reviewer A（降為 Suggestion）
- severity: Suggestion；confidence: 85；layer: design；location: design.md C5(d) ＋ tasks.md 1.2 負向斷言；summary: 負向斷言字串未指定，直覺候選（`loop-ledger.tsv`、`fixed_files`）在 cash-propose 變體因 shared review-gate block 本來就存在，選錯會使斷言永久失敗；recommendation: 指定鎖定摘要步驟特有文字且不得用 shared block 既有字串；reviewer source: Reviewer B（severity 原生 Suggestion）
- severity: Suggestion；confidence: 60；layer: design；location: proposal.md Non-Goals ＋ design.md；summary: TDD 選擇在 propose 之後無被定義的變更管道，手改 `false`→`true` 會使既有 `red: N/A` 與 canonical classification 矛盾、觸發 unclear-task branch，後果未言明；recommendation: 記錄後果與連動義務或宣告不可變；reviewer source: Reviewer B

## Rating

- 過濾後累積 blocking 集合 Critical 數：1
- 過濾後累積 blocking 集合 Warning 數：3
- 非阻塞 triaged finding 數：6
- critical_gap: true
- round_type: full
- 理由：首輪（unseeded）全部存活的 Critical 與 Warning 皆為 blocking。manifest fail-closed 窗口是排序保證觸發的工作流缺陷（Critical），另有三個 Warning 涉及 run 邊界、artifact 矛盾與 continue 路徑缺口，均需修正後由下一輪驗證，故 decision 為 next_round。

## Fix Actions

1. （Critical：manifest 窗口）tasks.md 1.1／1.2／2.1 各自內嵌「generate 後、任何下一次 Cash CLI 呼叫前執行 `./install-cash-skills.fish --self`」並將 `.cash-skills/manifest.tsv` 加入 delivery；3.2 改為最終冪等收尾；design.md C5 新增 manifest 同步窗口規則、Risks 新增窗口風險；proposal.md 第 5 點同步。修改檔案：tasks.md、design.md、proposal.md。
2. （Warning：run 邊界）design.md C4 明定 N／M 以主 agent 本次 run 寫入的 round files 與 ledger 列為權威來源、ledger 讀取僅核對尾端列；失敗模式改為「印警告、摘要仍以 run 紀錄回報」；delta spec ledger requirement 正文與 scenario（含新增 re-run scenario、ledger 缺失或不一致 scenario）同步；proposal.md 第 4 點同步；tasks.md 1.2 同步。修改檔案：design.md、specs/cash-skill-workflows/spec.md、proposal.md、tasks.md。
3. （Warning：proposal red 句矛盾）proposal.md 第 2 點末句改為「tasks 的 `red` 欄位撰寫規則不變（toggle-independent）；apply 時是否以 `red` 對照 canonical classification 依生效值判定」。修改檔案：proposal.md。
4. （Warning：continue 路徑）design.md C2 新增前置檢查（已有 `tdd:` 行跳過＝「恰好一次」機械判準；continue 缺行補問）；delta spec propose requirement 正文改寫並新增「已有 tdd 行時跳過詢問」「continue 路徑缺行時補問」兩個 scenario；proposal.md 第 2 點、tasks.md 2.1 同步。修改檔案：design.md、specs/cash-skill-workflows/spec.md、proposal.md、tasks.md。
5. （Suggestion：警訊判準漂移）統一為 run 內位置計數：design Decision 4 改寫、delta scenario GIVEN 改為「run 進行了 N 輪」、新增 re-run 輪數 scenario。修改檔案：design.md、specs/cash-skill-workflows/spec.md。
6. （Suggestion：重複行）design C3 與 delta MODIFIED requirement 明定 first-match wins，新增「重複 tdd 行取第一行」scenario；tasks 1.1 同步。修改檔案：design.md、specs/cash-skill-workflows/spec.md、tasks.md。
7. （Suggestion：ADDED requirements 治理）兩個 ADDED requirements 各新增具名群組治理 scenario；「不修改 `.cash.yaml`」納入 propose requirement 正文與 scenario AND。修改檔案：specs/cash-skill-workflows/spec.md。
8. （Suggestion：prefix literal）警訊文字改為 prefix-中立的「cash-ingest workflow」表述並寫入 requirement 正文；design C4／C5 同步約束斷言避開 prefix-variant token。修改檔案：specs/cash-skill-workflows/spec.md、design.md、proposal.md。
9. （Suggestion：負向斷言字串）design C5 新增斷言字串約束（鎖定「apply 迴圈：本次」等特有文字、不得用 shared block 既有字串）；delta ledger 治理 scenario 與 tasks 1.2 同步。修改檔案：design.md、specs/cash-skill-workflows/spec.md、tasks.md。
10. （Suggestion：propose 後變更管道）proposal Non-Goals 新增「不修改 cash-ingest」條目；design Risks 記錄翻轉後果（`red: N/A` 矛盾觸發 unclear-task branch 為預期保護）。修改檔案：proposal.md、design.md。

修正後已重跑 `"$cash_cli" validate per-change-tdd-override`（通過）與 post-fix mechanical self-check（annotation lint、MODIFIED 標題 byte-for-byte、舊措辭殘留 grep、新概念 cross-grep：`cash-ingest workflow`、run 內位置、first-match、`--self` 四處，全數通過）。本輪修改檔案共 4 個：proposal.md、design.md、specs/cash-skill-workflows/spec.md、tasks.md（皆在 change 目錄內，無 touched 記錄需求）。

## Decision

next_round

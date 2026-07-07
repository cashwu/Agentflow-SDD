# Propose Plus Review — Round 3

## Reviewer Findings

### Critical

（無 — confidence ≥ 80 的 Critical finding 不存在。）

### Warning

（無 — confidence ≥ 80 的 Warning finding 不存在。）

### Suggestion

- severity: Suggestion（原 Critical 75，confidence < 80 降級）| confidence: 75 | layer: design | reviewer: B
  - location: delta「Review loop grader immutability」的「explicitly named … appears verbatim; naming a directory path names all files under it」
  - summary: 逐字路徑出現的範圍例外會被「順帶提及」誤觸發 — 路徑作為要執行的命令、驗證步驟或規則描述出現時也機械性地取得修改權；本 change 自己的 tasks.md 2.1 即含 `openspec/specs/` 字樣（規則描述）、4.1 含 `scripts/spectra-plus/generate.fish`（執行命令），依字面規則會解鎖 master specs 與 generator。
  - recommendation: 把「明文列入」限縮到結構化宣告位置（proposal `## Impact` 的 Modified/New 行、task 的交付標的），排除僅作為命令、驗證步驟或規則描述出現的路徑。
- severity: Suggestion（原 Warning 75 降級）| confidence: 75 | layer: design | reviewer: B
  - location: delta「Deterministic signal-derived self-checks」exit-1 分流句
  - summary: 自指涉 change 中，review-loop-block.md 同時是「本 change 的修改檔案」（分支一：MUST fix）與「裁判保護路徑」（分支二：MUST NOT fix），兩個 MUST 對撞；救援讀法（保護指「套用範圍例外後仍受保護」）成立但未明文。
  - recommendation: 分支二限定為「不在範圍例外覆蓋內的裁判保護路徑」，使兩分支互斥。
- severity: Suggestion（原 Warning 75 降級）| confidence: 75 | layer: design | reviewer: A+B
  - location: delta grader requirement 的 completion summary 義務 vs 兩個 plus skill 的實際流程錨點
  - summary: 「completion summary」在 apply-plus（loop 是最後一步、既有摘要在 gate 之前）與 aborted 路徑（只有 unresolved-findings warning）沒有既定落點，義務可被兩種讀法執行。
  - recommendation: 在 GRADER-IMMUTABILITY 區塊為每個 skill 與每種結局點名具體錨點（propose-plus 的 Show summary、apply-plus 的 gate 後輸出、aborted 的 warning 附列）。
- severity: Suggestion（原 Warning 75 降級）| confidence: 75 | layer: design | reviewer: B
  - location: delta「Deterministic signal-derived self-checks」的 in-scope／pre-existing 判定
  - summary: check 只回傳 boolean exit code（規範自己的例是 `grep -rq`），exit 1 時 agent 無法從輸出得知實例位置；「pre-existing」也沒有基準定義 — 逃生分支重新引入了確定性想移除的裁量，且偏向可鑽（任何失敗都可辯稱範圍外）。
  - recommendation: 定義判定程序（改跑限縮於 change 檔案的變體或輸出位置的變體；無法限縮時 fail-closed 視為範圍內）。
- severity: Suggestion | confidence: 70 | layer: text | reviewer: A
  - location: delta grader requirement「completion summary」用語 vs 母 spec 的「final summary」／aborted 路徑措辭
  - summary: 「completion summary」在 aborted 結局沒有對應的既名步驟，義務僅有 pass 情境的 scenario 覆蓋。
  - recommendation: 在 requirement 文字中定義該詞（passed = final summary；aborted = unresolved-findings warning）或補 abort 情境 scenario。
- severity: Suggestion | confidence: 50 | layer: design | reviewer: B
  - location: signals delta exit 慣例 + README 撰寫規則
  - summary: POSIX sh 無 pipefail，管線上游錯誤會被折疊成 0/1；部分工具原生錯誤碼即為 1，與「1 = 偵測到」相撞（後果是吵鬧安全而非靜默通過）。
  - recommendation: README 撰寫規則補管線與 exit-1 原生錯誤工具的注意事項。
- severity: Suggestion | confidence: 50 | layer: text | reviewer: B
  - location: delta deterministic requirement 註記行的「that round」
  - summary: 兼作第 N 輪 post-fix 與第 N+1 輪 pre-round 的 self-check 執行，其註記歸屬輪次可被兩讀。
  - recommendation: 明定註記歸屬（check 所把關的那一輪）。
- severity: Suggestion | confidence: 50 | layer: design | reviewer: B
  - location: delta deterministic requirement 的 reviewers context 注入 vs Reviewer V 的職權範圍
  - summary: micro 輪注入失敗 check 結果，但 Reviewer V 的契約限於驗證前輪修復，無從處置。
  - recommendation: 注入限於 full 輪，或明文允許 V 附記（不裁決）。
- severity: Suggestion | confidence: 50 | layer: text | reviewer: B
  - location: delta deterministic requirement 末句「Executing a check command MUST NOT modify any file」
  - summary: 對執行者下了不可驗證的 MUST，與 signals delta 的撰寫面規則重複且可被讀成「執行前須審查命令」。
  - recommendation: 移除執行者側句子或改寫為撰寫面義務。

## Rating

- surviving Critical count: 0
- surviving Warning count: 0
- critical_gap: false
- round_type: full
- rationale: Reviewer A 的機械 diff 與全量交叉檢查確認 artifact 集內部一致（8 個 delta requirement 全有 backing task、5 個 MODIFIED 區塊除宣告修改外逐字同母 spec、跨 artifact 定義同步），僅提出 1 筆用語錨定 Suggestion。Reviewer B 的 4 筆主要 findings（範圍例外誤觸發、exit-1 分支對撞、completion summary 落點、in-scope 判定程序）confidence 均為 75，屬「已驗證、實務可能遇到」但未達 ≥ 80 的存活門檻，依 confidence filter 全數降級為 Suggestion。過濾後無存活 Critical 與 Warning → 機械決策為 passed。降級的四筆設計層 Suggestion 已完整記錄於本檔，建議於 apply 階段（實作模板文字時）一併吸收其 recommendation，或由人決定是否先行 ingest 修訂。

## Fix Actions

None; pass condition met.

## Decision

passed

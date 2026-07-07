## Summary

收斂 plus review loop 中幾個已知的邊界規則，避免 scope exception、deterministic signal checks 與 completion output 在實務執行時出現可鑽或互相衝突的讀法。

## Motivation

add-review-loop-discipline 已建立 grader immutability、loop ledger 與 signal check 的主契約，但 propose-r3 留下四個降級 Suggestion，且 apply loop 已為其中兩類鑄出 recurring signals。這些問題不阻擋上一個 change，但會影響下一批 plus loop 對 scope、check failure 與 completion output 的一致判斷，應以小型 follow-up 收斂。

## Proposed Solution

- 將 grader-immutability 的 declared-scope exception 從「任意 artifact 中逐字出現路徑」限縮為結構化範圍宣告：proposal ## Impact 的 affected-code entries，以及 tasks.md 中明確作為交付標的的路徑；驗證命令、規則描述、範例與 finding context 中順帶提到的路徑不解鎖 protected grader files。
- 將 deterministic signal-derived checks 的 exit 1 分流改成互斥規則：scope 內且不受未覆蓋 grader protection 阻擋的實例必須修復；pre-existing、修復落在 declared scope 外、或修復落在未被 scope exception 覆蓋的 protected grader path 時不得修復並記錄範圍外 check 失敗。
- 為 check failure 的 in-scope / pre-existing 判定定義程序：優先使用 check output 中的 project-root-relative path 與本 change artifact/source file set 做交集；若無法判定位置，fail closed 視為 scope 內，避免把不明失敗辯稱為範圍外。
- 明確定義 unfixed-due-to-grader-protection records 的 workflow completion output 錨點：propose-plus passed 時列入 final summary，apply-plus passed 時列入 gate 後最終回覆，aborted 時列入 unresolved-findings warning。
- 補強 signals README 的 check authoring guidance，要求新寫的 check 優先輸出命中位置，並提醒 POSIX sh 無 pipefail、管線與原生 exit 1 工具的錯誤碼陷阱。
- 更新 signals shared layer 的 canonical check 範例，將 quiet grep -rq 改成會輸出 project-root-relative path 且保留 explicit exit-code remapping 的 pattern，讓權威範例與新的 scope-classification guidance 一致。

## Non-Goals

- 不重新設計 plus review loop 的 round decision、confidence filter、micro round 或 loop ledger。
- 不改變 signal status 與 check 欄位的人工作業權限；自動 writer 仍不得增改刪 check。
- 不為既有 signals 自動新增 check 欄位。
- 不處理與本次四個 edge cases 無關的 plus skill 行為。

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- spectra-plus-skills: 收斂 grader immutability、deterministic signal-derived checks 與 completion output 錨點的邊界規則。
- signals-shared-layer: 補強 check authoring guidance，並更新 canonical check 範例，使可定位輸出與錯誤碼處理規則一致。

## Impact

- Affected specs: spectra-plus-skills, signals-shared-layer
- Affected code:
  - Modified: scripts/spectra-plus/template/review-loop-block.md
  - Modified: openspec/signals/README.md
  - Modified: openspec/specs/signals-shared-layer/spec.md
  - Modified: scripts/spectra-plus/tests/generator-checks.fish
  - Regenerated: .claude/skills/spectra-propose-plus/SKILL.md
  - Regenerated: .claude/skills/spectra-apply-plus/SKILL.md
  - Regenerated: .agents/skills/spectra-propose-plus/SKILL.md
  - Regenerated: .agents/skills/spectra-apply-plus/SKILL.md

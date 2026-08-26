## Summary

讓每個 change 記錄自己的 TDD 選擇：`cash-propose` 建立 change 後以互動詢問本 change 是否套用 TDD，將 `tdd: true` 或 `tdd: false` 寫入該 change 目錄的 `.openspec.yaml`；`cash-apply` Step 5 改為 change-level 值優先、`.cash.yaml` 全域值作 fallback。另外，`cash-apply` 品質關卡結束後回報本次 apply 迴圈的輪數與修復檔案數（以本次 run 的紀錄為權威來源，並核對 `loop-ledger.tsv`），輪數偏高時附上設計劣化警訊。

## Motivation

- 現況 TDD 只有 `.cash.yaml` 的全域開關。小 change 想跳過 TDD、下一個大 change 想啟用時，使用者必須來回編輯 `.cash.yaml`，決定無法跟著 change 走；apply 常跨多個 session，全域開關也可能在 change 進行中被改動而造成前後不一致。
- TDD 的決定實際上在 propose 時就發生：tasks 的 `red` evidence 欄位在 propose 時撰寫，而 `tdd: true` 時 apply 會以 `red` 欄位對照 canonical TDD classification。把選擇記錄在 change-scoped metadata，使 propose 與 apply 對同一個 change 使用同一個值。
- 參考「TDD in the agent loop」一文的結論：與其微觀管理 agent 的流程，不如量測 agent 的產出品質。loop ledger 已逐輪記錄 criticals、warnings 與 fixed_files，於品質關卡結束時回報摘要與高輪數警訊，是該結論最便宜的落地點。

## Proposed Solution

1. **Change-scoped TDD 欄位**：在 change 目錄的 `.openspec.yaml` 追加一行 unindented 的 `tdd: true` 或 `tdd: false`；非空檔案缺少尾端 LF 時先補恰好一個 LF separator，避免新 key 與既有尾行黏合。此欄位不需修改 Cash CLI 的 metadata parser 或可觀察行為：`validate` 對該檔只做 `schema: spec-driven` 子字串檢查，preflight 的 created 讀取是 `created: ` 行前綴掃描，兩者都容忍額外的行。
2. **cash-propose 詢問並記錄**：建立 change 目錄之後、撰寫 proposal 之前，以 AskUserQuestion 詢問本 change 是否套用 TDD（依需求描述的規模與型態給建議選項），將答案寫入 `.openspec.yaml`。詢問前先檢查該檔是否已有 `tdd:` 行——已有則跳過詢問，這也是 continue 既有 change 時的補問判準。tasks 的 `red` 欄位撰寫規則不變（toggle-independent 的 failure marker 描述）；apply 時是否以 `red` 對照 canonical TDD classification 依該生效值判定。
3. **cash-apply Step 5 解析順序**：先讀該 change `.openspec.yaml` 的 `tdd:` 行；值恰為 `true` 或 `false` 時採用，並於進度輸出宣告生效值與來源（change-level 或 global）；缺檔、缺行時 fallback 到 `.cash.yaml`；出現其他值時印出一則警告後 fallback 到 `.cash.yaml`。
4. **Loop-ledger 摘要與警訊**：`cash-apply` 的品質關卡以 `passed` 或 `aborted` 結束、最終 ledger 列與 signals 寫入完成後，在最終回應中回報本次 loop run 的 apply 輪數 N 與該 run 的 fixed_files 總和 M。N 與 M 以主 agent 本次 run 寫入的 round files 與 ledger 列為權威來源（主 agent 即產生者），讀取 `loop-ledger.tsv` 僅核對尾端列與本次 run 紀錄一致；本次 run 輪數（run 內位置計數）達 4 以上時，附一則設計劣化警訊，建議檢視 design.md 或以 cash-ingest workflow 更新設計。此步驟 read-only：ledger 缺檔或與本次 run 紀錄不一致時印警告，摘要仍以本次 run 紀錄回報；不影響任何 round file 的 decision，也不使 workflow 失敗。
5. **變體與測試同步**：以 scripts/cash-skills/generate.fish 重新生成 `.agents` 變體；更新 scripts/cash-skills/tests/skill-checks.fish 的 `tdd-discipline` 群組斷言至新的解析文字；每次修改 SKILL.md 並重新生成後、下一次 Cash CLI 呼叫前，立即以 install-cash-skills.fish --self 重建 `.cash-skills/manifest.tsv` 的 skill digests，避免 manifest fail-closed 窗口。
6. **Bundle version 同步**：Cash skills 屬既有 bundle version history contract 的 replaceable inventory；實作時讀取工作樹與 `git show HEAD:cash-skills.version` 的值，以兩者較大者為基準嚴格提升為更大的版本（strictly greater，與受治理測試的判準一致），並同步 `.cash-skills/lib/cash_cli/installer.py` 的 `BUNDLE_VERSION`，再重建 manifest。版本不得寫死，以免覆蓋同工作樹其他 change 已提升但尚未提交的值。

## Non-Goals

- 不修改 Cash CLI 的 metadata parser、commands 或可觀察行為：config parser、`DISCIPLINES["tdd"]` instruction 內容、`new change` 寫入的 `.openspec.yaml` 初始格式皆不變；唯一 CLI runtime 檔案修改是 C6 要求的 installer `BUNDLE_VERSION` 發布 metadata 同步。
- `cash-debug` 的 TDD toggle 仍只讀 `.cash.yaml`：它不必然在 change context 中執行，沒有 change-level 值可讀。
- 不做 mutation testing 類的測試有效性量測：signal `check` 指令不得修改檔案、且需要新依賴，如有需要另開 change。
- 不做跨 change 的歷史趨勢比較：ledger 摘要只涵蓋本次 loop run。
- 不修改 `cash-ingest` skill：TDD 選擇在 propose 之後的變更（範圍成長時翻轉該值）由使用者手動編輯 `.openspec.yaml` 或在 ingest 中一併處理；其後果與連動義務記錄於 design 的 Risks。

## Alternatives Considered

- **per-invocation flag（在 apply 指令參數帶 no-tdd）**：apply 常跨多個 session 執行，同一 change 會前後不一致，捨棄。
- **把選擇寫進 proposal.md 或 design.md**：敘事 artifact 不是穩定的機器讀取位置；`.openspec.yaml` 已是 change-scoped metadata 的既有載體，捨棄。
- **`.cash.yaml` 改三值設定（always／never／ask）**：仍是全域值，無法跟著 change 走，且 `.cash.yaml` parser 只接受 boolean，改動會外溢到 CLI 與 installer 的 config 驗證，捨棄。

## Capabilities

### New Capabilities

（無）

### Modified Capabilities

- `cash-skill-workflows`：conditional TDD requirement 的 toggle 來源改為 change-level 優先、全域 fallback；新增 cash-propose 記錄 change-level TDD 選擇的 requirement 與 cash-apply 品質關卡結束時回報 loop-ledger 摘要的 requirement。

## Impact

- Affected specs: cash-skill-workflows
- Affected code:
  - New:
    - (none)
  - Modified:
    - .claude/skills/cash-propose/SKILL.md
    - .claude/skills/cash-apply/SKILL.md
    - .agents/skills/cash-propose/SKILL.md
    - .agents/skills/cash-apply/SKILL.md
    - scripts/cash-skills/tests/skill-checks.fish
    - cash-skills.version
    - .cash-skills/lib/cash_cli/installer.py
    - .cash-skills/manifest.tsv
  - Removed:
    - (none)

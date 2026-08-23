## Summary

把 Ponytail 中可操作、且與 Cash contract-first workflow 相容的最小解法紀律整合進既有 Cash skills：在 `cash-apply` task loop 加入有序的 minimal-solution ladder；在既有 Reviewer B 品質掃描加入 changed-diff complexity checklist；並讓具有真實已知 ceiling 的 `deviation` 記錄其限制與可觀察的重訪條件。維持既有兩位 reviewer 架構、變體生成模型、scope discipline 與驗證強度，不引入新的 skill、模式切換或 LOC gate。

## Motivation

Cash 已透過 Focused Implementation Discipline 禁止未要求的抽象、額外設定與範圍外重構，也要求搜尋既有實作、修正根因並依 Implementation Contract 驗證。然而目前三個執行缺口仍會造成結果不一致：

1. task loop 只有獨立的 `Reuse` 提醒，沒有固定的選擇順序；agent 可能在 codebase reuse、standard library、platform／framework native feature、既有 dependency 與 custom implementation 之間直接跳到較重方案。
2. Reviewer B 會掃描一般品質缺陷，但沒有明確檢查本次 diff 是否引入可刪除的 dependency、單一實作 abstraction、pass-through wrapper、speculative configuration 或重寫既有能力。現行 false-positive 規則只阻止 reviewer 建議新增未要求的複雜度，沒有正向要求它辨識已新增的複雜度。
3. contract-preserving mechanism substitution 會寫入 `deviation`，但若替代方案具有 global lock、linear scan、naive heuristic 等已知 ceiling，現有 entry shape 沒有位置保存限制與重訪 trigger。這使合理簡化可能永久化，或只能以未治理的 source comment 記錄。

Ponytail 的實際價值在於把上述判斷變成固定階梯、專門的 complexity review 類別，以及 ceiling／upgrade trigger；本 change 將這些機制轉成 Cash-native contract，而不採用其「one line wins」、持久模式與以 LOC 衡量品質的部分。

## Proposed Solution

1. 在 `cash-apply` 每個 task 的 pre-edit checks 中加入 ordered minimal-solution ladder。階梯依序判定：contract 是否要求該行為、codebase 是否已有可重用實作、standard library 是否涵蓋、platform／framework native feature 是否涵蓋、已安裝 dependency 是否涵蓋，最後才寫最小且清楚的 custom implementation。階梯在完整理解 task、相關 call sites 與 Implementation Contract 之後執行，且不得以 brevity 犧牲 correctness、clarity、trust-boundary validation、data-loss prevention、security、accessibility 或明確驗收條件。
2. 定義多個保留 contract 的候選方案之 deterministic tie-break：先選階梯中較早成立者；同一層成本相當時，選 edge-case correctness 較強且更符合既有 codebase pattern 的方案。若此選擇發生於既有 blocker triage 的 mechanism substitution 分支，仍依現行規則記 `deviation` 後繼續。
3. 擴充 Reviewer B 的既有品質範圍，使其對 cash-apply 的 changed diff 明確檢查 `dependency`、`single-implementation abstraction`、`pass-through wrapper`、`speculative configuration`、`duplicate existing capability` 與可由 `stdlib`／`native` 取代的 custom code。這是既有 reviewer 的額外 lens，不新增 reviewer、round type、severity、confidence 或 decision 規則。cash-propose 的 Reviewer B 則檢查 artifacts 是否要求或默許同類不必要複雜度。
4. 擴充 Implementation Notes Protocol 的 `deviation` entry：只有替代手段存在非平凡、真實且已知的 ceiling 時，額外要求 `限制` 與 `重訪條件`；無已知 ceiling 時維持現有 entry shape，不為 routine implementation、ordinary tradeoff 或小判斷建立紀錄。重訪條件必須是可觀察或可衡量的 trigger，不接受「之後需要時」這類無法驗證的文字。
5. 更新 `cash-skill-workflows` master spec 的 delta、skill contract tests、雙 variant generated outputs 與 bundle version。機械斷言同時正向釘住新 ladder、complexity checklist、ceiling fields／條件，以及負向排除 `one line`／LOC gate／新增 reviewer 等非目標行為。

## Non-Goals

- 不新增 `cash-simplify`、`cash-debt`、`cash-gain` 或其他 skill。
- 不新增 `lite`、`full`、`ultra`、always-on hook、session-persistent mode 或 sub-agent mode propagation。
- 不把一行程式、最少行數或 `net: -N lines` 當成完成、評分或 quality-gate 條件；`clarity 永遠優先於 brevity` 保持不變。
- 不降低既有 task verification、spec `##### Example:` coverage、TDD、security、accessibility、trust-boundary validation 或 data-loss handling 要求。
- 不要求所有 simplification 都寫 `deviation`，也不在 source code 引入 `ponytail:` comment convention；只有既有 Implementation Notes Protocol 已要求記錄的 deviation，且存在非平凡已知 ceiling 時，才增加限制與重訪條件。
- 不改變 blocker triage 的互斥分支、逐字 circuit-breaker 邊界、`cash-ingest` 導向、review round 數量、角色數量、confidence filter、cumulative blocking set、signals 或 accepted-risks 行為。
- 不以外部 Ponytail benchmark 數字宣稱 Cash 的 LOC、token、成本或速度收益，也不在本 change 建立 benchmark harness。
- 不修改 `.cash.yaml`、Cash CLI command contract 或 artifact schema engine。

## Alternatives Considered

**直接安裝或依賴 Ponytail plugin。** 放棄。Cash 需要 repository-owned、雙 variant、可由 spec 與 tests 稽核的 deterministic workflow；外部 plugin 的模式狀態、hooks 與更新生命週期會形成第二套控制面。

**新增獨立 `cash-simplify` reviewer skill。** 放棄。既有 Reviewer B 已負責非 artifact 明示的品質風險；在同一 reviewer 增加明確 lens 是最小變更，也避免額外 skill、觸發規則與維護面。

**照搬 `ponytail:` source comments 並建立 debt ledger。** 放棄。Cash 已有 append-only `implementation-notes.md`、Reviewer A／V 讀取義務與 ingest resolution history；將 ceiling 放進受治理的 deviation entry 可避免兩套 debt 記錄漂移。

**把「one line」加入階梯。** 放棄。一行是表示形狀而非 correctness 或 maintainability 判準，與現行 `clarity 永遠優先於 brevity` 衝突，也可能鼓勵刪除安全或驗收所需的 guard。

**只增加一般性的「保持簡單」一句話。** 放棄。Ponytail 的 agentic benchmark 顯示短 YAGNI／one-liner prompt 行為不穩定；本 change 選擇有序階梯、具名 complexity lens 與機械斷言，使行為可稽核。

## Capabilities

### New Capabilities

（無）

### Modified Capabilities

- `cash-skill-workflows`：擴充 `cash-apply` 的最小解法選擇紀律、Reviewer B 的 complexity review 範圍，以及 Implementation Notes Protocol 對已知 ceiling deviation 的記錄契約，並維持雙 variant 對等與既有品質關卡狀態機。

## Impact

- Affected specs:
  - cash-skill-workflows
- Affected code:
  - New:
    - （無）
  - Modified:
    - `cash-skills.version`
    - `.cash-skills/lib/cash_cli/installer.py`
    - `.cash-skills/manifest.tsv`
    - `.claude/skills/cash-apply/SKILL.md`
    - `.claude/skills/cash-propose/SKILL.md`
    - `.agents/skills/cash-apply/SKILL.md`
    - `.agents/skills/cash-propose/SKILL.md`
    - `scripts/cash-skills/blocks/review-gate.md`
    - `scripts/cash-skills/tests/skill-checks.fish`
    - `openspec/specs/cash-skill-workflows/spec.md`
  - Removed:
    - （無）

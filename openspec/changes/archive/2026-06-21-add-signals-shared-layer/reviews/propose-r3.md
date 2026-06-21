# Propose Plus Review — Round 3

## Reviewer Findings

### Critical

（無）

### Warning

- **severity**: Warning / **confidence**: 100 / **location**: design.md「Signal 寫入的觸發條件與去重」body + 「Risks / Trade-offs」第一項 / 來源：A
  - **summary**: 兩處仍寫「先依 slug 去重」，與新設計矛盾——新規則下 slug 是 rubric 比對後才指派，去重時 slug 尚不存在；其餘 artifact（design line 14、spec「deduplicated by issue class」、tasks 2.1、proposal）皆已用「issue class」。
  - **recommendation**: 將 design 兩處「依 slug 去重」改為「依 issue class 去重」。

- **severity**: Warning / **confidence**: 80 / **location**: design.md + `specs/spectra-plus-skills`「Plus review loop writes signals」（"coin 未被佔用的新 slug"） / 來源：B
  - **summary**: 「coin 未被佔用 slug」未說明 agent 如何得知 slug 未被佔用；若 coin 出的自然 slug（如 `unhandled-empty-input`）已存在於另一個被判為不同 class 的 signal，`Write` 覆寫會靜默毀掉不相關 signal——無需並發即可發生，比已記錄的並發 race 更嚴重。
  - **recommendation**: 明定 coin 新 slug 時 MUST 列舉 `openspec/signals/*.md`，選一個尚未存在的 slug（自然 slug 被佔用則加 disambiguate 後綴），且建檔 MUST NOT 覆寫既有檔；於 spec MUST、design 與 README 反映。

### Suggestion

- **severity**: Suggestion / **confidence**: 70 / **location**: proposal.md Why/design.md Goals / 來源：B（原 Warning 降級）
  - **summary**: 在「prefer create-new when uncertain」的保守偏向下，`occurrences` 多半停在 1、folder 易積近似重複單筆 signal，但 Why/Goals 仍把「跨 change 複利累積」當成已達成而非 best-effort + 人工合併。
  - **recommendation**: 於 proposal Why 與 design Goals 註明自動跨 change occurrence 累積為 best-effort，複利的實現需週期性人工合併重複 signal（README 已有 split/merge 指引支援）。

- **severity**: Suggestion / **confidence**: 60 / **location**: review-loop-block.md:22 既有 round 聚合去重 vs 新寫入 issue-class 去重 / 來源：B
  - **summary**: 兩種去重鍵並存（line 22 per-round `location + summary` 聚合 vs 寫入集 issue-class 語意），實作者可能混用；若寫入集誤用 `location + summary` 鍵會在寫入邊界重現原 Critical。
  - **recommendation**: 於 tasks 2.1／寫入步驟模板明示寫入集去重採 issue class，獨立於既有 line-22 round 聚合去重。

- **severity**: Suggestion / **confidence**: 55 / **location**: design.md Risks / spec README contract / 來源：B
  - **summary**: 兩個並發 loop 對同一新 issue-class coin 出相同自然 slug（同 rubric→同名）首次建檔最可能碰撞，README 條文雖技術涵蓋但未點明可能整個新 signal 消失。
  - **recommendation**: 可選於 README 明示同名 coined slug 並發首建可能整檔遺失。

- **severity**: Suggestion / **confidence**: 50 / **location**: tasks.md 5.1 / spec acceptance / 來源：B
  - **summary**: sentinel 斷言只驗標記存在/缺席與 DO-NOT-EDIT marker；occurrence 遞增與 status 保留等行為僅靠 advisory 手動驗收，無機械測試。
  - **recommendation**: 無須行動（純 prompt/模板變更，agent judgment 無法機械斷言）；可選於 tasks 註明 sentinel 檢查為設計上唯一 gating 覆蓋。

## Rating

- 存活 `Critical` 數（post-filter）：0
- 存活 `Warning` 數（post-filter）：2
- `critical_gap`: false
- rationale：A 以 conf 100 指出 design 兩處殘留「先依 slug 去重」與新「issue class」設計矛盾（artifact 內部不一致）；B 以 conf 80 指出「coin 未佔用 slug」缺「列舉既有檔名避免覆寫不相關 signal」的契約，`Write` 覆寫語意下會無需並發即毀檔。兩者皆為真實且廉價可修。無 Critical 但有存活 Warning → `next_round`。其餘 Suggestion（複利 over-claim 誠實化、雙去重鍵釐清）一併處理。

## Fix Actions

1. （A1）design.md 兩處「依 slug 去重」→「依 issue class 去重」。
2. （B2）`specs/spectra-plus-skills` 寫入 requirement、design、tasks 1.1/2.1、`specs/signals-shared-layer` README contract：明定 coin 新 slug 時 MUST 列舉既有 `openspec/signals/*.md`、選未存在 slug、建檔不覆寫既有檔。
3. （B1）proposal Why 與 design Goals：將跨 change occurrence 累積誠實標為 best-effort、需人工合併。
4. （B4）tasks 2.1：明示寫入集 issue-class 去重獨立於 line-22 round 聚合去重。

## Decision

next_round

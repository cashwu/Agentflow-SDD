# Propose Plus Review — Round 2

## Reviewer Findings

### Critical

- **severity**: Critical / **confidence**: 90 / **location**: design.md「Signal 寫入的觸發條件與去重」+ `specs/signals-shared-layer` schema requirement + `specs/spectra-plus-skills`「Plus review loop writes signals」 / 來源：B
  - **summary**: dedup key 含自由文字 `summary` 與 `location`，跨 change 觀察同一類問題時 `location`（不同檔案/行）與獨立 reviewer 寫的 `summary` 都不同 → slug 不同 → condition (b) 永不命中 → 每次都建新 `occurrences: 1` 的 signal，proposal 核心「跨 change 複利」結構性無法達成；而 design 又否決語意比對，等於移除唯一能讓跨 change 比對成立的機制。
  - **recommendation**: 將 `<slug>` 改為 main agent 指派的簡短語意 issue-class 識別碼，寫入時讀既有 open signals 做語意比對：同 class 沿用既有 slug 更新、否則 coin 新 slug；明確此為 judgment-based 並給比對 rubric。

### Warning

- **severity**: Warning / **confidence**: 80 / **location**: `specs/signals-shared-layer`「Slug derivation」+ design schema / 來源：B
  - **summary**: 機械式 slug 對退化/空字串與檔名長度無處理：round file prose 規定繁體中文，若 `summary` 全為非 `[a-z0-9]`（CJK）字元，正規化後得空字串 → `openspec/signals/.md` 無效/隱藏檔且全部塌成一檔；過長英文則可能超過 255-byte 檔名上限。
  - **recommendation**: 改用 agent coined 的 ASCII 短 slug 即可消除此問題；或於 spec/README 補空字串 fallback 與長度截斷規則。

### Suggestion

- **severity**: Suggestion / **confidence**: 75 / **location**: `specs/signals-shared-layer`「slug 為 dedup 鍵」vs design 碰撞風險 / 來源：B（原 Warning 降級）
  - **summary**: 機械式去標點 slug 可能讓兩個**真正不同**的 finding 塌成同一 slug，導致不相關問題被就地併入同一 signal（遞增 occurrences、append 不相關 occurrence），design Risks 未列此 over-collapse。
  - **recommendation**: 改用語意 slug 後此風險大幅降低；於 design Risks 補此碰撞案例並於 README 提示分析者可拆分混入不相關 occurrence 的 signal。

- **severity**: Suggestion / **confidence**: 60 / **location**: `specs/spectra-plus-skills`「Plus review loop writes signals」比對 rubric / 來源：B
  - **summary**: 規則寫「僅命中 addressed/dismissed signal → 建新 signal」，但新檔路徑仍是同一 `<slug>.md`，檔案系統無法同名兩檔；會覆寫已解決 signal（重設人工 status，違反 status 人維護 requirement）或靜默失敗。
  - **recommendation**: 改用 agent coined slug 後，命中非 open 同類 signal 時 coin 一個不同的新 slug 建檔，確保不覆寫人工 status；或明定 append occurrence 而不改 status。

- **severity**: Suggestion / **confidence**: 55 / **location**: design.md 並發 risk / 來源：B
  - **summary**: 並發 lost-entry 風險描述正確，但其實偏保守——需「同一兩個 change 同時產生同 slug」才會碰撞，比散文暗示更罕見。
  - **recommendation**: 可選註明同 slug 並發需同時滿足並發窗口與實際 slug 命中，風險低於散文暗示。非阻擋。

- **severity**: Suggestion / **confidence**: 50 / **location**: tasks.md 3.2 / rules.yaml schema / 來源：A
  - **summary**: 3.2 驗證未明確檢查新 transformation 符合 `target_section`+`operation`+`template` schema；generator 本會 fail loud，屬 minor。
  - **recommendation**: 可選在 3.2 補一行確認新 entry 帶 `operation: append`、`template: signals-read-block.md`。

- **severity**: Suggestion / **confidence**: 50 / **location**: `specs/signals-shared-layer`「README contract」vs tasks 1.1 / 來源：A
  - **summary**: 1.1 要求 README 記 lost-entry 風險，但無 spec requirement 強制該 README 內容，traceability 僅落在 task 與 design Risks。
  - **recommendation**: 可選將 lost-entry 註記併入 README contract requirement 以利 traceability。

## Rating

- 存活 `Critical` 數（post-filter）：1
- 存活 `Warning` 數（post-filter）：1
- `critical_gap`: true
- rationale：B 以 conf 90 指出 dedup key 含自由文字 `location + summary`，使跨 change condition (b) 比對結構性失效，直接抵觸 proposal 的「複利」核心目標——屬 artifact 目標與機制不一致的 Critical。另存活一條 conf 80 Warning（退化/CJK/長度 slug）。依機械規則有存活 Critical → `next_round`。多條 Suggestion（含 addressed/dismissed 同 slug 建檔不可能、over-collapse 碰撞）將由同一「語意 slug + 比對程序」設計改動一併解決。

## Fix Actions

1. （B-Crit / B-Warn2 / B-Sug over-collapse / B-Sug addressed-path）proposal.md、design.md、`specs/signals-shared-layer`、`specs/spectra-plus-skills`、tasks 1.1/2.1：將 `<slug>` 重新定義為 main agent 指派的簡短語意 issue-class 識別碼（ASCII kebab-case）；寫入程序改為「讀既有 open signals → 同 class 沿用既有 slug 更新、否則 coin 新且未被佔用的 slug 建檔」；移除 location+summary 機械轉換規則與其 worked example；命中非 open 同類 signal 時 coin 新 slug，不覆寫人工 status；給出語意比對 rubric（同 capability/domain + 同 rule/anti-pattern）。
2. （A-Sug README traceability）`specs/signals-shared-layer`「README contract」requirement 併入 lost-entry 風險與 slug 指派規則的文件義務。
3. （design Risks）補 over-collapse 碰撞與並發描述微調。

## Decision

next_round

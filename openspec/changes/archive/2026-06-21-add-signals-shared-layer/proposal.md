## Why

目前 Spectra Plus 的 review/rating/fix loop 只把 finding 寫進該 change 自己的 `openspec/changes/<change>/reviews/<skill>-r<N>.md`，review 結束後就沉底。跨 change 之間沒有任何共享記憶，導致同一類問題（反覆被違反的 SHALL、重複出現的 anti-pattern、一再被提的 friction）在每個新 change 都要從零重新被發現。借鏡 loop engineering 的「signals 共享腦」概念，引入一個跨 change 的共享層，讓 plus 從「一次性品質 gate」升級為「跨 change 共享記憶的品質迴圈」。自動跨 change 累積為 best-effort（比對為偏保守的 agent judgment），複利效果的充分實現仰賴週期性人工合併重複 signal；共享層本身已先提供 review finding 的持久跨 change 檔案庫。

## What Changes

- 新增 `openspec/signals/` 共享層目錄與 signal 檔案 schema：每個 signal 是一個 `openspec/signals/<slug>.md`，`<slug>` 為 main agent 指派的簡短語意 issue-class 識別碼（ASCII kebab-case，例如 `spec-requirement-no-backing-task`），作為跨 change 比對的穩定識別，含 frontmatter（`id`、`type`、`status`、`occurrences`、`first_seen`、`last_seen`、`links`）、主體說明與 occurrence 記錄。
- 新增 `openspec/signals/README.md` 說明此資料夾收什麼、不收什麼、schema 與新增流程（對齊 loop engineering 對每個 artifact 資料夾都附 README contract 的做法）。
- 修改共用的 review loop 模板 `scripts/spectra-plus/template/review-loop-block.md`，新增「寫 signal」步驟：loop 結束後，對在**任一 round** 通過 confidence filter 的 `Critical` / `Warning` finding，main agent 讀取 `openspec/signals/` 既有 open signals 做語意比對（同 capability/domain + 同 rule/anti-pattern 即視為同 issue-class）——同 class 命中既有 open signal 則沿用其 slug 就地更新（遞增 `occurrences`、更新 `last_seen`、append occurrence 與 `links`、不改 `status`），否則 coin 一個未被佔用的新語意 slug 建立新 signal（`status: open`、`occurrences: 1`）。同 change 內多 round 出現的同 class finding 先去重為一個對象。涵蓋「任一 round 出現過」而非僅最終 round，是因為健康 loop 通過時最終 round 已無 Critical/Warning，被修好的 finding 也應留下 signal，後續 change 才能跨 change 比對而產生複利。此模板同時被 `spectra-propose-plus` 與 `spectra-apply-plus` 使用，故一處改動即覆蓋兩個 plus skill 的寫入行為。
- 新增 propose-plus 專屬模板 `scripts/spectra-plus/template/signals-read-block.md` 與 `scripts/spectra-plus/rules.yaml` 中對應的 transformation，讓 `spectra-propose-plus` 在開新 change 的早期（既有「Scan existing specs for relevance」步驟之後）讀取 open signals，並把相關 signal 以資訊性摘要呈現以協助排優先序；此為 informational，不阻擋流程、不要求使用者確認。
- 更新 `scripts/spectra-plus/tests/generator-checks.fish`，以唯一 sentinel 標記字串斷言生成後兩個 plus skill 含 signal 寫入步驟、propose-plus 含 signal 讀取步驟、apply-plus 不含讀取步驟。
- 更新 `SPECTRA-PLUS.md`，記錄 signals 共享層的用途、schema 與 read/write 時機。

## Capabilities

### New Capabilities

- `signals-shared-layer`: 定義 `openspec/signals/` 共享層的目錄結構、signal 檔案 schema、status 生命週期（`open` / `addressed` / `dismissed`）、去重與 occurrence 累積規則，以及 README contract 的必備內容。

### Modified Capabilities

- `spectra-plus-skills`: 共用 review loop 在迴圈結束後新增「對任一 round 出現過的 post-filter Critical/Warning finding 依 class 去重後建立或更新 signal」行為；`spectra-propose-plus` 在 change 早期新增「讀取 open signals 作為排優先序輸入」行為。生成管線（generator、rules.yaml、template）與不可手改生成檔的既有約束維持不變。

## Impact

- Affected specs: `signals-shared-layer`（新增）、`spectra-plus-skills`（修改）
- Affected code:
  - New:
    - openspec/signals/README.md
    - scripts/spectra-plus/template/signals-read-block.md
  - Modified:
    - scripts/spectra-plus/template/review-loop-block.md
    - scripts/spectra-plus/rules.yaml
    - .claude/skills/spectra-propose-plus/SKILL.md
    - .agents/skills/spectra-propose-plus/SKILL.md
    - .claude/skills/spectra-apply-plus/SKILL.md
    - .agents/skills/spectra-apply-plus/SKILL.md
    - scripts/spectra-plus/tests/generator-checks.fish
    - SPECTRA-PLUS.md
    - openspec/specs/spectra-plus-skills/spec.md
  - Removed: (none)

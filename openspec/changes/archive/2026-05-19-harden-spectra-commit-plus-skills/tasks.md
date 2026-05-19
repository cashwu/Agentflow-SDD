## 1. Commit guard 行為規則

- [x] 1.1 在 `.agents/skills/spectra-commit/SKILL.md` 定義 `spectra-commit archive-first allowlist` 行為，交付「修改既有 `spectra-commit` 而不是新增 `spectra-commit-plus`」與「archive-first collection 必須以允許清單為準」契約：archive 後只額外納入 selected change archive 與使用者明確選擇 sync 時的 `openspec/specs/` 變更，tracked source files 只沿用 pre-archive confirmed commit set；驗證：內容檢查確認 archive-first 步驟描述 pre/post status 差異或 allowlist，且不再把 post-archive 全量 dirty state 視為 commit set。
- [x] 1.2 在 `.claude/skills/spectra-commit/SKILL.md` 套用與 Codex 同等的 `spectra-commit archive-first allowlist` 行為，交付 Claude skill 與 Codex skill 一致的 archive-first 排除 unrelated dirty files 契約；驗證：對兩個 `spectra-commit` SKILL.md 執行內容比對，確認 guard marker、allowlist 規則與 archive-related file collection 文案一致。
- [x] 1.3 在 Codex 與 Claude `spectra-commit` 規則加入 `plus generated skill deletion guard`，交付「plus generated skill deletion 預設受保護」契約：`.agents/skills/spectra-*-plus/` 與 `.claude/skills/spectra-*-plus/` deletion 預設排除，僅 Customize 明確加入才可 stage；驗證：`rg` 在兩個 SKILL.md 找到 protected deletion 文案與兩種 plus skill path pattern。
- [x] 1.4 在 Codex 與 Claude `spectra-commit` 規則統一 archive path 文案，交付 archive-first plan 顯示 `openspec/changes/archive/<date>-<change>/` 且不再使用舊 `openspec/archived/` 的契約；驗證：`rg` 在兩個 SKILL.md 確認存在 current archive path 並且不存在 `openspec/archived/`。

## 2. Installer 整合

- [x] 2.1 實作 `install-spectra-plus.fish` 的 `plus installer updates spectra-commit guard` 安裝檢查，交付「`install-spectra-plus.fish` 負責安裝與驗證 commit guard」契約：目標專案缺少 `.agents/skills/spectra-commit/SKILL.md` 或 `.claude/skills/spectra-commit/SKILL.md` 時明確失敗；驗證：對缺少其中一個 commit skill 的 temporary target 執行 installer，確認非零 exit 且 stderr 指出缺少檔案。
- [x] 2.2 實作 installer 對 target `spectra-commit` guard 的 deterministic update 或驗證，交付既有 `$spectra-commit` 入口在安裝 plus 後具備 archive-first allowlist 與 plus deletion guard 的行為；驗證：對含未加 guard commit skills 的 temporary target 執行 `./install-spectra-plus.fish --target <target>` 後，`rg` 能在 Codex/Claude target SKILL.md 找到 guard marker、allowlist 文案、`.agents/skills/spectra-*-plus/` 與 `.claude/skills/spectra-*-plus/`。
- [x] 2.3 實作 installer dry-run 輸出，交付 `./install-spectra-plus.fish --target <target> --dry-run` 會列出 `spectra-commit` guard check/update 且不改檔的契約；驗證：dry-run 前後比較 target `spectra-commit` SKILL.md checksum 不變，stdout 包含 planned guard check/update。
- [x] 2.4 實作 installer unsupported shape failure 與 idempotency 保護，交付無法安全 patch 時失敗、重跑 installer 不重複插入 guard block 的契約；驗證：對缺少預期 section 的 temporary target 確認非零 exit，對成功安裝 target 重跑兩次後確認 guard marker 只出現一次。

## 3. 測試與驗證

- [x] 3.1 新增或擴充 installer 測試來覆蓋 `plus installer updates spectra-commit guard`，交付安裝流程可重複驗證的 regression coverage；驗證：執行對應 fish 測試腳本，確認 guarded target、missing commit skill、dry-run 三種 case 通過。
- [x] 3.2 新增內容檢查測試覆蓋 `spectra-commit archive-first allowlist` 與 `plus generated skill deletion guard`，並修正既有 generator marker/schema regression checks，交付 commit skill 不會再把 plus skill deletion 預設納入 commit set 且 plus generator regression suite 保持可執行的文字契約；驗證：測試斷言兩個 `spectra-commit` SKILL.md 同時包含 allowlist guard、protected deletion guard、Customize override 文案，且 `fish scripts/spectra-plus/tests/generator-checks.fish` 通過。
- [x] 3.3 執行整體 Spectra 驗證，交付 proposal、design、spec、tasks 與 requirement/design cross-reference 一致；驗證：`spectra validate harden-spectra-commit-plus-skills` 通過。

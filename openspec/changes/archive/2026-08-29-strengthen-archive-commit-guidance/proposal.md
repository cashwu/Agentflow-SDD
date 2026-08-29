## Summary

強化「封存前先提交」的使用者指引：把 `cash-apply` 收尾時的封存指引改為固定文案模板，確保兩條安全路徑（先 `/cash-commit` 再 `/cash-archive`、或走 `/cash-commit` 的 `Archive first, then commit together` 子流程）每次都完整呈現；並在 `cash-archive` 加入單獨封存前的未提交來源守門，偵測到 touched 允許清單中仍有未提交的 source 檔案時，先警告並建議改走 `/cash-commit` 的 archive 子流程，再由使用者決定是否繼續。

## Motivation

使用者的實際習慣是「先 archive、再一起 commit」，而現行機制對這個習慣有兩個缺口：

1. `cash-apply` 的「Archive guidance timing」段落雖然規定收尾回覆 MUST 同時提出「先 commit」與「`Archive first, then commit together` 子流程」兩個選項，但沒有固定文案，實務上常被壓縮成只剩「請先 commit，再 archive」，使用者因此不知道有一條完全符合其習慣（archive 與 commit 進同一個 commit）的合法路徑。
2. 使用者直接執行 `/cash-archive` 時，該 workflow 完全沒有守門：封存會刪除 `.cash-skills/state/touched/<change>.json`，之後 `/cash-commit` 失去來源允許清單、退回封存 manifest 的時間點快照——封存後才改的檔案不會入列，較舊的封存甚至沒有該欄位。這個風險只寫在 `cash-apply` 的指引裡，`cash-archive` 本身不會提醒。

## Proposed Solution

1. **cash-apply 封存指引固定文案模板**：在 `.claude/skills/cash-apply/SKILL.md` 的「Archive guidance timing」段落內嵌一個逐字模板區塊，規定收尾回覆建議封存時 MUST 逐字輸出該模板（僅允許代入 change 名稱與 invocation 前綴差異）。模板內容同時呈現兩條路徑並說明單獨先封存會刪除 touched state 的後果。`.agents` 變體由 `scripts/cash-skills/generate.fish` 自 `.claude` 來源再生，維持前綴正規化後逐字對等。
2. **cash-archive 單獨封存前的未提交來源守門**：在 `.claude/skills/cash-archive/SKILL.md` 的封存執行步驟前新增一個守門步驟：讀取 `.cash-skills/state/touched/<change>.json` 的 top-level `files` 欄位（僅 legacy 路徑 `.spectra/touched/<change>.json` 存在時，改讀 legacy 檔 `touched` 陣列各條目 `files` 的聯集——legacy schema 沒有 top-level `files`），與 `git status --porcelain=v1 -z --untracked-files=all` 依 NUL-delimited 格式解析出的 dirty 路徑取交集；交集非空時列出這些未提交的 source 檔案，以 AskUserQuestion 讓使用者在「停止並改走 `/cash-commit` 的 `Archive first, then commit together` 子流程（建議）」與「知悉後果仍繼續單獨封存」之間選擇。兩個 touched 路徑都不存在或交集為空時，靜默通過不發問；touched 檔 malformed 時不猜測、直接放行，由封存步驟的 CLI fail closed 並保留其實際 diagnostic（`state_invalid`／`touched_invalid`／`legacy_touched_invalid`）。守門只讀取 touched state，不修改、不刪除。
3. **配套治理面**：更新 `openspec/specs/cash-skill-workflows/spec.md`（MODIFIED 既有的 cash-apply 封存指引 requirement、ADDED cash-archive 守門 requirement）；在 scripts/cash-skills/tests/skill-checks.fish 補上對應 literal assertion；因四個 SKILL.md 都是 portable manifest 的 skill record，需以 `git show HEAD:cash-skills.version` 推導新值提升 cash-skills.version，且每個修改 skill record 的 task 都在自身結尾、任何下一次 Cash CLI 呼叫之前，於 project root 執行 source-only installer self 模式重建 .cash-skills/manifest.tsv，關閉 manifest digest drift 的 fail-closed 窗口。

## Non-Goals

- 不修改 `.cash-skills/lib/cash_cli/` 任何 runtime 行為（`archive` 指令刪除 touched state 的行為、`cash-commit` 的 manifest 快照 fallback 都維持不變）；唯一例外是 `installer.py` 的版本常數 `BUNDLE_VERSION` 隨 `cash-skills.version` 同步——installer runtime contract 測試斷言兩者相等，此同步是歷次版本 bump 的既有慣例，不改變任何 runtime 行為。
- 不修改 `cash-commit` 的 SKILL.md：其 `Archive first, then commit together` 子流程與 step 2a 復原機制已足夠，本 change 只把使用者導向它。
- 不新增任何 CLI 旗標或 state 檔案格式。
- 不改動 review gate 區塊（`scripts/cash-skills/blocks/review-gate.md`）與 `scripts/cash-skills/generate.fish`、`scripts/cash-skills/variant-rules.yaml` 的生成規則本身。

## Alternatives Considered

- **在 CLI 的 `archive` 指令內做守門**：把偵測邏輯放進 `.cash-skills/lib/cash_cli/commands/archive.py`，以錯誤碼 fail closed。否決：這會把互動式決策（使用者可合法選擇繼續）塞進非互動 CLI，需要新旗標與新錯誤碼，影響面大；skill 層守門即可覆蓋兩個變體的實際入口，且 `cash-commit` 子流程呼叫 CLI archive 時不應被此守門擋下。
- **只加強文案、不加守門**：只做固定模板。否決：模板只在 `cash-apply` 收尾時出現，使用者直接執行 `/cash-archive`（例如隔天回來收尾）時仍然沒有任何提醒，正是實際踩到的情境。
- **讓 cash-archive 直接改跑 commit 流程**：偵測到未提交檔案時自動轉呼叫 `cash-commit`。否決：skill 之間互相 invoke 違反現有 workflow 邊界（各 skill 明確禁止 invoke 其他 skill），且剝奪使用者的選擇權。

## Capabilities

### New Capabilities

（無——不新增 capability 目錄，變更全部落在既有 `cash-skill-workflows` capability。）

### Modified Capabilities

- `cash-skill-workflows`：
  - MODIFIED「cash-apply 封存指引須指引提交優先」：由「回覆須包含兩條路徑」強化為「回覆 MUST 逐字輸出固定文案模板」。
  - ADDED「cash-archive 單獨封存前的未提交來源守門」：定義守門的觸發條件（touched files ∩ git dirty 非空）、兩個互斥出口、靜默通過條件與唯讀約束，以及兩個變體的對等要求。

## Impact

- Affected specs:
  - openspec/specs/cash-skill-workflows/spec.md
- Affected code:
  - New:
    - (none)
  - Modified:
    - .claude/skills/cash-apply/SKILL.md
    - .agents/skills/cash-apply/SKILL.md
    - .claude/skills/cash-archive/SKILL.md
    - .agents/skills/cash-archive/SKILL.md
    - scripts/cash-skills/tests/skill-checks.fish
    - scripts/cash-skills/tests/test_live_namespace.py
    - cash-skills.version
    - .cash-skills/lib/cash_cli/installer.py
    - .cash-skills/manifest.tsv
  - Removed:
    - (none)

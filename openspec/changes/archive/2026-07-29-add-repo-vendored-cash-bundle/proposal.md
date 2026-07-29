## Summary

新增可提交進專案版控的 Cash vendored bundle 模式。維護者執行一次安裝並提交受管 runtime、skills 與 portable manifest 後，團隊成員只需 clone 或 pull，即可直接使用 repo-local Cash skills 與 CLI，不必在每台機器重新安裝或初始化 receipt。

## Motivation

目前專案已把 `.agents/skills/`、`.claude/skills/` 與 `.cash-skills/` runtime 納入版控，但 CLI 啟動信任仍依賴被 `.gitignore` 排除、包含 `st_dev`／`st_ino` 的 machine-local receipt。新 clone 因此必須由每位團隊成員執行一次 `--init-receipt`，使「維護者安裝並提交一次」無法成為完整的團隊交付方式。

receipt 對直接安裝與 registry target 仍提供必要的本機 identity 保護；問題不是移除 receipt，而是缺少一個適用於 repo-vendored、可跨 clone 驗證且不需要首次執行寫入的信任模式。

## Proposed Solution

- 在 installer 增加 `--vendor <project>` 模式，讓維護者把受管 launcher、runtime、兩套 skills 與 portable manifest 發佈到目標 repo；preflight 必須確認所有預計提交的路徑已 tracked 或不受任何 Git exclude 規則排除，此模式不建立 machine-local receipt。
- portable manifest 只記錄可跨機器重現的 bundle version、runtime generation，以及受管檔案的 path、digest 與 Git logical executable mode；不得記錄 `st_dev` 或 `st_ino`。
- launcher 採明確且互斥的信任優先序：portable manifest path 存在時只走 vendored 驗證，manifest 無效時不得降級；manifest 不存在時才走既有 receipt 驗證；兩者皆無時維持 `bootstrap_invalid`。因此既有成員 pull 到 vendored commit 後，即使本機仍留有被 Git ignore 的舊 receipt，也會唯讀切換到 committed manifest。
- vendored 驗證在 shared stable lock 內以 no-follow regular-file、single-link、digest／mode 與動態 FD/path identity 檢查保護執行中的 bundle，全程不寫入 target。
- launcher 在 import managed runtime 前停用 Python bytecode寫入，並讓 `cash_cli` namespace只從已驗證的 `.py` source載入、不讀取既存 `.pyc`，使執行內容與manifest generation一致且首次唯讀command不建立 `__pycache__`。
- 為現有 receipt-based 安裝加入受控的一次性 launcher bootstrap migration：只接受明列的既有 launcher baseline、保留 `.cash-workspace.lock` identity，並在 exclusive lock 內完成 launcher 與 receipt 的一致轉換。
- 現有 `--target`、registry 與 `--init-receipt` 流程繼續使用 receipt 模式；source-only `--self`改為同步 canonical portable manifest並清除舊 source receipt。vendored repo 的更新由維護者重新執行 `--vendor` 並提交 diff，不做背景更新。

## Non-Goals

- 不提供組織層級的 Codex／Claude 外掛強制安裝或使用者全域設定佈署。
- 不在 clone 後自動建立 receipt、修改工作樹或執行 first-run installer。
- 不提供背景更新、遠端自動下載或未提交的 runtime 漂移。
- 不隨 bundle 內附 Python、Codex 或 Claude 執行環境。
- 不把既有直接安裝與 registry target 改成 portable-manifest 信任模式。

## Alternatives Considered

- **直接提交 receipt**：receipt 含 clone／filesystem 特定的 `st_dev` 與 `st_ino`，跨機器不可攜，且會削弱既有 identity 契約。
- **launcher 自動執行 `--init-receipt`**：會造成 clone 後首次使用的隱性寫入、read-only checkout 失敗與不清楚的信任建立時點，並違反現有不得 auto-trigger receipt 初始化的契約。
- **只提交 skills、不提交 CLI runtime**：可讓 agent 找到 skill，但 skill 依賴的 project-local Cash CLI 仍無法通過啟動 gate，未解決端到端團隊使用情境。
- **另建第二套 vendored launcher**：會形成雙 bootstrap、雙文件來源與不同更新路徑，增加維護與稽核成本。

## Capabilities

### New Capabilities

- 無。

### Modified Capabilities

- `cash-cli`：新增 repo-vendored 發佈、portable manifest 驗證、信任模式優先序與受控 launcher bootstrap migration。
- `cash-skill-workflows`：定義維護者一次發佈、團隊成員 clone 後直接使用，以及 vendored bundle 更新與文件契約。

## Impact

- Affected specs:
  - `openspec/specs/cash-cli/spec.md`
  - `openspec/specs/cash-skill-workflows/spec.md`
- Affected code:
  - New:
    - `.cash-skills/manifest.tsv`
  - Modified:
    - `cash-skills.version`
    - `.cash-skills/bin/cash`
    - `.cash-skills/lib/cash_cli/installer.py`
    - `AGENTS.md`
    - `CLAUDE.md`
    - `CASH-SKILLS.md`
    - `CASH-INIT-RECEIPT.md`
    - `scripts/cash-skills/tests/test_bundle_version_history.py`
    - `scripts/cash-skills/tests/test_installer_runtime.py`
    - `scripts/cash-skills/tests/test_init_receipt.py`
    - `scripts/cash-skills/tests/skill-checks.fish`
  - Removed:
    - 無。

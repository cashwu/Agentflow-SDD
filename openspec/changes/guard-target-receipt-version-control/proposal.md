## Summary

讓 installer 在部署 target 時，確保 target 的 `.gitignore` 排除 machine-specific receipt 與 per-target state 進入版控。

## Motivation

`.cash-skills/receipt.tsv` 依現行 contract 記錄 target-specific `st_dev`/`st_ino`，用於偵測 stable launcher 與 workspace lock 是否被抽換；這是刻意的安全設計。但 installer 只把 receipt 寫入 target，不會確保 target 排除它進入版控，因此一旦 receipt 被納入版控，任何 inode 不同的取得方式都會使該 target 的 CLI 完全不可用。

實測已確認：把已部署 target 的 `.cash-skills` 複製到新路徑（bytes 逐一相同、僅 inode 不同），launcher 立即以 `receipt_invalid` 失敗並回報 `stable record drift`，所有 command 不可執行。

舊 bundle 使這個風險更難察覺。舊 receipt schema 只有版本與 24 個 digest，不含任何 machine-specific 欄位，因此當時把它納入版控是正確做法，既有 target 也普遍如此。新 schema 加入 device 與 inode 之後，同一個已在版控中的檔案就變成有害，而系統沒有任何偵測、警告或遷移機制。

## Proposed Solution

- 讓 installer 的 direct、registry 與 batch 模式，在部署時確保 target 根目錄的 `.gitignore` 含有 `.cash-skills/receipt.tsv`、`.cash-skills/state/` 與 `__pycache__/` 三項規則。
- 保留 project-owned 內容：以 byte 層逐行精確比對判定，只把缺少的規則附加至檔案尾端，既有內容不重排、不去重、不刪除。
- `.gitignore` 不存在時建立之；既有但為 symlink、非 regular file、hard link 或無法安全讀取時，在首次 target write 前 fail closed。
- 將 `.gitignore` 納入既有的 installation inputs 與 snapshot revalidation：post-lock 不一致時重新分類、publication 前不一致時 fail closed，兩者皆不靜默覆寫外部修改。
- 維持 idempotence：三項規則齊備時該項目零寫入。
- 對 receipt 已被納入版控的既有 target，以 diagnostic 回報並建議清理動作，不代為修改使用者的版控索引。

## Non-Goals

- 不修改 stable launcher `.cash-skills/bin/cash`。改善 installed target 的 receipt 失效診斷需要先建立 stable bootstrap migration 契約，屬於獨立變更；本 change 若改動 launcher bytes，既有 installed target 反而會全數無法安裝。
- 不將 source-only `--self` 納入本保護。既有契約要求 `--self` real run 只寫 receipt 且 current 時零寫入，而 source bootstrap 沒有 transaction；source repository 的 `.gitignore` 由該 repository 自行維護。
- 不自動修改使用者的版控索引，不執行任何取消追蹤操作。
- 不改變 receipt 記錄 target-specific identity 的既有安全設計。
- 不改變 `updated`／`current`／`newer`／`conflict`／`failed` 既有分類語意。

## Alternatives Considered

- 讓 receipt 不再記錄 device 與 inode：會移除偵測 stable launcher 與 lock 被抽換的能力，削弱既有安全性質。
- 以 marker 界定的 managed block 管理 `.gitignore`：引入 marker 損毀、巢狀與孤立等失敗模式，且使用者搬移規則位置即產生 drift。
- 僅以文件說明要求使用者自行排除：已證實不可靠，既有 target 全數已把 receipt 納入版控，且失效症狀出現在取得端、離原因很遠。

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `cash-cli`: installer 增加 target `.gitignore` 版控排除保護，並將其納入既有 managed inventory 的分類、回滾與零寫入條文。

## Impact

- Affected specs: `cash-cli`
- Affected code:
  - Modified:
    - `.cash-skills/lib/cash_cli/installer.py`
    - `scripts/cash-skills/tests/test_installer_runtime.py`
    - `scripts/cash-skills/tests/skill-checks.fish`
    - `CASH-SKILLS.md`
    - `cash-skills.version`

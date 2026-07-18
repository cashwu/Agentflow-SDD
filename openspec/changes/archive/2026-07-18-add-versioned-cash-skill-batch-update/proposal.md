## Why

目前 cash skills 雖可安裝到其他專案，但來源更新後仍需逐一進入每個專案重跑 installer，且缺乏可判斷版本新舊與保護目標端修改的共同契約。需要一個由使用者明確觸發、可集中維護已登錄專案的版本化更新流程，降低漏更新與誤覆寫風險。

## What Changes

- 為整組 24 個 cash skill files 定義單一 SemVer bundle 版本，並在成功安裝後於目標專案保存版本與受管檔案雜湊 receipt。
- 擴充單一專案 installer：來源版本較新且目標受管檔案未漂移時可安全升級；目標版本相同或較新時不更新；缺少 receipt 時執行明確的首次安裝／接管規則。
- 將使用者層級專案 registry 與手動批次更新整合進同一支 installer，讓 `install-cash-skills.fish` 同時支援 target、register、unregister、list、all、dry-run 與 force 操作，不再要求使用者記住第二支更新 script。
- 讓每次成功的 target 安裝同時移除四個可辨識的 retired `spectra-propose-plus`／`spectra-apply-plus` skill 目錄；不符合 legacy shape、含額外內容或位於 symlink boundary 的候選路徑一律在任何 target write 前 fail closed，且非 plus 的 `spectra-*` skills 保持不變。
- 批次更新預設保留目標端修改並回報 conflict；只有明確使用 --force 才可覆寫漂移的受管檔案。單一專案失敗不阻止其他專案處理，但整體命令會以非零狀態回報未完成項目。
- 補齊版本順序、registry 安全邊界、receipt 漂移、dry-run、部分失敗與文件契約的 regression fixtures。

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `cash-skill-workflows`: 將現有無狀態單一專案安裝契約擴充為具 bundle 版本、目標 receipt 與使用者明確觸發之 registry 批次更新契約，同時維持無背景排程。

## Impact

- Affected specs: `cash-skill-workflows`
- Affected code:
  - New:
    - `cash-skills.version`
  - Modified:
    - `install-cash-skills.fish`
    - `scripts/cash-skills/tests/skill-checks.fish`
    - `CASH-SKILLS.md`
  - Removed: (none)

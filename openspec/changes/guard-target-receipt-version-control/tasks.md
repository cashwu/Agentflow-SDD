## 1. 版控排除保護

- [ ] 1.1 在 `.cash-skills/lib/cash_cli/installer.py` 實作 **Target 版控排除保護** 的判定與寫入：對 target 根目錄 `.gitignore` 以 byte 層逐行精確比對檢查 `.cash-skills/receipt.tsv`、`.cash-skills/state/` 與 `__pycache__/`，比對容忍行尾 `\r` 且不要求 UTF-8；缺少者只附加至尾端並沿用既有行終止符，既有內容逐 byte 保留且 mode 保留，既有內容未以行終止符結尾時先補一個；檔案不存在時以 `0644` 建立並納入同一 transaction；symlink／非 regular file／hard link／不可安全讀取時在首次 target write 前以 execution error 失敗且 `--force` 不繞過。範圍限 direct、registry 與 batch 模式，不含 `--self`。以 `skill-checks.fish` 驗證全新 target 取得三項規則、既有自訂內容逐 byte 不變、只在尾端追加缺少項。
- [ ] 1.2 在 `.cash-skills/lib/cash_cli/installer.py` 將 `.gitignore` 納入 installation inputs 與 post-lock／publication 前的 revalidation，使判定與寫入內容由同一份 no-follow snapshot 導出；post-lock 不一致時重新分類、publication 前不一致時以 execution error fail closed，兩者皆不覆寫外部修改；並固定該檔在 transaction operation 序列中的位置。既有的外部修改注入 hook 位於 post-lock revalidation 之前，因此 publication 前的案例需另新增組裝後／publication 前的 hold hook，不得沿用既有 hook 以免測試實際落在 post-lock 階段。以 `scripts/cash-skills/tests/test_installer_runtime.py` 新增兩個檢查點各自的外部修改案例，分別驗證重新分類與 fail closed，且外部修改未被覆寫。
- [ ] 1.3 在 `scripts/cash-skills/tests/test_installer_runtime.py` 先新增失敗測試再驗證 **Acceptance criteria** 的其餘各項：無尾端行終止符的既有檔案、空檔案、不含任何行終止符的單行檔案、CRLF、非 UTF-8 pathname bytes、symlink／非 regular file／hard link 的 fail-closed（含 `--force`）、三項規則齊備時零寫入且回報 `current`、`--dry-run` 零寫入、transaction 失敗時依既有 rollback 契約還原，並涵蓋 `.cash-skills/`、`.cash-skills/state`、`/.cash-skills/state/`、`*.tsv` 等不得判定為已涵蓋的既有寫法。同時重新校準 `CASH_INSTALL_FAIL_AFTER` 的硬編索引或改以 operation path 注入失敗，確認既有 rollback 測試仍落在原本階段。
- [ ] 1.4 在 `.cash-skills/lib/cash_cli/installer.py` 實作已納入版控的 receipt 偵測與回報：以唯讀 version-control index 查詢判定，為真時輸出 diagnostic 至 stderr 指出狀態與建議動作，查詢失敗靜默略過，不修改版控索引、不改變結果分類與 exit code。以 `test_installer_runtime.py` 驗證已追蹤／未追蹤／查詢失敗三種 target 的輸出差異、索引未變與分類未變，涵蓋分類為 `current` 的 target 仍輸出 diagnostic，並斷言輸出串流為 stderr。

## 2. 文件與版本

- [ ] 2.1 修改 `CASH-SKILLS.md`，說明 installer 會確保 target `.gitignore` 排除 machine-specific receipt 與 per-target state、byte 層逐行精確比對的判定規則與等價寫法不視為已滿足的後果、只附加不重排的保留策略，以及既有 target 若 receipt 已被納入版控時的一次性清理步驟；在 `scripts/cash-skills/tests/skill-checks.fish` 的文件 literal 清單加入對應斷言；並提升 `cash-skills.version`。以 `skill-checks.fish` 的 bundle 版本治理測試驗證版本嚴格遞增與文件敘述一致。

## 3. 驗收

- [ ] 3.1 執行 `.cash-skills/bin/cash validate --all`、`fish scripts/cash-cli/tests/cli-checks.fish` 與 `fish scripts/cash-skills/tests/skill-checks.fish`，並以隔離 fixture target 驗證 **Acceptance criteria** 全部七項成立；確認 `.cash-skills/bin/cash` 逐 byte 未變、`newer` 與 `conflict` target 零寫入、既有 `updated`／`current`／`newer`／`conflict`／`failed` 分類語意未改變，且測試後無 receipt 或 state 殘留。

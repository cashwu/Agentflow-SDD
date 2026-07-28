---
id: umask-dependent-mode-contract
type: recurring-finding
status: open
occurrences: 2
first_seen: 2026-07-27
last_seen: 2026-07-28
links:
  - openspec/changes/target-receipt-bootstrap/reviews/propose-r1.md
  - openspec/changes/target-receipt-bootstrap/reviews/apply-r1.md
---

# Umask-dependent mode contract

一條以精確檔案 mode 為判準的契約（`0755`／`0644` 逐 bit 比對）被套用到由 git checkout 或其他環境相依機制產生的檔案上，而 checkout 的實際 mode 是 `0666/0777 & ~umask`——契約在 umask `022` 環境成立、在 `002` 等群組協作預設下必然失敗，「開箱即用」主張因此變成機器相依。修法是明文承認 umask 前提，或在進入 mode 檢核前加入受控的 mode 正規化步驟（no-follow lstat 確認 regular file 後 chmod 為契約值），並以固定 umask 的 fixture 測試兩種環境。

## Occurrences

- 2026-07-27 — target-receipt-bootstrap — cash-propose round 1 — 「clone 即用」隱含依賴 umask `022`：在 umask `002` 機器上 checkout 出 launcher `0775`／其餘 `0664`，launcher 的 `open_regular` 自檢與 init 的 inventory mode 檢核都會 fail closed，原 artifacts 未承認此假設；修正為 init 流程加入 managed inventory 的 mode 正規化步驟並以 umask `002` fixture 測試。
- 2026-07-28 — target-receipt-bootstrap — cash-apply round 1 — 同一個 change 的第二次命中，這次落在 source-repo 判定式而非 inventory 檢核：`init_source_layout` 沿用 launcher `is_source_layout` 的逐 bit mode 相等比對，但它比對的 marker（`install-cash-skills.fish`、`cash-skills.version`、`CASH-SKILLS.md`、legacy manifest）全都不在 mode 正規化涵蓋的 managed inventory 內，因此 umask `002` clone 的 canonical source repository 被誤判為一般 target 並直接簽發 receipt，與同一 change 明文支援 umask 偏移 clone 的立場自相矛盾。修法是讓該判定只依存在性與 regular-file 形狀加上可解析的版本檔，不以 contract mode 為條件。教訓：為某條路徑加了 mode 正規化，不代表同一個 change 內其他讀 mode 的判定都被涵蓋，必須逐一盤點哪些路徑在正規化的覆蓋範圍內。

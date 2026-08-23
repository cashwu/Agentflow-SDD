<!-- cash-apply implementation notes | change: guard-task-state-integrity | initialized: 2026-08-22 23:44 | no entries below means no deviations or open questions were recorded -->

## 2026-08-23 08:06 — 改用 cash-ingest 的無參數入口

- 類別：deviation
- 任務：n/a
- 內容：原 contract 導向 `/cash-ingest <name>`／`$cash-ingest <change-name>`，但現行 cash-ingest 將 argument 視為 plan file；改為無參數 invocation，明示以目前 `touched_invalid` 與 change name 的 conversation context 進入 change selection，復原結果不變。
- 原因：帶 change-name argument 在現行 workflow 不可執行；無參數 conversation-context path 是既有支援機制，且不改變 observable behavior、interface/data shape、failure mode or acceptance criteria。

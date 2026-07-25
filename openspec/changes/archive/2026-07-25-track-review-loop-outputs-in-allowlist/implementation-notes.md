<!-- cash-apply implementation notes | change: track-review-loop-outputs-in-allowlist | initialized: 2026-07-25 20:19 | no entries below means no deviations or open questions were recorded -->

## 2026-07-25 20:27 — 記錄共用 signal 判準實測值
- 類別：deviation
- 任務：5.1
- 內容：依 task 與 design.md C4 的明確要求，在本檔記錄 workspace 實測值：含非空 `links` 的 signal 檔共 95 個，`links` 跨越多個 change 的 signal 檔共 37 個，跨越多個目前仍 active 或 parked change 的 signal 檔共 0 個；套用 change 目錄存在性條件後，僅因已封存 change 歷史 link 而被判為共用的誤判數為 0。
- 原因：Implementation Notes Protocol 原則上只收 deviation 與 open-question，但 task 5.1 與 design.md C4 另行要求把這組觀測值寫入本檔；因此以 deviation 留下可稽核紀錄，不改變任何產品 contract 或實作行為。

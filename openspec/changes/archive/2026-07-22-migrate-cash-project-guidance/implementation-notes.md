<!-- cash-apply implementation notes | change: migrate-cash-project-guidance | initialized: 2026-07-22 11:33 | no entries below means no deviations or open questions were recorded -->

## 2026-07-22 13:52 — macOS 不支援 directory FD child lookup
- 類別：open-question
- 任務：5.2
- 內容：本機驗證顯示 macOS 可開啟並 `stat` `/dev/fd/<dir-fd>`，但同一 Perl process 對 `/dev/fd/<dir-fd>/AGENTS.md` 的 child lookup 回傳 `ENOENT`；目前 `design.md`、delta spec與 task 5.2 明定所有 child operations透過該 namespace，無法在本平台完成可通過的 publisher。需要決定改採 Perl `syscall` 的 `openat`／`renameat`／`unlinkat`、以 `fchdir` 綁定 held directory object，或將平台不支援視為安裝器全面 fail closed。
- 原因：依 Implementation Contract 擅自改用未定義 primitive會偏離 durable handoff；全面 fail closed則會使本 repository的macOS installer成功路徑與現有tests失效，因此必須先由 `$cash-ingest migrate-cash-project-guidance` 更新機制與驗證合約。

## 2026-07-22 13:52 — directory FD child lookup決議
- 類別：open-question
- 任務：5.2
- 內容：`$cash-ingest migrate-cash-project-guidance` 已將publisher機制更新為Perl `chdir($directory_fh)`：先以no-follow開啟並`fstat` parent directory FD，將單一publisher process的working directory綁定到held object並核對`stat(".")` identity，再只對validated relative basenames執行child operations；不再要求`/dev/fd/<dir-fd>/<basename>`。
- 原因：macOS不支援`/dev/fd` directory child traversal，但已實測Perl `chdir($directory_fh)`可用且在parent pathname被rename後仍維持原directory object授權邊界；此更新保留原安全語意並避免platform-specific syscall numbers。

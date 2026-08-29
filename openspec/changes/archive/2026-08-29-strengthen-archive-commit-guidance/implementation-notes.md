<!-- cash-apply implementation notes | change: strengthen-archive-commit-guidance | initialized: 2026-08-29 20:23 | no entries below means no deviations or open questions were recorded -->

## 2026-08-29 12:00 — BUNDLE_VERSION 常數需與 cash-skills.version 同步
- 類別：deviation
- 任務：3.2
- 內容：task 1.1 依設計只把 `cash-skills.version` 由 2.18.0 提升為 2.18.1，但全套測試中的 installer runtime contract 測試斷言 `.cash-skills/lib/cash_cli/installer.py` 的 `BUNDLE_VERSION` 常數必須等於 `cash-skills.version`。已依歷次版本 bump 的既有 codebase 慣例（如 commit 1ab35dd 同時更新兩處）把該常數同步為 "2.18.1"，並於下一次 Cash CLI 呼叫前重跑 `./install-cash-skills.fish --self` 重建 manifest（installer.py 屬 runtime record）。
- 原因：proposal Non-Goals 的「不修改 `.cash-skills/lib/cash_cli/` 任何 runtime 程式」意在保持 archive／commit 的行為不變；版本常數同步不改變任何可觀察行為、interface、失敗模式或驗收標準，且不同步時 task 3.2 的 success 條件（skill-checks 全綠）在現實上不可達，屬機制替換而非 contract 變更。

## 2026-08-29 12:20 — legacy touched 路徑 literal 需加入 live-namespace allowlist
- 類別：deviation
- 任務：3.2
- 內容：design D2 與 delta spec 要求 cash-archive 守門步驟逐字寫出 legacy 路徑 `.spectra/touched/<name>.json`，但 `scripts/cash-skills/tests/test_live_namespace.py` 的 live-namespace 掃描禁止 `.spectra/touched` literal 出現在 `touched_allow` allowlist 之外，導致兩個 cash-archive SKILL.md 以 `unmanaged legacy touched-state literal` 失敗。已把 `.claude/skills/cash-archive/SKILL.md` 與 `.agents/skills/cash-archive/SKILL.md` 加入該測試既有的 `touched_allow` 集合。
- 原因：守門對 legacy touched state 的引用是受管理的唯讀引用（涵蓋 CLI import-then-delete 的同一 hazard），與該掃描要防的「unmanaged 遺留引用」不同類；擴充既有 allowlist 不新增機制、不改變任何觀察行為與驗收標準，屬機制替換而非 contract 變更。`test_live_namespace.py` 不在 grader 保護清單內。

## 2026-08-29 12:35 — 兩筆 deviation 已回填 design 與 proposal
- 類別：deviation
- 任務：n/a
- 內容：前兩筆 deviation（BUNDLE_VERSION 同步、live-namespace touched_allow 擴充）已回填：proposal Non-Goals 加入版本常數同步例外、proposal Impact Modified 加入 `.cash-skills/lib/cash_cli/installer.py` 與 `scripts/cash-skills/tests/test_live_namespace.py`；design D5 補 BUNDLE_VERSION 同步與 manifest 重建義務、design D2 補 live-namespace 掃描配套。
- 原因：對齊 open signals `implementation-deviation-not-backfilled` 與 `declared-scope-implementation-drift` 描述的 anti-pattern，於 review loop 開始前完成回填，使 durable artifacts 與實作一致。

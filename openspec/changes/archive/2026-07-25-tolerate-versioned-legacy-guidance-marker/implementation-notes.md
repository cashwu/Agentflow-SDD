<!-- cash-apply implementation notes | change: tolerate-versioned-legacy-guidance-marker | initialized: 2026-07-25 18:35 | no entries below means no deviations or open questions were recorded -->

## 2026-07-25 19:58 — 字尾字集必須同時排除 CR 與 LF，而非只排除 LF

- 類別：deviation
- 任務：2.1
- 內容：IC1 與 delta 原本把字尾定義為「不含 `<`、`>` 與換行」，實作最初據此寫成 `[^<>\n]+`，只排除 LF。apply round 1 的 review 指出並實測確認：該字集會讓 CR-only 行界之後的 project-owned bytes 被當作 marker 字尾而納入 managed span，並在遷移時隨該 span 一併被替換或移除，而尾側緊接 LF 使它通過非獨立行判定、不會被任何既有 fail-closed 攔下。實作改為 `[^<>\r\n]+` 並新增一個 CR 邊界的 fail-closed fixture（`test_suffixed_malformed_guidance_fails_closed` 的 `carriage-return-in-suffix` case）。本次一併把 delta、design IC1／D1 與 tasks 2.1 的「換行」明確化為「CR 與 LF」，並在 delta 補上該排除的理由，另開 signal `newline-byte-class-excludes-only-lf`。
- 原因：屬 contract 不變的機制修正，走機制替換分支。要交付的觀察行為未變——帶字尾 marker 仍被辨識、managed span 外 bytes 仍逐 byte 保留、五種判定仍 fail closed；改變的只是「哪些 bytes 算字尾」這個實作層判準，且方向是收緊而非放寬。artifact 的字面若停留在「換行」而被讀成僅 LF，會使 spec 比實作寬：日後有人退回 `[^<>\n]+` 仍符合 requirement 字面，而那正是本輪修掉的缺陷。此 delta 即將併入 master 成為永久 requirement，故在封存前補明確。

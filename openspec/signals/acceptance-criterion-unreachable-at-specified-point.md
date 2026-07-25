---
id: acceptance-criterion-unreachable-at-specified-point
type: recurring-finding
status: open
occurrences: 6
first_seen: 2026-07-25
last_seen: 2026-07-25
links:
  - openspec/changes/harden-installer-mode-and-recovery/reviews/propose-r1.md
  - openspec/changes/harden-installer-mode-and-recovery/reviews/propose-r7.md
  - openspec/changes/derive-version-assertion-and-add-cli-help/reviews/propose-r1.md
  - openspec/changes/derive-version-assertion-and-add-cli-help/reviews/propose-r2.md
  - openspec/changes/derive-version-assertion-and-add-cli-help/reviews/propose-r4.md
  - openspec/changes/tolerate-versioned-legacy-guidance-marker/reviews/propose-r4.md
  - openspec/changes/guard-post-archive-commit-allowlist/reviews/propose-r1.md
  - openspec/changes/track-review-loop-outputs-in-allowlist/reviews/propose-r1.md

---

# 驗收條件在指定位置不可能成立

scenario 的 THEN 指定了一個時間點（例如「首次 write 之前」），但被驗收的機制在程式碼中的位置晚於該時間點，使該條件在字面上無法成立；由於測試只斷言較弱的部分，測試仍會通過而落差不被發現。

## Occurrences

- 2026-07-25 — harden-installer-mode-and-recovery — cash-propose round 1 — hold path 形狀的 scenario 要求「在首次 target write 前 fail closed」，但兩個 hold 等待點都在 `acquire_lock` 建立 workspace lock 與 launcher 發布之後；修正為把 hook 設定驗證前移到任何取鎖之前的 preflight。

- 2026-07-25 — harden-installer-mode-and-recovery — cash-propose round 7（re-run）— 同一 requirement 內兩條 MUST 互斥而使 scenario 子句無任何實作可滿足：(1) 兩個 hold hook 指向同一路徑時「publication hook 仍正常等待」與 ready 檔 exclusive 建立、release 檔在等待點不得預先存在互斥；(2) 只在等待點可判定的 release 形狀被塞進「首次 target write 之前 fail closed」的 THEN，而等待點在 `acquire_lock` 之後。修法分別為 preflight 要求兩個 hold path 互異，以及把 scenario 依可判定時機拆為兩個。

- 2026-07-25 — derive-version-assertion-and-add-cli-help — cash-propose rounds 1、2、4 — 驗收條件在指定時點或指定檔案內不可達：spec 的 help MUST 無條件成立但 launcher 在 `main()` 之前就驗 receipt；tasks 要求「以 `test_bundle_version_history.py` 驗證內容綁定」而該分支在升版未 commit 時被 early return 跳過；一個描述變更前現況的斷言被要求「驗證在實作前失敗」而 red 階段不可達。

- 2026-07-25 — tolerate-versioned-legacy-guidance-marker — cash-propose round 4 與 round 6 — Q4：tasks 3.2 被指派承接「Missing、Spectra-only 與 mixed guidance 收斂」，但它只跑 `--dry-run`，而 dry-run 既不寫檔也不輸出 guidance diff，該 scenario 的三條斷言沒有一條被觀察到。F2：red-first 規則對 1.7 生效，但 1.7 在現行實作下任何 fixture 形狀都無法變紅——其對照組是「完成 2.1 但未完成 2.3 的中間實作」而非現行實作。

- 2026-07-25 — guard-post-archive-commit-allowlist — cash-propose round 1 與 round 2 — 任務的驗證目標引用整組 `skill-checks.fish codex-command-matrix`，但該組同時檢查尚未被該任務修改的其他 SKILL 檔字面句，驗收在該任務的時點必然失敗；round 1 修好任務 3.1 後，同型缺陷在 round 2 被發現只是搬到任務 3.2，最終把「四個檔全部改完之前，以通過為驗收的 task 一律改用單一檔案 `rg -F`」升級為 design 通則。

- 2026-07-25 — track-review-loop-outputs-in-allowlist — cash-propose round 1 — TDD 紅燈任務宣稱七個新測試都會以 `invalid_arguments` 失敗，但其中一個案例斷言的正是該 code，現行 fallback 已回它，該案例在紅燈階段必然通過；同時該檔既有 helper 只回傳 `Workspace.discover(root)`，而 argument 解析行為只存在於 `execute()`，需要 chdir 進 temp root 才能驅動。

---
id: acceptance-criterion-unreachable-at-specified-point
type: recurring-finding
status: open
occurrences: 8
first_seen: 2026-07-25
last_seen: 2026-09-05
links:
  - openspec/changes/harden-installer-mode-and-recovery/reviews/propose-r1.md
  - openspec/changes/harden-installer-mode-and-recovery/reviews/propose-r7.md
  - openspec/changes/derive-version-assertion-and-add-cli-help/reviews/propose-r1.md
  - openspec/changes/derive-version-assertion-and-add-cli-help/reviews/propose-r2.md
  - openspec/changes/derive-version-assertion-and-add-cli-help/reviews/propose-r4.md
  - openspec/changes/tolerate-versioned-legacy-guidance-marker/reviews/propose-r4.md
  - openspec/changes/guard-post-archive-commit-allowlist/reviews/propose-r1.md
  - openspec/changes/track-review-loop-outputs-in-allowlist/reviews/propose-r1.md
  - openspec/changes/target-receipt-bootstrap/reviews/apply-r4.md
  - openspec/changes/dispatch-vendored-targets-in-batch/reviews/propose-r4.md
  - openspec/changes/dispatch-vendored-targets-in-batch/reviews/propose-r5.md
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
- 2026-07-28 — target-receipt-bootstrap — cash-apply round 4 — `--init-receipt` 新增 runtime 期望集合檢核後，spec Scenario 以全稱宣稱「少了任一 canonical runtime 模組即以 `init_inventory_invalid` fail closed」，但 19 個成員中有 4 個是 `cash_cli.installer` 的 import-time 相依（`installer.py` 自身、它直接匯入的 `config.py`、套件 `__init__` 鏈上的 `main.py` 與 `errors.py`），缺席時 `-m` 載入即以 `No module named` 死亡，位置遠早於該檢核，條件在字面上不可能成立。測試之所以全綠，是因為兩個 runtime 案例恰好都挑了非 import-time 成員；更嚴重的是同批新增的排錯文件把 `config.py` 列為最可能被 `.gitignore` 誤吞的檔名，指向一條對它永不觸發的路徑。修法是收斂全稱敘述、於 Non-Goals 明載此類 import-time 失敗，並以參數化測試逐一斷言全部成員落在具名 error code 或 import-time 失敗何者，使不對稱在套件內可見。相關：[[expected-set-derived-from-observed-state]]。
- 2026-09-05 — dispatch-vendored-targets-in-batch — cash-propose rounds 4–5 — bundle version bump task 以 `test_bundle_version_history.py` 為 verification，但其 `__main__` 的 `check_history` 無條件要求 `.cash-skills/manifest.tsv` 逐 byte 等於由工作樹版本導出的 canonical bytes，因此從 bump 完成到 `--self` 重新發佈之間該腳本必然以 `portable manifest is not canonical` 失敗；round 5 又發現文件 task 的 regression `skill-checks.fish` 是包含同一 gate 的超集而排在 `--self` 之前，修法是重排使發佈先於文件 task。

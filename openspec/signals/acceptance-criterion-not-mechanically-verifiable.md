---
id: acceptance-criterion-not-mechanically-verifiable
type: recurring-finding
status: open
occurrences: 4
first_seen: 2026-07-25
last_seen: 2026-07-28
links:
  - openspec/changes/align-cli-skill-contracts/reviews/propose-r1.md
  - openspec/changes/tolerate-versioned-legacy-guidance-marker/reviews/propose-r1.md
  - openspec/changes/rightsize-cash-skills/reviews/propose-r2.md
  - openspec/changes/target-receipt-bootstrap/reviews/apply-r3.md
---

# Acceptance criterion not mechanically verifiable

An acceptance criterion is phrased against a state that no longer exists at verification time — most often the pre-change behavior — so no test can be written for it. It reads as rigorous while being untestable, and the corresponding spec scenario usually states a weaker but checkable version, leaving the two out of step.

## Occurrences

- 2026-07-25 — align-cli-skill-contracts — cash-propose round 1 — C4 的驗收寫「--scope all 的結果集合與變更前的預設結果集合相同」，測試環境沒有變更前的實作可比對；改寫為走訪層的超集合命題後才可機械驗證。

- 2026-07-25 — tolerate-versioned-legacy-guidance-marker — cash-propose round 1 — W6：三項驗收基準都是本機一次性且會自我銷毀的。Tubify 的 span offset `(1200, 5095)` 在第一次真實安裝後即永久失效（同一次修復會從該檔刪去前 1198 bytes），`would-update=7` 綁定本機 registry 條目數且真實安裝後會變成 `current=7`。修法是把 byte-identity 斷言改綁到可重跑的 fixture，一次性量測降級為 proposal 的證據。
- 2026-07-26 — rightsize-cash-skills — cash-propose round 2／3 — 把 fallback 規則的所在位置寫成 MUST，但機械斷言只能計數而無法判定「首次使用之前」；另一條 scenario 的 WHEN 是套件執行，AND 卻要求驗證測試檔的靜態註解屬性。
- 2026-07-28 — target-receipt-bootstrap — cash-apply round 3 — Implementation Contract 第 7 項要求「每次 bump 的 commit 序位皆先於其後的 `installer.py` 修改」，但 cash change 以單一 commit 落地，中間版本 2.8.0 從未也不會存在於任何 commit，該合取項在驗收時永遠不可能為真、也無從查證。實際 gate（`test_bundle_version_history.py` 的 `check_history`）在工作樹版本嚴格遞增時即 early return，本就不檢查 commit 序位——判準寫得比實際 gate 嚴格，卻嚴格在一個不存在的維度上。修法是改以工作樹狀態與 task 序位表述。

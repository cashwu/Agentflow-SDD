---
id: acceptance-criterion-not-mechanically-verifiable
type: recurring-finding
status: open
occurrences: 2
first_seen: 2026-07-25
last_seen: 2026-07-25
links:
  - openspec/changes/align-cli-skill-contracts/reviews/propose-r1.md
  - openspec/changes/tolerate-versioned-legacy-guidance-marker/reviews/propose-r1.md
---

# Acceptance criterion not mechanically verifiable

An acceptance criterion is phrased against a state that no longer exists at verification time — most often the pre-change behavior — so no test can be written for it. It reads as rigorous while being untestable, and the corresponding spec scenario usually states a weaker but checkable version, leaving the two out of step.

## Occurrences

- 2026-07-25 — align-cli-skill-contracts — cash-propose round 1 — C4 的驗收寫「--scope all 的結果集合與變更前的預設結果集合相同」，測試環境沒有變更前的實作可比對；改寫為走訪層的超集合命題後才可機械驗證。

- 2026-07-25 — tolerate-versioned-legacy-guidance-marker — cash-propose round 1 — W6：三項驗收基準都是本機一次性且會自我銷毀的。Tubify 的 span offset `(1200, 5095)` 在第一次真實安裝後即永久失效（同一次修復會從該檔刪去前 1198 bytes），`would-update=7` 綁定本機 registry 條目數且真實安裝後會變成 `current=7`。修法是把 byte-identity 斷言改綁到可重跑的 fixture，一次性量測降級為 proposal 的證據。

---
id: test-fixture-required-case-missing
type: recurring-finding
status: open
occurrences: 7
first_seen: 2026-07-24
last_seen: 2026-07-29
links:
  - openspec/changes/replace-spectra-cli-with-cash-cli/reviews/apply-r6.md
  - openspec/changes/harden-installer-mode-and-recovery/reviews/propose-r1.md
  - openspec/changes/harden-installer-mode-and-recovery/reviews/apply-r1.md
  - openspec/changes/tolerate-versioned-legacy-guidance-marker/reviews/propose-r4.md
  - openspec/changes/tolerate-versioned-legacy-guidance-marker/reviews/propose-r7.md
  - openspec/changes/rightsize-cash-skills/reviews/apply-r1.md
  - openspec/changes/add-global-cash-shim/reviews/apply-r1.md

---

# Test fixture required case missing

A regression test claims to cover a task-required input shape, but its fixture does not actually contain the distinguishing case needed to exercise that behavior.

## Occurrences

- 2026-07-24 — replace-spectra-cli-with-cash-cli — cash-apply round 6 — Registry empty-line test claimed leading/middle/trailing coverage but only contained one non-empty record, so no true middle empty line existed；改用兩筆有效records與中間空行，並驗證順序及registry inode/mtime/bytes不變。

- 2026-07-25 — harden-installer-mode-and-recovery — cash-propose round 1 — tasks 要求的 `phase: publishing` journal fixture 沒有任何既有機制可產生（失敗注入會走 rollback 並清除 journal，崩潰型 hook 都在 committed 之後），TDD 的第一步因而沒有可執行路徑；改為明訂手工構造 schema v2 journal 的方式。
- 2026-07-25 — harden-installer-mode-and-recovery — cash-apply round 1 — User-site fixture 假設固定 site path 且 qualified shim 未真正執行 interpreter probe，無法觀察 probe 載入 `usercustomize.py`；改由真實 interpreter 探測 site path 並實跑 probe。

- 2026-07-25 — tolerate-versioned-legacy-guidance-marker — cash-propose round 1 與 round 4 — Q2 最嚴重：1.5 的五個 fail-closed case 未指明對側 marker 是否也帶字尾，而現行實作對單側帶字尾必然已 fail closed，因此四個 case 照字面寫出來在修復前就是綠的，宣稱最重要的「五種判定不放寬」驗證實際上四分之四空轉。另 W1 與 F-A2 分別遺漏帶字尾的 END 與 source 側 CASH:END，W2 的 fixture 描述自相矛盾（首行即 marker vs marker 之前另有文字）。

- 2026-07-25 — tolerate-versioned-legacy-guidance-marker — cash-propose round 7 與 round 10 —— B-2：IC4 的核心 MUST（`canonical_guidance` 須傳入帶 source 限定詞的標籤）完全沒有驗證點，因為全部失敗情境中 `marker_span` 的例外都在 target 側，source 側的兩個打到的是另一條 IC5 新例外；實作者只要在該新訊息寫死限定詞就能讓全部斷言變綠而 IC4 已被違反。B-3 與 Q-4：1.4 case 二與 1.2 的斷言非排他形式，現行實作對兩側皆帶字尾的 block 會於檔尾附加 canonical 而 exit 0，包含式斷言在修復前即成立。
- 2026-07-26 — rightsize-cash-skills — cash-apply round 1 — fallback parser 的 canonical corpus 全為單行 `ask` 形式，沒有固定 fixture 覆蓋 spec 要求的跨行 `present the same options` 形狀；修正後加入單行、跨行、單軸與重複陳述 fixtures。
- 2026-07-29 — add-global-cash-shim — cash-apply round 1 — `shim-checks.fish` 以合併組合覆蓋部分路由，卻沒有逐列執行 spec 兩個 `##### Example:` 的完整 argv：dispatch 漏 `--limit 10`，init 也漏掉四列旗標映射的獨立斷言。

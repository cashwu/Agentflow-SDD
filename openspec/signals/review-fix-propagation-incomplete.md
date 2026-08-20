---
id: review-fix-propagation-incomplete
type: recurring-finding
status: open
occurrences: 17
first_seen: 2026-07-07
last_seen: 2026-08-20
links:
  - openspec/changes/add-micro-verification-round/reviews/propose-r3.md
  - openspec/changes/converge-plus-review-loop/reviews/propose-r5.md
  - openspec/changes/chinese-spec-content/reviews/propose-r2.md
  - openspec/changes/migrate-cash-project-guidance/reviews/propose-r2.md
  - openspec/changes/migrate-cash-project-guidance/reviews/propose-r3.md
  - openspec/changes/migrate-cash-project-guidance/reviews/propose-r4.md
  - openspec/changes/migrate-cash-project-guidance/reviews/propose-r5.md
  - openspec/changes/replace-spectra-cli-with-cash-cli/reviews/propose-r6.md
  - openspec/changes/harden-installer-mode-and-recovery/reviews/propose-r1.md
  - openspec/changes/harden-installer-mode-and-recovery/reviews/propose-r2.md
  - openspec/changes/harden-installer-mode-and-recovery/reviews/propose-r3.md
  - openspec/changes/harden-installer-mode-and-recovery/reviews/propose-r4.md
  - openspec/changes/harden-installer-mode-and-recovery/reviews/propose-r5.md
  - openspec/changes/harden-installer-mode-and-recovery/reviews/propose-r6.md
  - openspec/changes/align-cli-skill-contracts/reviews/propose-r1.md
  - openspec/changes/harden-installer-mode-and-recovery/reviews/propose-r7.md
  - openspec/changes/harden-installer-mode-and-recovery/reviews/propose-r8.md
  - openspec/changes/derive-version-assertion-and-add-cli-help/reviews/propose-r3.md
  - openspec/changes/derive-version-assertion-and-add-cli-help/reviews/propose-r4.md
  - openspec/changes/derive-version-assertion-and-add-cli-help/reviews/propose-r5.md
  - openspec/changes/tolerate-versioned-legacy-guidance-marker/reviews/propose-r5.md
  - openspec/changes/track-review-loop-outputs-in-allowlist/reviews/propose-r2.md
  - openspec/changes/bootstrap-openspec-config-on-install/reviews/propose-r2.md
  - openspec/changes/support-multi-file-skill-payload/reviews/propose-r3.md
  - openspec/changes/harden-spec-trace-path-extraction/reviews/propose-r6.md
  - openspec/changes/target-receipt-bootstrap/reviews/apply-r5.md
  - openspec/changes/add-global-cash-shim/reviews/propose-r2.md
  - openspec/changes/tolerate-remount-device-renumbering/reviews/propose-r3.md
---

# Review fix propagation incomplete

A review-round fix introduces or changes a rule, but claims about that rule elsewhere in the artifact set (risk statements, invariant claims, summaries) are not re-checked and updated in the same fix pass — the fix itself becomes the source of the next round's inconsistency finding.

## Occurrences

- 2026-07-07 — add-micro-verification-round — spectra-propose-plus round 3 — Round 2 added the post-fix re-derivation rule (a discretionary judgment), but design Risks still claimed round-type derivation was "purely mechanical with no discretion", and the new discretion point had no recorded mitigation.
- 2026-07-16 — converge-plus-review-loop — spectra-propose-plus rounds 4–6 — 前三輪 fix passes 引入的規則（同意 fallback、seeded re-run carve-out、per-class 動作選單、不回升例外）未在同一 fix pass 同步到 tasks（task 2.5/2.7 滯留舊版本）、scenario 與 proposal 短句，成為後續三輪 findings 的主要來源。
- 2026-07-19 — chinese-spec-content — cash-propose round 2 — round 1 修復把 cash-ingest parity diff 補進 proposal Impact 與 tasks 4.1，但 design 決策 6/C6 未同步，成為 round 2 的 fix-introduced finding（V-1）。
- 2026-07-22 — migrate-cash-project-guidance — cash-propose rounds 2–5 — Publication recovery修正連續漏掉receipt drift、receipt-less首次安裝、可觀測adoption與零檔clean install分支；最終以現行installer可觀測的0／24全等／partial-or-different三分法同步所有artifacts與fixtures。
- 2026-07-23 — replace-spectra-cli-with-cash-cli — cash-propose rounds 3–6 — consumer schema、config validation、stable bootstrap與legacy migration修正連續引入merge phase、parser ordering、old-receipt cutover、touched雙來源及lock rollback缺口；最後三項成為abort obligations。

- 2026-07-25 — harden-installer-mode-and-recovery — cash-propose rounds 1–6 — 本 loop 最高頻的形狀，出現七次：fix 只改到被舉例的那個 artifact／運算元／檔案，未涵蓋該規則涉及的全部位置（proposal 未隨 design 更新、免除規則只涵蓋 ready 檔而漏 release 檔、Non-Goals 措辭只落在 design、`--force` 變體只落在 tasks、IC5 列舉宣稱一一對應卻有缺漏）。fix action 的記述涵蓋範圍大於實際編輯範圍是其共同成因。
- 2026-07-25 — align-cli-skill-contracts — cash-propose round 2、3、5 — 三輪各有一項 blocking finding 是前一輪修正未同步到其餘出現位置所致：C6 驗收補了內容斷言但未同步承載斷言的任務、依賴理由更正未同步到 proposal、receipt 重建規則的觸發時點未覆蓋第一個 runtime 改動。

- 2026-07-25 — harden-installer-mode-and-recovery — cash-propose rounds 7–8（re-run）— 前一次執行第六輪為 recovery 寫入新增的零寫入 carve-out 未回頭掃描三處與之互斥的無條件斷言（「無併發 installer 介入時 SHALL 為 update、SHALL NOT 為 conflict」），使同一輸入同時被要求 conflict 與非 conflict；另有兩處 fix 未同步到 IC5 與 D2／proposal。修法為在三處加上「且 recovery 之後不存在與該 journal 無關的 drift」的限定並補齊同步。

- 2026-07-25 — derive-version-assertion-and-add-cli-help — cash-propose rounds 3–5 — 改設計後未掃到所有位置：round 2 把錯誤訊息改為指向 help 卻留下 design Risks 的舊敘述與過時的 scenario 標題；round 3 把 receipt gate 覆蓋移出 task 1.1 只改了斷言本體未改具名清單；round 4 更正擁有者計數只落在 Context，Goals、回指與 proposal 三處未同步。

- 2026-07-25 — tolerate-versioned-legacy-guidance-marker — cash-propose round 3 與 round 5 — NF1 是重算 IC6 情境數時漏改另一處引用；V2 更值得記錄：修 Q4 改寫 tasks 3.2 取消內容層級前置保護，卻未同步 design 的兩處引用，造成 design 與 tasks 對同一件事互相否定，是本 loop 第一次由 fix 反向製造 design 對 tasks 的矛盾。

- 2026-07-25 — track-review-loop-outputs-in-allowlist — cash-propose rounds 2 與 3 — 同一批修復連續三次只落到部分位置：round 1 宣稱「proposal、design、spec 三處統一」但未落到 proposal；round 1 的新前置規則只傳播到兩個呼叫點中較晚的那一個，而較早的那個才是該 skill 第一次接觸 state 的位置；round 2 的前綴收斂改了測試案例卻漏了唯一的實作任務，使該任務的驗收目標自相矛盾。三次都是 `## Fix Actions` 的宣稱與實際落點不符。
- 2026-07-26 — bootstrap-openspec-config-on-install — cash-propose round 2 — 第 1 輪為修正 `--register` 語意，同步了 `proposal.md`、delta spec、design 的 D5 與 Implementation Contract，卻漏掉同一份 `design.md` 的 `## Goals`；Goals 仍寫著「三種 target mode 行為一致」，與 D5／IC 的「`--register` MUST NOT 建立該檔」直接矛盾。fix propagation 的盲點常落在同一份檔案裡層級較高、措辭較概括的段落——grep 概念時容易只命中精確識別字，而漏掉概括敘述。
- 2026-07-26 — support-multi-file-skill-payload — cash-propose round 2／3 — 連續兩輪出現同型缺陷：Round 2 的 Y6 修正只記錄並執行了 `design.md`，而同一概念也出現在 `tasks.md` 6.1 的引述句；Round 1 的改寫亦未傳播到 `proposal.md` 三段與 `tasks.md` 2.2 本文。

- 2026-07-26 — harden-spec-trace-path-extraction — cash-propose rounds 3／4／5／6 — 同一個 loop 內連續四輪出現同型缺陷，且全部發生在主 agent 自己的修正上：round 3 發現前兩輪的修正集中在 delta／design／tasks 而 proposal 被落下到互相矛盾；round 4 發現被 D6 否定的因果句只從 design 移除、仍逐字留在 proposal 與會併入 master spec 的 delta；round 5 發現第 4 輪的 tasks 側修正全部未落地；round 6 發現新增 case 時未同步該 task 的 case 計數、下游 task 的驗證句與追溯表。教訓是「修正的傳播面」本身要當成 checklist 機械檢查，而非依賴撰寫當下的記憶。
- 2026-07-28 — target-receipt-bootstrap — cash-apply rounds 4–6 — 同一 change 內連續三輪復發。round 4 的 Fix Actions 明文宣稱「`design.md` D2、Contract 第 7 項、部署時序規則段與 `proposal.md` 的部署敘述皆同步為 2.11.0」，實際上 `proposal.md` 未被更新，其 `## Impact` Deployment surface 仍記「最終部署版本為 2.10.0」——而該欄位正是「targets 目前綁定哪個版本」的權威記錄，誤信它會導致下一次 `--all` 撞上 equal-version source integrity drift 而全數失敗。同輪的 post-fix self-check 宣稱「版本三處一致」，但那三處只涵蓋版本檔／常數／receipt，未 grep artifacts。round 5 同時暴露步驟編號交叉引用只同步了 design 與文件而漏掉 tasks 與 signals。止血作法有二：self-check 改為對每個被 fix 觸及的**概念**做跨全部 artifact／文件／測試／signals 的 grep 再比對地面事實，而非只 grep 被 finding 指名的檔案；以及把易漂移的交叉引用（步驟編號）改寫為不耦合編號的指稱。即便如此 round 6 仍找出一處未收斂的全稱 Scenario，顯示概念層級的掃描清單本身也需要逐輪擴充。

- 2026-07-29 — add-global-cash-shim — cash-propose round 2 — r1 對 dry-run 順序與 init 操作順序的修復只同步 design／spec／tasks 三份，漏掉 proposal.md 的 Proposed Solution 敘述，形成 fix-introduced 的跨 artifact 矛盾。

- 2026-08-20 — tolerate-remount-device-renumbering — cash-propose round 3 — 前一輪把「指引前提」改為依 gate 分寫，spec delta、Implementation Contract、tasks 與 proposal 四處都改了，卻漏掉同一節的契約總結句——而那句正是以「因此契約規定：」開頭的權威敘述。照該句實作會直接退回被修掉的缺陷。修法是把該句一併改寫並統一小標題用語，再以 grep 掃全部四份 artifact 確認無其他殘留。

<!-- cash-apply implementation notes | change: tolerate-remount-device-renumbering | initialized: 2026-08-20 17:38 | no entries below means no deviations or open questions were recorded -->

## 2026-08-20 19:05 — 受管 guidance 的 identity drift 入口條件與第三支訊息子字串重疊
- 類別：open-question
- 任務：4.1
- 內容：`AGENTS.md` 與 `CLAUDE.md` 受管區塊以字面分類 `stable record identity drift` 作為 `--init-receipt` 的入口條件，而 IC-4 前提不成立時的第三支訊息（launcher 為 `stable record identity drift: <stable>; runtime record drift: <path>. …`，installer 為 `stable receipt identity drift: <stable> in <target>; {runtime|skill} record drift: <path>. …`）逐字含有同一個子字串。以字串比對套用該 guidance 規則的 agent，會在 IC-4 前提閘門正要擋下的情境執行重新簽發，把已漂移的 runtime／skill 內容簽為合法。三位獨立 reviewer（本輪 Reviewer A、Reviewer B，以及一次外部 review）各自提出同一筆。目前假設是「維持現狀不改」：受管區塊的內容由 IC-12 與 spec delta `Target-local receipt 初始化` requirement 逐條指定，兩者都只要求載明「identity drift 是入口、content drift 不是、版控前提」三件事，全部已滿足；補上第四條「診斷僅指名該 stable record 時才適用」是 contract 未涵蓋的新條款。
- 原因：需要使用者決定是否以 `/cash-ingest` 收緊該 requirement。這不是實作層可自行吸收的選擇——受管區塊同時被 `skill-checks.fish` 的 literal 斷言與 canonical guidance baseline SHA-256 釘死，且該區塊會由既有 guidance deployment 部署到每一個 target，變更其條款屬使用者可見的契約調整。收緊 requirement 後，才有規範依據可為新條款補 guidance contract test 並重算 baseline。

## 2026-08-20 19:22 — 前述 open question 的處置：以 ingest 收緊 requirement
- 類別：open-question
- 任務：4.1
- 內容：使用者於本次 session 明示決定，不採「維持現狀」的假設，而是回到 `/cash-ingest` 收緊 requirement：IC-12 與 spec delta 的 `Target-local receipt 初始化` requirement 追加一條——guidance MUST 指出該 `--init-receipt` 入口只在診斷「僅」指名該 stable record 時適用；訊息同時指名 `runtime` 或 `skill` record drift 時 MUST 改為還原該 record 或從可信 source 重新安裝。artifacts 更新後才實作 `AGENTS.md`／`CLAUDE.md` 的補句、`scripts/cash-skills/tests/skill-checks.fish` 的新 literal 斷言，並重算 canonical Cash guidance baseline SHA-256。此條目解決前一筆 open question 的待決狀態；原條目保留不刪改。
- 原因：該補句改變受管 guidance 區塊的條款，而該區塊會部署到每一個 target，且同時被 literal 斷言與 baseline digest 釘死，屬使用者可見的契約調整，不能由實作層自行吸收。使用者選擇此路徑而非記為 accepted risk，因此本 change 的 artifacts 需先經 ingest 更新，實作與品質關卡再據以重跑。

## 2026-08-20 19:48 — 以 session group 訊號取代 Popen.terminate／kill
- 類別：deviation
- 任務：1.1
- 內容：IC-15 對 `test_identity_drift_fails_before_acquiring_the_exclusive_lock` 的 child lifecycle 逐字寫「仍未結束時依序 `terminate`、有限等待、最後 `kill` 並再次 `communicate`」，字面指向 `Popen.terminate()` 與 `Popen.kill()`。實作改以 `Popen(start_new_session=True)` 搭配 `os.killpg(child.pid, SIGTERM)` → 有限等待 → `os.killpg(child.pid, SIGKILL)` → 有限等待，訊號種類與先後完全相同，只是作用於整個 session group。訊號序列、有限回收、cleanup 不遮蔽主要失敗原因等觀察行為與驗收標準皆不變。
- 原因：只對直屬 child 送訊號無法滿足同一條 IC-15 的 `MUST NOT 留下 child process 或持有中的 workspace lock`。`install-cash-skills.fish` 目前以 `exec` 取代自身，因此 `child.pid` 即 installer、今日不存在 grandchild；但 `Popen.terminate()` 的語意綁定在直屬 child 上，一旦 wrapper 改為 fork 而非 `exec`，真正持有 flock 並繼承 pipe 的後代就不會被回收，該 MUST 會靜默失效。以 group 訊號實作同一序列在兩種拓樸下都成立，且不需要 design 定義任何新機制，故依 blocker triage 的機制替換分支記此條目後繼續。

## 2026-08-20 20:35 — 前述 open question 的收尾：ingest 收緊已落地
- 類別：open-question
- 任務：4.1
- 內容：`2026-08-20 19:22` 條目記載的處置已全數落地並經 round 3 的兩位 reviewer 各自獨立驗證為 `resolved`。六個落地點：`design.md` IC-12 的第四款；`design.md` IC-13 的「四件事各補一條 `assert_contains`」與 baseline 重算義務；spec delta `Target-local receipt 初始化` requirement 的新款；spec delta 新增的 `#### Scenario: 前提不成立的診斷不被指引為重新簽發`；`AGENTS.md` 與 `CLAUDE.md` 受管區塊的第四個 bullet（兩份逐 byte 相同）；`scripts/cash-skills/tests/skill-checks.fish` 的新 literal 斷言與重算後的 canonical Cash guidance baseline `5f4b9f4b94bd39a7e262a1e12dea901bcd35c10fc2c32d925c39e00515b193bc`。封閉性以兩個 gate 的實際第三支訊息驗證：訊息逐字含 `runtime record drift:` 或 `skill record drift:`，受管區塊據此指示還原該 record 或從可信 source 重新安裝而非 `--init-receipt`；不含這兩個子字串的裸 identity drift 訊息仍走初始化入口。前兩筆 `open-question` 條目自此不再阻塞，原條目保留不刪改。
- 原因：Implementation Notes Protocol 把 `open-question` 定義為「本 change 可視為完成之前需要使用者確認或修訂的項目」，因此決定落地後必須有一筆條目說明它已關閉，否則 archive 之後的讀者會看到一個最後狀態仍為「兩個未決問題」的 change，與已交付的 artifacts 相矛盾。使用者的裁定本身已記於 `19:22` 條目，不需要再次確認。

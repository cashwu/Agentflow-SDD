**Surgical & Simplicity Discipline**

在 step 7 的 task loop 期間，編輯任何來源碼之前必須套用以下兩項紀律。它們補充（而不取代）既有的 Reuse / Quality / Efficiency / No Placeholders / Examples as verification 檢查。

**Simplicity First — 寫最少能解決任務的程式碼**

- 不要實作 `tasks.md` 任務描述與 `design.md` Implementation Contract 以外的功能。
- 不要為單一使用情境引入抽象層、設定選項或「彈性」；YAGNI 優先於可擴充性。
- 不要為 contract 已排除或型別已保證的情境撰寫錯誤處理；只在系統邊界（外部輸入、外部 API）驗證。
- 完成後若發現實作行數遠超必要（例如 200 行能壓到 50 行），先檢查是否過度設計，必要時重寫成更小的版本。
- 自問：「資深工程師會不會說這太複雜？」如果會，就簡化。

**Surgical Changes — 只動該動的，且只清自己造成的殘骸**

- 不要「順手」改鄰近區塊的程式碼、註解或格式。
- 不要重構沒壞的東西；不要為了個人風格偏好改既有寫法。
- 即使既有風格與你習慣不同，跟著現況走（match existing style）。
- 若注意到不相關的死碼、bug 或可改進處，**不要直接刪或改** — 依照 Implementation Notes Protocol 在 `implementation-notes.md` 以 `open-question` 條目記錄，交給使用者決定。
- 只移除「因為本次改動而變成 orphan」的 import、變數、函式；既有的 pre-existing 死碼不要動。
- 驗收標準：本次 diff 的每一行，都能直接追溯到 `tasks.md` 中的某條任務或 `design.md` 中的 Implementation Contract 項目。

**Maintain Balance — Simplicity 不等於程式碼高爾夫**

Simplicity First 與 Surgical Changes 的目的是「不寫不必要的東西」，不是「越短越好」。下列反例同樣違反紀律，被 review loop 視為 Critical：

- 巢狀三元運算子（nested ternary）— 用 `if/else` 或 `switch` 替代。
- 為了減少行數犧牲可讀性的 dense one-liner、過度連鎖的 method chain。
- 為了「合併」把多個關注點塞進同一個 function、component 或檔案。
- 移除有意義的中介變數，讓 expression 變成難以閱讀或除錯的長句。
- 移除真正在傳遞意圖的命名常數，改用 magic number 或 inline literal。
- 拿掉合理的抽象（helper、type alias）只為了減少一層間接。

判準：實作完成後重讀 diff，若 future-self 或 reviewer 需要花超過幾秒才能理解某行的意圖，那不是 simpler，是 cleverer。Cleverer 違反紀律。Clarity 永遠優先於 brevity。

若違反上述任一條（無論刻意或非刻意），視同 task 未完成 — 在執行 `spectra task done` 之前先修正。若是刻意 deviate（例如 contract 與既有程式衝突，需要動到鄰近區塊），依 Implementation Notes Protocol 寫一筆 `deviation` 條目，說明原因。

**Keep verbatim (do not translate):** shell commands, file paths, code identifiers, schema field names (`applyRequires`, `outputPath` 等), artifact IDs, capability slugs, and quoted source text. If the user explicitly requests another language later, follow the latest user instruction.

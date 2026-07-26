---
id: review-isolation-unenforced-by-capability
type: gap
status: open
occurrences: 1
first_seen: 2026-07-26
last_seen: 2026-07-26
links:
  - openspec/changes/support-multi-file-skill-payload/reviews/propose-r1.md
---

# Review isolation unenforced by capability

Review loop 把 reviewer 的角色邊界（唯讀、只回傳 findings、不得修改任何檔案）**只寫在 prompt 裡**，而實際派發給 reviewer 的 sub-agent 型別握有完整的寫入與執行權限。角色隔離因此是「請求」而非「保證」：一個誤解指令、被 artifact 內容誘導、或單純自作主張的 reviewer，可以建立 change、改寫 artifacts、編輯測試或 signals，而迴圈沒有任何機制會發現。

這個缺口的危害不在於「reviewer 會不會亂寫」，而在於**事後無法區分**。當工作目錄在一次 review 之後出現非預期的變動，主 agent 只能從時間戳推測作者；若剛好有並行的人類 session 或其他 agent 在動同一個 repo，推測會失準。無論推測的方向是誤判 reviewer 有問題（使一次乾淨的 review 被無謂作廢）還是誤判 reviewer 沒問題（使一次受污染的 review 被採信），代價都落在迴圈的可信度上。

隔離應由能力授予承擔，而非由指令承擔：擔任 grader 角色的 sub-agent 應以唯讀工具集執行，或明確剝奪其寫入與 change 建立能力。這同時使「reviewer 未修改任何檔案」從一個需要事後查證的假設，變成一個由執行環境保證的前提。

同一原則適用於任何「以 prompt 宣告角色限制、但以完整能力執行」的委派——包含 fix-verification、claim-verification 與 abort triage 所使用的 sub-agent。

## Occurrences

- 2026-07-26 — support-multi-file-skill-payload — cash-propose round 1 — 該輪的兩個 reviewer 以 `general-purpose` sub-agent 型別派發，該型別具完整工具權限；prompt 要求它們只讀 artifacts 並回傳 JSON findings。同一時間工作目錄出現一個非本 session 建立的 change 目錄，主 agent 僅憑「session 早期 `cash list` 未列出、其後列出」與檔案時間戳，即在回覆中斷定該目錄由 reviewer 建立。使用者指出該 change 實際上出自其並行 session。事後以秒級 mtime 交錯比對確認：該目錄的寫入序列落在主 agent 自行執行 fix actions 的窗口內，當時沒有任何 sub-agent 在執行，reviewer 確實未寫入任何檔案。本次 review 未受污染，但整段查證之所以必要，正是因為隔離沒有由能力層保證。

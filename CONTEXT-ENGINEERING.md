# Context Engineering 指引（Claude 5 世代）

本文件摘錄 Anthropic 官方對 Claude 5 世代模型的 context engineering 建議，作為本專案撰寫與維護 skills、CLAUDE.md、AGENTS.md 及 Cash artifacts 時的對照基準。

- 來源：[The new rules of context engineering for Claude 5 generation models](https://claude.com/blog/the-new-rules-of-context-engineering-for-claude-5-generation-models)
- 摘錄日期：2026-07-27

## 七項核心建議

1. **移除過度約束的指示**（remove overconstrained instructions）——Anthropic 為新一代模型刪除了超過 80% 的 Claude Code system prompt 而沒有效能損失。
2. **信任模型判斷**（trust model judgment）——以「讓 Claude 依情境詮釋」的指引取代僵硬規則。
3. **設計更好的介面**——把力氣花在表達力強的 tool 參數與清晰 schema，而非堆使用範例。
4. **Progressive disclosure**——透過 skills 與 deferred-loading tools，讓 context 只在需要時載入。
5. **消除重複**——同一指示不要同時出現在 system prompt、tool description 與文件中。
6. **善用 auto-memory**——讓模型自動記錄相關資訊，而非人工維護 CLAUDE.md。
7. **使用 rich references**——以程式碼、測試套件與 artifacts 作為參照，而非只有 markdown 規格。

## 新舊對照

| 舊做法 | 新做法 |
| --- | --- |
| 給 Claude 明確規則 | 讓 Claude 行使判斷 |
| 為 tools 提供使用範例 | 設計表達力強的 tool 介面 |
| 前置塞入所有 context | Progressive disclosure |
| 指示在各處重複 | 指引放在 tool descriptions |
| 人工維護 CLAUDE.md 記憶 | 自動的情境記憶 |
| 純 markdown 規格 | Rich references（程式碼、測試、HTML） |

## 對 CLAUDE.md 的建議

保持輕量：簡述 repository，聚焦於 codebase 的「gotchas」。原文："Avoid stating 'the obvious' things Claude should know by looking at your file system or your repo."

## 對 Skills 的建議

- 把 skill 當作輕量指南：原文："Think of skills as lightweight guides to let Claude find information when needed. Avoid making them overconstrained, except in highly important areas."
- 長 skill 拆成多個檔案，廣泛使用 progressive disclosure。
- Tools 採 deferred loading，完整定義只在需要時載入。
- 指示風格從規定式（如 "default to writing no comments"）轉為情境式（如 "Write code that reads like the surrounding code: match its comment density, naming, and idiom."）。

## 在本專案的對應

- **「except in highly important areas」的例外條款**：cash skills 的 review gate、blocker triage、grader immutability 屬於刻意的高約束區（可稽核邊界），不因「減少約束」原則而鬆動；周邊程序性文字則適用瘦身原則。
- **消除重複**：change `cash-skill-maintainability` 將 review gate 四份拷貝收斂為 `scripts/cash-skills/blocks/review-gate.md` 單一源頭、`.agents` 變體改由生成器產出，即是第 5 項的落地。
- **Progressive disclosure 的邊界**：對每次執行必然用到的內容（propose／apply 的 gate），build-time 單一源頭生成優於 runtime 拆檔——拆檔只在內容是條件性使用時才省 context（見該 change design.md 的 Alternatives Considered）。
- **Rich references**：Cash artifacts 以 Implementation Contract、spec Scenario 與測試錨定驗收，符合第 7 項。

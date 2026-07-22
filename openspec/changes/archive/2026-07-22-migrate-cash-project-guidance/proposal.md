## Summary

讓 Cash installer 同步管理 `AGENTS.md` 與 `CLAUDE.md` 的 Cash-only workflow 指引，安全移除既有 Spectra managed block，並加入向量模型未下載時的檔案式替代流程。

## Motivation

目前 `install-cash-skills.fish` 只部署 cash skills；既有專案的 `AGENTS.md`／`CLAUDE.md` 仍可能保留 `spectra-*` workflow 指引，導致已安裝 Cash 後 agent 仍路由到錯誤 namespace。Cash 與 Spectra skills 可以同時存在於檔案系統，但專案 workflow 只應使用 `cash-*`；同時，Spectra 語意搜尋在本機向量模型尚未下載時不應阻斷工作。

## Proposed Solution

- **BREAKING**：Cash installer 對可安全辨識的 `<!-- SPECTRA:START ... -->`／`<!-- SPECTRA:END -->` managed block 執行 guidance migration，以 Cash managed block 取代，而非保留兩套 workflow routing。
- 在 `AGENTS.md` 與 `CLAUDE.md` 寫入工具語法相符的 Cash-only 指引；Codex 使用 `$cash-*`，Claude 使用 `/cash-*`。
- Cash managed block 明確保留 Spectra CLI 與 `openspec/` artifact schema 的權威，但不指示 agent 呼叫 `spectra-*` skills。
- Cash managed block新增「向量模型未下載時的替代方式」：已知 change 名稱時直接讀取 `openspec/changes/<name>/`，必要時用 `spectra list --parked` 確認 parked 狀態；程式碼或需求問題則用 Grep／Read 搜尋 `openspec/specs/` 與程式碼。
- Installer 僅移除完整、唯一且邊界安全的 Spectra managed block，只更新完整且唯一的 Cash managed block，並保留兩者以外的專案自訂內容；破損、重複或不安全的 marker 結構在任何寫入前 fail closed。
- 保留所有非 plus 的 `.agents/skills/spectra-*` 與 `.claude/skills/spectra-*`；既有 retired `spectra-propose-plus`／`spectra-apply-plus` cleanup 不變。Spectra app 可重新安裝標準 Spectra skills，但不改變 Cash-only workflow routing。
- 將 guidance migration 納入 `--dry-run`、單一 target、registry batch、衝突判斷、結果狀態與 idempotence 測試。
- 補齊 source malformed marker的零寫入fail-closed fixture、target `CLAUDE.md` `/cash-*` variant直接斷言，以及dry-run system temporary snapshots於exit後無遺留的runtime cleanup驗證。
- 將每個 guidance atomic publication 綁定到 preflight驗證過的 parent directory object：單一 Perl publisher持有 directory FD並以 `chdir($directory_fh)` 把 process working directory綁定到該 object，temporary create、snapshot revalidation、cleanup與atomic rename全部只使用不含 `/` 的相對 basename完成，parent pathname swap不得把任何操作重新導向 target外替代路徑。
- 將每份 source與target guidance的identity、mode、完整bytes、digest、marker解析與render綁定到同一次`O_NOFOLLOW` file-handle snapshot，禁止先hash再從pathname重讀內容。
- 明確界定atomic rename的可保證邊界：publisher會拒絕最後destination checkpoint前已發生的變更；一般POSIX filesystem沒有以預期inode為條件的atomic replace，因此最後checkpoint至rename之間的非協作concurrent destination writer不在本change保證內。
- 明確定義 runtime partial publication 的恢復方式，完全依重試時可觀測狀態分類：有有效 receipt且 skills相對 receipt漂移時回報 `conflict`；無 receipt時，零個受管 skill目的地存在就走首次安裝，24檔全數存在且與source相同就走 adoption，只有至少一個目的地存在但未滿足完整全等 adoption時才回報 `conflict`並須帶 `--force`收斂。

## Non-Goals

- 不移除或修改任何非 plus 的 `spectra-*` skill。
- 不 fork 或修改 Spectra CLI、向量模型下載流程或 Spectra app。
- 不覆蓋整份 `AGENTS.md`／`CLAUDE.md`，也不修改 managed block 之外的使用者內容。
- 不建立背景 repair；Spectra app 若日後在 target project 重新加入 Spectra managed block，須再次明確執行 Cash installer 才收斂回 Cash-only guidance。Source repository 若被外部工具改動，仍由版本控制還原其 canonical Cash-only 文件。
- 不提供跨process lock service，也不宣稱能對未遵守同一協作鎖的writer執行pathname compare-and-swap；operator MUST 避免在單次guidance atomic publication的最後checkpoint至rename區間同時改寫同一destination basename。

## Alternatives Considered

- 保留 Spectra managed block並在後方追加 Cash precedence override：會持續呈現兩套互斥 workflow，與 Cash-only routing 決策不符。
- 覆蓋整份 `AGENTS.md`／`CLAUDE.md`：會破壞專案自訂指引，且 ownership 邊界過大。
- 同時刪除 `spectra-*` skills：Spectra app 可能重新安裝，且 skills 是否存在與有效 workflow routing 是不同問題。

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `cash-skill-workflows`: 擴充 installer 與專案指引合約，加入 Cash-only managed-block migration、雙工具變體、向量搜尋 fallback、衝突安全與重複執行語意。

## Impact

- Affected specs: `cash-skill-workflows`
- Affected code:
  - Modified:
    - install-cash-skills.fish
    - AGENTS.md
    - CLAUDE.md
    - CASH-SKILLS.md
    - scripts/cash-skills/tests/skill-checks.fish
  - New: (none)
  - Removed: (none)

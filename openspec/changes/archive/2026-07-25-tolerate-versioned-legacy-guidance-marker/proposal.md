## Summary

修正 installer 的 guidance marker 比對：`marker_span` 目前以字面 bytes 比對 legacy start marker，無法辨識真實 target 上帶版本字尾的形式，導致整個 target 的安裝 fail closed。同時補上 legacy guidance 遷移分支的 contract test —— 該分支目前零覆蓋，正是本缺陷得以長期存活的原因。

## Motivation

這是一個 Bug Fix。缺陷、後果與覆蓋缺口三者皆已由實測確認。

### 缺陷：判準只認一種字面形式

`.cash-skills/lib/cash_cli/installer.py` 的 `marker_span` 以字串串接組出兩個 marker：start 為 `<!-- ` 加 name 加 `:START -->`，end 為 `<!-- ` 加 name 加 `:END -->`，然後對 data 做 `count`。真實 target 的 legacy start marker 是 `<!-- SPECTRA:START v1.0.2 -->` —— marker 名稱與結尾之間帶了一段版本字尾。該形式不等於組出的字面 bytes，因此 start 的 count 為 0，而 end 的 count 為 1。

兩者不相等，於是落進 `count(start) != count(end)` 這條判斷，拋出 `duplicate or unbalanced SPECTRA guidance marker`。診斷訊息本身也是誤導的：檔案裡的 marker 既不重複也不失衡，恰好各有一個。

### 後果：整個 target 永久無法更新，且死 block 永久殘留

`marker_span` 由 `render_guidance` 呼叫，而 guidance 是 installer transaction 的一環，因此這個例外不是只讓 guidance 略過，而是讓該 target 的整次安裝 fail closed。實測 `install-cash-skills.fish --all` 時 Tubify 與 player-log-downloader 兩個 target 每次都以 marker 理由 `failed`（`failed=2`），維持在舊 bundle 版本；其餘 target 的分類會隨安裝狀態變動，不是穩定的量測值。

更關鍵的是這個失敗會自我維持。移除那段死掉的 legacy block 是 `render_guidance` 的職責 —— 當 target 同時存在合法 Cash block 與 legacy block 時，它會把 legacy span 換成空 bytes。但要走到那一步必須先通過 `marker_span`，而 `marker_span` 正是失敗點。因此該 block 沒有任何自動路徑可以被移除，會無限期留在使用者的 AGENTS.md 與 CLAUDE.md 中，繼續指示 agent 使用早已不存在的 legacy skill 命名空間。

### 語料事實

全機器 8 個 repository 的 AGENTS.md 與 CLAUDE.md 實測列舉，marker 只有三種實際形式：帶版本字尾的 legacy start marker（僅 `v1.0.2` 一種字尾，出現在 2 個 target）、不帶字尾的 legacy end marker、以及兩端皆不帶字尾的 Cash marker。沒有其他字尾變體。

### 覆蓋缺口：這是缺陷存活的原因

`scripts/` 底下沒有任何檔案提到 legacy start marker 的字串。`render_guidance` 的 legacy 分支 —— 也就是遷移與移除 legacy block 的整條路徑 —— 完全沒有 contract test。`scripts/cash-skills/tests/test_installer_runtime.py` 雖然多處建立 AGENTS.md，但從未讓它含有 legacy block。這條路徑既然從未被執行過，判準對真實語料的偽陽性自然無從被發現。

## Proposed Solution

**一、讓 marker 比對容忍字尾，並保持行錨定。** 把 `marker_span` 對 start 與 end 的定位，從字面 bytes `count` 與 `index` 改為對「marker 名稱與種類固定、其後允許一段不含 `<`、`>` 與換行的可選字尾、再以結尾符號收束」的形式做掃描。字尾對 start 與 end 一致適用：函式本身就對 name 與種類泛化，統一處理比只特判 start 少一個分支，程式碼更簡單，且未來若出現帶字尾的 end marker 不會以同樣方式 fail closed。

**二、既有的 fail-closed 判定一項都不放寬。** 容忍的只有「marker 名稱與結尾符號之間的字尾」這一個維度。孤立、反序、重複、巢狀、非獨立行這五種判定的語意與觸發條件維持不變，只是改為建立在新的定位結果上。字尾內不得含 `>` 或 `<`，前者使字尾無法跨越結尾符號吞掉後續內容，後者使字尾無法向前吞掉同行稍前的另一個註解起始序列——若少了後者，那段原本受「managed span 外 bytes 逐 byte 保留」保護的內容會被捲入 span 並在遷移時刪除，且因尾側緊接換行而不會被任何既有判定攔下。每個 marker 仍必須緊接換行，非獨立行仍然 fail closed。

**三、在 source 側反向封死字尾。** 定位對 name 泛化，因此容忍必然同時作用於 Cash marker。這在 target 側是自我修復，在 source 側卻是新風險：source 的 Cash span 會被逐 byte 當作 canonical block 寫入每一個 target，若 source marker 帶字尾，該字尾會散播到全部 target，而現行實作對此輸入原本是 fail closed。因此 `canonical_guidance` 對 source 的 Cash marker 額外要求不帶字尾。

**四、讓失敗可被自助定位。** 容忍改變了「哪些 bytes 會被當成 marker」，因此行為改變是雙向的：現行可安裝的 guidance 若含形似 marker 的散文孤行，容忍之後會 fail closed；反過來，現行 fail closed 的 guidance 若含形似 marker 的完整範例且其 marker 帶字尾，容忍之後會成功安裝並靜默改寫該段內容。兩個方向都已實測並記錄於 design 的 Risks，本次接受而不加防範——可靠的區分需要行首錨定與 fenced 區塊解析，遠超本 change 範圍。能做的是讓失敗可定位：全部 marker 失敗訊息具名 guidance 檔案，且必須可區分出問題的是 source bundle 還是 target——兩側的相對路徑取值相同，只具名路徑不足以消歧，而在 `--all` 下一個 source 端失敗會被印成 N 行、每行指控一個無辜的 target。更細緻的 marker 形式診斷列為 Non-Goal，理由見 design D6。

**五、補上 legacy 遷移分支的 contract test。** 在 `scripts/cash-skills/tests/test_installer_runtime.py` 新增涵蓋六類成功情境與八類失敗情境的案例，使上述每一條「不放寬」與「不散播」都成為可執行的驗證而非敘述。

**六、同步文件並調升 bundle 版本。** `CASH-SKILLS.md` 需改寫三處：「未知版本 marker」會 fail closed 那句因本次改動而變假，另需補上兩個「一個 source 檔擋掉全部 registered target」的新失敗模式——source Cash marker 帶字尾、以及 source guidance 中出現形似 legacy marker 的文字。`.cash-skills/lib/cash_cli/installer.py` 屬 replaceable runtime record，改動後必須調升 `cash-skills.version` 才能通過 bundle version history contract test。

## Non-Goals

- 不修改任何 target repository 的 AGENTS.md 或 CLAUDE.md。死 block 的移除由修好之後的 installer 自行完成，本次不手動編輯外部專案。
- 不改變 legacy block 被移除後留下的空白行處理。managed span 以外的 bytes 逐 byte 保留是既有契約，移除 span 後其前後的空白行屬於 span 外內容，維持不動。
- 不改變 `render_guidance` 的替換策略本身，也不改變 Cash block 的 canonical 內容。
- 不新增 legacy 命名空間的任何新支援。本次只讓既有的「辨識並移除」路徑能在真實語料上執行。
- 不修改 `install-cash-skills.fish` 的批次彙總、狀態分類或結束行為。
- 不擴充 marker 字尾的語意。字尾內容只被容忍與略過，不被解析、不被比較、不影響 marker 定位的任何決策。此限定僅及於定位；source 側以字尾之有無為判準的禁令是本 change 刻意新增的，不在此列。
- 不新增「形式不被辨識」的獨立診斷分支。不做行首錨定就無法可靠區分文件中談到 marker 與一個寫壞的 marker，該判準在本次範圍內無法寫對，理由見 design D6。

## Alternatives Considered

**手動編輯那兩個 target 的 guidance 檔案。** 可以立刻讓 `--all` 全綠，但只治這兩個專案。判準的偽陽性仍在，任何一個尚未安裝、或日後從備份還原的帶字尾 target 都會再次卡住，而且同樣沒有測試會發現。已否決。

**把 legacy marker 的辨識完全移除，改為不再處理 legacy block。** 會讓死 block 永久留存在所有既有 target，與既有 requirement 明訂的「移除一個合法 legacy block」直接衝突。已否決。

**只對 start marker 特判字尾，end marker 維持字面比對。** 貼合當前語料，但在同一個對種類泛化的函式裡製造不對稱分支，程式碼反而更長，且未來出現帶字尾的 end marker 時會以完全相同的方式整個 target fail closed。已否決。

**把字尾解析成版本並據以決策（例如依版本選擇遷移策略）。** 超出修復所需，且會讓字尾從「可略過的雜訊」升格為「必須維護的介面」。已否決。

## Capabilities

### New Capabilities

（無）

### Modified Capabilities

- `cash-cli`：`Cash guidance deployment` 明訂 marker 的可接受形式包含可選字尾、該容忍不放寬既有的五種 malformed fail-closed 判定、字尾同時排除 `<` 與 `>` 以免跨越註解界定符、source canonical marker 不得帶字尾、以及全部 marker 失敗診斷必須具名 guidance 檔案。

## Impact

- Affected specs:
  - openspec/specs/cash-cli/spec.md
- Affected code:
  - New:
    - （無）
  - Modified:
    - .cash-skills/lib/cash_cli/installer.py
    - scripts/cash-skills/tests/test_installer_runtime.py
    - CASH-SKILLS.md
    - cash-skills.version
  - Removed:
    - （無）

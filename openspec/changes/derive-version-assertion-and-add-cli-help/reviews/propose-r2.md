# Cash Propose Review — Round 2

本輪為 micro 輪，由單一 Reviewer V — Verification 對 round 1 的 cumulative blocking set 做 delta 驗證，並重點檢查兩處結構性改動（形狀驗證移入 `assert_installer`、byte-level 機制與 `source_inventory` 的一致性）。

## Reviewer Findings

### Cumulative blocking set 逐項判定

round 1 的 9 個 blocking 成員全數 `resolved`，4 個非阻斷項亦全數關閉：

| member | verdict | 依據摘要 |
| --- | --- | --- |
| C1 | resolved | design 已如實記載 fixture 逐字釘住訊息與整個 object 相等比對；proposal `## Impact` 已列入 fixture；tasks 2.2 同批更新；IC3 增列條款；tasks 3.2 明列 `negative-atomicity` group |
| W1 | resolved | D1 改為「`version()` 以 `.strip()` 解析，容忍無 LF、CRLF 與多個結尾 LF……形狀驗證的實質新增價值就在這一點」，與 `check_history:140` 的實際執行位置一致 |
| W2 | resolved | delta 改為引用，全份已無 `0|[1-9][0-9]*`；design Context 列出三個既有擁有者 |
| W3 | resolved | Reviewer V 重跑實測確認 `string trim` 對三種結尾形狀全部 PASS，design 敘述正確；IC1／IC4／tasks 2.3 皆要求 byte-level 完整比對與五個負面案例 |
| W4 | resolved | tasks 3.1 收斂為嚴格遞增與 stable-path 綁定；Reviewer V 核對 `test_bundle_version_history.py:146-153` 確認 stable-path 綁定在 early return **之前**執行，收斂後兩項在該時點皆真正可驗 |
| W5 | resolved | 核對 `.cash-skills/bin/cash:292-300` 的 `flock` → `validate_receipt` → `import main` 順序，四份 artifact 的敘述與實際相符 |
| W6 | resolved | 限定本身成立（但新 scenario 的 WHEN 有事實錯誤，見 N1） |
| W7 | resolved | IC2 與 delta 同步收斂為 dispatch 目標／exit code／`error` code／JSON 結構四項，與 `message` 擴充不再互斥 |
| W8 | resolved | proposal 與 design 如實記載觸發差異；設計已改為把形狀驗證移入 `assert_installer` |
| S1–S4 | resolved | 四項逐一核對到位 |

### 兩處結構性改動的專項查核（Reviewer V）

**移到 `assert_installer` 的結構事實成立。** 核對 `skill-checks.fish:267-293` 的 dispatch：`assert_installer` 只由 `installer-runtime` 與 `all` 進入，因此「任一會觸發形狀驗證的 group 也呼叫 `test_bundle_version_history.py`」為結構必然。移除 `assert_inventory:38` 不破壞該 function 內其餘任何斷言（24 目錄數、frontmatter、launcher 0755、lock 0644／size 0、`.spectra.yaml` 缺席皆與版本無關）。master `Cash 合約測試套件` 的治理是檔案層級、不指定 group，故不破壞任何 requirement。

**byte-level 接受集合在內容層可與 `source_inventory` 完全一致。** `installer.py:291-300` 的內容判準等價於全檔比對 `^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\n$`；五個負面案例逐一確認皆被拒絕，且任意長度分量不會被誤拒。但 `source_inventory` 另經 `read_regular` 強制 mode `0644` 等 identity 條件——見 N3。

### Warning

**N1**（confidence 100，`fix-introduced`）新 scenario `Handler 層的 unknown_command 不受影響` 的 WHEN 用 `cash new bogus` 舉例，但該 argv 只有一個 argument 時會先落在 `create.py:113` 的 `invalid_arguments`。主 agent 實測確認：`cash new bogus` → `error[invalid_arguments]`；`cash new bogus x` → `error[unknown_command]: Unknown new mode: bogus`（`cash new bogus --json` 因 `--json` 算第二個 argument 而意外落在 `unknown_command`，更顯示該形式不穩定）。`introduced_by`：r1 `## Fix Actions` 的「**修 W6** …… 新增 `#### Scenario: Handler 層的 unknown_command 不受影響`」。

**N2**（confidence 90，`fix-introduced`）spec 與 IC2 要求 `commands` 為**排序後**的 key 陣列，但 IC4 與 tasks 1.1 只斷言**集合**相等。主 agent 實測 `COMMANDS` 的插入序（`list, status, instructions, new, task…`）與排序後（`analyze, archive, drift…`）不同，因此 `list(COMMANDS)` 會違反 MUST 卻通過全部斷言——正是本 change 要防的「宣稱檢查、實際不檢查」形狀。`introduced_by`：r1 的「**修 S2**」。

**N3**（confidence 80，`fix-introduced`）tasks 2.3 要求接受集合與 `source_inventory` 「不得給出相反判定」，但後者另強制 mode `0644`、regular file、single hard link，該一致性在本 change 範圍內不可達；照字面補上 mode 檢查會使五個負面案例（若以 `mktemp` 預設 `0600` 建立）因 mode 而非形狀被拒絕，斷言全部空轉。`introduced_by`：r1 的「**修 W3** …… tasks 2.3 另加一條一致性要求」。

**N4**（confidence 80，`fix-introduced`）「fixture 是期望值的唯一承載處，更新它不會產生第二份會漂移的清單」為事實錯誤。訊息若內嵌 15 個 command，golden fixture 就逐字承載一份 122 字元的清單副本；任何人增刪 dispatch table 的 key 都得手動同步它——與本 change 要從 `skill-checks.fish` 移除的絆線同型，一邊移除一邊新增。`introduced_by`：r1 的「**修 C1** …… 說明 fixture 是期望值的唯一承載處、不會產生第二份會漂移的清單」。

### Suggestion（非阻斷）

- **N5**（85）master 的 `Bundle 安裝與 runtime receipt` 只定義格式，**未**定義單一 LF 終止；delta 末句宣稱「形狀規則的權威來源維持在 `Bundle 安裝與 runtime receipt`」對 LF 分量不成立。
- **N6**（55）tasks 2.3 同一句內「五個負面案例」與「全檔不含任何三段式版本字面值」抵觸——負面 fixture 天然需要看起來像版本的字串。

## Rating

- post-filter cumulative blocking set Critical count: **0**
- post-filter cumulative blocking set Warning count: **4**（N1、N2、N3、N4）
- 非阻斷 triaged finding count: **2**（N5、N6）
- `critical_gap`: **false**
- `round_type`: **micro**

rationale：round 1 的 9 個 blocking 成員全部以 verified resolution 離開集合，缺陷密度由 1C+8W 降至 0C+4W。本輪 4 個新 blocking 全數 `fix-introduced`，其中 N4 最值得記錄：我在 round 1 修 C1 時，為了讓 fixture 的更新看起來無害而寫下「不會產生第二份會漂移的清單」，但實際上把 15 個 command 名稱塞進被 golden fixture 逐字釘住的訊息，正好複製了我這份 change 要消滅的絆線型態。這不是措辭問題而是設計問題，因此本輪的修法是改變設計而非改寫敘述。

## Fix Actions

4 個 blocking 成員與 2 個非阻斷項全部修復。無 grader-protection 保留項，無 accepted-risks 條目。修改檔案共 4 個：`proposal.md`、`design.md`、`tasks.md`、`specs/cash-cli/spec.md`。

**修 N4（改變設計，不只改敘述）** — 兩個 dispatch 層錯誤的訊息由「內嵌 command 清單」改為「**指向 help flag**」。指向 help 是不隨 dispatch table 變動的穩定字串，fixture 只需一次性更新後不再需要同步，可發現性的目標則由 help 本身承擔；command 清單因此只有 help 一個輸出處。spec、design D3、IC3、tasks 1.1／2.1／2.2、proposal 全部同步改寫，並在 D3 與 tasks 2.2 明文記錄「當初若內嵌清單會產生什麼後果」作為決策依據。

**修 N2** — IC4 與 tasks 1.1 的斷言由「集合相等」改為「逐元素等於排序後的 dispatch table key 序列」，並註明 `COMMANDS` 的插入順序與排序後不同、只比對集合會讓違反排序 MUST 的實作通過。（此修正只涉及 help 的 `commands` 欄位；錯誤訊息路徑因 N4 的改設計已不再有清單。）

**修 N1** — scenario 的 WHEN 改為 `.cash-skills/bin/cash new bogus <artifact-id>`；tasks 1.1 加註「須以帶第二個 argument 的形式觸發——`new bogus` 只有一個 argument 時會先落在 `invalid_arguments`」；scenario 的 AND 補上「也不指向 help flag」以配合 N4 的改設計。

**修 N3** — tasks 2.3 的一致性要求限定為「**內容**接受集合」，明文排除 mode／regular file／single hard link 屬安裝時 identity 前置條件、不納入本驗證也不得因此在本檔加入 mode 檢查；IC1 增列同一限定。

**修 N5** — delta 改為如實表述：格式規則引用 `Bundle 安裝與 runtime receipt`，單一 LF 條款則明文「由本 requirement 擁有，installer 在安裝時對 source version 檔強制同一條件，兩者 MUST 一致」，不再假稱其權威在別處；design D1 同步說明。

**修 N6** — tasks 2.3 補上相容解：負面 fixture 必須由 `cash-skills.version` 的當前值派生（去 LF／換 CRLF／追加第二個 LF／清空／前置 `0`）而非在檔內寫死版本字串，並須以 `0644` 建立使拒絕理由唯一為形狀。

**修正後的機械自檢與驗證** — 4 份 artifact comment/annotation 平衡皆 0/0；兩個 MODIFIED 標題與 master 逐 byte 相符；7 個新增 scenario 與 tasks.md 雙向對應無缺漏；proposal 含 `/` 的 6 個 code span 全部在 tasks.md 出現；無 lowercase `may`／`should`；舊措辭（訊息內嵌清單）全 artifact 零殘留，新措辭（指向 help）已在四份 artifact 就位。自檢另捕捉到本輪 fix 引入的一個 ghost bold（`**內容**`）——這是本 session 第五次同型錯誤，已修正。重跑 `cash validate` 通過，`cash analyze` 非 Suggestion finding 為 0，兩個契約套件維持全綠。

**Signal-derived checks** — 全部 open signal 無 `check` frontmatter，採 best-effort。本輪最相關者：`cross-artifact-definition-drift`（N4 —— 修正動作本身差點製造出要消滅的東西）、`acceptance-criterion-unreachable-at-specified-point`（N1、N3）、`enumerated-site-set-factually-wrong`（N2 的集合 vs 序列）、`review-fix-propagation-incomplete`（N5）。

## Decision

next_round

post-filter cumulative blocking set 含 0 個 Critical 與 4 個 Warning（N1–N4），未滿足 pass 條件。round 1 的 9 個成員已全部以 verified resolution 離開集合。4 個 blocking 成員與 2 個非阻斷項皆已完成 fix 並記錄於 `## Fix Actions`。下一輪為本次執行的第三輪，非第四輪，故為 `micro` 輪，由單一 Reviewer V 對 N1–N4 逐一給出 resolved/unresolved 判定，並重點檢查本輪「錯誤訊息改為指向 help」這項改設計是否引入新缺陷。

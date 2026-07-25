## Context

`.cash-skills/lib/cash_cli/installer.py` 的 `marker_span(data, name)` 以字串串接組出兩個字面 bytes：start 為 `<!-- ` 加 name 加 `:START -->`，end 為 `<!-- ` 加 name 加 `:END -->`。它先以 `count` 做三層防護，再以 `index` 取得位置，最後把 span 的結尾延伸到 end marker 所在行的行尾之後。

呼叫端有兩個，都在同一檔案內，全 repo 已確認沒有其他使用者：

- `canonical_guidance` 以 `CASH` 取 source 的 Cash block，並以 `SPECTRA` 確認 source 不含 legacy block。它把 source 的 Cash span 逐 byte 當作 canonical block 回傳，該 bytes 會被寫入每一個 target。
- `render_guidance` 同時以兩個名稱取 target 的兩個 span，據以決定替換內容。當 Cash span 與 legacy span 皆存在時，legacy span 的替換內容是空 bytes（移除），Cash span 的替換內容是 canonical block；只有 legacy span 存在時，legacy span 的替換內容才是 canonical block（遷移）。

五種 fail-closed 判定分屬兩處，這個分工在設計時必須精確認知：

| 判定 | 所在 | 觸發條件 |
| --- | --- | --- |
| 非獨立行 | `marker_span` | 某個 marker 的出現次數不等於「該 marker 緊接換行」的出現次數 |
| 重複 | `marker_span` | start 或 end 的出現次數大於 1 |
| 孤立 | `marker_span` | start 與 end 的出現次數不相等（含其一為 0） |
| 反序 | `marker_span` | end 的位置早於 start |
| 巢狀 | `render_guidance` | Cash span 與 legacy span 相交 |

其中「非獨立行」只約束尾側 —— 判定的是每個 marker 之後是否緊接換行，並未約束 marker 之前是否為行首。因此 marker 之前同行若另有文字，現行實作會接受並在遷移後留下一個不獨立成行的 Cash marker。這是既有行為，本次不改動也不宣稱改善。

marker 定位發生在 `install_target` 內、早於 stable lock 取得，本次不移動這個位置。

實測語料：全機器 8 個 repository 的 `AGENTS.md` 與 `CLAUDE.md` 共 16 個檔案，出現三種 marker 形式 —— 帶版本字尾的 legacy start（字尾僅 `v1.0.2` 一種，出現於 2 個 target）、不帶字尾的 legacy end、兩端皆不帶字尾的 Cash marker。

## Goals / Non-Goals

**Goals**

- 讓帶字尾的 legacy marker 能被正確定位，使既有的遷移與移除路徑在真實語料上可執行。
- 五種 fail-closed 判定的語意與觸發條件完全不變。
- 獨立成行且不帶字尾的 marker，其定位結果與現行實作逐 byte 相同。
- 讓 legacy 遷移分支從零測試覆蓋變成有 contract test。
- 讓 marker 相關的失敗可被自助定位——訊息具名 guidance 檔案。

**Non-Goals**

- 不解析、不比較、不儲存字尾內容。
- 不改動 `render_guidance` 的替換策略、canonical block 內容或 span 外 bytes 的保留規則。
- 不補上 marker 前側的行首錨定 —— 那是既有缺口，屬另案。
- 不新增「形式不被辨識」的獨立診斷分支。理由見 D6：不做行首錨定就無法可靠區分文件中談到 marker 與一個寫壞的 marker，該判準在本次範圍內無法寫對。
- 不手動編輯任何 target repository 的 guidance 檔案。

## Decisions

### D1：以 pattern 掃描取代字面 count 與 index，字尾對 start 與 end 一致適用

marker 的可接受形式定義為：`<!-- ` 加 name 加 `:` 加種類，其後允許一段可選字尾，再以 ` -->` 收束。字尾的形式是一個前導空白加上一段不含 `<`、`>`、CR 與 LF 的 bytes。行界必須同時排除 CR 與 LF：只排除 LF 時，CR-only 行界之後的 project-owned bytes 會被當作字尾納入 managed span。

字尾對 start 與 end 一致適用，而非只特判 start。理由有三：`marker_span` 本身就對 name 與種類泛化，統一處理比不對稱分支少一個判斷、程式碼更短；當前語料的 end 不帶字尾這件事是觀察結果而非契約，若日後出現帶字尾的 end，不對稱設計會以完全相同的方式讓整個 target fail closed；而字尾既然不被解析，容忍它在任一側都不增加語意負擔。

字尾必須同時排除 `<` 與 `>`，兩者各擋一個方向的吞噬，缺一不可。

排除 `>` 擋住向後吞噬：字尾無法跨越 ` -->` 吃掉後續內容。已實測 `<!-- SPECTRA:START --> -->` 這種輸入下，pattern 只匹配到第一個 ` -->` 為止，其後緊接的是空白而非換行，因而仍被「非獨立行」判定攔下。

排除 `<` 擋住向前吞噬，這是 round 2 review 才發現的。若字尾只排除 `>`，輸入 `<!-- CASH:START <!-- CASH:START -->` 會從位置 0 起匹配，把稍前的 `<!-- CASH:START ` 這 16 bytes 一併納入 span——而該輸入的尾側緊接換行，通過非獨立行判定，不會 fail closed。後果不只是 span 起點不同：`render_guidance` 會以 canonical block 取代整個 span，把舊實作視為 span 外、受「managed spans 外 bytes 逐 byte 保留」保護的那 16 bytes 一併刪除。實測現行實作對該輸入回傳 `(16, 54)`，只排除 `>` 的 pattern 回傳 `(0, 54)`，同時排除 `<` 與 `>` 則回傳 `(16, 54)`，與現行實作逐 byte 相同。

### D2：三層防護改為建立在掃描結果的計數與位置上，判定語意逐條對應不變

現行的 `data.count(start)` 換成掃描到的 start 匹配數，`data.count(start + b"\n")` 換成「匹配結尾緊接換行」的匹配數，`data.index(start)` 換成第一個匹配的起始位置，end 同理。三個既有 `raise` 的觸發條件不變，span 的結尾仍由 end marker 所在行的行尾決定。

已實測：對現行語料中不帶字尾的 Cash marker，新舊兩種定位給出的 span 完全相同 —— 現行 `marker_span` 對 Tubify 的 `AGENTS.md` 回傳 `(1200, 5095)`，新 pattern 對同一檔案定位到的 end 匹配結束於 5094，加一即 5095，start 亦同為 1200。全部 16 個語料檔案逐一比對，舊實作成功的案例中新舊 span 不一致數為 0。

等價保證的邊界必須據實陳述，不能用一個假理由帶過。round 2 review 指出：把構造反例 `<!-- CASH:START <!-- CASH:START -->` 排除在保證之外的理由若寫成「該行另有文字，本就違反非獨立行判定」，那是錯的 —— 已實測該輸入的尾側緊接換行，新舊實作都通過非獨立行判定、都不 fail closed。真正的處理方式是 D1 的字尾排除 `<`，使該輸入的 span 回到與現行實作相同的 `(16, 54)`，因此它不再是等價保證的例外，而是被保證涵蓋。

保證仍限定於 marker 獨立成行的情形，但這個限定的理由是 Non-Goals 中「不補行首錨定」的直接後果：marker 之前同行若有普通文字（不含註解起始序列），新舊實作行為一致地接受它並在遷移後留下不獨立成行的 Cash marker，這是既有行為，本次不改。

### D3：字尾容忍在 target 側是修復，在 source 側必須反向封死

`marker_span` 由呼叫端傳入 name，因此容忍字尾必然同時作用於 `CASH`。這在 target 側與 source 側的後果相反，必須分開處理。

**target 上的真 marker 是修復。** target 上若出現帶字尾的 Cash marker，現行實作會以誤導的重複／孤立訊息讓整個 target fail closed，容忍之後則會被辨識並替換為 canonical block（其 marker 不帶字尾），即自我修復。

但「target 側一律是修復」這個推廣不成立，理由見 Risks 的第二與第三段：target guidance 裡形似 marker 的散文或範例，容忍之後會由 fail closed 變成被當作真 marker 處理。

**source 側是新風險，不是改善。** 這是本輪 review 修正的一個設計錯誤。`canonical_guidance` 把 source 的 Cash span 逐 byte 當作 canonical block 回傳並寫入每一個 target。已實測：source 為 `<!-- CASH:START v9.9.9 -->` 起始時，新定位回傳的 canonical block 逐字包含該字尾，於是字尾會被散播到全部 registered target。現行實作對此輸入是 fail closed，因此容忍在 source 側嚴格變差。

**source 側還有第二個後果，方向與上一個相反且不被 IC5 攔下。** IC5 只管 source 的 Cash marker 帶字尾。但 source guidance 若在任何位置出現形似 legacy marker 的文字——包括散文中的舉例——`canonical_guidance` 對 `SPECTRA` 的定位就會落入既有的 fail-closed 判定而失敗，於是**每一個** registered target 都安裝失敗。落入哪一條判定取決於該行的形狀：散文中的舉例通常後面還接著其他字元，走的是非獨立行判定；只有當該 marker 恰好獨立成行且無對側時才是計數不相等。兩者的後果相同，但診斷字樣不同，因此文件不應指名內部判定。已實測：在本 repo 的 `AGENTS.md` 的 Cash block 內插入一行「legacy start marker looks like `<!-- SPECTRA:START v1.0.2 -->`」，現行實作對該檔的 `SPECTRA` 定位回傳無 span 而放行，容忍之後則拋例外；`--all` 的彙總由 `failed=0` 變成全部 target `failed`。這與 Risks 記載的 target 側方向是同一個機制，但後果從「該 target 失敗」升級為「全部 target 失敗」。本 repo 的 `CASH-SKILLS.md` 今天就含有一行這種寫法，可見它在本專案是自然會出現的形式；一旦哪天搬進 guidance 就全面停擺。本次不加防範（理由同 D6：可靠的區分需要行首錨定），但必須在 `CASH-SKILLS.md` 明文告知，見 tasks 2.4 的第三處改寫。

處置：`canonical_guidance` 對 source 的 Cash marker 額外要求不帶字尾，帶字尾即 fail closed。這與 `scripts/cash-skills/tests/skill-checks.fish` 既有的「source guidance 恰好含一行字面 marker」檢查方向一致。字尾容忍的目的是接納既有 target 上的 legacy 形式，不是讓 source 產出帶字尾的 marker。

### D4：移除 legacy block 後留下的空白行不做任何處理

target 同時有 Cash block 與 legacy block 時，legacy span 被替換為空 bytes。span 的邊界是 start marker 起始位置到 end marker 行尾之後，因此 legacy block 之後、Cash block 之前的空白行落在 span 之外，會原樣保留。實測 Tubify 的 `AGENTS.md` 在 legacy span 之後有兩個空行，移除後檔案將以兩個空行開頭。

這在觀感上不完美，但「managed span 以外的 bytes 逐 byte 保留」是既有 requirement 明訂的契約，主動修剪空白行反而會違反它。因此不處理，並在此明文記錄，避免 review 將其誤判為缺陷。

### D5：測試放在 `scripts/cash-skills/tests/test_installer_runtime.py`，不動 `scripts/cash-skills/tests/skill-checks.fish`

`skill-checks.fish` 的 `assert_installer` 以檔名呼叫 `test_installer_runtime.py`，該檔以 `unittest.main()` 收尾，新增測試案例會被自動探索，不需要修改 `skill-checks.fish`。它是 grader-protected path，未在本 change 的 `## Impact` 宣告，也不應宣告。

測試 fixture 中會出現 legacy marker 的字面字串。`openspec/specs/cash-cli/spec.md` 的 `Live namespace` requirement 列有可辨識 legacy marker 的 path 白名單，不含 `scripts/cash-skills/tests/`；但 `scripts/cash-skills/tests/test_live_namespace.py` 實際偵測的是 legacy config、state 目錄與可執行的 legacy 呼叫，不偵測 marker 字面，因此新增 fixture 不會使該檢查變紅。fixture 中的 marker 字面是測試資料，不是 legacy migration code。

### D6：字尾容忍新增一類永久失敗形態，處置限於讓診斷具名檔案

字尾容忍擴大了「會被當成 marker」的輸入集合，因此一份**現行實作處理正常**的 guidance，容忍之後可能 fail closed。已端對端實測：target 的 `AGENTS.md` 含一個合法 Cash block，另有獨立一行的 `<!-- SPECTRA:START v1.0.2 -->` 但無對應 end（例如 migration 筆記或示範 marker 格式的段落），現行實作回報 `Result: update` exit 0，容忍之後則以孤立判定 exit 1，且 `--force` 不繞過。

這個後果本身是可接受的 —— 該形式確實是一個孤立 marker，fail closed 符合既有 requirement，訊息措辭與真實成因也相符。真正的缺口只有一個：訊息不指出是哪一個檔案，使用者無法自助定位。

**處置只有一項：把 guidance 的相對路徑傳入 `marker_span` 並附在全部例外訊息尾，兩個呼叫端各補一個引數。** `marker_span` 目前的三個例外都不含檔名，而同一路徑上 `render_guidance` 的巢狀例外則有帶檔名，落差明顯；補齊之後全部 marker 失敗都能定位到檔案。

**明確不做「形式不被辨識」的獨立診斷分支。** round 1 曾規劃這個分支——計數不相等時額外檢查是否存在 marker 前綴卻無合法匹配——round 2 review 對它提出三個獨立缺陷，全部經實測證實：

- 該分支 gate 在計數不相等上，但形式不被辨識的 marker 若是檔案中唯一的 marker，合法匹配數是 0 對 0、計數相等，分支根本不觸發，installer 照常成功。要涵蓋這種情形就得移除 gate，那等於為所有含形似 marker 散文的檔案新增一類 fail closed，比原問題更糟。
- 前綴判準無法區分散文與畸形 marker。實測輸入「散文中提到 `<!-- SPECTRA:START` ＋ 一個真正孤立的合法 END」會被診斷為形式不被辨識，但真實成因是孤立，方向剛好相反。
- 它對上述動機案例完全無效：那個案例的 marker 形式**是**被辨識的，前綴數等於合法匹配數，分支不觸發。

三者的共同根因是：不做行首錨定就無法可靠區分「文件裡談到 marker」與「一個寫壞的 marker」，而行首錨定是本 change 的 Non-Goal。因此這個分支的規格不可能在本次範圍內寫對，撤除是正確的收斂。更細緻的 marker 形式診斷列為 Non-Goal。

同一個根因也決定了 Risks 記載的雙向行為改變如何寫進 requirement。定位不去區分「文件中談到 marker」與「一個真的 marker」，這是實作手法層面的事實而非可觀察行為，因此它留在此處作為 rationale，**不寫成 requirement 的 MUST NOT**——把不可觀察的實作禁令寫成永久 normative，既無法機械驗證，也會使日後真要修這個資料損壞時必須先 MODIFY 一條剛寫進 master 的 MUST NOT。requirement 只承載可觀察的部分：容忍同時擴大與縮小可安裝的 target 集合，且 span 外 bytes 逐 byte 保留契約在兩個方向皆維持。

### D7：`CASH-SKILLS.md` 的 marker 治理敘述必須手動同步

`CASH-SKILLS.md` 描述 guidance marker 治理的段落，目前把「未知版本 marker」與 symlink、duplicate、orphan、reversed、nested、非獨立行並列為會在首次 target write 前 fail closed 的形式。本次改動使該句直接變假 —— 帶版本字尾正是要被容忍的形式。

該檔案由 `openspec/specs/cash-skill-workflows/spec.md` 中要求指南說明 marker 衝突的 requirement 治理。沒有任何自動檢查會偵測這處 drift，但理由必須據實敘述——round 2 review 指出我先前把兩個不同的檢查混為一談：

- `scripts/cash-skills/tests/test_live_namespace.py` 偵測的是 legacy config、state 目錄與可執行的 legacy 呼叫，不讀 `CASH-SKILLS.md` 的任何敘述。
- `skill-checks.fish` 的 sha256 baseline 綁定的是 source `AGENTS.md` 的 canonical block，與 `CASH-SKILLS.md` 無關。
- `skill-checks.fish` 的 `assert_guidance_and_docs` **確實會讀 `CASH-SKILLS.md`**，以 14 條字面做 `assert_contains`，其中包含 `fail closed`。但該字面在本檔 46、56、68、70、74 五行皆出現，改寫其中一行不會使檢查變紅，因此它不構成對本處敘述的保護。

結論不變（無自動檢查會攔下這處 drift），但實作者必須知道那 14 條字面的存在：改寫時 MUST 全數保留，否則 `assert_guidance_and_docs` 會失敗。因此本檔必須被列入 `## Impact` 並以獨立 task 手動同步。

同步的範圍不只那一句。IC5 與 D3 各引入一個「一個 source 檔擋掉全部 registered target」的新失敗模式——source Cash marker 帶字尾、以及 source guidance 中出現形似 legacy marker 的文字——兩者都是使用者無從自行推導的行為，指南未載則他們看到全部 target 同時失敗時無從理解成因。因此 tasks 2.4 要求改寫三處而非一處。

## Implementation Contract

**IC1 — marker 可接受形式**：`marker_span` 對 start 與 end 皆接受「`<!-- ` 加 name 加 `:` 加種類，其後可選一段以單一空白起始、不含 `<`、`>`、CR 與 LF 的字尾，再接 ` -->`」。同時排除 `<` 與 `>` 使字尾無法跨越註解的任一側界定符吞噬鄰接內容。字尾內容不被解析、不被比較、不影響任何回傳值或判定。

**IC2 — 獨立成行無字尾 marker 的行為零變化**：當一份 guidance 中某個名稱的全部 marker 都獨立成行且都不帶字尾時，新定位對該名稱回傳的 span 起訖與現行實作逐 byte 相同。此保證是**逐檔**而非逐 marker：定位的三層防護建立在整份資料的匹配計數上，因此同一份檔案裡若另有一個帶字尾的同名 marker，計數會改變而使原本可定位的那一對落入重複判定。該情形屬 D6 記載的行為改變，不在本保證範圍內。marker 之前同行若有普通文字（不含註解起始序列）亦不在保證範圍內，理由是行首錨定屬 Non-Goals；同行稍前為另一個註解起始序列的情形則由 D1 的 `<` 排除規則處理，span 起點仍落在合法 marker 處，屬保證涵蓋範圍。驗收以 tasks 1.3 的可重跑 fixture 為準。

**IC3 — 五種判定不放寬**：非獨立行、重複、孤立、反序四項在 `marker_span` 內的觸發條件不變；巢狀在 `render_guidance` 內的判定不變。帶字尾的 marker 若同時違反其中任一項，仍必須 fail closed，且 `--force` 不繞過。

**IC4 — 診斷具名且可區分 source 與 target**：`marker_span` 新增一個能唯一識別該 guidance 的標籤引數，其全部例外訊息必須包含該標籤。標籤不得只是相對路徑：`canonical_guidance` 與 `render_guidance` 的 `relative` 取值是同一組 `AGENTS.md` 與 `CLAUDE.md`，只傳路徑會使 source 端與 target 端的失敗訊息逐字相同。`canonical_guidance` MUST 傳入帶 source 限定詞的標籤（既有的兩個 source 專用例外已靠訊息中的 `source` 字樣自我消歧，新標籤沿用同一慣例），`render_guidance` 傳入 target 側的相對路徑。此消歧在 `--all` 下尤其關鍵：批次路徑對每個 registry 條目印出以 target 路徑為前綴的錯誤行，一個 source 端的 marker 失敗會被印成 N 行、每行指控一個不同且無辜的 target。`marker_span` 全部既有例外的語意維持不變，僅附加該標籤——現行三個例外分別對應非獨立行、重複與孤立、反序，四種判定一個都不得改變措辭語意。不新增任何其他診斷分支。

**IC5 — source canonical marker 不得帶字尾**：`canonical_guidance` 對 source 的 Cash start 與 end marker 額外要求不帶字尾，帶字尾時在首次 target write 前 fail closed，該字尾不得被寫入任何 target。該例外的訊息必須包含帶 source 限定詞的標籤（其中含相對路徑），與 IC4 對其餘 marker 例外的要求一致。

**IC6 — legacy 遷移分支的測試覆蓋**：`test_installer_runtime.py` 必須涵蓋六個成功情境與八個失敗情境。成功情境為：帶字尾 legacy block 與 Cash block 並存時 legacy 被移除；帶字尾的 legacy-only guidance 被遷移；帶字尾的 legacy end marker 被正確定位；`CASH:START` 與 `CASH:END` 皆帶字尾時自我修復為不帶字尾的 canonical block；不帶字尾的既有形式維持既有行為；合法 marker 之前同行另有註解起始序列時 span 起點不變且該行稍前 bytes 不被刪除。失敗情境為孤立、重複、反序、非獨立行、巢狀各一，加上 source marker 帶字尾兩個（start 與 end 各一——delta 與 IC5 都要求兩側，只測 start 會讓「只對 start 加檢查」的實作通過全部斷言），以及 source 側由 `marker_span` 觸發的失敗一個。最後一項不可省略：其餘七個失敗情境中，`marker_span` 的例外全部在 target 側，source 側的兩個打到的是 IC5 的新例外，因此若無此情境，IC4 的「`canonical_guidance` MUST 傳入帶 source 限定詞的標籤」沒有任何可執行驗證。診斷具名且可區分 source 與 target 不另計為情境，它是對全部失敗情境的橫向斷言；「managed span 以外的 bytes 與檔案 mode 未變」同樣是對全部成功情境的橫向斷言，由 tasks 第 1 節前言單一承接，不在各 task 逐項重述。

**IC7 — 版本調升**：`cash-skills.version` MUST 寫為嚴格大於「當下工作樹值」與「`git show HEAD:cash-skills.version`」兩者的下一個版本，MUST NOT 寫死常數。理由是同一 workspace 可能有其他進行中的 change 也宣告調升該檔——sibling change `guard-post-archive-commit-allowlist` 曾於本 loop 進行期間把該檔由 `2.3.1` 升為 `2.4.0`，並已於 commit `2c700eb` 提交並封存，故當下工作樹與 HEAD 皆為 `2.4.0`。寫死常數在兩種狀態下各有一種後果，且較危險的那種無自動檢查攔截：

- sibling **已提交**（HEAD 為 `2.4.0`）時，寫死 `2.3.2` 會因不大於 HEAD 而使 `check_history` 拋 bundle version must strictly increase，IC8 的三道關卡必然失敗。這種失敗是響亮的。
- sibling **尚未提交**（HEAD 為 `2.3.1`、工作樹為 `2.4.0`）時，`check_history` 只比對工作樹值與 `git show HEAD:cash-skills.version` 這兩個值，它不知道工作樹被覆寫前是什麼，因此寫死 `2.3.2` 會**靜默通過**——`2.3.2` 確實大於 HEAD 的 `2.3.1`——同時把 sibling 已完成的 `2.4.0` 覆寫掉。沒有任何檢查會攔下這個回退。

第二種正是必須推導而非寫死的主要理由：響亮的失敗會被關卡擋住，無聲的回退不會。改動 `.cash-skills/lib/cash_cli/installer.py` 之後、下一次執行任何 `.cash-skills/bin/cash` 指令之前，必須於 project root 執行 `./install-cash-skills.fish --self` 重建 receipt，否則 launcher 會以 receipt 驗證失敗擋下所有後續指令。

**IC8 — 驗收**：`.cash-skills/bin/cash validate --all`、`fish scripts/cash-cli/tests/cli-checks.fish` 與 `fish scripts/cash-skills/tests/skill-checks.fish` 三者全綠。另需實跑 `./install-cash-skills.fish --all --dry-run`，確認先前以 marker 理由 `failed` 的兩個 target 不再 `failed`、且彙總的 `failed` 計數為 0。此驗收不綁定 registry 條目總數。

## Risks / Trade-offs

**修好之後會刪除使用者檔案中的內容。** Tubify 與 player-log-downloader 的 `AGENTS.md` 與 `CLAUDE.md` 會在下一次安裝時各被刪去一段 legacy block（實測刪除量分別為 1198 與 1212 bytes，兩個 repository 的 `AGENTS.md` block 逐 byte 相同、`CLAUDE.md` block 逐 byte 相同——實測為兩個相異 digest 各兩份而非四段一致，長度既已分別為 1198 與 1212 就不可能同 digest；兩兩逐 byte 相同對「是標準死指引而非使用者客製」這個結論的支撐反而更強）。這不是新行為，而是既有 requirement 明訂卻一直無法執行的行為，且兩個 target 都已有完整正確的 Cash block。

需要留意的是 `--dry-run` **不提供 byte-level 預覽** —— 實測其輸出只有分類結果，沒有 guidance diff 或刪除量，因此「先跑 dry-run」不是內容層級的保護。真正的保護是先確認那兩個 target 的 guidance 檔案已提交到版控；實測目前兩者的 `AGENTS.md` 與 `CLAUDE.md` 都處於 uncommitted modified 狀態，直接安裝會讓「用 git 還原」這條退路連帶丟掉未提交的修改。tasks 3.2 本身只跑 `--dry-run`、不寫入任何 target，因此該確認不是 3.2 的前置步驟，而是 3.2 明訂本 change 完成回報時必須告知使用者的交付說明——真正的刪除發生在使用者日後某次真實安裝。

**字尾容忍會讓一部分現行可安裝的 target 變成 fail closed。** 見 D6：guidance 散文中若出現形似 marker 的獨立行且無對應另一側，容忍之後會被判為孤立而 fail closed，`--force` 不繞過。這符合既有 requirement 的語意，但確實是本次改動引入的行為改變，已在 D6 記錄並以可辨識的具名診斷緩解。

**字尾容忍的行為改變是雙向的，第二個方向後果更嚴重。** 上一段記錄的是「現行可安裝 → 容忍後 fail closed」。反方向同時存在：一份**現行實作 fail closed** 的 target guidance，容忍之後會成功安裝並靜默改寫 project-owned 內容。三個實測案例：

- target `AGENTS.md` 含一個合法 Cash block，另有一段 fenced 範例逐行寫出完整的 legacy start／內容／end，**且該範例的 start marker 帶字尾**（例如文件照實抄錄 `<!-- SPECTRA:START v1.0.2 -->`）。現行實作因計數不相等而 fail closed；容忍之後該 span 被辨識為真的 legacy block 並替換為空 bytes，範例內容被刪除，只剩一組空的 fence。與第二個案例同理，「帶字尾」這個前提不可省略：實測範例兩側皆不帶字尾時新舊定位完全相同（皆為 `(47, 96)`），該範例內容在現行實作下即已被刪除，不屬本次引入的行為改變。
- target guidance 沒有真正的 Cash block，但有一對獨立成行的說明用 Cash marker，且其中**恰有一側帶字尾**。現行實作因計數不相等而 fail closed；容忍之後兩行之間的說明被整段換成 canonical block。前提中的「恰有一側」不可省略：實測兩側皆不帶字尾時新舊定位完全相同（皆為 `(6, 49)`）、根本不是行為改變，兩側皆帶字尾時現行回傳無 span 而於檔尾附加 canonical block、亦非 fail closed。但「亦非 fail closed」不等於「無風險」——這個形狀是第三個方向：容忍之後該 span 會被辨識為真 marker，其間的 project-owned 內容被替換或移除，而前後兩次安裝都以相同狀態成功、exit code 與分類皆不變，使用者沒有任何訊號。它是三個方向中唯一不可被觀察到的資料移除，見下一段。只有恰有單側帶字尾才是「現行 fail closed、容忍後靜默替換」。
- guidance 首行為 `<!-- SPECTRA:START <!-- SPECTRA:START v1 -->`。現行 fail closed；容忍之後 span 起點落在第二個 marker（`<` 排除規則的正確結果），移除 legacy block 後首行永久殘留一個斷頭的 `<!-- SPECTRA:START `。

還有第四種形狀既非散文也非範例：一個貨真價實的完整 legacy block，兩側皆帶字尾且 end marker 是檔案最後一行、其後無尾隨換行。實測現行實作因字面計數 0 對 0 而回傳無 span、於檔尾附加 canonical block 並 exit 0；容忍之後兩個匹配成立但 end 的尾側不是換行，落入非獨立行判定而整個 target fail closed。它同屬「容忍擴大 fail-closed 集合」這一類，列出來是為了讓 requirement 正文的「散文或範例」不被讀成窮舉。其前提要求兩側皆帶字尾，語料上不存在，實務風險低。

**第三個方向：原本保留、容忍後被移除，且完全無訊號。** 上述案例的共同起點都是「現行實作 fail closed」。還有一類的起點是「現行實作安裝成功且內容被原樣保留」：target guidance 含一個合法 Cash block，另有一段以兩側皆帶字尾的 legacy marker 包住的說明文字。現行實作因字面計數 0 對 0 而回傳無 span，該段原樣保留、安裝 `Result: update` exit 0；容忍之後同一份檔案的該 span 被辨識為真 legacy block 並被移除，安裝同樣 `Result: update` exit 0。**前後兩次的 exit code 與分類結果完全相同，使用者沒有任何訊號**，而 `--dry-run` 又不提供 byte-level 預覽。這是三個方向中唯一連失敗訊息都沒有的資料移除，因此在 requirement 正文中被明確列為第三個方向而非前兩者的特例。附帶一提，tasks 1.4 case 二測的正是同一個定位事件——`CASH` 兩側皆帶字尾被辨識並自我修復——本 change 為它寫了「這樣做是對的」的測試，此處記錄的是它的有害孿生體。

前三者的共同前提是 guidance 裡出現了形似 marker 的散文或範例，而定位無法區分「文件裡談到 marker」與「一個真的 marker」——這正是 D6 撤除診斷分支時記錄的同一個根因，只是後果落在另一側。第三個案例的殘留 bytes 落在 managed span 之外，因此逐 byte 保留契約仍成立，但輸出結果對使用者而言是壞的。

本次接受這三個後果而不加防範，理由是可靠的區分需要行首錨定與 fenced 區塊解析，兩者都遠超本 change 的範圍；但它們必須被記錄，因為 `--dry-run` 不提供 byte-level 預覽，使用者在真正寫入前沒有機會看到刪除量。這也是 tasks 3.2 把「先確認 guidance 已提交或另存副本」列為完成回報時之交付說明的真正理由。

**測試補的是既有路徑而非本次新增的路徑。** IC6 的十四個情境中，只有帶字尾的相關情境是本次修復直接產生的行為；其餘是在補既有的覆蓋缺口。這使本 change 的測試量相對於程式碼改動量偏大，但該缺口正是本缺陷得以存活的原因，不補則同型缺陷仍可再次無聲通過。

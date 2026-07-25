## MODIFIED Requirements

### Requirement: Cash guidance deployment

Installer SHALL從source `AGENTS.md`與`CLAUDE.md`各擷取唯一、完整且no-follow snapshot的Cash block。對非`newer`、非`conflict`target，它 MUST建立或更新對應Cash block、移除一個合法legacy Spectra block、逐byte保留managed spans外內容與既有mode，並與runtime/skills/receipt共用transaction。Marker孤立、反序、重複、巢狀、非獨立行、post-preflight bytes/identity drift或parent swap MUST在publication前fail closed。

Managed marker的可接受形式 MUST為`<!-- `加marker名稱加`:`加`START`或`END`，其後可選一段以單一空白起始、不含`<`、`>`、CR與LF的字尾，再接` -->`。該字尾容忍 MUST對`CASH`與`SPECTRA`兩個名稱、`START`與`END`兩種種類一致適用——marker定位對名稱與種類泛化，只容忍其中一側會在另一側出現字尾時以完全相同的方式使整個target fail closed。字尾**內容** MUST NOT被解析、比較或用於marker定位的任何決策，且 MUST NOT放寬孤立、反序、重複、巢狀、非獨立行任一項判定。此限定僅及於marker定位；source側以字尾之有無為判準的禁令見下文，不受本段拘束。

字尾內同時排除`<`與`>` MUST維持，使字尾無法跨越註解的任一側界定符吞噬鄰接內容。行界的排除 MUST同時涵蓋CR與LF而非僅LF——只排除LF時，CR-only行界之後的project-owned bytes會被當作字尾而納入managed span，並在遷移時隨該span一併被替換或移除。排除`>`防止字尾越過結尾符號吞掉後續內容；排除`<`防止字尾向前吞掉同行稍前的另一個註解起始序列——後者會把原本落在managed span之外、受逐byte保留保護的bytes捲入span而在遷移時被刪除。

一份guidance中某個名稱的全部marker都獨立成行且都不帶字尾時，字尾容忍 MUST NOT改變該名稱所定位出的span起訖。此等價保證是逐檔而非逐marker：定位的判定建立在整份資料的匹配計數上，因此同一份檔案裡若另有一個帶字尾的同名marker，計數會改變而使原本可定位的那一對落入重複判定，該情形不在本保證範圍內。marker之前同行若有普通文字（不含註解起始序列）亦不在範圍內，理由是行首錨定不在本requirement的規範範圍。marker之前同行若是另一個註解起始序列，則由前一段的`<`排除規則處理，span起點仍落在合法marker處，屬本保證涵蓋範圍而非例外。

字尾容忍改變了「哪些bytes會被當作managed marker」。guidance中形似marker的散文或範例，因此會落入以下三個方向之一，三者皆為本requirement接受的結果：由原本被靜默忽略變成被判定為孤立而fail closed；由原本fail closed變成被當作真marker而其內容被替換或移除；以及由原本被忽略而**內容原樣保留**變成被當作真marker而內容被替換或移除。第三個方向 MUST被明確涵蓋而非視為前兩者的特例——它的前後兩次安裝都以相同狀態成功結束、exit code與分類結果皆不變，使用者沒有任何訊號，且`--dry-run`不提供byte-level預覽，因此它是三者中唯一不可被觀察到的資料移除。此列舉 MUST NOT被讀成窮舉。managed span以外的bytes逐byte保留契約在三個方向皆 MUST維持不變。

Source的canonical Cash block其start與end marker MUST NOT帶字尾。理由是source的Cash span會被逐byte當作canonical block寫入每一個target，若source marker帶字尾，該字尾會被散播到全部target；字尾容忍的目的是接納既有target上的legacy形式，不是讓source產出帶字尾的marker。source Cash marker帶字尾時 MUST在首次target write前fail closed。

全部marker相關的失敗診斷 MUST具名出問題的guidance檔案，且 MUST可區分該檔案屬source bundle或屬target，使失敗可被自助定位；source與target的guidance相對路徑取值相同，僅具名路徑不足以消歧，此義務涵蓋非獨立行、重複、孤立、反序、巢狀與source字尾全部判定。各既有診斷 MUST維持其既有語意，僅附加該標籤。

#### Scenario: Missing、Spectra-only 與 mixed guidance 收斂

- **WHEN**target guidance missing、沒有managed block、只有一個合法Spectra block或同時有合法Cash/Spectra blocks
- **THEN**installer產生恰好一個canonical Cash block並移除合法Spectra block
- **AND**managed spans外bytes與既有mode保持不變，新建file mode為`0644`

#### Scenario: Guidance snapshot 與 parent identity 綁定

- **GIVEN**preflight記錄guidance no-follow handle的bytes、digest、mode與parent/destination identity
- **WHEN**temporary create與最後publication checkpoint執行
- **THEN**installer重新驗證全部snapshot與identity
- **AND**parent/destination被替換時不覆蓋新內容或root外sentinel

#### Scenario: Guidance marker malformed

- **WHEN**source或target Cash/Spectra markers孤立、反序、重複、巢狀或非獨立行
- **THEN**installer在首次target write前exit 1
- **AND**`--force`不繞過失敗

#### Scenario: 帶字尾的 marker 被辨識並收斂

- **GIVEN**target guidance中`CASH`或`SPECTRA`的start或end marker帶有一段符合本requirement所定義之可接受形式的字尾
- **WHEN**installer處理該target
- **THEN**installer辨識該marker並依既有收斂規則處理
- **AND**該target MUST NOT因該字尾而以marker重複、孤立或任何其他guidance理由fail closed
- **AND**字尾含`<`或`>`者不屬本scenario：僅一側如此時由`帶字尾 marker 違反判定仍 fail closed`涵蓋，兩側皆如此時該形式不被辨識為managed marker，由`Missing、Spectra-only 與 mixed guidance 收斂`的「沒有managed block」分支涵蓋
- **AND**同一份guidance中該名稱另有其他marker而使匹配計數落入重複或孤立判定者亦不屬本scenario，由`帶字尾 marker 違反判定仍 fail closed`涵蓋；此限定與本requirement等價保證段的逐檔判準一致

##### Example: 帶版本字尾的 legacy start marker

- **GIVEN**target guidance首行為`<!-- SPECTRA:START v1.0.2 -->`且檔案另含一個合法Cash block
- **WHEN**installer處理該target
- **THEN**legacy block被移除、Cash block被更新為canonical內容
- **AND**兩個managed span以外的bytes與檔案mode逐byte不變

##### Example: 帶字尾的 Cash marker 自我修復

- **GIVEN**target guidance的`CASH:START` marker帶有字尾
- **WHEN**installer處理該target
- **THEN**該span被替換為source的canonical Cash block，其marker不帶字尾
- **AND**installer MUST NOT因該字尾fail closed

#### Scenario: 字尾容忍不改變獨立成行無字尾 marker 的 span

- **GIVEN**guidance中`CASH`的全部marker都獨立成行且都不帶字尾
- **WHEN**installer定位該managed span
- **THEN**span起訖與字尾容忍導入前逐byte相同

#### Scenario: 帶字尾 marker 違反判定仍 fail closed

- **WHEN**帶字尾的marker孤立、反序、重複、巢狀或非獨立行
- **THEN**installer在首次target write前exit 1
- **AND**`--force`不繞過失敗

#### Scenario: 字尾不跨越註解界定符

- **GIVEN**guidance的某一行在合法Cash start marker之前另有一個註解起始序列，亦即該marker的前綴在同一行出現兩次而只由行尾單一個結尾符號收束
- **WHEN**installer定位該managed span
- **THEN**span起點落在合法marker處，與字尾容忍導入前相同
- **AND**該行稍前的bytes MUST維持在managed span之外，MUST NOT在遷移時被刪除

#### Scenario: 全部 marker 失敗診斷具名檔案

- **WHEN**任一guidance marker判定導致installer失敗
- **THEN**該診斷包含出問題的guidance檔案的project-root相對路徑
- **AND**該診斷可區分出問題的是source bundle的guidance或target的guidance
- **AND**非獨立行、重複、孤立與反序各既有診斷維持既有語意

##### Example: source 側的 marker 失敗具名

- **GIVEN**source的`AGENTS.md`其`CASH` marker違反非獨立行、重複、孤立或反序任一判定
- **WHEN**installer擷取canonical Cash block
- **THEN**installer在首次target write前exit 1
- **AND**該診斷同時包含source限定詞與相對路徑，與target側同一判定的診斷可區分

#### Scenario: Source canonical marker 不得帶字尾

- **GIVEN**source的`AGENTS.md`或`CLAUDE.md`其Cash start或end marker帶有字尾
- **WHEN**installer擷取canonical Cash block
- **THEN**installer在首次target write前exit 1
- **AND**該字尾 MUST NOT被寫入任何target

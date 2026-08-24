## ADDED Requirements

### Requirement: Canonical discipline contract tests 精確辨識語意退化

canonical TDD、test-quality 與 tasks resource 的 deterministic contract tests SHALL分離 required-marker absence 與 additive contradiction 兩種失敗機制。required marker 被移除或替換時 MUST以`missing`類 rejection失敗；canonical required markers全部仍存在、但另加入會弱化同一義務的矛盾句時 MUST以`forbidden`類 rejection失敗。每個保留的 explicit contradiction MUST有一個只加入該句的獨立 mutation case直接行使，不得由較早的required-marker failure冒充。

validator MUST只拒絕 obligation-specific contradiction，不得以`可以不`、`不必`、`視情況`等裸 token作為跨 contract 的通用失敗條件。測試 MUST包含會命中這些裸 token但符合 canonical contract 的 acceptance cases，至少涵蓋remaining task不建立red phase、未修改測試時不取得test-quality，以及無自動測試邊界時使用manual assertion。checker MUST保持tool與framework中立，且 MUST NOT引入外部dependency或mutation framework。

TDD contradiction categories MUST恰為`carrier-fixed`、`unexecuted-red`與`red-after-edit`；test-quality categories MUST恰為`derived-expected`、`non-observable-result`、`unbounded-mock`、`framework-required`、`test-for-every-task`與`mutation-skippable`；tasks categories MUST恰為`multiple-primary`、`mixed-success`、`blank-red`與`placeholder-fields`。每個category的detector literal與固定mutation fixture MUST逐字相同，但兩份inventory MUST獨立定義，fixture不得從detector registry推導。測試 MUST先斷言category exact sets，再由fixture inventory執行mutations；只刪除detector guard而保留fixture時，suite MUST非零結束。

每個contradiction literal MUST滿足negation-containment不變式：把該literal改寫成強化同一義務的合法否定句時，該literal MUST NOT仍是該否定句的子字串。測試 MUST持有一份與detector registry及mutation fixture inventory都獨立定義、逐字固定的negation restatement inventory，先斷言其category exact set，再逐一驗證該不變式。測試 MUST另斷言`可以不`、`不必`與`視情況`三個retired裸token都 MUST NOT成為任一detector inventory的完整value，並 MUST以exact set斷言錨定這三個token本身，使該守衛的比對來源無法被靜默削減。negation restatement inventory本身也是守衛的輸入：測試 MUST斷言每句restatement包含「把該category的literal插入單一個`不`或`並非`後」所得的字串，使inventory退化成空字串、單字元、缺少否定詞或與該義務無關的字串時該不變式非零結束；MUST以exact set斷言錨定這兩個否定詞；MUST斷言每句append到對應canonical文本後仍被該validator接受；並 MUST以「該category的literal append到同一canonical後被同一validator具名拒絕」綁定validator與category的對應，使對照表被錯接時非零結束。negation-containment斷言 MUST排在上述斷言之前，使literal退化時它是首先失敗且具名的診斷。此結構規則 MUST NOT宣稱能判定否定詞的插入位置在語法上真的構成否定；該層由D5的逐字清單與人工審查保證。

#### Scenario: Required marker removal 與 additive contradiction 使用不同 rejection

- **GIVEN** canonical instruction或tasks resource包含全部required markers
- **WHEN** mutation只移除或替換一個required marker
- **THEN** validator以`missing`類rejection失敗
- **AND** mutation保留全部required markers、只加入一個具名矛盾句時，validator以`forbidden`類rejection失敗

#### Scenario: 每個 explicit contradiction 都被直接行使

- **WHEN** 執行`PYTHONPATH=.cash-skills/lib python3 scripts/cash-cli/tests/test_graph_instructions.py`
- **THEN** TDD、test-quality與tasks validator的每個保留explicit contradiction都有獨立additive mutation
- **AND** 刪除任一對應guard時，該mutation以未捕捉矛盾而使suite非零結束
- **AND** fixed mutation fixtures不由受測detector registry派生，刪除guard不會同步刪除對應case

#### Scenario: 合法近義措辭不被裸 token 誤判

- **GIVEN** canonical required markers保持不變
- **WHEN** instruction或resource另含符合contract且使用`可以不`、`不必`或`視情況`的合法說明
- **THEN** validator接受該內容
- **AND** acceptance cases分別覆蓋TDD remaining-task、test-quality no-test scope與tasks manual verification

#### Scenario: 強化義務的合法否定句不被 contradiction literal 命中

- **GIVEN** 某個category的contradiction literal
- **WHEN** 把該literal改寫成強化同一義務的合法否定句
- **THEN** 該literal不是該否定句的子字串
- **AND** negation restatement inventory獨立於detector registry與mutation fixture inventory定義，且其category exact set先被斷言

#### Scenario: 守衛的比對來源本身被錨定

- **GIVEN** retired裸token集合與negation restatement inventory
- **WHEN** 任一者被靜默弱化——retired token集合被削減，或restatement被改為空字串、單字元、去掉否定詞、與該義務無關的字串、或本身即為contradiction的字串
- **THEN** suite非零結束
- **AND** validator與category的對照表被錯接時同樣非零結束

#### Scenario: 裸 token 未被重新加入 detector inventory

- **GIVEN** TDD、test-quality與tasks三個detector inventory
- **WHEN** 檢查其全部value
- **THEN** `可以不`、`不必`與`視情況`都不是任一value的完整內容
- **AND** 把任一retired裸token加入某個inventory時，該斷言使suite非零結束

#### Scenario: 精煉不改變 canonical resources

- **WHEN** 完成本requirement的實作
- **THEN** `DISCIPLINES["tdd"]`、`DISCIPLINES["test-quality"]`與tasks artifact resource bytes保持不變
- **AND** 變更只落在contract test validator與fixtures

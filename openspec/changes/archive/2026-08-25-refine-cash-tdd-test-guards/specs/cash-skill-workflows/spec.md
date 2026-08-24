## ADDED Requirements

### Requirement: Testing discipline 單一來源檢查精確辨識重複語意

`tdd-discipline` test group SHALL以完整、低碰撞且與canonical test-quality五項gate對應的繁中canonical原文與英文equivalent clauses檢查`cash-apply`與`cash-debug`是否重複擁有canonical語意。checker MUST涵蓋named defect、independent expected、consumer-visible assertion、slow／external mock boundary與bounded mutation check，且每個gate MUST恰有`zh`與`en`兩個逐字固定clauses，對`.agents`與`.claude`兩個變體的四份skill執行。

五個gate的逐字clauses MUST分別使用：`命名一個會使該測試失敗的 realistic production defect`／`name a realistic production defect that would make the test fail`、`expected value 以 literal 或手工驗證 fixture 獨立推導`／`derive the expected value independently from a literal or hand-verified fixture`、`斷言 consumer-visible output、state、side effect 或 failure mode`／`assert consumer-visible output, state, side effect, or failure mode`、`mock 只切 slow 或 external boundary`／`mock only a slow or external boundary`、`執行有限 mutation check`／`perform a bounded mutation check`。

每個forbidden clause MUST有一個in-memory append-injection mutation證明checker會拒絕。detector registry與固定mutation fixtures MUST獨立定義，fixtures不得從registry推導；tests MUST先斷言兩邊gate exact set與每個gate的`zh`／`en`exact set，再以fixtures驅動mutation。測試 MUST另證明只含一般`expected value`或verification prose、不構成完整gate複述的合法文字會被接受。checker MUST NOT以單獨的`expected value`或與canonical語意不對齊的泛用短片語判定失敗，也不宣稱能辨識上述十個固定clauses以外的任意自然語言paraphrase。現有test-quality consumer count、variant parity與command matrix contract MUST保持不變。

checker MUST另斷言五個`zh` clause仍是canonical `DISCIPLINES["test-quality"]`的逐字span，使canonical改寫後這份副本的漂移無法靜默通過。此斷言為anchor而非derivation：十個clause MUST維持逐字固定，fixtures MUST NOT從registry推導。取得canonical失敗時checker MUST fail closed，MUST NOT靜默跳過該斷言。此anchor只涵蓋`zh`半邊；`en` clause僅由本requirement的逐字文字約束，checker MUST NOT宣稱對`en`半邊提供執行期canonical anchor。checker MUST另斷言detector與fixture兩份inventory的clause值逐字相等，使單方面縮短或改寫detector clause無法靜默通過。

checker MUST以具名`LEGITIMATE_PROSE_TOKENS` inventory固定`expected value`與`verification target`兩個合法散文fixture token，並 MUST以inline fixed set執行exact-set斷言。token inventory被削減或擴增時 MUST使`tdd-discipline`群組非零結束；token inventory與合法散文fixture同步削減時同樣 MUST非零結束。

#### Scenario: 十個雙語 canonical-equivalent clauses 都有 mutation 證據

- **GIVEN** 一份未重複test-quality完整語意的canonical skill text
- **WHEN** 測試分別append五個gate的繁中canonical原文或英文equivalent clause
- **THEN** checker對每個mutation都具名拒絕
- **AND** 任一clause從checker移除時，對應mutation使`tdd-discipline`群組非零結束
- **AND** mutation fixtures不由checker registry派生，刪除guard不會同步刪除對應case

#### Scenario: 泛用 expected value 散文不被誤判

- **GIVEN** skill text只在example或verification context使用一般`expected value`措辭
- **WHEN** checker檢查該text
- **THEN** checker接受
- **AND** 該text未包含十個固定雙語canonical-equivalent clauses中的任何一個

#### Scenario: 合法散文 fixture token inventory 被錨定

- **GIVEN** `LEGITIMATE_PROSE_TOKENS`恰含`expected value`與`verification target`
- **WHEN** 任一token被移除、替換或另加入額外token
- **THEN** exact-set斷言具名失敗並使`tdd-discipline`群組非零結束
- **AND** 即使同步從`LEGITIMATE_PROSE`移除相同token，該exact-set斷言仍失敗

#### Scenario: 四份 skill 與既有治理保持完整

- **WHEN** 執行`fish scripts/cash-skills/tests/skill-checks.fish tdd-discipline`
- **THEN** checker檢查`.agents`與`.claude`的`cash-apply`與`cash-debug`
- **AND** test-quality consumer count、variant parity與command matrix assertions仍執行
- **AND** 全量`fish scripts/cash-skills/tests/skill-checks.fish`同樣執行此contract

#### Scenario: zh clause 與 canonical 同步漂移仍被捕捉

- **GIVEN** detector與fixture的某個`zh` clause被同步改成canonical不含的措辭
- **WHEN** 執行`fish scripts/cash-skills/tests/skill-checks.fish tdd-discipline`
- **THEN** injection self-test因兩份inventory自洽而仍通過
- **AND** canonical anchor斷言具名指出該gate的`zh` clause已非canonical的逐字span，並使群組非零結束

#### Scenario: detector clause 單方面漂移不被 key set 檢查放行

- **GIVEN** detector與fixture的gate exact set與每個gate的`zh`／`en` key set都仍成立
- **WHEN** 只把detector某個clause縮短或改寫而fixture不動
- **THEN** clause值逐字相等斷言具名失敗並使`tdd-discipline`群組非零結束
- **AND** 該漂移即使仍是canonical的逐字span，也不因通過`zh` anchor而被放行

#### Scenario: 精煉不修改 workflow 本文

- **WHEN** 完成本requirement的實作
- **THEN** 四份`cash-apply`／`cash-debug` `SKILL.md` bytes保持不變
- **AND** 變更只修改`skill-checks.fish`的deterministic guard與mutation self-tests

## Summary

精煉 `strengthen-cash-tdd-evidence` 引入的 deterministic test guards：移除或直接覆蓋未被行使的顯式 `forbidden` 分支，把過寬的 permissive token 改為義務導向的精確矛盾句，並讓 skill 的 test-quality 單一來源檢查使用與 canonical discipline 對應且不誤傷合法散文的具體片段。

## Motivation

現有實作已正確交付 executed RED／GREEN、test-quality discipline 與 task evidence contract，所有 primary 與 regression suites 也通過；但 review 留下三項非阻塞測試品質問題。第一，三個 resource validator 的顯式 `forbidden` literals 沒有獨立 mutation 直接行使，移除它們不會讓現有 suite 失敗。第二，`PERMISSIVE_CONTRADICTIONS` 使用 `可以不`、`不必`、`視情況` 等裸 token，未來合法改寫可能被誤判。第三，skill checks 用泛用或英文片語偵測 canonical test-quality 語意重複，既可能漏掉繁體中文複述，也可能因 `expected value` 誤傷合法 example prose。

apply 的 review loop 另揭露這三項精確度本身缺乏守衛：四個以 modal 起始的 contradiction literal（`red-after-edit`、`non-observable-result`、`framework-required`、`test-for-every-task`）會被其 `不`／`並非` 前綴的合法反述命中，等於在新機制裡重新引入舊的 false-positive class；繁中 clause 與 canonical 之間沒有任何斷言相連，canonical 改寫後這份副本會靜默過時而測試仍全綠；「裸 matcher 已移除」先前只靠程式碼裡沒有那段被動成立，沒有任何斷言守著。三者都屬「檢查本身不會失敗」的假綠形狀，與本 change 的目的同一類。

這些問題不改變目前使用者可見行為，但會削弱後續 contract 變更時測試的鑑別力與可維護性，因此適合拆成獨立的 refactor change，不阻塞原 change 封存。

## Proposed Solution

- 對 TDD、test-quality 與 tasks resource validator 的每一個保留 prohibition，建立逐字固定的 category inventory，並由不從 detector registry 推導的獨立 mutation fixtures 保留全部 required markers、只加入該禁止句，再具名斷言 rejection 原因；若某個顯式 prohibition 已被更精確的 obligation-specific guard 完整涵蓋，直接移除重複分支。
- 將 `PERMISSIVE_CONTRADICTIONS` 的裸 token 改為按 validator 分組的精確矛盾句，只拒絕會弱化 executed RED、test-quality 或 task evidence 義務的句型；加入合法近義措辭 acceptance cases，證明 checker 不以單獨的 `可以不`、`不必` 或 `視情況` 判死刑。
- 將 `test_quality_gate_literals` 改為具體、低碰撞且與 canonical discipline 對應的繁中原文／英文 equivalent 雙語去重 markers；固定五個 gate、每個 gate 兩個 clauses，並由獨立 mutation fixtures 驗證在 `cash-apply` 與 `cash-debug` 兩個變體中加入任一完整 clause 都會失敗，而合法的 example／verification prose 保持通過。
- 為守衛的**輸入**也補上錨定：retired 裸 token 集合以 exact set 斷言、negation restatement inventory 逐字寫入 design 並加內容斷言、fish 兩份 inventory 斷言 clause 值逐字相等；並在 Risks 具名記下兩項刻意接受的殘餘缺口（`可以先做` 家族在 TDD 側零覆蓋、`en` 半邊無執行期 anchor）。
- 將合法散文 acceptance fixture 使用的 `expected value` 與 `verification target` 兩個歷史 false-positive token 固定為具名 inventory，並以 exact set 斷言，避免 token inventory 與 fixture 同時被削減後 checker 靜默全綠。
- 為三個精確度性質各補一層機械覆蓋，避免它們只靠「當初寫對了」維繫：contradiction literal 必須滿足 negation-containment 不變式並由獨立的 negation restatement inventory 驗證；skill checker 的五個繁中 clause 必須錨定 canonical `DISCIPLINES["test-quality"]`；三個 retired 裸 token 不得成為任一 detector inventory 的完整 value。
- 保留現有 consumer 數量、variant parity、command matrix 與全量 regression coverage，不改 canonical resource 或 workflow 行為；每個 implementation task 另以 change-scoped diff manual assertion 證明只修改自身 delivery path。

## Non-Goals

- 不改變 `DISCIPLINES["tdd"]`、`DISCIPLINES["test-quality"]` 或 tasks artifact resource 的 canonical 文本。
- 不改變 `cash-apply`、`cash-debug` 的執行流程、toggle 語意、evidence mapping 或 CLI command surface。
- 不新增 test framework、mutation framework、dependency 或 production runtime abstraction。
- 不回寫或重開 `strengthen-cash-tdd-evidence`；該 change 可獨立封存。

## Alternatives Considered

- 保留現況：目前 suite 全綠，但 dead guard 與過寬 matcher 會讓未來修改產生 false green 或 false positive，延後只會提高定位成本。
- 只刪除 dead `forbidden` tuples：能減少無效分支，但未處理 permissive token 與跨語言去重 matcher 的精準度。
- 引入通用自然語言規則引擎：超出問題規模，增加依賴與不可預測性；本 change 採有限、具名、可 mutation 驗證的 literals。

## Capabilities

### New Capabilities

- (none)

### Modified Capabilities

- cash-cli：精煉 canonical TDD、test-quality 與 tasks resource contract tests 的 rejection-path 鑑別力與合法措辭容忍度。
- cash-skill-workflows：精煉 `cash-apply`／`cash-debug` test-quality 單一來源去重 checks，避免跨語言漏檢與泛用片語誤判。

## Impact

- Affected specs:
  - openspec/specs/cash-cli/spec.md
  - openspec/specs/cash-skill-workflows/spec.md
- Affected code:
  - New:
    - (none)
  - Modified:
    - scripts/cash-cli/tests/test_graph_instructions.py
    - scripts/cash-skills/tests/skill-checks.fish
  - Removed:
    - (none)

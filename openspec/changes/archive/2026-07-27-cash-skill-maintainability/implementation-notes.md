<!-- cash-apply implementation notes | change: cash-skill-maintainability | initialized: 2026-07-27 20:03 | no entries below means no deviations or open questions were recorded -->

## 2026-07-27 20:31 — variant-rules.yaml 以受限 YAML 子集自解析

- 類別：deviation
- 任務：2.2
- 內容：`design.md` D2 允許「generator 得以 python3 輔助解析規則檔」，實作時發現本機 python3（3.13.0）沒有 PyYAML，stdlib 也不含 YAML 解析器。`scripts/cash-skills/generate.fish` 因此內嵌一個受限 YAML 子集讀取器，只支援 `variant-rules.yaml` 實際使用的形狀：巢狀 block mapping、scalar 或 mapping 的 block sequence、雙引號或裸 scalar，以及 `|` literal block scalar。literal block 的內縮固定為 `parent_indent + 2`（不由首行推導），使本身帶前導空白的 patch 文字不被誤剝。此範圍之外的形狀以明確錯誤結束：縮排不符、缺少值、非預期的 sequence／mapping 位置，以及以 `'`、`{`、`[`、`&`、`*`、`>` 開頭的 scalar（涵蓋單引號 scalar、flow mapping／sequence、anchor、alias、folded block）；`skills:` 之下未知的 skill 名稱與非 `description`／`patches` 的 entry 鍵名同樣以明確錯誤結束，不會靜默丟棄該 skill 的 patch。
- 原因：規則檔的 contract（路徑、宣告式、人可讀、per-skill 具名 entry）完全不變，改變的只是達成手段，且不需要 `a synchronization primitive, identity/generation type, or state machine not defined in design.md`。新增第三方相依會使 `generate.fish` 與回歸套件在無網路或未安裝 PyYAML 的環境失效，違反既有測試套件僅依賴 python3 stdlib 的現況。

## 2026-07-27 20:31 — 生成輸出與 committed `.agents` 的差異裁決

- 類別：deviation
- 任務：2.3
- 內容：完整生成後逐檔比對，十二個 skill 中十個與 committed 內容 byte-identical。`cash-propose` 與 `cash-apply` 的差異僅有本 change 刻意引入的兩類：成對錨點 `<!-- REVIEW-GATE:BEGIN -->`／`<!-- REVIEW-GATE:END -->`，以及受保護 grader 路徑集合新增的三個路徑。第三類差異（apply 兩檔 `## What Changes` 統一為 `## Proposed Solution`）已於 task 1.2 直接套用於兩個變體，故不在此次比對中出現。沒有任何無法由規則重現的既有漂移，因此除 `cash-audit`、`cash-ingest`、`cash-propose` 三個 per-skill entry 外未新增任何 entry。
- 原因：`design.md` D2 要求每個無法由規則重現的差異逐項裁決並記錄；此處裁決結果為「全部差異皆已被規則或本 change 的刻意變更涵蓋」，記錄以留下可稽核的裁決痕跡。

## 2026-07-27 20:22 — cash-cli master spec 的「24-skill variant parity」措辭未列入 delta

- 類別：open-question
- 任務：3.5
- 內容：`openspec/specs/cash-cli/spec.md` 中治理兩套測試套件的 requirement 敘述 `scripts/cash-skills/tests/skill-checks.fish` MUST 治理「24-skill variant parity」。本 change 的 cash-cli delta 只 MODIFIED `Live namespace 與歷史邊界`，未涵蓋該句。此句沒有引用 `scripts/cash-skills/variant-parity/` 路徑，因此不違反 task 3.5 的驗證條件；但對等機制已由 diff manifest 比對改為重新生成 freshness 檢查，該措辭是否需要在 delta 中改寫（例如改為「24-skill 變體生成 freshness」）需要使用者決定。
- 原因：假設為「維持現狀」——「variant parity」描述的是被治理的性質（變體一致性），該性質未變，只有達成手段改變，而手段已由 `cash-skill-workflows` 的 MODIFIED requirement `變體對等比較完整的受治理本文` 涵蓋。若使用者認為該句應同步改寫，需經 `/cash-ingest` 擴充 cash-cli delta。

## 2026-07-27 21:00 — open question 已解決：cash-cli spec 措辭維持現狀

- 類別：open-question
- 任務：3.5
- 內容：本檔上一則 `open-question`（cash-cli master spec 的「24-skill variant parity」措辭是否需改寫）已於 apply review loop Round 1 的 fix actions 以 AskUserQuestion 徵詢使用者，使用者選擇「維持現狀」。原條目保留不刪改，此則為其解決紀錄。
- 原因：使用者確認「variant parity」描述的是被治理的性質（變體一致性），該性質未變，只有達成手段由 diff manifest 比對改為重新生成 freshness 檢查，而手段變更已由 `cash-skill-workflows` 的 MODIFIED requirement `變體對等比較完整的受治理本文` 涵蓋。cash-cli delta 不擴充。

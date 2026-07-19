# Cash Apply Review — Round 2

## Reviewer Findings

### Warning

- `severity`: Warning｜`confidence`: 95｜`layer`: design（原報 spec-text，依規則歸 design）｜`disposition`: unresolved-prior｜來源: Reviewer V
  - `introduced_by`: 本 change 的標題翻譯 diff（非 round 1 修復引入；round 1 修復未觸及此 span）
  - `location`: openspec/specs/cash-skill-workflows/spec.md:1393（「每輪使用全新 sub-agent」requirement）
  - `summary`: `Confidence-scored findings`（HEAD 既有縮短引用形式）未列入 round 1 的 7+2 枚舉，標題翻譯後成為完全懸空的規範性交叉參照；repo-wide 掃描（排除 archive）僅此 1 處殘留。與 round 1 merged finding 同檔同缺陷機制，故成員 1 判 unresolved。
  - `recommendation`: 替換為完整中文標題並把 C3 枚舉擴為 8+2。

## Rating

- post-filter cumulative blocking set：Critical 0、Warning 1（成員 1 因同機制殘留維持在集合中）
- 非阻擋 triaged findings：0（round 1 的 4 項無新證據，不重報）
- `critical_gap`: false
- `round_type`: micro
- 理由：成員 2（bucket 1 歧義）經 Reviewer V 語意對照與絕跡掃描判 resolved 並移除；成員 1 的 46 處宣告修復全部機械驗證通過（絕跡、可解析、逐一對應、hash 相等、套件 PASS），但同缺陷機制在枚舉外尚有 1 處殘留，成員保留至下一輪驗證單點修復。

## 驗證解除紀錄（cumulative blocking set 移除）

- bucket 1 否定歧義 Warning：resolved — 修復參照 apply round 1 fix action（spec.md:2590 改「未經由同意路徑被接受」）；驗證者 Reviewer V（round 2，逐子句對照 HEAD 原文、舊歧義句絕跡掃描、鄰句未誤動確認）。

## Fix Actions

- openspec/specs/cash-skill-workflows/spec.md：行 1393 `Confidence-scored findings` 替換為 `具信心分數的 findings 與過濾器`（替換後該中文標題出現 2 次：標題 1 + 引用 1）。
- design.md：C3 第二差異來源枚舉自 7+2 擴為 8+2，註明縮短引用形式。
- implementation-notes.md：追加 follow-up deviation entry（第 47 處補修，不改寫原 entry）。
- 修復後驗證：舊縮短引用於 openspec/specs/、.claude、.agents 絕跡；`spectra validate chinese-spec-content --strict` 通過。
- 修改檔案：openspec/specs/cash-skill-workflows/spec.md、design.md、implementation-notes.md。

## Decision

next_round

## Context

`spectra-propose-plus` 與 `spectra-apply-plus` 是 generated skills。單一真實來源是 `scripts/spectra-plus/rules.yaml`、`scripts/spectra-plus/generate.fish` 與 `scripts/spectra-plus/template/`，生成輸出包含 `.claude/skills/spectra-propose-plus/SKILL.md`、`.claude/skills/spectra-apply-plus/SKILL.md`、`.agents/skills/spectra-propose-plus/SKILL.md`、`.agents/skills/spectra-apply-plus/SKILL.md`。

目前 generated frontmatter 內的 `metadata.version: "1.0"` 來自 base Spectra skill，不代表 plus layer 版本。`install-spectra-plus.fish` 的 `target_is_current` 目前透過多個內容 sentinel 判斷 target 是否 current，這可以抓到已知內容變化，但缺少一個清楚、穩定、可人讀也可機器檢查的 plus version signal。

## Goals / Non-Goals

**Goals:**

- 讓四個 generated plus skill outputs 都帶有 current plus layer version 與 updated date。
- 讓 version/update metadata 由 `scripts/spectra-plus/rules.yaml` 控制，避免手改 generated files。
- 讓 generator 對缺少 plus version metadata 的 rules fail loudly。
- 讓 installer/repair-all 將缺少 current metadata 或 metadata mismatch 的 target 視為 stale，並重新產生 plus skills。
- 保持 generator idempotency：沒有 source/rules/template 變更時，重跑 generator 產生 byte-identical output。

**Non-Goals:**

- 不修改 `install-agentflow-sdd.fish`。
- 不加入每次 generate 都變動的 `generatedAt` 或 timestamp。
- 不把 base skill 的 nested `metadata.version` 改成 plus layer version。
- 不新增獨立 manifest 檔或新的 dependency。

## Decisions

### Version metadata lives in rules.yaml and is emitted as stable frontmatter fields

在 `scripts/spectra-plus/rules.yaml` 的每個 plus skill `metadata` 區塊加入 `spectraPlusVersion` 與 `spectraPlusUpdated`。現有 generator 已會把 metadata keys 寫入 top-level frontmatter；本變更沿用該機制，讓欄位出現在 generated `SKILL.md` 的 frontmatter。

採用 top-level `spectraPlusVersion` / `spectraPlusUpdated`，而不是覆寫 nested `metadata.version`，原因是 nested `metadata.version` 仍代表來源 skill 的既有 metadata。分開命名可以避免 base Spectra skill version 與 plus generated layer version 混在一起。

### Generator validates the plus metadata contract

`generate.fish` 的 `validate_skill` 需要要求每個 `skills.<name>.metadata` 都包含 `spectraPlusVersion` 與 `spectraPlusUpdated`，並驗證 `spectraPlusUpdated` 是穩定日期格式 `YYYY-MM-DD`。`spectra-propose-plus` 與 `spectra-apply-plus` 的 `spectraPlusVersion` / `spectraPlusUpdated` 必須一致，避免同一批 generated outputs 帶著不同 plus layer 版本。生成後的 `validate_generated` 也要確認 output YAML frontmatter 含有這兩個欄位，避免 rules parse 成功但 output contract 漏掉。

這個 validation 保持 fail-loud：缺欄位屬於 rules schema error，日期格式錯誤或兩個 plus skill metadata 不一致也屬於 rules schema error。這比靜默 fallback 到 base `metadata.version` 更安全。

### Installer current checks use explicit current plus metadata

`install-spectra-plus.fish` 的 `plus_outputs_are_current` 與 `validate_plus_outputs_current` 需要從本專案的 `scripts/spectra-plus/rules.yaml` 讀取 current `spectraPlusVersion` 與 `spectraPlusUpdated`，再檢查所有 propose-plus/apply-plus output 的 top-level YAML frontmatter 都含有相同值。當 target project 的 generated plus skill 缺少欄位或版本不同，`target_is_current` 會回傳 stale，repair-all 會重新跑 installer 產生 current outputs。

版本值先使用 `1.1.0`，更新日期使用 `2026-07-04`。後續 plus behavior 變更時，維護者只需要在 `rules.yaml` bump `spectraPlusVersion` 並同步更新 `spectraPlusUpdated`；installer freshness check 應跟著讀到新的 current values，而不是維護另一份 hard-coded 版本常數。

### Tests assert version freshness across all variants

`generator-checks.fish` 需要鎖定四個 generated outputs 都含有 current version/update metadata，且 idempotent regeneration 仍通過。`repair-all-checks.fish` 需要在 target assertion 中檢查 metadata，並加入 stale metadata target 情境：把已安裝 target 的 plus version 改舊後，repair-all 必須修復為 current metadata。

## Implementation Contract

**Behavior:** 產生或修復 plus skills 後，四個 generated plus skill `SKILL.md` frontmatter 都會包含 current top-level `spectraPlusVersion` 與 `spectraPlusUpdated`。人可以直接打開檔案辨識 plus layer 版本；installer/repair-all 可以用相同欄位判斷 target 是否落後。

**Interface / data shape:**

- `scripts/spectra-plus/rules.yaml` 的 `skills.spectra-propose-plus.metadata` 與 `skills.spectra-apply-plus.metadata` 必須包含：
  - `spectraPlusVersion`: stable string，例如 `"1.1.0"`
  - `spectraPlusUpdated`: stable date string，格式為 `YYYY-MM-DD`，例如 `"2026-07-04"`
- 兩個 plus skill metadata block 的 `spectraPlusVersion` 與 `spectraPlusUpdated` 必須完全一致。
- Generated `SKILL.md` frontmatter 必須包含 top-level 欄位：
  - `spectraPlusVersion: 1.1.0`
  - `spectraPlusUpdated: 2026-07-04`
- `install-spectra-plus.fish` 判斷 current target 時，必須從 local `scripts/spectra-plus/rules.yaml` 解析 expected values，並只把 generated `SKILL.md` 的 YAML frontmatter 視為 metadata 來源。
- `metadata.version` 保留原樣，不作為 plus freshness 判斷來源。

**Failure modes:**

- `rules.yaml` 缺少任一 required plus metadata field 時，`scripts/spectra-plus/generate.fish` 必須以 rules schema error 失敗，不產生 partial output。
- `spectraPlusUpdated` 不符合 `YYYY-MM-DD` 時，generator 必須以 rules schema error 失敗。
- 兩個 plus skill metadata block 不一致時，generator 必須以 rules schema error 失敗，不產生 partial output。
- Target project 的 plus outputs 缺少 current metadata 或 metadata value mismatch 時，`target_is_current` 必須判定 stale，repair-all 必須重新產生 outputs。
- Installer 無法解析 local `rules.yaml` 的 expected plus metadata，或讀到兩個 plus skill metadata block 不一致時，必須 fail loudly，不得把 target 誤判為 current，也不得修改 target generated outputs。

**Acceptance criteria:**

- `fish scripts/spectra-plus/tests/generator-checks.fish` 通過。
- `fish scripts/spectra-plus/tests/repair-all-checks.fish` 通過。
- 手動檢查四個 generated plus skill outputs 的 YAML frontmatter，確認包含 `spectraPlusVersion: 1.1.0` 與 `spectraPlusUpdated: 2026-07-04`。
- 重新執行 `scripts/spectra-plus/generate.fish` 兩次，在無輸入變更時仍 byte-identical。

**Scope boundaries:**

- In scope: plus skill generator、rules、installer freshness check、generator/repair-all tests、generated plus skill outputs、`spectra-plus-skills` spec。
- Out of scope: `install-agentflow-sdd.fish`、base non-plus Spectra skills、runtime app behavior、新 dependency 或 registry schema migration。

## Risks / Trade-offs

- [Risk] 維護者更新 plus behavior 但忘記 bump version → Mitigation: generator/repair tests 只能驗證欄位存在；tasks 需要求在本次 change 設定明確 current values，後續變更則透過 review gate 檢查是否需要 bump。
- [Risk] top-level metadata 欄位與 nested `metadata` 區塊並存會讓讀者疑惑 → Mitigation: 欄位命名使用 `spectraPlus*`，明確表示這是 plus layer freshness，不覆寫 base `metadata.version`。
- [Risk] installer 解析 `rules.yaml` 失敗會阻擋 install/repair → Mitigation: 專案已要求 `yq` 作為 installer dependency；解析失敗時 fail loudly 比誤判 target current 更安全。

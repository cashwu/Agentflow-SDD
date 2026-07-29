## ADDED Requirements

### Requirement: Repo-vendored Cash 團隊交付與指引

本 repository SHALL提供以 Git版控交付的 Cash team workflow：維護者使用 `install-cash-skills.fish --vendor <project>`發佈 repository-owned `.agents/skills/cash-*/SKILL.md`、`.claude/skills/cash-*/SKILL.md`、project-local CLI runtime、stable bootstrap與 `.cash-skills/manifest.tsv`，確認每個planned path已tracked或可被Git提交，再由維護者提交受管 diff。團隊成員取得該 commit的 clone或 pull後，Codex MUST可直接發現 `.agents/skills/`中的 canonical Cash skills，Claude MUST可直接發現 `.claude/skills/`中的 canonical Cash skills，skill呼叫的 project-local launcher MUST可使用 committed portable manifest通過啟動 gate；團隊成員 MUST NOT需要再次執行 skill installer、`--init-receipt`或任何 first-run寫入。manifest presence MUST優先選擇portable mode，使舊checkout殘留的ignored receipt不會阻擋pull後cutover。

vendored交付 MUST維持 `Cash skill 清單與所有權`的 authoritative／generated ownership、完整雙 variant清單與 parity rules，不得把外部 plugin cache、使用者 home目錄或 machine-local receipt提交為交付物。更新 MUST由維護者重新執行 `--vendor`、檢查並提交明確 diff；Cash skills與launcher MUST NOT在團隊成員端排程修復、自動下載或背景更新。需要 Python 3.11+以及 host agent本身已可使用 repository-local skills仍是環境 prerequisite，不屬於 team bundle安裝動作。

`CASH-SKILLS.md` SHALL把 repo-vendored模式列為「維護者安裝一次、團隊clone／pull直接使用」的建議團隊路徑，完整記載 `--vendor`、`--vendor --dry-run`、`--vendor --force`、portable manifest信任邊界、Git logical mode、manifest-presence優先序、更新／認養／轉換／衝突、launcher migration與 commit責任，同時保留 direct、registry、batch及 `--init-receipt`的 receipt-based用法，並說明source-only `--self`維護manifest與清除source receipt。`CASH-INIT-RECEIPT.md` MUST重新定位為receipt-only direct／legacy target指南，移除launcher無條件receipt gate、所有clone都要init與launcher bytes不變的舊敘述，補上portable分流、`init_vendored_bundle`與mode矩陣。`AGENTS.md`與 `CLAUDE.md`的 Cash-owned guidance block MUST使用相同分流：manifest存在時直接使用且舊receipt不具權威；只有不含manifest的 receipt-based target在 `bootstrap_invalid`時才引導執行 `PYTHONPATH=.cash-skills/lib python3 -s -P -B -m cash_cli.installer --init-receipt`。指引 MUST NOT讓 vendored clone建立 receipt，也 MUST NOT把 invalid manifest解讀為可 fallback到receipt。

本 requirement 與 `現行文件反映 cash 所有權與清理`及 `cash-cli` capability之 `Target-local receipt 初始化`的本文共同定義vendored／receipt-based onboarding分流；receipt-based target的既有文件義務不變。

#### Scenario: Codex 團隊成員 clone 後直接使用

- **GIVEN** 維護者已提交 valid vendored bundle且團隊成員取得該 commit
- **WHEN** Codex從該 repository載入 project skills並呼叫任一 `cash-*` workflow
- **THEN** Codex發現 committed `.agents/skills/`變體並使用 project-local Cash launcher
- **AND** 團隊成員不執行額外安裝或初始化

#### Scenario: Claude 團隊成員 clone 後直接使用

- **GIVEN** 維護者已提交 valid vendored bundle且團隊成員取得該 commit
- **WHEN** Claude從該 repository載入 project skills並呼叫任一 `cash-*` workflow
- **THEN** Claude發現 committed `.claude/skills/`變體並使用 project-local Cash launcher
- **AND** 團隊成員不執行額外安裝或初始化

#### Scenario: 維護者更新一次、團隊 pull 生效

- **WHEN** 維護者以較新source重新執行 `--vendor <project>`、通過 contract tests並提交受管 diff
- **THEN** 其他成員pull該 commit後使用新版 runtime與skills
- **AND** 每位成員不需重跑installer、刪除舊receipt或刷新machine-local狀態

#### Scenario: Pull 後舊 receipt 不遮蔽 manifest

- **GIVEN** 團隊成員的既有checkout留有上一版machine-local receipt
- **WHEN** 該成員pull到首次包含valid portable manifest的commit
- **THEN** launcher以manifest-presence優先序使用portable mode
- **AND** 不讀取、不刪除也不重新簽發舊receipt

#### Scenario: Vendored 指引不要求 init receipt

- **GIVEN** repository含 `.cash-skills/manifest.tsv`，不論receipt缺失或殘留
- **WHEN** agent讀取 `AGENTS.md`或 `CLAUDE.md`的 Cash guidance
- **THEN** 指引說明可直接執行project-local Cash launcher
- **AND** 不要求或自動呼叫 `--init-receipt`

#### Scenario: Legacy receipt-based 指引仍可行動

- **GIVEN** installed target不含portable manifest且launcher以 `bootstrap_invalid`失敗
- **WHEN** agent讀取 deployed Cash guidance
- **THEN** 指引提供完整 target-local `--init-receipt`指令與 Python 3.11+ prerequisite
- **AND** 不宣稱該 receipt可提交或跨 clone共用

#### Scenario: 文件說明信任邊界

- **WHEN** 使用者閱讀 `CASH-SKILLS.md`或 `CASH-INIT-RECEIPT.md`
- **THEN** 文件清楚區分 Git provenance的portable manifest與 machine-local identity的receipt
- **AND** 文件說明manifest存在時它優先且invalid manifest不fallback、portable mode不抵抗可同時改寫manifest與inventory的repository writer


## MODIFIED Requirements

### Requirement: 現行文件反映 cash 所有權與清理

本 repository SHALL提供`CASH-SKILLS.md`作為當前的Cash workflow指南。該指南 MUST列出雙變體清單；把repo-vendored模式列為維護者一次執行`--vendor <project>`並提交、團隊clone／pull後直接使用的建議路徑；說明portable manifest信任邊界、Git logical mode、manifest-presence優先序、planned path excludes、receiptless adoption、更新／轉換／衝突、launcher migration與commit責任；同時保留project-local Cash CLI、receipt-based direct、registry、batch、`--init-receipt`、dry-run、force、各狀態、Cash guidance migration、legacy cleanup與bundle版本調升責任。`CASH-INIT-RECEIPT.md` MUST定位為receipt-only direct／legacy target指南，不得宣稱所有clone都需初始化、launcher無條件只驗證receipt或launcher bytes永不受控遷移。`openspec/signals/README.md` MUST繼續將當前writer描述為Cash審查迴圈，同時保留歷史性的`## Occurrences` provenance文字。

#### Scenario: 當前的安裝與更新說明是完整的

- **WHEN**使用者閱讀`CASH-SKILLS.md`
- **THEN**文件提供單一installer進入點與vendor、direct、registry及batch commands
- **AND**它說明vendored與receipt-based target何時因runtime、skill、guidance、manifest或receipt更新，何時因current或newer略過，何時被阻擋為conflict，何時歸類為failed
- **AND**它指明`cash-skills.version`、`.cash-skills/manifest.tsv`、`.cash-skills/receipt.tsv`、`.cash-skills/bin/cash`與`$HOME/.config/cash-skills/projects.txt`，並區分manifest與receipt的信任邊界
- **AND**它說明Cash guidance migration只管理marker spans、逐byte保留其餘內容，並在不合法marker時fail closed
- **AND**它說明成功migration只移除逐byte符合已知baseline的標準`spectra-*` directories，同名customization或未知legacy內容一律保留並fail closed

#### Scenario: 文件不再要求保留標準 Spectra skills

- **WHEN**contract suite掃描`CASH-SKILLS.md`與non-archive master requirements
- **THEN**不存在要求保留標準Spectra skills或只移除`spectra-*-plus`的現行規範
- **AND**合法legacy detector與歷史occurrence文字不被誤判

#### Scenario: 遷移文件沒有現行的修復指示

- **WHEN**使用者閱讀`CASH-SKILLS.md`與`openspec/signals/README.md`
- **THEN**現行指示使用Cash workflows、project-local Cash CLI、installer與一次性cleanup
- **AND**沒有任何現行指示要使用者產生或週期性修復plus或Cash skills
- **AND**歷史性的occurrence項目維持不變

### Requirement: 手動的 cash 專案 registry

本 repository SHALL經由`install-cash-skills.fish`提供registry操作與明示的repo-vendored publication。每次registry操作恰好使用`--target <project>`、`--register <project>`、`--unregister <project>`、`--list`或`--all`其中之一；`--vendor <project>`與這些registry操作互斥，屬非registry的publication模式，MUST NOT讀取或修改registry，其target與publication契約由 `Repo-vendored Cash bundle 發佈` requirement治理。source-only `--self`與target-local `--init-receipt`另由 `Bundle 安裝與 runtime receipt`及 `Target-local receipt 初始化` requirements治理，不屬本requirement的封閉registry操作集合。registry SHALL是`$HOME/.config/cash-skills/projects.txt`，每個非空行一個正規化絕對專案路徑，路徑 MUST NOT包含ASCII控制字元。每個registry支援的模式 MUST在使用既有registry前完整驗證它；registry變動 MUST使用同目錄暫存檔與atomic rename，且installer MUST NOT排程或啟動未來呼叫。`--register`的target除了既存non-symlink directory外，還 MUST是canonical Git worktree top-level，並具有安全、可讀、schema-valid的regular `openspec/config.yaml`；它與direct/batch target使用同一prerequisite validator。

#### Scenario: Vendor mode 不使用 registry

- **WHEN** 維護者執行`--vendor <project>`
- **THEN** installer依repo-vendored publication契約處理明示target
- **AND** 它不讀取、不建立也不修改`$HOME/.config/cash-skills/projects.txt`

#### Scenario: 首次 register 建立安全狀態

- **GIVEN**cash-skills組態目錄與registry在安全HOME之下不存在
- **WHEN**`--register <project>`收到符合全部target prerequisites的target
- **THEN**installer僅建立所需組態目錄與atomic發佈的registry

#### Scenario: 缺失 registry 對讀取與移除模式視為空

- **GIVEN**cash-skills組態目錄與registry在安全HOME之下不存在
- **WHEN**`--unregister <project>`、`--list`或`--all`執行
- **THEN**installer對空清單成功執行且不建立狀態
- **AND**`--all`印出零計數摘要

#### Scenario: Register 正規化、去重並驗證 prerequisite

- **WHEN**`--register <project>`收到既存non-symlink directory
- **THEN**installer先canonicalize並要求該path恰為Git worktree top-level且具有安全有效的`openspec/config.yaml`
- **AND**成功時恰好儲存一次canonical absolute path並保持其他有效項目不變
- **AND**non-Git、Git子目錄、missing/unsafe/invalid config都以非零結束且registry零寫入

#### Scenario: Register 拒絕行導向 path injection

- **WHEN**register或unregister輸入包含tab、CR、LF或其他ASCII控制字元
- **THEN**installer以非零結束
- **AND**它不建立也不修改registry

#### Scenario: 既有 registry 紀錄拒絕殘留控制字元

- **WHEN**以LF分隔的既有registry紀錄包含tab、CR或其他殘留ASCII控制字元
- **THEN**每個registry支援的installer mode以非零結束
- **AND**它不建立也不修改registry或任何target

#### Scenario: Unregister 移除既存或過時 target

- **WHEN**`--unregister <project>`識別出canonical既存target，或不含dot segment且與儲存值完全一致的absolute stale target
- **THEN**installer以atomic方式移除該項目
- **AND**缺失項目是成功no-op

#### Scenario: List 是唯讀的

- **WHEN**`--list`收到有效registry
- **THEN**它印出去重後的canonical項目
- **AND**它不建立也不修改任何registry、target、receipt、skill、temporary file或background process

#### Scenario: 無效 registry fail closed

- **WHEN**registry不可讀，或包含relative path、root path、dot segment、malformed line或unsafe boundary
- **THEN**`--register`、`--unregister`、`--list`與`--all`在處理target或重寫registry前以非零結束
- **AND**沒有任何registry或target state被修改

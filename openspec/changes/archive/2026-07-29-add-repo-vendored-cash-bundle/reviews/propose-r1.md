# Cash Propose Review — Round 1

## Reviewer Findings

### Critical

1. severity: Critical
   confidence: 100
   layer: design
   location: `proposal.md` Summary、`design.md`「兩種信任模式使用 receipt-presence 優先序」、`specs/cash-skill-workflows/spec.md`「維護者更新一次、團隊 pull 生效」
   summary: receipt優先會讓既有成員pull後留下的舊receipt遮蔽新manifest，使零動作cutover失敗。
   recommendation: 以committed manifest作為可稽核的trust-mode marker，明定manifest-present時的唯讀cutover與stale receipt案例。
   reviewer source: Reviewer A（Adherence）

2. severity: Critical
   confidence: 98
   layer: design
   location: `design.md` launcher migration、`specs/cash-cli/spec.md`「受控 launcher bootstrap migration」、`.cash-skills/lib/cash_cli/installer.py` transaction／receipt call sites
   summary: 現有generic journal只保存bytes／mode，rollback替換launcher後會改變inode，無法恢復舊receipt所綁定的identity；desired receipt若在planning時計算也會記到舊inode。
   recommendation: 定義launcher與receipt專用journal operations、動態receipt publication，以及rollback後重綁舊receipt stable identity的完整recovery protocol。
   reviewer source: Reviewer A（Adherence）、Reviewer B（Quality）

### Warning

1. severity: Warning
   confidence: 98
   layer: text
   location: `specs/cash-cli/spec.md`「Portable manifest 啟動信任模式」precedence exception
   summary: precedence exception漏列master `Cash workflow command surface`的help receipt gate與只載入receipt-validated generation的併發契約。
   recommendation: 納入兩個master clauses，並新增portable help與concurrent generation scenarios／tests。
   reviewer source: Reviewer A（Adherence）、Reviewer B（Quality）

2. severity: Warning
   confidence: 99
   layer: text
   location: `proposal.md` Impact、`design.md`文件決策、`tasks.md`文件tasks、`CASH-INIT-RECEIPT.md`
   summary: Impact與tasks漏掉仍宣稱所有clone都需init、launcher無條件validate receipt且launcher bytes不變的 `CASH-INIT-RECEIPT.md`。
   recommendation: 把該檔納入scope、task與文件contract tests，重新定位為receipt-only指南。
   reviewer source: Reviewer A（Adherence）、Reviewer B（Quality）

3. severity: Warning
   confidence: 99
   layer: design
   location: `design.md` `--vendor` preflight、`specs/cash-cli/spec.md`「Repo-vendored Cash bundle 發佈」
   summary: 只檢查manifest沒有被ignore，無法保證launcher、runtime、skills及其他planned paths都可提交。
   recommendation: 對每個planned publication path驗證已tracked或不受repository／info／global excludes排除，並在publication前重驗。
   reviewer source: Reviewer B（Quality）

4. severity: Warning
   confidence: 99
   layer: design
   location: `design.md` portable zero-write contract、`specs/cash-cli/spec.md`「Fresh vendored clone 不需初始化」、`.cash-skills/bin/cash` import call site
   summary: launcher未強制停用Python bytecode，fresh clone第一次import可能建立ignored `__pycache__`，違反零寫入契約。
   recommendation: 在managed import前設定 `sys.dont_write_bytecode = True`，並以包含ignored paths與mtime的完整filesystem snapshot驗證。
   reviewer source: Reviewer B（Quality）

5. severity: Warning
   confidence: 95
   layer: design
   location: `design.md` trust precedence、`specs/cash-cli/spec.md`「Portable manifest 啟動信任模式」
   summary: manifest presence／shape沒有明定open前no-follow判定，FIFO可能阻塞、broken symlink可能被誤判missing。
   recommendation: 要求open前 `lstat`，所有unsafe-present shapes走 `manifest_invalid`且不得fallback。
   reviewer source: Reviewer B（Quality）

6. severity: Warning
   confidence: 93
   layer: design
   location: `design.md` `--vendor`分類、`specs/cash-cli/spec.md`「Repo-vendored Cash bundle 發佈」
   summary: receipt與manifest都缺失但已有完整或部分Cash inventory時，adoption／force邊界未定義。
   recommendation: 定義exact receiptless adoption、partial／different conflict、force canonical replaceable邊界與unknown runtime／stable drift失敗。
   reviewer source: Reviewer B（Quality）

### Suggestion

無。

## Rating

- Critical: 2
- Warning: 6
- non-blocking triaged findings: 0
- critical_gap: true
- round_type: full
- 理由：第一輪共有兩個Critical與六個Warning通過信心過濾，且第一輪所有存活的Critical／Warning皆進入cumulative blocking set；完成設計與範圍修正後仍須由下一輪驗證修正是否有效。

## Fix Actions

- 修正stale receipt cutover：修改 `proposal.md`、`design.md`、`specs/cash-cli/spec.md`、`specs/cash-skill-workflows/spec.md`與 `tasks.md`，改採manifest-presence優先，invalid manifest不fallback，並補既有成員pull案例。
- 修正launcher identity rollback：修改 `design.md`、`specs/cash-cli/spec.md`與 `tasks.md`，定義schema v3專用 `launcher`／dynamic `receipt` operations、schema v2相容recovery、rollback後old receipt identity rebind與phase fault matrix。
- 修正help／generation precedence：修改 `design.md`、`specs/cash-cli/spec.md`與 `tasks.md`，明列 `Cash workflow command surface`及receipt-validated generation例外，補portable help與concurrency驗收。
- 修正文件scope：修改 `proposal.md`、`design.md`、`specs/cash-skill-workflows/spec.md`與 `tasks.md`，把 `CASH-INIT-RECEIPT.md`加入Impact、delivery task與contract check。
- 修正Git exclude缺口：修改 `proposal.md`、`design.md`、`specs/cash-cli/spec.md`與 `tasks.md`，要求全部planned publication paths已tracked或不受repository／info／global excludes排除，並做final revalidation。
- 修正bytecode零寫入：修改 `proposal.md`、`design.md`、`specs/cash-cli/spec.md`與 `tasks.md`，要求managed import前設定 `sys.dont_write_bytecode = True`及完整filesystem snapshot驗證。
- 修正manifest unsafe shape：修改 `design.md`、`specs/cash-cli/spec.md`與 `tasks.md`，要求open前no-follow `lstat`並覆蓋FIFO、broken symlink、directory及hard link。
- 修正receiptless adoption：修改 `design.md`、`specs/cash-cli/spec.md`與 `tasks.md`，定義fresh／exact adoption／partial conflict／force canonical expected paths／unknown extra runtime與stable drift邊界。
- 修正概念後已跨全部artifacts搜尋 `manifest-presence`、`receipt`、`CASH-INIT-RECEIPT.md`、`schema v3`、`sys.dont_write_bytecode`、planned paths與receiptless adoption並同步；`cash validate add-repo-vendored-cash-bundle`、annotation lint、identifier scan、Impact count與 `git diff --check`全數通過。
- open signals沒有任何 `check` frontmatter；相關machine-checkable signals已由precedence、umask、history binding、version ordering、expected-set、filesystem shape、snapshot revalidation及task coverage自檢覆蓋。
- 本輪fix沒有修改change directory外檔案，因此不需呼叫Cash touched commands。

## Decision

next_round

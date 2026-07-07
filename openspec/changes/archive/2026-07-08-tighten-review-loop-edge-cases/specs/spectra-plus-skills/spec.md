## MODIFIED Requirements

### Requirement: Review loop grader immutability

The system SHALL extend the shared review-loop template `scripts/spectra-plus/template/review-loop-block.md` with a grader-immutability rule marked by the unique sentinel comment `<!-- GRADER-IMMUTABILITY -->`. During a plus review loop, the main agent MUST NOT modify — whether as a fix action or as a mechanical self-check fix — any file in the protected grader path set: files under `scripts/spectra-plus/template/`, `scripts/spectra-plus/rules.yaml`, `scripts/spectra-plus/generate.fish`, the generated plus skill files (`.claude/skills/spectra-propose-plus/SKILL.md`, `.claude/skills/spectra-apply-plus/SKILL.md`, `.agents/skills/spectra-propose-plus/SKILL.md`, `.agents/skills/spectra-apply-plus/SKILL.md`), `.spectra.yaml`, and the master spec files under `openspec/specs/` — unless that file is explicitly named by the current change's structured scope declarations. Structured scope declarations are limited to project-root-relative paths in the proposal `## Impact` affected-code entries and project-root-relative paths in `tasks.md` that are explicitly identified as delivery targets. A path that appears only in a verification command, a rule description, an example, a review finding, reviewer context, or other incidental prose MUST NOT count as a structured scope declaration. Naming a directory path in a structured scope declaration names all files under it. When a file under `scripts/spectra-plus/template/` is named in the structured scope declarations, its regenerated outputs (the four generated plus skill files) count as named as well, so the mandatory regeneration step is never blocked by this rule; a loop already in progress continues under the instruction version it started with, and regenerated instructions take effect from the next loop run. In addition, the main agent MUST NOT add, modify, or remove the `check` frontmatter field of any signal under `openspec/signals/`, regardless of declared scope — the `check` field is grader input for the pre-round mechanical self-check. When a surviving finding's resolution would require modifying a protected file outside that structured scope, or touching a signal's `check` field, the fix action MUST NOT perform the modification, MUST record an unfixed-due-to-grader-protection note naming the file and the finding in `## Fix Actions`, and the finding remains surviving for the round decision. The plus workflow's completion output MUST list every unfixed-due-to-grader-protection note recorded in any round of the loop, regardless of the final decision: for `spectra-propose-plus` with `decision: passed`, the notes MUST be listed in the final summary; for `spectra-apply-plus` with `decision: passed`, the notes MUST be listed in the gate-complete final response; for any `decision: aborted`, the notes MUST be listed in the unresolved-findings warning. A protected file modified under the structured-scope exception remains subject to the existing next-round re-derivation rules. Because both `spectra-propose-plus` and `spectra-apply-plus` consume this template, this rule MUST apply to both generated plus skills.

#### Scenario: Out-of-scope grader modification is refused

- **WHEN** a review-loop finding's recommendation requires editing `scripts/spectra-plus/rules.yaml` and the current change's structured scope declarations do not name that file
- **THEN** the fix action does not modify `scripts/spectra-plus/rules.yaml`
- **AND** the round file's `## Fix Actions` records an unfixed-due-to-grader-protection note naming the file and the finding
- **AND** the finding still counts toward the round decision

#### Scenario: Incidental protected path text does not unlock a grader file

- **WHEN** `tasks.md` mentions `openspec/specs/` only while describing the grader-protection rule or a verification step
- **THEN** that mention does not count as a structured scope declaration
- **AND** the main agent MUST NOT modify files under `openspec/specs/` through the grader-immutability exception

#### Scenario: Signal check field is never modified by a fix action

- **WHEN** a pre-round self-check `check` command fails and a fix action could make it pass by weakening or removing that signal's `check` field
- **THEN** the fix action does not add, modify, or remove any signal's `check` field
- **AND** the underlying defect is fixed in the change's own artifacts or files instead

#### Scenario: Declared-scope grader file stays modifiable

- **WHEN** the current change's structured scope declarations explicitly name `scripts/spectra-plus/template/review-loop-block.md` and a fix action modifies that file
- **THEN** the modification is permitted, and regenerating the four plus skill files is also permitted
- **AND** the existing re-derivation rules treat the modification like any other fix-action modification

#### Scenario: Completion output anchors grader-protection records

- **WHEN** any round of a loop recorded an unfixed-due-to-grader-protection note and the loop later ends with `decision: passed` for `spectra-propose-plus`
- **THEN** the final summary lists every such note from every round of the loop

- **WHEN** any round of a loop recorded an unfixed-due-to-grader-protection note and the loop later ends with `decision: passed` for `spectra-apply-plus`
- **THEN** the gate-complete final response lists every such note from every round of the loop

- **WHEN** any round of a loop recorded an unfixed-due-to-grader-protection note and the loop ends with `decision: aborted`
- **THEN** the unresolved-findings warning lists every such note from every round of the loop

#### Scenario: Generated skills carry the grader-immutability sentinel

- **WHEN** the generator produces the four plus skill files
- **THEN** each generated file contains the `<!-- GRADER-IMMUTABILITY -->` sentinel and the protected grader path set
- **AND** `scripts/spectra-plus/tests/generator-checks.fish` asserts the sentinel's presence

### Requirement: Deterministic signal-derived self-checks

The system SHALL upgrade the "Signal-derived checks" item of the pre-round mechanical self-check in the shared review-loop template to consume the optional signal `check` frontmatter field. For EVERY `open` signal whose frontmatter contains a `check` field — without applying best-effort relevance selection to these signals — the main agent MUST execute that command from the project root by passing the `check` value as the single command-string argument to `sh -c` (not by interpolating it into a quoted shell string). Exit code `0` means the check passed. Exit code `1` means the anti-pattern is present. The main agent MUST classify the failing check before deciding whether to fix it: it MUST inspect any project-root-relative paths printed by the check command and compare them with the current change's artifacts and, for apply-plus, modified source files. If at least one printed path is inside that artifact/source file set, the detected instance is in scope. If the command prints no usable project-root-relative path, or the output cannot be reliably mapped to a project-root-relative path, the main agent MUST fail closed and treat the detected instance as in scope unless the already-read repository state proves that the instance is pre-existing or that the required fix location is outside the change's structured scope. When the detected instance is in scope and the fix location is not blocked by an uncovered protected grader path, it is a self-check failure that MUST be fixed before spawning that round's reviewers, per the existing self-check rules. When the detected instance is pre-existing, or its fix lies outside the change's structured scope, or its fix lies inside a protected grader path that is not covered by the structured-scope exception, the main agent MUST NOT fix it, MUST record a one-line out-of-scope-check-failure note in that round's `## Fix Actions` when the round file is written, MUST include the failing check result in that round's reviewers' context, and MUST proceed to spawn the reviewers — a pre-existing anti-pattern never deadlocks the loop. Any other exit code (for example `2`, `126`, `127`) is an execution error: the main agent MUST fall back to the existing best-effort judgment for that signal and record a one-line fallback note in that round's `## Fix Actions` when the round file is written. Note lines (out-of-scope or fallback) coexist with the `None; pass condition met.` text on a passing round and do not count toward the ledger `fixed_files` value. For `open` signals without a `check` field, the existing best-effort behavior MUST remain unchanged. Executing a `check` command MUST NOT modify any file.

#### Scenario: Signal with check field is executed deterministically

- **WHEN** the pre-round mechanical self-check runs and an `open` signal's frontmatter contains `check`
- **THEN** the main agent executes the `check` command from the project root by passing its value as the single argument to `sh -c`, regardless of relevance judgment
- **AND** exit code `1` with the detected instance inside the change's own artifacts or modified files is treated as a self-check failure to fix before spawning the reviewers

#### Scenario: Check output path inside the change is in scope

- **WHEN** an `open` signal's `check` command exits `1`
- **AND** the command output contains a project-root-relative path under `openspec/changes/<change>/`
- **THEN** the main agent treats the failure as in scope for a propose-plus loop
- **AND** fixes the failure before spawning reviewers unless the fix location is blocked by an uncovered protected grader path

#### Scenario: Unlocatable check failure fails closed

- **WHEN** an `open` signal's `check` command exits `1`
- **AND** the command output contains no usable project-root-relative path
- **AND** the already-read repository state does not prove that the instance is pre-existing or that the required fix location is outside the change's structured scope
- **THEN** the main agent treats the failure as in scope
- **AND** does not record it as an out-of-scope-check-failure note

#### Scenario: Protected path branch applies only outside structured scope

- **WHEN** an `open` signal's `check` command exits `1`
- **AND** fixing the detected instance requires editing `scripts/spectra-plus/template/review-loop-block.md`
- **AND** the current change's structured scope declarations explicitly name `scripts/spectra-plus/template/review-loop-block.md`
- **THEN** the protected grader path does not trigger the out-of-scope-check-failure branch
- **AND** the main agent fixes the failure before spawning reviewers

#### Scenario: Out-of-scope check failure does not deadlock the loop

- **WHEN** an `open` signal's `check` command exits `1` and the detected instance is pre-existing or its fix lies outside the change's structured scope or inside a protected grader path not covered by the structured-scope exception
- **THEN** the main agent does not fix it, records a one-line out-of-scope-check-failure note in that round's `## Fix Actions` when the round file is written
- **AND** includes the failing check result in that round's reviewers' context and proceeds to spawn the reviewers

#### Scenario: Execution-error exit codes fall back to best-effort

- **WHEN** an `open` signal's `check` command exits with a code other than `0` or `1`
- **THEN** the main agent applies the existing best-effort judgment for that signal
- **AND** records a one-line fallback note in that round's `## Fix Actions` when the round file is written
- **AND** the note does not count toward the ledger `fixed_files` value

#### Scenario: Signals without check keep best-effort behavior

- **WHEN** an `open` signal has no `check` field
- **THEN** the Signal-derived checks behavior for that signal is unchanged from the existing best-effort rule

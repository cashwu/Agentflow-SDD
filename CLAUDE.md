<!-- SPECTRA:START v1.0.2 -->

# Spectra Instructions

This project uses Spectra for Spec-Driven Development(SDD). Specs live in `openspec/specs/`, change proposals in `openspec/changes/`.

## Use `/spectra-*` skills when:

- A discussion needs structure before coding → `/spectra-discuss`
- User wants to plan, propose, or design a change → `/spectra-propose`
- Tasks are ready to implement → `/spectra-apply`
- There's an in-progress change to continue → `/spectra-ingest`
- User asks about specs or how something works → `/spectra-ask`
- Implementation is done → `/spectra-archive`
- Commit only files related to a specific change → `/spectra-commit`

## Workflow

discuss? → propose → apply ⇄ ingest → archive

- `discuss` is optional — skip if requirements are clear
- Requirements change mid-work? Plan mode → `ingest` → resume `apply`

## Parked Changes

Changes can be parked（暫存）— temporarily moved out of `openspec/changes/`. Parked changes won't appear in `spectra list` but can be found with `spectra list --parked`. To restore: `spectra unpark <name>`. The `/spectra-apply` and `/spectra-ingest` skills handle parked changes automatically.

<!-- SPECTRA:END -->

<!-- PROJECT-SDD:START -->

# Project SDD Overlay

Use `/sdd-*` Agentflow wrappers for non-trivial feature work before going directly to `/spectra-*`. Direct `/spectra-*` usage is allowed only when a `/sdd-*` wrapper delegates to Spectra, or for tiny mechanical edits and pure queries.

The 9-step Agentflow is `/sdd-discuss` → `/sdd-explore` → `/sdd-prototype` → `/sdd-spec` → `/sdd-usage` → `/sdd-ticket` → `/sdd-dev` → `/sdd-review` → `/sdd-wrap`. `/sdd-agentflow` is the end-to-end entry point that coordinates those steps.

Each review/rating/fix round must produce its own file under `openspec/changes/<change>/agentflow/reviews/`; step files only summarize and link those round records. Passing requires `quality_score > 9/10` with no critical gap.

Use `/sdd-spectra-refresh` after `spectra update --force` or a Spectra upgrade to verify project-owned `sdd-*` skills and `openspec/config.yaml` rules still exist.

Use `./install-agentflow-sdd.fish --target <project-dir>` to install the Agentflow-SDD overlay into another project. Add `--with-spectra` only when the target project does not already have generated Spectra skills.

Do not put project-specific Agentflow-SDD rules inside generated `spectra-*` skills. Keep custom behavior in project-owned `sdd-*` skills and outside the `SPECTRA:START` / `SPECTRA:END` block.

<!-- PROJECT-SDD:END -->

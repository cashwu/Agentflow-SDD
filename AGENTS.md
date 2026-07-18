<!-- SPECTRA:START v1.0.2 -->

# Spectra Instructions

This project uses Spectra for Spec-Driven Development(SDD). Specs live in `openspec/specs/`, change proposals in `openspec/changes/`.

## Use `$spectra-*` skills when:

- A discussion needs structure before coding → `$spectra-discuss`
- User wants to plan, propose, or design a change → `$spectra-propose`
- Tasks are ready to implement → `$spectra-apply`
- There's an in-progress change to continue → `$spectra-ingest`
- User asks about specs or how something works → `$spectra-ask`
- Implementation is done → `$spectra-archive`
- Commit only files related to a specific change → `$spectra-commit`

## Workflow

discuss? → propose → apply ⇄ ingest → archive

- `discuss` is optional — skip if requirements are clear
- Requirements change mid-work? `ingest` → resume `apply`

## Parked Changes

Changes can be parked（暫存）— temporarily moved out of `openspec/changes/`. Parked changes won't appear in `spectra list` but can be found with `spectra list --parked`. To restore: `spectra unpark <name>`. The `$spectra-apply` and `$spectra-ingest` skills handle parked changes automatically.

<!-- SPECTRA:END -->

## Project-owned Cash workflow override

For this repository, cash workflow invocation takes precedence over the Spectra-managed `$spectra-*` workflow guidance above. Spectra CLI and artifact schema remain authoritative: cash skills continue to use `spectra` commands and `openspec/` artifacts.

- Structured discussion → `$cash-discuss`
- Plan or propose a change → `$cash-propose`
- Implement or resume tasks → `$cash-apply`
- Requirements changed during implementation → `$cash-ingest`, then resume `$cash-apply`
- Archive completed work → `$cash-archive`
- Commit one selected change → `$cash-commit`

Effective workflow: `$cash-discuss`? → `$cash-propose` → `$cash-apply` ⇄ `$cash-ingest` → `$cash-archive` → `$cash-commit`.

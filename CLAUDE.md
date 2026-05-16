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

# Agentflow SDD

This project uses a self-contained Agentflow-SDD workflow. Master specs live in `openspec/specs/`, change proposals in `agentflow/changes/`.

## Use `/sdd-*` skills for:

- Clarify requirements → `/sdd-discuss`
- Explore risks and architecture → `/sdd-explore`
- Run a throwaway spike → `/sdd-prototype`
- Create proposal, design, spec → `/sdd-spec`
- Define usage contracts → `/sdd-usage`
- Create implementation tickets → `/sdd-ticket`
- Implement tasks → `/sdd-dev`
- Post-dev review → `/sdd-review`
- Archive completed change → `/sdd-wrap`
- Full end-to-end → `/sdd-agentflow`
- Integrity check → `/sdd-refresh`

## Workflow

discuss → explore → prototype → spec → usage → ticket → dev → review → wrap

- `discuss` is optional — skip if requirements are clear
- Each step has a review/rating/fix quality loop (quality_score > 9/10, no critical gap)
- Every review/rating round must use a fresh, independent sub-agent

Each review/rating/fix round must produce its own file under `agentflow/changes/<change>/agentflow/reviews/`; step files only summarize and link those round records.

## Parked Changes

Changes can be parked（暫存）by setting `status: parked` in `status.yaml`. To restore, set `status: active`. The `/sdd-dev` skill handles parked changes automatically.

Use `./install-agentflow-sdd.fish --target <project-dir>` to install the Agentflow-SDD overlay into another project.

Do not implement production code before `/sdd-dev`.

<!-- PROJECT-SDD:END -->

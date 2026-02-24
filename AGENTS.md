# AGENTS

## Purpose and Scope

This file is an execution playbook for AI coding agents working in Arcadia.
Default priorities are correctness, minimal diffs, and verifiable outcomes.

This guide is agent-only and operational. Keep reports factual and concise.

## Architecture Map

Module ownership:

- `lib/src/logic`: state mutation and interaction orchestration.
- `lib/src/data`: viewport state model.
- `lib/src/tools`: tool interaction state machines and preview/final geometry
  behavior.
- `lib/src/geometry`: geometry primitives and shape behavior (`render`,
  `contains`, `snappingPoints`, `copyWith`).
- `lib/src/ui`: input wiring and rendering composition.
- `lib/src/providers`: notifier access and selective rebuild helpers.
- `lib/src/constants`: shared configuration and colors.

System flow:

1. Keyboard shortcuts/actions are defined in `lib/src/ui/project_page.dart`.
2. Pointer events are handled in `lib/src/ui/viewport.dart`.
3. State transitions happen in `lib/src/logic/viewport_notifier.dart`.
4. Rendering reads state through `ViewportStateBuilder` + `CustomPaint`.

## Non-Negotiable Rules

- `ViewportNotifier` is the single owner of viewport-state mutation.
- Keep UI widgets thin; behavior belongs in `logic`, `tools`, and `geometry`.
- Preserve paint layer order:
  `Grid -> Selection -> Geometry -> Snapping -> Tool -> Cursor`.
- Keep keyboard and pointer routing in their current entry points unless
  explicitly requested to change.
- Preserve existing interaction behavior for selection, snapping, undo/redo,
  and tool preview/finalization flows unless the task explicitly changes them.
- Prefer Dart dot shorthands whenever possible.
- Prefer `ArcadiaColor` instead of `Color` whenever possible.

## Change Workflow

- Read the target file and immediate neighbors before editing.
- Keep changes minimal and localized to the correct layer.
- Preserve public API and naming unless explicitly requested otherwise.
- Reuse existing patterns before introducing new abstractions.
- Avoid broad refactors during feature/bug tasks unless explicitly requested.
- Before completion, perform a style pass on changed Dart files and apply dot
  shorthand wherever type context allows.

## Tooling and Verification

- Use Dart MCP tools whenever possible for analysis, formatting, tests, and
  Dart/Flutter-aware operations.
- Use shell fallbacks only when MCP does not cover the required action.
- For style cleanups, use Dart LSP/code actions on changed files first. If a
  dot shorthand code action is available, apply it.
- If no code action is available, manually convert obvious cases to dot
  shorthand in changed lines before final verification.

Always verify before claiming completion:

1. Run static analysis.
2. Run relevant tests (or full suite when scope is broad/unclear).
3. Run Dart LSP code actions for changed Dart files and apply dot shorthand
   actions when available.
4. Confirm no avoidable non-dot shorthand remains in changed lines (quick grep
   checks are acceptable).
5. Run `dart format` after analysis/tests/style pass (prefer Dart MCP tooling).
6. Run impacted golden tests when rendering output changes.

Do not claim completion without command outcomes.

Definition of done:

- Changes are placed in the correct architectural layer.
- Verification commands were executed and outcomes reported.
- Remaining risks or constraints are explicitly documented.

## Testing Strategy

- Add or update tests alongside behavior changes.
- Keep visual regressions controlled through focused golden verification.
- Prioritize regression coverage for:
  - selection and hover behavior
  - snapping behavior
  - undo/redo transitions
  - tool preview versus final geometry behavior

## Report Output Contract

Every completion report must include:

- files changed
- behavior impact summary
- verification commands executed with pass/fail outcomes
- dot shorthand pass outcome (code action applied, manual conversions, or no
  eligible changes)
- known risks, constraints, or follow-ups

## Quick Command Reference

Preferred: use Dart MCP tooling.

Fallback commands:

- `dart analyze`
- `dart test`
- `dart format lib test`

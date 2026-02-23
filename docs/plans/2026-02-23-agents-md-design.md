# AGENTS.md Design

Date: 2026-02-23
Status: Approved
Audience: AI coding agents only

## Context

This repository is a Flutter CAD application with a clear layered structure:

- `lib/src/logic`: state mutation and interaction logic (`ViewportNotifier`)
- `lib/src/data`: state model (`ViewportState`)
- `lib/src/tools`: interaction state machines for drawing tools
- `lib/src/geometry`: domain primitives and rendering/containment behavior
- `lib/src/ui`: input and rendering composition
- `lib/src/providers`: notifier access and selective rebuilding
- `lib/src/constants`: configuration and palette constants

The AGENTS file should codify these boundaries and define strict execution and
verification rules for autonomous agents.

## Goals

- Provide a strict, agent-only operating playbook.
- Encode architecture boundaries so agents place changes in the correct layer.
- Enforce verification before completion claims.
- Prefer Dart MCP tooling whenever possible.
- Avoid mentioning deprecated internals/features.

## Non-Goals

- Human onboarding/tutorial documentation.
- Broad style-guide replacement for the whole codebase.
- Any mention of deprecated Flutter internals/features.

## Approach Options Considered

1. Architecture-first playbook (recommended)
2. Workflow-first playbook
3. Checklist-only playbook

### Recommendation

Use architecture-first playbook. The project has strong separations between
domain, tool logic, state mutation, and rendering. Front-loading boundaries
reduces wrong-layer edits and behavioral regressions.

## Proposed AGENTS.md Structure

1. Purpose and Scope
2. Architecture Map
3. Non-Negotiable Rules
4. Change Workflow
5. Tooling and Verification
6. Testing Strategy
7. Report Output Contract
8. Quick Command Reference (fallback when MCP is unavailable)

## Detailed Design

### 1) Purpose and Scope

- Agent-only execution guide.
- Default priorities: correctness, minimal diff, reproducible verification.

### 2) Architecture Map

- Input enters via `ui/project_page.dart` (shortcuts/actions) and
  `ui/viewport.dart` (pointer events).
- Mutable state transitions occur in `logic/viewport_notifier.dart`.
- Render layers consume state through `ViewportStateBuilder` and `CustomPaint`.
- Geometry classes define shape behavior (`render`, `contains`,
  `snappingPoints`, `copyWith`) and should remain domain-focused.
- Tool actions model interaction workflows and preview/finalization behavior.

### 3) Non-Negotiable Rules

- `ViewportNotifier` is the single owner for viewport-state mutation.
- Keep UI widgets thin; behavior belongs in logic/tools/domain layers.
- Preserve paint order: Grid -> Selection -> Geometry -> Snapping -> Tool ->
  Cursor.
- Keep keyboard and pointer handling centralized in existing entry points.

### 4) Change Workflow

- Read target file and immediate neighbors before editing.
- Preserve public API and naming unless explicitly requested otherwise.
- Apply minimal, localized changes; avoid broad refactors by default.
- Follow existing conventions before introducing new abstractions.

### 5) Tooling and Verification

- Use Dart MCP tools whenever possible for analysis, formatting, and tests.
- Fall back to shell commands only when MCP capability is unavailable.
- Required pre-completion checks for every code change:
  - Static analysis.
  - Relevant tests (or full test suite when scope is broad/unclear).
  - Golden verification for rendering-impacting changes.
- Never claim completion without reporting command outcomes.

### 6) Testing Strategy

- Add/update tests alongside behavior changes.
- Keep visual regressions controlled through focused golden updates.
- Pay special attention to selection, snapping, undo/redo, and tool previews.

### 7) Report Output Contract

Each task report from agents must include:

- Files changed.
- Behavior impact summary.
- Verification commands executed and outcomes.
- Known risks, constraints, or follow-ups.

### 8) Quick Command Reference

Provide canonical fallback commands for:

- Analysis.
- Test execution (including project-specific wrapper script).
- Formatting.

MCP-first rule remains primary.

## Enforcement and Failure Handling

- If verification fails, do not report task as complete.
- Report failing command, likely cause, and next corrective step.
- Document residual risks explicitly when constraints prevent full validation.

## Acceptance Criteria for AGENTS.md

- Reflects actual repository architecture and responsibilities.
- Contains strict workflow and verification gate.
- Explicitly prefers Dart MCP tooling.
- Excludes deprecated feature discussion.
- Is concise, actionable, and agent-focused.

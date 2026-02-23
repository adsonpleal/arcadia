# AGENTS.md Playbook Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create a strict, AI-agent-only `AGENTS.md` for Arcadia that
documents architecture boundaries, required workflow, MCP-first tooling, and
verification gates.

**Architecture:** The implementation is a root-level Markdown playbook
(`AGENTS.md`) aligned with the current `lib/src` layering and test workflows.
The document will define ownership boundaries (`logic`, `tools`, `geometry`,
`ui`), an execution protocol for edits, and required completion evidence.
Validation is performed with content assertions and repo verification commands.

**Tech Stack:** Markdown, Dart/Flutter project conventions, git, `rg`,
`dart analyze`, `dart test`.

---

### Task 1: Create AGENTS.md Skeleton

**Files:**
- Create: `AGENTS.md`
- Test: `AGENTS.md`

**Step 1: Write the failing test**

```bash
test -f AGENTS.md
```

**Step 2: Run test to verify it fails**

Run: `test -f AGENTS.md`
Expected: non-zero exit status (file does not exist yet).

**Step 3: Write minimal implementation**

Create `AGENTS.md` with this minimal scaffold:

```markdown
# AGENTS

## Purpose and Scope

## Architecture Map

## Non-Negotiable Rules

## Change Workflow

## Tooling and Verification

## Testing Strategy

## Report Output Contract

## Quick Command Reference
```

**Step 4: Run test to verify it passes**

Run: `test -f AGENTS.md && rg '^## ' AGENTS.md`
Expected: command succeeds and prints all section headings.

**Step 5: Commit**

```bash
git add AGENTS.md
git commit -m "docs: scaffold AGENTS playbook sections"
```

### Task 2: Add Architecture Map and Ownership Rules

**Files:**
- Modify: `AGENTS.md`
- Test: `AGENTS.md`

**Step 1: Write the failing test**

```bash
rg -n 'ViewportNotifier.*single owner' AGENTS.md && \
rg -n 'Grid -> Selection -> Geometry -> Snapping -> Tool -> Cursor' AGENTS.md
```

**Step 2: Run test to verify it fails**

Run:
`rg -n 'ViewportNotifier.*single owner|Grid -> Selection -> Geometry -> Snapping -> Tool -> Cursor' AGENTS.md`
Expected: missing one or more required rules in current skeleton.

**Step 3: Write minimal implementation**

Add these blocks to `AGENTS.md`:

```markdown
## Purpose and Scope

This file is an execution playbook for AI coding agents working in Arcadia.
Priorities: correctness, minimal diffs, and verifiable outcomes.

## Architecture Map

- `lib/src/logic`: state mutation and interaction orchestration.
- `lib/src/data`: immutable viewport state.
- `lib/src/tools`: tool interaction state machines and previews.
- `lib/src/geometry`: geometry primitives and rendering/containment behavior.
- `lib/src/ui`: input wiring and rendering composition.
- `lib/src/providers`: notifier access and selective rebuild helpers.
- `lib/src/constants`: configuration and color/system constants.

System flow:
- Shortcuts/actions originate in `lib/src/ui/project_page.dart`.
- Pointer events originate in `lib/src/ui/viewport.dart`.
- State mutation occurs in `lib/src/logic/viewport_notifier.dart`.
- Render layers consume state through `ViewportStateBuilder` + `CustomPaint`.

## Non-Negotiable Rules

- `ViewportNotifier` is the single owner of viewport-state mutation.
- Keep UI widgets thin; behavior belongs in `logic`, `tools`, and `geometry`.
- Preserve paint layer order:
  `Grid -> Selection -> Geometry -> Snapping -> Tool -> Cursor`.
- Keep keyboard and pointer routing in existing entry points unless requested.
```

**Step 4: Run test to verify it passes**

Run:
`rg -n 'ViewportNotifier.*single owner|Grid -> Selection -> Geometry -> Snapping -> Tool -> Cursor' AGENTS.md`
Expected: both rules are present.

**Step 5: Commit**

```bash
git add AGENTS.md
git commit -m "docs: define AGENTS architecture boundaries"
```

### Task 3: Add Workflow, MCP-First Tooling, and Completion Gate

**Files:**
- Modify: `AGENTS.md`
- Test: `AGENTS.md`

**Step 1: Write the failing test**

```bash
rg -n 'Dart MCP|always verify|Do not claim completion without command outcomes' AGENTS.md
```

**Step 2: Run test to verify it fails**

Run:
`rg -n 'Dart MCP|always verify|Do not claim completion without command outcomes' AGENTS.md`
Expected: one or more required policy lines are missing.

**Step 3: Write minimal implementation**

Add/update these sections in `AGENTS.md`:

```markdown
## Change Workflow

- Read target files and immediate neighbors before editing.
- Keep changes minimal and localized.
- Preserve public APIs and naming unless explicitly requested otherwise.
- Follow existing patterns before introducing new abstractions.
- Avoid broad refactors in feature/bug tasks unless explicitly requested.

## Tooling and Verification

- Use Dart MCP tools whenever possible for analysis, formatting, tests, and
  Dart/Flutter-aware operations.
- Use shell fallbacks only when MCP does not cover the required action.
- Always verify before claiming completion:
  - Run static analysis.
  - Run relevant tests (or full suite if scope is broad/unclear).
  - Run impacted golden tests for rendering changes.
- Do not claim completion without command outcomes.

Definition of done:
- Changes are layered correctly.
- Verification was executed and reported.
- Remaining risks (if any) are explicitly documented.
```

**Step 4: Run test to verify it passes**

Run:
`rg -n 'Dart MCP|Always verify|Do not claim completion without command outcomes|Definition of done' AGENTS.md`
Expected: all required policy markers are found.

**Step 5: Commit**

```bash
git add AGENTS.md
git commit -m "docs: add AGENTS workflow and verification gate"
```

### Task 4: Add Testing Strategy, Reporting Contract, and Command Matrix

**Files:**
- Modify: `AGENTS.md`
- Test: `AGENTS.md`

**Step 1: Write the failing test**

```bash
rg -n '## Testing Strategy|## Report Output Contract|## Quick Command Reference' AGENTS.md && \
rg -n 'dart analyze|dart test' AGENTS.md
```

**Step 2: Run test to verify it fails**

Run:
`rg -n '## Testing Strategy|## Report Output Contract|## Quick Command Reference|dart analyze|dart test' AGENTS.md`
Expected: missing one or more sections/commands.

**Step 3: Write minimal implementation**

Add this content:

```markdown
## Testing Strategy

- Add or update tests alongside behavior changes.
- Keep visual regressions controlled with focused golden verification.
- Prioritize regression coverage for:
  - selection/hover
  - snapping behavior
  - undo/redo transitions
  - tool preview vs final geometry behavior

## Report Output Contract

Every agent completion report must include:
- files changed
- behavior impact summary
- verification commands executed with outcomes
- known risks, constraints, or follow-ups

## Quick Command Reference

Preferred: use Dart MCP tooling.
Fallback commands:
- `dart analyze`
- `dart test`
- `dart format lib test`
```

**Step 4: Run test to verify it passes**

Run:
`rg -n '## Testing Strategy|## Report Output Contract|## Quick Command Reference|dart analyze|dart test|dart format lib test' AGENTS.md`
Expected: all sections and commands are present.

**Step 5: Commit**

```bash
git add AGENTS.md
git commit -m "docs: finalize AGENTS testing and reporting guidance"
```

### Task 5: Constraint and Quality Verification

**Files:**
- Modify: `AGENTS.md` (only if needed)
- Test: `AGENTS.md`

**Step 1: Write the failing test**

```bash
rg -n -i 'macro|deprecated flutter feature|deprecated internals' AGENTS.md
```

**Step 2: Run test to verify it fails**

Run: `rg -n -i 'macro|deprecated flutter feature|deprecated internals' AGENTS.md`
Expected: no matches. If there are matches, treat as failure.

**Step 3: Write minimal implementation**

If the test finds banned wording:
- Remove or rewrite the offending lines.
- Re-run the command until zero matches.

If no matches:
- No file edits required in this step.

**Step 4: Run test to verify it passes**

Run:
`rg -n -i 'macro|deprecated flutter feature|deprecated internals' AGENTS.md`
Expected: no output and non-zero status from `rg` (treated as pass for this
negative assertion).

**Step 5: Commit**

```bash
git add AGENTS.md
git commit -m "docs: enforce AGENTS wording constraints"
```

### Task 6: Repository Verification and Finalization

**Files:**
- Modify: `AGENTS.md` (only if verification requires fixes)
- Test: `AGENTS.md`

**Step 1: Write the failing test**

```bash
dart analyze
```

**Step 2: Run test to verify it fails**

Run: `dart analyze`
Expected: ideally pass. If it fails, capture issues and fix as needed.

**Step 3: Write minimal implementation**

If verification uncovers issues caused by the work:
- apply the smallest possible fix
- re-run verification

If verification passes:
- no code changes in this step

**Step 4: Run test to verify it passes**

Run: `dart analyze && dart test`
Expected: both commands pass.

**Step 5: Commit**

```bash
git add AGENTS.md
git commit -m "docs: complete AGENTS playbook with verified checks"
```

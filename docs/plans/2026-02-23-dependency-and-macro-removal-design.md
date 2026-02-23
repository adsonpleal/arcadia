# Dependency and Macro Removal Design

Date: 2026-02-23
Status: Approved
Owner: Codex + project maintainer

## Context

Arcadia currently uses a custom macro (`@Data`) in `lib/src/macros/data.dart`
to generate `copyWith`, equality, and `hashCode`. In production code, this
macro is used by `lib/src/data/viewport_state.dart`. The project also contains
macro-focused tests in `test/src/macros/data_test.dart`.

Current `pubspec.yaml` includes:

- `environment.sdk: ^3.6.0-55.0.dev`
- dependency `macros`

Installed local SDK:

- Dart `3.10.8` (stable)
- Flutter `3.38.9`

## Goals

- Remove dependency on macros and delete `lib/src/macros`.
- Update SDK constraint to the currently installed Dart version.
- Refresh dependencies to latest compatible versions.
- Replace generated model behavior with explicit `ViewportState` methods.
- Add extensive model tests for manual `copyWith`, `==`, and `hashCode`.

## Non-Goals

- Refactoring unrelated architecture layers.
- Moving input routing, paint ordering, or notifier ownership.
- Introducing new code-generation frameworks.

## Scope

- `pubspec.yaml` and `pubspec.lock`
- `lib/src/data/viewport_state.dart`
- remove `lib/src/macros/`
- remove/replace `test/src/macros/data_test.dart`
- add `test/src/data/viewport_state_test.dart`

## Chosen Approach

Manual model methods with no replacement macro/codegen dependency.

### Why this approach

- Minimal and explicit migration aligned with requested outcome.
- Avoids adding new build tooling or generators.
- Keeps behavior concentrated in the data layer with localized diffs.

## Behavior Specification

### `ViewportState.copyWith`

- Supports all fields.
- Preserves existing values when omitted.
- Supports explicit null assignment for nullable fields (`selectedTool`) via a
  sentinel-based parameter pattern.

### Equality and hash code

- Use deep equality for list fields:
  - `geometries`
  - `toolGeometries`
  - `snappingGeometries`
  - `selectionGeometries`
- Use standard equality for scalar/object fields.
- `hashCode` mirrors equality semantics, including deep hashing for list fields.

## Dependency Strategy

- Remove `macros` from dependencies.
- Update `environment.sdk` to Dart `3.10.8` constraint.
- Upgrade direct dependencies/dev dependencies to latest compatible versions.
- Regenerate lockfile with `dart pub upgrade`.

## Test Strategy

Replace macro-specific tests with focused `ViewportState` tests that cover:

- default constructor values
- per-field `copyWith` updates
- copy-with omission preserving previous values
- explicit null behavior for nullable field updates
- deep list equality behavior
- `hashCode` consistency for equal objects
- inequality when any relevant field differs

## Verification Plan

Required verification before completion:

1. static analysis (`dart analyze`)
2. test execution (at least model tests, and full suite for dependency updates)
3. golden verification only if rendering behavior changes are observed

## Risks and Mitigations

- Risk: dependency upgrades can introduce unrelated API/test failures.
  - Mitigation: keep fixes minimal and localized; report each compatibility fix.
- Risk: equality semantic change (identity list equality -> deep equality).
  - Mitigation: add explicit regression tests documenting intended semantics.

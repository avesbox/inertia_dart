# inertia_dart

Private split repository for the standalone Dart Inertia package.

This repo is a history-reset extraction from the larger `routed_ecosystem`
monorepo and contains only the standalone `inertia_dart` surface:

- `packages/inertia` (`inertia_dart`)
- standalone examples that do not depend on the local Routed source tree

The goal is to keep package development, examples, and release history for the
core Inertia implementation separate from the broader Routed framework source
tree.

## Workspace

```bash
dart pub get
```

## Packages

- `packages/inertia` implements the core Inertia protocol helpers for Dart.

## Examples

- `examples/contacts_app` shows standalone `dart:io` usage.
- `packages/inertia/example/*` contains focused package examples.

## Notes

- This repository intentionally starts from a fresh git history.
- The Routed integration package, `routed_inertia`, was not included in this
  split because it is still coupled to the local Routed package set and is not
  independently movable yet.

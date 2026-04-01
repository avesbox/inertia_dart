# inertia_dart

Standalone repository for the Dart implementation of the Inertia.js server-side
protocol.

This repository contains the core `inertia_dart` package and standalone
examples built around `dart:io`.

## Workspace

```bash
dart pub get
```

## Packages

- `packages/inertia` implements the core Inertia protocol helpers for Dart.
- `packages/routed_inertia` adds Routed middleware, `EngineContext` helpers,
  config wiring, and SSR support for Inertia responses.
- `packages/serinus_inertia` adds Serinus request/response adapters and
  `RequestContext` helpers for Inertia responses.

## Examples

- `examples/contacts_app` shows standalone `dart:io` usage.
- `packages/inertia/example/*` contains focused package examples.

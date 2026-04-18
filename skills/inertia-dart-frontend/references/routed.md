# `routed_inertia`

Use this path when the project is built on Routed.

## Local Anchors

If local code is available, search for:

- `ctx.inertia(`
- `RoutedInertiaMiddleware`
- `registerRoutedInertiaProvider`
- `InertiaServiceProvider`
- `config/inertia.yaml`

## Integration Shape

The main server-side entrypoint is usually `ctx.inertia(...)`.

Typical route:

```dart
engine.get('/', (ctx) {
  return ctx.inertia(
    'Home',
    props: {'title': 'Hello'},
    htmlBuilder: htmlBuilder,
  );
});
```

Use `ctx.inertia(...)` instead of manually recreating the raw `inertia_dart`
request flow unless the app already chose a lower-level path.

## Setup Choices

Two common setups exist:

1. Middleware-first setup
   - `RoutedInertiaMiddleware(versionResolver: () => '1.0.0').call`

2. Config/provider setup
   - `registerRoutedInertiaProvider(...)`
   - `InertiaServiceProvider(...)`
   - config files for HTTP and Inertia options

Prefer whichever style the project already uses.

## Assets and HTML

Projects commonly support both:

- dev mode from a hot file or explicit dev URL
- production mode from the Vite manifest

If the app uses custom HTML rendering, keep the `htmlBuilder` aligned with
these rules:

- inject `ssr.head` when SSR is enabled
- render `renderInertiaBootstrap(page, body: ssr?.body)`
- inject manifest or dev-server tags

If the app uses a template engine, keep asset injection and the Inertia
bootstrap container in the template instead of duplicating them in code.

## Config Expectations

An Inertia config file may carry:

- `version`
- `root_view`
- history settings
- `ssr.enabled`
- `ssr.url`
- asset paths such as `manifest_path`, `entry`, `base_url`, and `hot_file`

Prefer adjusting config over scattering those values through route handlers.

## SSR

Only add SSR hooks when the user asked for first-visit SSR or the app already
has the runtime in place.

Keep the project's existing runtime model:

- separate SSR process
- managed child process
- external SSR endpoint

## Extension Rules

- Add frontend pages under the frontend pages directory the resolver already uses.
- Match route component names to page file paths exactly.
- Reuse shared props, flash data, and error-bag helpers like `ctx.inertiaShare`, `ctx.inertiaFlash`, and `ctx.inertiaErrors` instead of inventing ad hoc response metadata.

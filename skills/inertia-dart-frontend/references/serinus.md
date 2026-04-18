# `serinus_inertia`

Use this path when the project is built on Serinus.

## Local Anchors

If local code is available, search for:

- `InertiaModule(`
- `InertiaOptions(`
- `InertiaAssetsOptions(`
- `context.inertia(`
- `InertiaSsrOptions(`

## Integration Shape

Register `InertiaModule` once in the root module, then render pages with
`context.inertia(...)`.

Module setup:

```dart
InertiaModule(
  options: InertiaOptions(
    version: '1.0.0',
    assets: InertiaAssetsOptions(
      entry: 'src/main.jsx',
      clientDirectory: 'client',
      includeReactRefresh: true,
    ),
  ),
)
```

Controller route:

```dart
on(Route.get('/'), (context) async {
  return context.inertia(
    component: 'Home',
    props: {'title': 'Hello from Serinus'},
  );
});
```

Use that high-level path unless the project explicitly wants lower-level
request and response handling.

## Client Bootstrapping

The React client usually uses `createInertiaApp` with `import.meta.glob`.

If SSR markup may already exist, hydrate instead of always replacing the root:

```jsx
if (el.hasChildNodes()) {
  hydrateRoot(el, <App {...props} />)
  return
}
```

That is the right default for Serinus projects that may switch between
client-only and SSR modes.

## Asset Handling

`InertiaAssetsOptions` lets the package inject dev or production assets for
first visits.

Use:

- `entry: 'src/main.jsx'`
- `clientDirectory: 'client'`
- optional overrides for `manifestPath`, `hotFile`, `devServerUrl`, and `baseUrl`

Prefer configuring assets in `InertiaOptions` instead of hand-writing HTML
wrappers unless the project already has a custom `htmlBuilder`.

For a minimal Serinus static-file setup, prefer the official package:

```dart
import 'package:serinus_serve_static/serinus_serve_static.dart';

ServeStaticModule(
  rootPath: '/public',
  renderPath: '*',
  serveRoot: '',
  exclude: const [],
  extensions: const ['.html', '.css', '.js'],
  index: const ['index.html'],
  redirect: true,
)
```

Use that when the project just needs a straightforward static directory exposed
by Serinus.

For production bundles, Serinus can also serve Vite assets itself. One common
pattern is a dedicated controller that exposes `/assets/**` from the built
frontend assets directory and sets content type plus immutable cache headers.
Do not assume nginx is required just to serve hashed frontend assets. Also do
not assume `ServeStaticModule` is always a drop-in replacement for Vite output
layouts where the URL prefix and on-disk directory need different mappings.

## SSR Choices

Serinus supports both managed and external SSR runtimes.

Managed process:

```dart
ssr: InertiaSsrOptions(
  enabled: true,
  manageProcess: true,
  runtime: 'node',
  bundle: 'client/dist/ssr.js',
),
```

External endpoint:

```dart
ssr: InertiaSsrOptions(
  enabled: true,
  endpoint: Uri.parse('http://127.0.0.1:13714/render'),
),
```

CLI helpers for a separate runtime:

```bash
dart run serinus_inertia:ssr start --bundle client/dist/ssr.js
dart run serinus_inertia:ssr check
dart run serinus_inertia:ssr stop
```

Only add SSR when the user asked for it or the project already has the entry
file and runtime workflow.

## Extension Rules

- Keep shared defaults in `InertiaOptions` rather than duplicating them in every controller.
- Add frontend pages under the frontend pages directory the resolver already uses.
- Match controller `component` names to those page file paths exactly.
- Use `LazyProp`, `DeferredProp`, `MergeProp`, `ScrollProp`, and `OnceProp` only when their behavior is needed.
- Use `context.inertiaLocation(...)` for location redirects instead of inventing a custom `409` response.

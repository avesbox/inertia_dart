# Client Patterns

Use this file for any frontend task, regardless of server integration.

## Supported Adapters

The CLI and package templates support three adapters:

- React
  - `src/main.jsx`
  - `src/ssr.jsx`
  - `src/Pages/**/*.jsx`
- Vue
  - `src/main.js`
  - `src/ssr.js`
  - `src/Pages/**/*.vue`
- Svelte
  - `src/main.js`
  - `src/ssr.js`
  - `src/Pages/**/*.svelte`

Prefer the adapter already present in the project. If the project is greenfield
and the user did not specify an adapter, default to React because the CLI
defaults there.

## Fastest Safe Commands

Use the package CLI instead of recreating Vite + Inertia boilerplate manually.

New client:

```bash
dart run inertia_dart:inertia create my-app --framework react
```

Existing Vite app:

```bash
dart run inertia_dart:inertia install --framework react --path ./client
```

The CLI wires:

- `createInertiaApp`
- `import.meta.glob` page resolution
- `src/ssr.*`
- `src/Pages/Home.*`
- `vite.config.js`
- `inertia_hot_file.js`

## Component Name Mapping

Treat the Dart-side `component` value as a path under `client/src/Pages` without the extension.

Examples:

- `component: 'Home'` -> `client/src/Pages/Home.jsx`
- `component: 'Users/Index'` -> `client/src/Pages/Users/Index.jsx`

Do not change one side without the other.

## Resolver Pattern

Keep the resolver close to the scaffolded pattern:

```jsx
resolve: (name) => {
  const pages = import.meta.glob('./Pages/**/*.jsx', { eager: true })
  return pages[`./Pages/${name}.jsx`]
}
```

Use the matching extension for Vue or Svelte. Avoid replacing this with custom dynamic import logic unless the app already has a stable alternative.

## Client and SSR Entry Rules

Client-only React entry:

```jsx
createInertiaApp({
  resolve: ...,
  setup({ el, App, props }) {
    createRoot(el).render(<App {...props} />)
  },
})
```

SSR React entry:

```jsx
createServer(page =>
  createInertiaApp({
    page,
    render: ReactDOMServer.renderToString,
    resolve: ...,
    setup: ({ App, props }) => <App {...props} />,
  }),
)
```

If the server already injects SSR markup into the page, hydrate instead of replacing the DOM. The Serinus docs use:

```jsx
if (el.hasChildNodes()) {
  hydrateRoot(el, <App {...props} />)
  return
}
```

## Dev and Production Assets

Preserve these conventions unless the project already uses different paths:

- hot file: `client/public/hot`
- manifest: `client/dist/.vite/manifest.json`
- generated Vite helper: `client/inertia_hot_file.js`

The standard Vite config includes `inertiaHotFile()` so the Dart server can discover the dev server URL from the hot file.

If you need to generate the helper from Dart, use:

```dart
await writeInertiaViteHotFilePlugin(Directory('client'));
```

## Server-Side Asset Resolution

When rendering first-visit HTML manually, prefer `InertiaViteAssets` or the higher-level integration instead of hard-coded script tags.

Typical setup:

```dart
final assets = InertiaViteAssets(
  entry: 'index.html',
  hotFile: 'client/public/hot',
  manifestPath: 'client/dist/.vite/manifest.json',
  includeReactRefresh: true,
);
```

## Common Mistakes

- Creating a page file whose path does not match the Dart `component` string.
- Adding SSR on the client side without starting or configuring an SSR runtime.
- Hand-writing Vite asset tags instead of using `InertiaViteAssets` or the integration's asset support.
- Replacing the scaffolded `import.meta.glob` pattern with something incompatible with nested page names.
- Starting Vite without the hot-file plugin, leaving the Dart server unable to discover the dev origin.

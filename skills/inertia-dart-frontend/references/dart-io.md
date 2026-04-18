# Raw `inertia_dart` Apps

Use this path when the app is built directly on `dart:io` instead of Routed or
Serinus.

## Local Anchors

If local code is available, search for:

- `HttpServer.bind`
- `inertiaRequestFromHttp`
- `buildPageDataAsync`
- `renderInertiaBootstrap`
- `InertiaViteAssets`

Those are the fastest signals that the project is using the low-level
`inertia_dart` flow.

## Core Request Flow

For each request:

1. Parse the request with `inertiaRequestFromHttp(request)`.
2. Build `PropertyContext` from `inertiaRequest.createContext()`.
3. Build page data with `InertiaResponseFactory().buildPageDataAsync(...)`.
4. Return JSON when `inertiaRequest.isInertia` is true.
5. Otherwise render HTML with `renderInertiaBootstrap(page)` and resolved asset tags.

Typical shape:

```dart
final inertiaRequest = inertiaRequestFromHttp(request);
final context = inertiaRequest.createContext();
final page = await InertiaResponseFactory().buildPageDataAsync(
  component: 'Home',
  props: {'title': 'Hello'},
  url: _requestUrl(request.uri),
  context: context,
);
```

## Manual HTML Rendering

For first visits, render HTML with:

- `renderInertiaBootstrap(page)` for client-only mode
- `renderInertiaBootstrap(page, body: ssr?.body)` for SSR mode
- `InertiaViteAssets` for styles and scripts

Avoid hard-coded script tags if the helper already covers the case.

## Static Assets

If the server owns asset serving in production, serve `client/dist/assets/*`
and keep the manifest and hot-file paths aligned with the frontend build:

- `client/dist/.vite/manifest.json`
- `client/public/hot`

If the project uses a different client directory, adapt the paths consistently.

## SSR

Use `HttpSsrGateway` when the user explicitly wants SSR or the app already has
an SSR entry.

Typical flow:

1. Build the page JSON.
2. Call `gateway.render(jsonEncode(page.toJson()))`.
3. Merge `ssr.head` and `ssr.body` into the final HTML.

Common local endpoint default:

- `http://127.0.0.1:13714/render`

Useful CLI commands:

```bash
dart run inertia_dart:inertia ssr:start --runtime node
dart run inertia_dart:inertia ssr:check --url http://127.0.0.1:13714
dart run inertia_dart:inertia ssr:stop --url http://127.0.0.1:13714
```

## Extension Rules

- Keep existing request parsing and response writing helpers if the app already has them.
- Add new page files under the frontend pages directory the resolver already uses.
- Add new routes by returning a matching `component` string.
- Use advanced props only where partial reloads, deferred sections, or merge behavior are actually needed.

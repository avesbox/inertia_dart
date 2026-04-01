# Serinus Inertia

Use `inertia_dart` from Serinus route handlers.

`serinus_inertia` adapts Serinus requests and responses to the Inertia protocol
and gives you:

- `InertiaModule` for app-wide defaults
- `RequestContext.inertia()` for rendering Inertia pages
- `RequestContext.inertiaLocation()` for `409 X-Inertia-Location` responses
- asset-aware HTML bootstrapping for Vite
- optional SSR integration, including managed `node` or `bun` processes

## Install

Add the server package:

```bash
dart pub add serinus_inertia
```

If you do not already have a client app, add the usual Inertia React stack in
your frontend:

```bash
npm install @inertiajs/react react react-dom
npm install -D vite @vitejs/plugin-react
```

## Getting Started

The shortest useful setup has four parts:

1. Register `InertiaModule`
2. Render a page from a Serinus controller
3. Bootstrap the client app
4. Run the server and Vite together

### 1. Register `InertiaModule`

Register the module once in your root module. If you provide asset settings, the
default HTML wrapper will inject the correct Vite tags for first visits.

```dart
import 'package:serinus/serinus.dart';
import 'package:serinus_inertia/serinus_inertia.dart';

class AppModule extends Module {
  AppModule()
    : super(
        imports: [
          InertiaModule(
            options: SerinusInertiaOptions(
              version: '1.0.0',
              assets: SerinusInertiaAssetOptions(
                entry: 'src/main.jsx',
                clientDirectory: 'client',
                includeReactRefresh: true,
              ),
              sharedProps: (context) async => {
                'appName': 'Serinus Inertia',
              },
            ),
          ),
        ],
        controllers: [AppController()],
      );
}
```

### 2. Render a page from a controller

Once the module is registered, render pages with `context.inertia()`.

```dart
import 'package:inertia_dart/inertia_dart.dart';
import 'package:serinus/serinus.dart';
import 'package:serinus_inertia/serinus_inertia.dart';

class AppController extends Controller {
  AppController() : super('/') {
    on(Route.get('/'), (context) async {
      return context.inertia(
        component: 'Home',
        props: {
          'title': 'Hello from Serinus',
          'stats': LazyProp(() => loadStats()),
        },
      );
    });
  }
}
```

`context.inertia()` returns:

- an HTML document on the first visit
- a JSON page payload for `X-Inertia: true` requests

### 3. Bootstrap the client app

The React client can use the same page tree for both client-side rendering and
SSR.

```jsx
import { createInertiaApp } from '@inertiajs/react'
import { createRoot, hydrateRoot } from 'react-dom/client'
import './index.css'

createInertiaApp({
  title: (title) => (title ? `${title} | Serinus Inertia` : 'Serinus Inertia'),
  resolve: (name) => {
    const pages = import.meta.glob('./Pages/**/*.jsx', { eager: true })
    return pages[`./Pages/${name}.jsx`]
  },
  setup({ el, App, props }) {
    if (el.hasChildNodes()) {
      hydrateRoot(el, <App {...props} />)
      return
    }

    createRoot(el).render(<App {...props} />)
  },
})
```

If you want the package to generate the Vite hot-file plugin for you, add a
small Dart script and run it once:

```dart
import 'dart:io';

import 'package:inertia_dart/inertia_dart.dart';

Future<void> main() async {
  await writeInertiaViteHotFilePlugin(Directory('client'));
}
```

That writes `client/inertia_hot_file.js`, which you can import from
`vite.config.js`.

### 4. Run the app in development

In one terminal, run Vite:

```bash
cd client
npm install
npm run dev
```

In a second terminal, run your Serinus app:

```bash
dart pub get
dart run bin/main.dart
```

Open `http://127.0.0.1:4000`.

## InertiaModule

`InertiaModule` is the high-level integration point. Use it when you want
shared defaults instead of repeating options in every handler.

`SerinusInertiaOptions` can define:

- `version`
- `elementId`
- `sharedProps`
- `encryptHistory`
- `clearHistory`
- `assets`
- `ssr`
- `htmlBuilder`

If `htmlBuilder` is omitted, the default wrapper renders:

- the Inertia bootstrap container
- Vite dev tags or production asset tags when `assets` is configured
- SSR head and body when SSR is enabled

## Client Assets

Use `SerinusInertiaAssetOptions` when you want the package to know where the
frontend lives.

For development asset resolution, the package uses this order:

1. `devServerUrl` if you set it explicitly
2. `hotFile` if the Vite hot file exists
3. the production manifest when neither dev option is available

The package reads a single Vite hot file, not multiple hot files. By default
that path is `client/public/hot`.

If you want to generate the Vite plugin file from Dart instead of copying one
manually, use `writeInertiaViteHotFilePlugin(Directory('client'))` from
`package:inertia_dart/inertia_dart.dart`.

```dart
InertiaModule(
  options: SerinusInertiaOptions(
    assets: SerinusInertiaAssetOptions(
      entry: 'src/main.jsx',
      clientDirectory: 'client',
      // Optional overrides:
      // manifestPath: 'frontend/dist/.vite/manifest.json',
      // hotFile: 'frontend/public/hot',
      // devServerUrl: 'http://localhost:5173',
      // baseUrl: '/',
    ),
  ),
)
```

That keeps the first-visit HTML generation inside the package instead of
hand-writing script and stylesheet tags.

If your dev server runs somewhere unusual, either point directly at it:

```dart
assets: SerinusInertiaAssetOptions(
  entry: 'src/main.jsx',
  clientDirectory: 'client',
  devServerUrl: 'http://127.0.0.1:5174',
),
```

or override the hot file path if your tooling writes it somewhere else:

```dart
assets: SerinusInertiaAssetOptions(
  entry: 'src/main.jsx',
  clientDirectory: 'client',
  hotFile: 'frontend/public/hot',
),
```

## SSR

Use `SerinusInertiaSsrOptions` for first-visit SSR.

### Managed by Serinus

Enable `manageProcess` if you want Serinus to launch `node` or `bun` as a
separate child process during startup and stop it again on shutdown.

```dart
InertiaModule(
  options: SerinusInertiaOptions(
    ssr: SerinusInertiaSsrOptions(
      enabled: true,
      manageProcess: true,
      runtime: 'node', // or 'bun'
      bundle: 'client/dist/ssr.js',
    ),
  ),
)
```

When `manageProcess` is enabled and `endpoint` is omitted, the default endpoint
is `http://127.0.0.1:13714/render`, with matching `/health` and `/shutdown`
endpoints.

### Managed separately

If you prefer to keep the SSR runtime outside the Serinus process, point at an
existing endpoint instead:

```dart
InertiaModule(
  options: SerinusInertiaOptions(
    ssr: SerinusInertiaSsrOptions(
      enabled: true,
      endpoint: Uri.parse('http://127.0.0.1:13714/render'),
      // Optional:
      // healthEndpoint: Uri.parse('http://127.0.0.1:13714/health'),
    ),
  ),
)
```

You can start the SSR server from the package executable:

```bash
dart run serinus_inertia:ssr start --bundle client/dist/ssr.js
dart run serinus_inertia:ssr check
dart run serinus_inertia:ssr stop
```

The start command auto-detects common bundle paths such as:

- `client/dist/ssr.js`
- `client/dist/server/entry-server.js`
- `bootstrap/ssr/ssr.mjs`

The older `dart run serinus_inertia:serinus_inertia ssr:start` form remains
supported as an alias.

### Custom gateways

If you already have your own SSR transport, pass a gateway implementation
directly:

```dart
InertiaModule(
  options: SerinusInertiaOptions(
    ssr: SerinusInertiaSsrOptions(
      enabled: true,
      gateway: MyCustomSsrGateway(),
    ),
  ),
)
```

## Low-Level Helpers

Use the lower-level helpers when you want to control response handling
yourself.

```dart
final inertiaRequest = inertiaRequestFromSerinus(context.request);
final page = await context.buildInertiaPageData(
  component: 'Dashboard',
  props: {'user': {'name': 'Ada'}},
);
final response = await context.buildInertiaResponse(
  component: 'Dashboard',
  props: {'user': {'name': 'Ada'}},
);

applyInertiaResponse(context.res, response);
return response.html ?? response.toJson();
```

## Location Responses

Use `context.inertiaLocation('/login')` when you need an Inertia
`409 X-Inertia-Location` response.

## Example App

See [`example/`](example) for a complete Serinus + Vite demo with:

- a simple landing page
- a users page with lazy props and remembered history state
- a feature lab for deferred props, merge props, scroll props, flash data, and
  history flags
- optional SSR instructions for both managed and external runtime modes

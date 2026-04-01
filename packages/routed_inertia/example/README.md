# Routed Inertia + React Example

This example demonstrates a simple Routed server that renders Inertia responses
and a React frontend powered by `@inertiajs/react`.

## Prerequisites
- Dart SDK 3.9+
- Node.js 18+

## Setup

From the package root:

```bash
cd packages/routed_inertia
dart pub get
```

Install frontend dependencies:

```bash
cd example/client
npm install
```

## Run

Start the React dev server:

```bash
cd example/client
npm run dev
```

The Vite dev server writes `example/client/public/hot`.
If you want to override the URL, set `INERTIA_DEV_SERVER_URL` (or
`VITE_DEV_SERVER_URL`):

```bash
export INERTIA_DEV_SERVER_URL="http://localhost:5173"
```

Start the Routed app in another terminal:

```bash
dart run example/server.dart
```

The example app loads config from `example/config`.
Update `config/inertia.yaml` to change the version, SSR, or asset settings.

Visit:
- http://localhost:8080

## Server usage

The example uses the `EngineContext` extension helper:

```dart
engine.get('/', (ctx) {
  return ctx.inertia(
    'Home',
    props: {'title': 'Routed + Inertia'},
    htmlBuilder: htmlBuilder,
  );
});
```

If you want to render via the configured view engine (e.g. Liquify),
pass a template name or template content:

```dart
return ctx.inertia(
  'Home',
  props: {'title': 'Routed + Inertia'},
  templateName: 'inertia/home',
);
```

## Production Build

Build frontend assets:

```bash
cd example/client
npm run build
```

Run the server with the production flag so it loads the Vite manifest:

```bash
INERTIA_DEV=false dart run example/server.dart
```

This will serve `/assets/*` from `example/client/dist/assets`
and inject the correct hashed bundle paths.

## SSR

Build the client and SSR bundles:

```bash
cd example/client
npm run build
```

Start the SSR renderer in one terminal:

```bash
dart run example/ssr.dart
```

Start the Routed server with SSR enabled in another terminal:

```bash
INERTIA_DEV=false INERTIA_SSR=true dart run example/server.dart
```

The `INERTIA_SSR=true` flag turns on SSR for the example without requiring you
to edit `example/config/inertia.yaml`. If you prefer config-driven SSR, set
`ssr.enabled: true` there and keep using the same `example/ssr.dart` process.

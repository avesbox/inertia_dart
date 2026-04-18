# Serinus Inertia Example

This example is a complete Serinus + Inertia + Vite setup.

## Getting Started

If you want the shortest path from clone to browser, use this sequence.

### 1. Install dependencies

Install the Dart packages:

```bash
dart pub get
```

Install the client packages:

```bash
cd client
npm install
```

### 2. Start development mode

Run Vite in one terminal:

```bash
cd client
npm run dev
```

Run the Serinus app in a second terminal:

```bash
dart run bin/main.dart
```

Then open <http://127.0.0.1:4000>.

### Dev server discovery

The example uses a single Vite hot file at `client/public/hot`.

In development the server resolves client assets in this order:

1. `devServerUrl` if you set one in `lib/app_module.dart`
2. the hot file at `client/public/hot`
3. the production manifest if neither dev option is available

If you run Vite on a custom port and do not want to rely on the hot file, set:

```dart
assets: InertiaAssetsOptions(
  entry: 'src/main.jsx',
  clientDirectory: 'client',
  devServerUrl: 'http://127.0.0.1:5174',
),
```

If your toolchain writes the hot file somewhere else, override `hotFile` in the
same asset options block.

## What It Covers

The demo is intentionally broader than a hello-world app so the adapter can be
exercised properly.

- `/` is a launchpad that explains the available drills.
- `/users` tests remembered history state, query-param server filters, and a
  lazy prop loaded through partial reloads.
- `/lab` concentrates deferred props, optional props, merge props, scroll props,
  polling, flash payloads, history flags, and a post-action redirect.

## Project Layout

- `lib/app_module.dart` registers `InertiaModule`
- `lib/app_controller.dart` defines the demo routes
- `client/src/main.jsx` is the client bootstrap
- `client/src/ssr.jsx` is the SSR entry
- `client/src/Pages/` contains the demo pages

## Suggested Manual Checks

Once the app is running, use these routes to shake out the adapter behavior.

### Users page

- Change the team filter and confirm the server-side roster changes.
- Type in the client-side search box, leave the page, then use browser
  back/forward navigation to confirm the remembered state is restored.
- Load the lazy diagnostics panel and confirm the rest of the page state stays
  in place.

### Feature lab

- Wait for the live stats cards to poll fresh data.
- Scroll until the deep dive section loads its optional prop.
- Watch the deferred release timeline resolve after the initial paint.
- Load more highlight batches, then reset them to confirm merge reset behavior.
- Scroll the activity feed until the next page loads.
- Trigger the post action and confirm the redirect arrives with flash data.
- Toggle the history buttons and inspect the page metadata panel.

## Optional SSR

You can run SSR in either of two ways.

### Managed by Serinus

Build the SSR bundle:

```bash
cd client
npm run build:ssr
```

Then enable this in `lib/app_module.dart`:

```dart
ssr: InertiaSsrOptions(
  enabled: true,
  manageProcess: true,
  runtime: 'node', // or 'bun'
  bundle: 'client/dist/ssr.js',
),
```

Now `dart run bin/main.dart` will start Serinus and launch the SSR runtime as a
separate child process.

### Managed Separately

Build the SSR bundle:

```bash
cd client
npm run build:ssr
```

Start the SSR server manually from the package executable:

```bash
dart run serinus_inertia:ssr start --bundle client/dist/ssr.js
```

Then enable the endpoint-based `ssr:` section in `lib/app_module.dart`.

## Production Build

See [DEPLOY.md](DEPLOY.md) for a full walkthrough covering client and SSR
bundle compilation, Dart server compilation, direct static asset serving from
Serinus, optional front-door proxies, alternative nginx/Caddy asset serving,
and a systemd service unit.

The short version:

```bash
cd client
npm run build   # builds both the browser bundle and client/dist/ssr.js
cd ..
mkdir -p build
dart compile exe bin/main.dart -o build/server
```

The server reads the Vite manifest from `client/dist/.vite/manifest.json`
relative to its working directory, and the example serves production assets
from `client/dist/assets` at `/assets/*`. The deploy guide also shows the
alternative layout where nginx or Caddy serves those same built assets
directly.

## Docker Compose

If you want containerized production-style setups, the bundled Compose file
defines separate client-rendered and SSR stacks without an nginx sidecar.

From this directory:

```bash
docker compose --profile client up --build
```

Then open <http://127.0.0.1:8080>.

The client-rendered stack uses:

- `client-app` — the compiled Dart server with `client/dist/` copied into the
  image and `/assets/*` served directly by Serinus

For SSR with the same Compose file:

```bash
docker compose --profile ssr up --build
```

That starts:

- `ssr-renderer` — a Node container running `client/dist/ssr.js`
- `ssr-app` — the compiled Dart server configured to call
  `http://ssr-renderer:13714/render`

Compose waits for `ssr-renderer` to report healthy before starting `ssr-app`.

The SSR stack publishes port `8081` by default so you can run both stacks side
by side. Override the defaults with `SERINUS_INERTIA_CLIENT_PORT` or
`SERINUS_INERTIA_SSR_PORT` if needed.

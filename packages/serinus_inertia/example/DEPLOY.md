# Deploying the Serinus Inertia Example

This guide walks through a production build of the example and the deployment
layout it expects. The example serves `/assets/*` directly from Serinus, so a
reverse proxy is optional rather than required.

## Overview

A production deployment has three moving parts:

1. `client/dist/` for the browser bundle and Vite manifest
2. `client/dist/ssr.js` if SSR is enabled
3. the Dart HTTP server, usually compiled to `build/server`

The production asset flow in this example is:

```text
Browser -> Dart server :4000 -> /assets/* served from client/dist/assets/*
                       -> all page and Inertia requests handled normally
```

You can still place nginx, Caddy, or another front door in front for TLS,
host-based routing, or load-balancing, but it does not need to own static file
serving for this example.

## Prerequisites

| Tool | Minimum version | Notes |
| --- | --- | --- |
| Dart SDK | 3.10 | `dart --version` |
| Node.js | 18 LTS | `node --version` |
| npm | 9 | bundled with Node |
| Node or Bun | 18 LTS / 1.0 | SSR only |

Run all commands from `packages/serinus_inertia/example` unless stated
otherwise.

## Step 1: Install dependencies

```bash
dart pub get

cd client
npm install
cd ..
```

## Step 2: Build the frontend

```bash
cd client
npm run build
cd ..
```

That produces:

```text
client/dist/
├── .vite/
│   └── manifest.json
├── assets/
│   ├── main-<hash>.js
│   └── main-<hash>.css
├── ssr-manifest.json
└── ssr.js
```

Verify the required outputs before you deploy:

```bash
ls client/dist/.vite/manifest.json
ls client/dist/assets
ls client/dist/ssr.js
```

`npm run build` clears `client/public/hot` before the browser build. That hot
file must not survive into the deployed layout, or the app will try to use a
Vite dev server in production.

## Step 3: Compile the Dart server

The recommended production path is a native executable:

```bash
mkdir -p build
dart compile exe bin/main.dart -o build/server
```

You can also run `dart run bin/main.dart` directly, but that requires deploying
the full monorepo checkout because this example depends on local `path:`
packages.

## Step 4: Understand the static asset route

`lib/asset_controller.dart` maps `/assets/**` to `client/dist/assets/**`.
Nothing special is required in front of the app for hashed Vite bundles.

The controller sets:

- the response content type based on the asset path
- `Cache-Control: public, max-age=31536000, immutable`

That cache policy is safe because Vite emits hashed filenames.

If you only need a minimal Serinus static-file setup, use the official
`serinus_serve_static` package:

```dart
import 'package:serinus/serinus.dart';
import 'package:serinus_serve_static/serinus_serve_static.dart';

class AppModule extends Module {
  AppModule()
    : super(
        imports: [
          ServeStaticModule(
            rootPath: '/public',
            renderPath: '*',
            serveRoot: '',
            exclude: const [],
            extensions: const ['.html', '.css', '.js'],
            index: const ['index.html'],
            redirect: true,
          ),
        ],
      );
}
```

That is the minimal package-backed path for serving files directly from
Serinus. For this Inertia example, we keep the explicit controller because the
production Vite output lives under `client/dist/assets`, while the public URL
must stay `/assets/*`.

## Step 5: Assemble the deployment root

For the compiled-binary path, the runtime layout should look like this:

```text
/opt/serinus-inertia/
├── server
└── client/
    └── dist/
        ├── .vite/
        │   └── manifest.json
        ├── assets/
        │   ├── main-<hash>.js
        │   └── main-<hash>.css
        ├── ssr-manifest.json
        └── ssr.js
```

Copy the outputs into place:

```bash
mkdir -p /opt/serinus-inertia/client
cp build/server /opt/serinus-inertia/server
cp -r client/dist /opt/serinus-inertia/client/dist
```

The server resolves the manifest and asset files relative to its working
directory. Keep the process working directory at `/opt/serinus-inertia`.

## Step 6: Run the app

### Client-rendered only

No extra configuration is required:

```bash
cd /opt/serinus-inertia
./server
```

### SSR managed by Serinus

If Node or Bun is installed on the host, the app can launch the renderer
itself:

```bash
cd /opt/serinus-inertia
SERINUS_INERTIA_ENABLE_SSR=true ./server
```

Optional overrides:

```bash
SERINUS_INERTIA_ENABLE_SSR=true \
SERINUS_INERTIA_SSR_RUNTIME=node \
SERINUS_INERTIA_SSR_BUNDLE=client/dist/ssr.js \
./server
```

### SSR with an external renderer

Run the renderer separately:

```bash
cd /opt/serinus-inertia
node ./client/dist/ssr.js
```

Then point the Dart app at it:

```bash
cd /opt/serinus-inertia
SERINUS_INERTIA_ENABLE_SSR=true \
SERINUS_INERTIA_SSR_ENDPOINT=http://127.0.0.1:13714/render \
./server
```

## Step 7: systemd units

### Client-rendered app

```ini
[Unit]
Description=Serinus Inertia Example
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/serinus-inertia
ExecStart=/opt/serinus-inertia/server
Restart=on-failure
User=www-data
Group=www-data

[Install]
WantedBy=multi-user.target
```

### External SSR renderer

```ini
[Unit]
Description=Serinus Inertia SSR Renderer
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/serinus-inertia
ExecStart=/usr/bin/node /opt/serinus-inertia/client/dist/ssr.js
Restart=on-failure
User=www-data
Group=www-data

[Install]
WantedBy=multi-user.target
```

If you use the external renderer unit, add these environment variables to the
app unit:

```ini
Environment=SERINUS_INERTIA_ENABLE_SSR=true
Environment=SERINUS_INERTIA_SSR_ENDPOINT=http://127.0.0.1:13714/render
```

You can then wire the dependencies with `After=` and `Wants=` if you want the
app to wait on the renderer service.

## Step 8: Optional reverse proxy

Use a reverse proxy only when you need a front door for TLS termination,
multiple apps, host routing, or similar concerns.

### Option A: proxy everything to Serinus

This keeps the deployment simple. Serinus still serves `/assets/*` itself.

Minimal nginx example:

```nginx
server {
    listen 80;
    server_name example.com;

    location / {
        proxy_pass http://127.0.0.1:4000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Minimal Caddy example:

```caddy
example.com {
    reverse_proxy 127.0.0.1:4000
}
```

### Option B: let the proxy serve `/assets/*` directly

If you want nginx or Caddy to own static asset delivery, point the asset root
at `client/dist` and proxy everything else to the app. The request path
`/assets/main-<hash>.js` must resolve to
`/opt/serinus-inertia/client/dist/assets/main-<hash>.js` on disk.

nginx example:

```nginx
server {
    listen 80;
    server_name example.com;

    location /assets/ {
        root /opt/serinus-inertia/client/dist;
        expires 1y;
        add_header Cache-Control "public, max-age=31536000, immutable";
        try_files $uri =404;
    }

    location / {
        proxy_pass http://127.0.0.1:4000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Caddy example:

```caddy
example.com {
    handle /assets/* {
        root * /opt/serinus-inertia/client/dist
        header Cache-Control "public, max-age=31536000, immutable"
        file_server
    }

    handle {
        reverse_proxy 127.0.0.1:4000
    }
}
```

If you use this split topology, keep the proxy asset root and the app working
directory aligned with the same `client/dist` build output.

## Step 9: Docker Compose

The bundled Compose file exposes two profiles:

- `client`: one container running the compiled Dart app
- `ssr`: one renderer container plus one compiled Dart app container

Client-rendered stack:

```bash
docker compose --profile client up --build
```

Open <http://127.0.0.1:8080>.

SSR stack:

```bash
docker compose --profile ssr up --build
```

Open <http://127.0.0.1:8081>.

The SSR app waits for `ssr-renderer` to report healthy before starting.

## Smoke checks

### Client-rendered

```bash
curl -I http://127.0.0.1:4000/assets/main-<hash>.js
curl -H 'X-Inertia: true' -H 'X-Requested-With: XMLHttpRequest' http://127.0.0.1:4000/users
```

Expect:

- `200 OK` for the asset
- `Cache-Control: public, max-age=31536000, immutable`
- JSON from the Inertia request

If you put nginx or Caddy in front and let it serve assets directly, run the
same checks against the public origin instead of port `4000`.

### SSR

Load the page once and confirm the initial HTML already contains rendered app
content inside `#app`.

## Troubleshooting

- If the app tries to load assets from a Vite dev server, remove `client/public/hot`.
- If assets 404, confirm the working directory contains `client/dist/assets`.
- If assets 404 behind nginx or Caddy, confirm the proxy root points to `client/dist`, not the deployment root.
- If first visits fail, confirm `client/dist/.vite/manifest.json` exists.
- If SSR is enabled, confirm `client/dist/ssr.js` exists and the renderer is reachable on `/render`.

# Deployment

Use this file when the request is about productionizing an Inertia Dart app:
deployment guides, Dockerfiles, static asset serving, reverse proxies, SSR
runtime topology, or smoke-checking a release build.

## Local Anchors

If local project files exist, inspect equivalents of:

- `client/dist/.vite/manifest.json`
- the frontend build directory such as `client/dist/`
- deployment docs such as `DEPLOY.md`
- `Dockerfile*`, `Containerfile`, `compose.yaml`, or `compose.yml`
- systemd units, Procfiles, or platform deploy configs

If package examples are available locally, they can inform details, but the
skill must still work without them.

## Production Shape

The stable deployment pattern is:

- build the browser bundle into a frontend dist directory
- optionally build an SSR bundle such as `client/dist/ssr.js`
- run the Dart app as the dynamic origin
- serve `/assets/*` from the same deployment root, either directly from Dart or through an explicit front-door proxy
- keep a reverse proxy optional for TLS, host routing, or load-balancing rather than treating it as the only way to expose assets

## Build Outputs To Expect

For a production build, confirm these files exist before writing deployment
instructions:

- the Vite manifest, commonly `client/dist/.vite/manifest.json`
- built frontend assets, commonly `client/dist/assets/*`
- an SSR bundle when SSR is enabled

Do not treat development artefacts as deployable. In particular, the Vite hot
file must not survive into the deployment layout because it forces the server
to look for a dev server.

## Deployment Rules

1. Prefer describing the deployment root relative to the frontend dist directory and the compiled server binary.
2. Call out that the manifest path is read relative to the app working directory.
3. Tell the user when `dart run` requires a full workspace checkout because of `path:` dependencies.
4. Prefer `dart compile exe` for standalone deployments unless the project intentionally deploys the full SDK and workspace.
5. Keep SSR optional. Do not require Node or Bun unless SSR is actually enabled.
6. Do not introduce new bash or shell wrapper scripts in deployment guides. Prefer direct commands, systemd units, Docker `CMD`, Compose health checks, or orchestrator-native readiness.
7. Do not require nginx or Caddy just to serve Vite assets when the app already has a native static-file route.
8. When the user asks for the minimal Serinus-native static-file path, show `serinus_serve_static` with `ServeStaticModule(...)` before reaching for custom controllers.

## SSR Deployment Rules

Two acceptable SSR topologies exist:

1. Managed process
   - The Dart app starts Node or Bun itself.
   - The bundle path must exist inside the app container or deployment root.

2. External renderer
   - A separate process or container serves `/render` and `/health`.
   - The Dart app points at that endpoint and should wait for health in orchestrated environments.

## Docker Guidance

When editing or creating Docker docs:

- separate client-build and server-build stages from the runtime stage
- copy only the compiled server binary and frontend dist directory into the runtime image
- prefer one app container for the client-rendered path plus an optional separate SSR renderer container
- keep the renderer separate unless there is a strong reason to bundle it into the app container
- do not recommend extra `.sh` helpers for startup or deployment unless there is no native alternative in the runtime environment

It is often useful to keep client-rendered and SSR container topologies separate,
but do not force exact service names or profiles unless the project already has
them.

## Reverse Proxy Expectations

For optional nginx or Caddy examples:

- `/assets/*` must resolve under the built frontend assets directory
- hashed assets should keep long-lived immutable cache headers
- the proxy should forward non-asset routes to the Dart app without rewriting the Inertia paths
- when the guide already documents app-served assets, keep the proxy-served asset layout as an explicit alternative instead of replacing it

Do not force proxy-only guidance when the app already serves the built assets
correctly.

## Smoke Checks

When writing or updating deployment instructions, include checks for:

- first page load
- one Inertia navigation or partial reload
- manifest presence
- absence of the hot file
- SSR-rendered HTML in view source when SSR is enabled
- asset responses with cache headers from the actual serving layer in use

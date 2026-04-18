# Docker

Use this file when the request is specifically about Dockerfiles, Compose,
image layout, container startup behavior, or containerized SSR for an Inertia
Dart app. Shell command examples are fine; standalone bash wrapper scripts are
not the preferred deployment pattern.

## Local Anchors

If local project files exist, inspect equivalents of:

- `Dockerfile*` or `Containerfile`
- `compose.yaml` or `compose.yml`
- the frontend dist directory
- SSR runtime commands or health endpoints
- deployment docs for environment variables and working-directory assumptions

If package examples are available locally, they can inform details, but the
skill must still work without them.

## Container Model

A common production shape is:

- build stages for the client bundle and the Dart server binary
- an app image that runs the compiled Dart server
- for SSR, a dedicated renderer image that runs the SSR bundle

Keep that split unless the user explicitly wants a simpler single-image setup.

## Client-Rendered Dockerfile Shape

A typical client-rendered Dockerfile defines:

1. `client-build`
   - runs `npm ci`
   - runs the frontend production build

2. `server-build`
   - runs `dart pub get`
   - compiles the app to a server binary

3. `app`
   - copies only the compiled server binary and frontend dist directory
   - exposes the app port

When editing this file:

- keep the runtime image small
- avoid copying the full source tree into the final runtime stage
- preserve the frontend dist directory as the asset root the app or proxy serves from

## SSR Dockerfile Shape

SSR images commonly add:

1. `app`
   - runs the compiled Dart server
   - starts with direct `CMD` instead of a shell wrapper

2. `ssr`
   - installs production Node or Bun dependencies
   - runs the SSR bundle
   - exposes the renderer port if it is a separate container

When modifying SSR container flow:

- keep the renderer separate from the Dart app unless the user explicitly wants to merge them
- keep the renderer health endpoint part of the orchestration contract
- keep the app blocked on renderer health before startup in Compose-style environments
- prefer Compose or orchestrator readiness features over adding new shell wrappers

## Compose Patterns

It is often useful to define separate client-rendered and SSR topologies:

- client-only: app container only, or app plus optional proxy
- SSR: renderer plus app, and optionally a proxy

Preserve an existing split if the project already has one, but do not force
specific service names.

## Networking Contracts

Keep these contracts explicit:

- the app container port
- the SSR renderer port, if any
- the SSR render endpoint such as `/render`
- the SSR health endpoint such as `/health`
- any cross-container hostnames or env vars the app depends on

If you change service names in Compose, update the SSR endpoint env vars and
readiness wiring consistently.

## Static Asset Expectations

The runtime image should include the built frontend assets, and one of these
layers should serve `/assets/*`:

- the Dart app itself
- a front-door proxy such as nginx or Caddy

Keep immutable caching on hashed assets regardless of which layer serves them.

## Readiness

Prefer, in order:

1. Compose `healthcheck` plus `depends_on`
2. orchestrator-native readiness and startup ordering
3. app-level retry logic if the integration owns the SSR client
4. a shell wrapper only if the runtime environment provides no cleaner option

Do not remove the wait step unless the runtime environment provides an
equivalent readiness gate.

## Safe Editing Rules

- Update Dockerfiles, Compose, and readiness wiring together when the topology changes.
- Keep the production asset root aligned with the frontend build output.
- Keep SSR optional. Do not force Node into the client-only path.
- Prefer explicit environment variables over hard-coded cross-container hostnames when generalizing a setup.
- Do not add new bash or shell scripts to deployment guides or container flows unless unavoidable.

## Smoke Checks

For client-rendered setups:

- build and start the container stack
- confirm the first page loads
- confirm `/assets/*` is served correctly

For SSR setups:

- confirm the renderer becomes healthy
- confirm the app waits successfully, then starts
- confirm view source shows SSR-rendered markup on first load

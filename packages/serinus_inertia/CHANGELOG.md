## 0.1.0

- Initial release of the Serinus adapter package for `inertia_dart`.
- Added `InertiaModule`, `InertiaService`, and `SerinusInertiaOptions` for
  configurable app-wide defaults.
- Added module-level asset and SSR options so default HTML responses can inject
  Vite client tags and SSR output.
- Added request/header extraction helpers and response application helpers.
- Added `RequestContext` extensions for building page data, full Inertia
  responses, and location responses.
- Added `serinus_inertia` CLI commands for `ssr:start`, `ssr:check`, and `ssr:stop`.
- Added a full Serinus + Vite example app with an optional SSR bundle.

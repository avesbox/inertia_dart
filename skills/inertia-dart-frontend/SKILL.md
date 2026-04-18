---
name: inertia-dart-frontend
description: Guide LLMs to build, extend, and deploy Inertia Dart frontends efficiently across `inertia_dart`, `routed_inertia`, and `serinus_inertia`. Use when requests involve creating pages or components, wiring a Vite client, mapping Dart-side `component` names to frontend files, installing or scaffolding an Inertia client, adding SSR, or preparing Docker, static-serving, reverse-proxy, or production deployment flows for an Inertia-based Dart project.
---

# Inertia Dart Frontend

Build on the package's existing conventions instead of inventing a new Inertia stack. Detect the server integration first, then load only the reference file that matches the current project.

## Workflow

1. Detect the server integration before editing frontend files.

- Inspect `pubspec.yaml`, imports, and existing route handlers.
- If the project uses `package:serinus/serinus.dart`, read `references/serinus.md`.
- If the project uses `package:routed/routed.dart`, read `references/routed.md`.
- Otherwise treat it as a raw `inertia_dart` app and read `references/dart-io.md`.
- For any frontend task, also read `references/client-patterns.md`.
- If the request mentions deployment, manifests, static asset serving, reverse proxies, or production SSR, also read `references/deployment.md`.
- If the request mentions Docker, Dockerfiles, Compose, container images, or container startup flow, also read `references/docker.md`.

2. Prefer official scaffolding over hand-rolled setup.

- Use `dart run inertia_dart:inertia create <name> --framework <react|vue|svelte>` for a new client.
- Use `dart run inertia_dart:inertia install --framework <react|vue|svelte> --path <dir>` for an existing Vite project.
- Default to React only when the project has no established adapter and the user did not choose one.
- If the project already has `client/src/main.*`, `client/src/ssr.*`, or a pages directory, extend that structure instead of re-scaffolding it.

3. Preserve the server-to-client component contract exactly.

- Match `component: 'Home'` to `client/src/Pages/Home.*`.
- Match nested names like `Users/Index` to `client/src/Pages/Users/Index.*`.
- Keep the scaffolded `import.meta.glob('./Pages/**/*.jsx', { eager: true })` style resolver pattern, adapted to the current framework and extension.
- Do not rename component strings on the Dart side without updating the matching frontend file paths.

4. Keep rendering mode honest.

- For Inertia requests, return JSON page payloads and do not wrap them in HTML.
- For first visits, either let the integration render HTML or render `renderInertiaBootstrap(page, body: ssr?.body)` plus resolved asset tags.
- Add SSR only when the user asked for it or the project already contains an SSR runtime and entry file.

5. Use advanced Inertia props only when they change behavior meaningfully.

- Use plain serializable props by default.
- Use `LazyProp` or `OptionalProp` for expensive partial reload data.
- Use `DeferredProp` for non-critical sections that should load after first paint.
- Use `MergeProp` and `ScrollProp` for append, prepend, and infinite-scroll flows.
- Use `OnceProp` for values that should not keep re-resolving.

6. Validate the loop before stopping.

- Check that component names resolve to real page files.
- Check that dev assets come from the Vite hot file in development and the manifest in production.
- If SSR is enabled, check that the runtime endpoint and bundle path both exist.
- When feasible, run the Dart server and the client dev server together and confirm the first visit and one Inertia navigation work.
- For deployment work, confirm the production build outputs exist and that static assets resolve from the deployment target actually in use, whether that is the Dart process or an explicit proxy.
- For deployment and container work, prefer direct commands and declarative config over new bash wrapper scripts.

## References

- Read `references/client-patterns.md` for shared frontend rules, file naming, commands, and SSR/client conventions.
- Read `references/dart-io.md` for raw `inertia_dart` apps built on `dart:io`.
- Read `references/routed.md` for `routed_inertia` apps.
- Read `references/serinus.md` for `serinus_inertia` apps.
- Read `references/deployment.md` for production build, static serving, Docker, proxy, and SSR runtime guidance.
- Read `references/docker.md` for Dockerfiles, Compose profiles, native Serinus asset serving, and SSR container startup guidance.

## Output Expectations

- State which integration and client adapter you are targeting before making structural changes.
- Reuse the project's existing file names and directory layout where possible.
- Prefer direct code edits and commands over long architectural explanations.

# inertia_dart

Dart implementation of the [Inertia.js](https://inertiajs.com) server-side protocol. Build
single-page apps without building an API — pair any Dart HTTP server with a client adapter
like `@inertiajs/react`, `@inertiajs/vue3`, or `@inertiajs/svelte`.

## Packages

| Package | pub.dev | Description |
| --- | --- | --- |
| [`inertia_dart`](packages/inertia) | [![pub](https://img.shields.io/pub/v/inertia_dart.svg)](https://pub.dev/packages/inertia_dart) | Core protocol — framework-agnostic props, SSR, asset helpers, and testing utilities |
| [`routed_inertia`](packages/routed_inertia) | [![pub](https://img.shields.io/pub/v/routed_inertia.svg)](https://pub.dev/packages/routed_inertia) | [Routed](https://pub.dev/packages/routed) integration — middleware, `EngineContext` helpers, config-driven setup, and SSR |
| [`serinus_inertia`](packages/serinus_inertia) | [![pub](https://img.shields.io/pub/v/serinus_inertia.svg)](https://pub.dev/packages/serinus_inertia) | [Serinus](https://pub.dev/packages/serinus) integration — `InertiaModule`, `RequestContext.inertia()`, and managed SSR |

---

### `inertia_dart` — Core Package

The framework-agnostic foundation. Use it directly with `dart:io` or as the
building block for higher-level integrations.

```dart
import 'package:inertia_dart/inertia_dart.dart';

final request = inertiaRequestFromHttp(httpRequest);
final page = InertiaResponseFactory().buildPageData(
  component: 'Dashboard',
  props: {
    'user': {'name': 'Ada'},
    'stats': LazyProp(() => loadStats()),
  },
  url: request.url,
  context: request.createContext(),
  version: '1.0.0',
);

await writeInertiaResponse(httpRequest.response, InertiaResponse.json(page));
```

[Full docs →](https://kingwill101.github.io/docs/inertia_dart/)

---

### `serinus_inertia` — Serinus Integration

Provides a first-class [Serinus](https://pub.dev/packages/serinus) experience via
`InertiaModule` and `RequestContext.inertia()`.

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
            ),
          ),
        ],
        controllers: [AppController()],
      );
}
```

```dart
class AppController extends Controller {
  AppController() : super('/') {
    on(Route.get('/'), (context) async {
      return context.inertia(
        component: 'Home',
        props: {'title': 'Hello from Serinus'},
      );
    });
  }
}
```

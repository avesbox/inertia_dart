import 'dart:io';

import 'package:inertia_dart/inertia_dart.dart';
import 'package:routed/routed.dart';
import 'package:routed/providers.dart';
import 'package:routed_inertia/routed_inertia.dart';

void main() async {
  final configRoot = _resolveExamplePath(
    packageRootPath: 'example/config',
    repoRootPath: 'packages/routed_inertia/example/config',
  );
  final assetsRoot = _resolveExamplePath(
    packageRootPath: 'example/client',
    repoRootPath: 'packages/routed_inertia/example/client',
  );

  registerRoutedInertiaProvider(ProviderRegistry.instance);

  final devServer = Platform.environment['INERTIA_DEV'] != 'false';
  final engine = Engine(
    providers: [
      CoreServiceProvider.withLoader(
        ConfigLoaderOptions(configDirectory: configRoot.path),
      ),
      RoutingServiceProvider(),
    ],
  );

  final config = _resolveInertiaConfig(engine);
  final ssrEnabled = _boolEnv(
    'INERTIA_SSR',
    defaultValue: config?.ssr.enabled ?? false,
  );
  final ssrGateway = _resolveSsrGateway(config, enabled: ssrEnabled);
  final assets = devServer
      ? _devAssetTags(_resolveDevServerOrigin(config?.assets, assetsRoot))
      : await _loadManifestAssets(config?.assets, assetsRoot);
  String htmlBuilder(PageData page, SsrResponse? ssr) =>
      _renderHtml(page, assets: assets, ssr: ssr);

  engine.get('/assets/{*filepath}', (ctx) {
    final filePath = ctx.mustGetParam<String>('filepath');
    return ctx.file(_joinExamplePath(assetsRoot, 'dist/assets/$filePath'));
  });

  engine.get('/', (ctx) {
    return ctx.inertia(
      'Home',
      props: {
        'title': 'Routed + Inertia',
        'subtitle': 'Server-driven pages with a React frontend',
        'links': [
          {'label': 'Home', 'href': '/'},
          {'label': 'Users', 'href': '/users'},
        ],
      },
      htmlBuilder: htmlBuilder,
      ssrEnabled: ssrEnabled,
      ssrGateway: ssrGateway,
    );
  });

  engine.get('/users', (ctx) {
    return ctx.inertia(
      'Users/Index',
      props: {
        'title': 'Users',
        'users': [
          {'id': 1, 'name': 'Ada Lovelace'},
          {'id': 2, 'name': 'Grace Hopper'},
          {'id': 3, 'name': 'Alan Turing'},
        ],
        'links': [
          {'label': 'Home', 'href': '/'},
          {'label': 'Users', 'href': '/users'},
        ],
      },
      htmlBuilder: htmlBuilder,
      ssrEnabled: ssrEnabled,
      ssrGateway: ssrGateway,
    );
  });

  await engine.serve(port: 8080);
}

String _renderHtml(
  PageData page, {
  required AssetTags assets,
  SsrResponse? ssr,
}) {
  final title = page.props['title']?.toString() ?? 'Routed Inertia';
  final headTags = ssr?.head ?? '';
  final styleTags = assets.styles.join('\n    ');
  final scriptTags = assets.scripts.join('\n    ');

  return '''<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="icon" href="data:,">
    $headTags
    <title>$title</title>
    ${styleTags.isEmpty ? '' : styleTags}
  </head>
  <body>
    ${renderInertiaBootstrap(page, body: ssr?.body)}
    ${scriptTags.trim()}
  </body>
</html>
''';
}

class AssetTags {
  const AssetTags({this.styles = const [], this.scripts = const []});

  final List<String> styles;
  final List<String> scripts;
}

AssetTags _devAssetTags(String devOrigin) {
  final scripts = <String>[
    '<script type="module" src="$devOrigin/@vite/client"></script>',
    '''<script type="module">
  import RefreshRuntime from '$devOrigin/@react-refresh'
  RefreshRuntime.injectIntoGlobalHook(window)
  window.
    \$RefreshReg\$ = () => {}
  window.
    \$RefreshSig\$ = () => (type) => type
  window.
    __vite_plugin_react_preamble_installed__ = true
</script>''',
    '<script type="module" src="$devOrigin/src/main.jsx"></script>',
  ];

  return AssetTags(scripts: scripts);
}

String _resolveDevServerOrigin(
  InertiaAssetsConfig? assets,
  Directory assetsRoot,
) {
  final env = Platform.environment;
  final direct = env['INERTIA_DEV_SERVER_URL'] ?? env['VITE_DEV_SERVER_URL'];
  if (direct != null && direct.trim().isNotEmpty) {
    return _trimTrailingSlash(direct.trim());
  }

  final configUrl = assets?.resolveDevServerUrl();
  if (configUrl != null && configUrl.isNotEmpty) {
    return _trimTrailingSlash(configUrl);
  }

  final hotFile = File(_joinExamplePath(assetsRoot, 'public/hot'));
  if (hotFile.existsSync()) {
    final contents = hotFile.readAsStringSync().trim();
    if (contents.isNotEmpty) {
      return _trimTrailingSlash(contents);
    }
  }

  final host = env['INERTIA_DEV_SERVER_HOST'] ?? env['VITE_DEV_SERVER_HOST'];
  final port = env['INERTIA_DEV_SERVER_PORT'] ?? env['VITE_DEV_SERVER_PORT'];
  if (host == null || host.trim().isEmpty || port == null || port.isEmpty) {
    throw StateError(
      'Set INERTIA_DEV_SERVER_URL (or VITE_DEV_SERVER_URL), provide '
      'INERTIA_DEV_SERVER_HOST and INERTIA_DEV_SERVER_PORT, or start Vite '
      'with the hot file enabled for dev mode.',
    );
  }

  final scheme =
      env['INERTIA_DEV_SERVER_SCHEME'] ??
      env['VITE_DEV_SERVER_SCHEME'] ??
      'http';
  return _trimTrailingSlash('$scheme://${host.trim()}:${port.trim()}');
}

Future<AssetTags> _loadManifestAssets(
  InertiaAssetsConfig? assets,
  Directory assetsRoot,
) async {
  final manifestPath = assets?.manifestPath?.trim().isNotEmpty == true
      ? assets!.manifestPath!
      : _joinExamplePath(assetsRoot, 'dist/.vite/manifest.json');
  final entry = assets?.entry ?? 'index.html';
  final baseUrl = assets?.baseUrl ?? '/';
  final manifestFile = File(manifestPath);

  if (!manifestFile.existsSync()) {
    return const AssetTags(
      scripts: ['<script type="module" src="/assets/main.js"></script>'],
    );
  }

  final manifest = await InertiaAssetManifest.load(manifestPath);
  final styles = manifest.styleTags(entry, baseUrl: baseUrl);
  final scripts = manifest.scriptTags(entry, baseUrl: baseUrl);
  return AssetTags(styles: styles, scripts: scripts);
}

InertiaConfig? _resolveInertiaConfig(Engine engine) {
  if (!engine.container.has<InertiaConfig>()) {
    return null;
  }
  try {
    return engine.container.get<InertiaConfig>();
  } catch (_) {
    return null;
  }
}

SsrGateway? _resolveSsrGateway(InertiaConfig? config, {required bool enabled}) {
  if (!enabled || config == null) {
    return null;
  }

  if (config.ssrGateway != null) {
    return config.ssrGateway;
  }

  final endpoint = config.ssr.resolveRenderEndpoint();
  if (endpoint == null) {
    return null;
  }

  return HttpSsrGateway(
    endpoint,
    healthEndpoint: config.ssr.resolveHealthEndpoint(),
  );
}

String _trimTrailingSlash(String value) {
  if (value.endsWith('/')) {
    return value.substring(0, value.length - 1);
  }
  return value;
}

Directory _resolveExamplePath({
  required String packageRootPath,
  required String repoRootPath,
}) {
  final packageRoot = Directory(packageRootPath);
  if (packageRoot.existsSync()) {
    return packageRoot;
  }

  final repoRoot = Directory(repoRootPath);
  if (repoRoot.existsSync()) {
    return repoRoot;
  }

  throw StateError(
    'Unable to find example directory at "$packageRootPath" or "$repoRootPath".',
  );
}

String _joinExamplePath(Directory root, String relativePath) {
  final sanitized = relativePath.startsWith('/')
      ? relativePath.substring(1)
      : relativePath;
  return '${root.path}/$sanitized';
}

bool _boolEnv(String key, {required bool defaultValue}) {
  final raw = Platform.environment[key];
  if (raw == null) return defaultValue;
  final value = raw.toLowerCase().trim();
  if (value == 'true' || value == '1' || value == 'yes') return true;
  if (value == 'false' || value == '0' || value == 'no') return false;
  return defaultValue;
}

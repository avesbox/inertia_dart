library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:inertia_dart/inertia_dart.dart';
import 'package:serinus/serinus.dart';

/// Builds shared props for every Inertia response in a request.
typedef InertiaSharedPropsBuilder =
    FutureOr<Map<String, dynamic>> Function(RequestContext<dynamic> context);

/// Wraps the Inertia bootstrap markup in a full HTML response.
typedef InertiaHtmlBuilder =
    FutureOr<String> Function(
      RequestContext<dynamic> context,
      PageData page,
      String bootstrap,
    );

/// Starts an external SSR process for [InertiaSsrProcessManager].
typedef StartSsrServerCallback =
    Future<Process> Function(SsrServerConfig config, {bool inheritStdio});

/// Checks whether an external SSR process is ready to accept requests.
typedef CheckSsrServerCallback =
    Future<bool> Function({required Uri endpoint, Uri? healthEndpoint});

/// Stops an external SSR process that was started for Inertia rendering.
typedef StopSsrServerCallback =
    Future<bool> Function({required Uri endpoint, Uri? shutdownEndpoint});

const String _defaultManagedSsrRenderUrl = 'http://127.0.0.1:13714/render';
const List<String> _defaultManagedSsrBundleCandidates = [
  'client/dist/ssr.js',
  'client/dist/ssr.mjs',
  'client/dist/server/entry-server.js',
  'client/dist/server/entry-server.mjs',
  'bootstrap/ssr/ssr.js',
  'bootstrap/ssr/ssr.mjs',
];

/// Module-level Vite asset configuration.
class InertiaAssetsOptions {
  /// Creates a new Vite asset configuration.
  const InertiaAssetsOptions({
    this.entry = 'index.html',
    this.clientDirectory = 'client',
    this.manifestPath,
    this.hotFile,
    this.baseUrl = '/',
    this.devServerUrl,
    this.includeReactRefresh = false,
    this.fallbackScript,
  });

  /// The Vite entry file.
  final String entry;

  /// Base client application directory used for derived defaults.
  final String clientDirectory;

  /// Optional manifest path override.
  final String? manifestPath;

  /// Optional Vite hot file override.
  final String? hotFile;

  /// Public base URL for built assets.
  final String baseUrl;

  /// Optional explicit dev server URL.
  final String? devServerUrl;

  /// Whether to include the React refresh preamble in dev mode.
  final bool includeReactRefresh;

  /// Fallback script used when no manifest exists.
  final String? fallbackScript;

  /// Builds an [InertiaViteAssets] resolver from these options.
  InertiaViteAssets toViteAssets() {
    return InertiaViteAssets(
      entry: entry,
      manifestPath: manifestPath ?? '$clientDirectory/dist/.vite/manifest.json',
      hotFile: hotFile ?? '$clientDirectory/public/hot',
      baseUrl: baseUrl,
      devServerUrl: devServerUrl,
      includeReactRefresh: includeReactRefresh,
      fallbackScript: fallbackScript,
    );
  }

  /// Returns a copy with updated fields.
  InertiaAssetsOptions copyWith({
    String? entry,
    String? clientDirectory,
    String? manifestPath,
    String? hotFile,
    String? baseUrl,
    String? devServerUrl,
    bool? includeReactRefresh,
    String? fallbackScript,
  }) {
    return InertiaAssetsOptions(
      entry: entry ?? this.entry,
      clientDirectory: clientDirectory ?? this.clientDirectory,
      manifestPath: manifestPath ?? this.manifestPath,
      hotFile: hotFile ?? this.hotFile,
      baseUrl: baseUrl ?? this.baseUrl,
      devServerUrl: devServerUrl ?? this.devServerUrl,
      includeReactRefresh: includeReactRefresh ?? this.includeReactRefresh,
      fallbackScript: fallbackScript ?? this.fallbackScript,
    );
  }
}

/// Module-level SSR configuration.
class InertiaSsrOptions {
  /// Creates a new SSR configuration.
  const InertiaSsrOptions({
    this.enabled = false,
    this.gateway,
    this.endpoint,
    this.healthEndpoint,
    this.shutdownEndpoint,
    this.manageProcess = false,
    this.runtime = 'node',
    this.runtimeArgs = const [],
    this.bundle,
    this.bundleCandidates = const [],
    this.workingDirectory,
    this.environment = const {},
    this.waitUntilReady = true,
    this.startupTimeout = const Duration(seconds: 5),
    this.healthCheckInterval = const Duration(milliseconds: 100),
  });

  /// Whether SSR is enabled.
  final bool enabled;

  /// Optional injected gateway implementation.
  final SsrGateway? gateway;

  /// Optional HTTP render endpoint used when [gateway] is omitted.
  final Uri? endpoint;

  /// Optional health check endpoint for the default HTTP gateway.
  final Uri? healthEndpoint;

  /// Optional shutdown endpoint for a managed SSR process.
  final Uri? shutdownEndpoint;

  /// Whether Serinus should manage the external SSR process lifecycle.
  final bool manageProcess;

  /// Runtime used to launch the managed SSR process.
  final String runtime;

  /// Additional arguments passed to the managed runtime.
  final List<String> runtimeArgs;

  /// Explicit SSR bundle path for the managed runtime.
  final String? bundle;

  /// Additional bundle candidates checked when [bundle] is omitted.
  final List<String> bundleCandidates;

  /// Working directory used to resolve bundle paths.
  final Directory? workingDirectory;

  /// Environment variables passed to the managed runtime.
  final Map<String, String> environment;

  /// Whether bootstrap should wait for the managed process health check.
  final bool waitUntilReady;

  /// Maximum time to wait for the managed SSR process to become healthy.
  final Duration startupTimeout;

  /// Poll interval used while waiting for the managed SSR process.
  final Duration healthCheckInterval;

  /// Resolves the effective render endpoint.
  Uri? resolveRenderEndpoint() {
    if (endpoint != null) {
      if (endpoint!.path.endsWith('/render')) return endpoint;
      return endpoint!.resolve('/render');
    }
    if (manageProcess) {
      return Uri.parse(_defaultManagedSsrRenderUrl);
    }
    return null;
  }

  /// Resolves the effective base endpoint.
  Uri? resolveBaseEndpoint() {
    final renderEndpoint = resolveRenderEndpoint();
    if (renderEndpoint == null) return null;
    if (!renderEndpoint.path.endsWith('/render')) {
      return renderEndpoint;
    }
    final basePath = renderEndpoint.path.substring(
      0,
      renderEndpoint.path.length - '/render'.length,
    );
    return renderEndpoint.replace(path: basePath.isEmpty ? '/' : basePath);
  }

  /// Resolves the effective health endpoint.
  Uri? resolveHealthEndpoint() {
    if (healthEndpoint != null) return healthEndpoint;
    return resolveBaseEndpoint()?.resolve('/health');
  }

  /// Resolves the effective shutdown endpoint.
  Uri? resolveShutdownEndpoint() {
    if (shutdownEndpoint != null) return shutdownEndpoint;
    return resolveBaseEndpoint()?.resolve('/shutdown');
  }

  /// Builds the managed SSR process configuration, if enabled.
  SsrServerConfig? createServerConfig() {
    if (!manageProcess) return null;
    return SsrServerConfig(
      runtime: runtime,
      bundle: bundle,
      runtimeArgs: runtimeArgs,
      bundleCandidates: [
        ...bundleCandidates,
        ..._defaultManagedSsrBundleCandidates,
      ],
      workingDirectory: workingDirectory,
      environment: environment,
    );
  }

  /// Creates the effective SSR gateway, if configured.
  SsrGateway? createGateway() {
    if (!enabled) return null;
    if (gateway != null) return gateway;
    final renderEndpoint = resolveRenderEndpoint();
    if (renderEndpoint != null) {
      return HttpSsrGateway(
        renderEndpoint,
        healthEndpoint: resolveHealthEndpoint(),
      );
    }
    return null;
  }

  /// Returns a copy with updated fields.
  InertiaSsrOptions copyWith({
    bool? enabled,
    SsrGateway? gateway,
    Uri? endpoint,
    Uri? healthEndpoint,
    Uri? shutdownEndpoint,
    bool? manageProcess,
    String? runtime,
    List<String>? runtimeArgs,
    String? bundle,
    List<String>? bundleCandidates,
    Directory? workingDirectory,
    Map<String, String>? environment,
    bool? waitUntilReady,
    Duration? startupTimeout,
    Duration? healthCheckInterval,
  }) {
    return InertiaSsrOptions(
      enabled: enabled ?? this.enabled,
      gateway: gateway ?? this.gateway,
      endpoint: endpoint ?? this.endpoint,
      healthEndpoint: healthEndpoint ?? this.healthEndpoint,
      shutdownEndpoint: shutdownEndpoint ?? this.shutdownEndpoint,
      manageProcess: manageProcess ?? this.manageProcess,
      runtime: runtime ?? this.runtime,
      runtimeArgs: runtimeArgs ?? this.runtimeArgs,
      bundle: bundle ?? this.bundle,
      bundleCandidates: bundleCandidates ?? this.bundleCandidates,
      workingDirectory: workingDirectory ?? this.workingDirectory,
      environment: environment ?? this.environment,
      waitUntilReady: waitUntilReady ?? this.waitUntilReady,
      startupTimeout: startupTimeout ?? this.startupTimeout,
      healthCheckInterval: healthCheckInterval ?? this.healthCheckInterval,
    );
  }
}

/// Module-level configuration for the Serinus Inertia integration.
class InertiaOptions {
  /// Creates a new options object.
  const InertiaOptions({
    this.version = '',
    this.encryptHistory = false,
    this.clearHistory = false,
    this.elementId = 'app',
    this.sharedProps,
    this.htmlBuilder,
    this.assets,
    this.ssr = const InertiaSsrOptions(),
  });

  /// The asset version sent with every page.
  final String version;

  /// Whether history entries should be encrypted by default.
  final bool encryptHistory;

  /// Whether history entries should be cleared by default.
  final bool clearHistory;

  /// The DOM element id used for the root Inertia mount point.
  final String elementId;

  /// Shared props resolved for every page response.
  final InertiaSharedPropsBuilder? sharedProps;

  /// Optional HTML wrapper used for first visits.
  final InertiaHtmlBuilder? htmlBuilder;

  /// Optional Vite asset settings used by the default HTML wrapper.
  final InertiaAssetsOptions? assets;

  /// SSR configuration for first visits.
  final InertiaSsrOptions ssr;

  /// Returns a copy with updated fields.
  InertiaOptions copyWith({
    String? version,
    bool? encryptHistory,
    bool? clearHistory,
    String? elementId,
    InertiaSharedPropsBuilder? sharedProps,
    InertiaHtmlBuilder? htmlBuilder,
    InertiaAssetsOptions? assets,
    InertiaSsrOptions? ssr,
  }) {
    return InertiaOptions(
      version: version ?? this.version,
      encryptHistory: encryptHistory ?? this.encryptHistory,
      clearHistory: clearHistory ?? this.clearHistory,
      elementId: elementId ?? this.elementId,
      sharedProps: sharedProps ?? this.sharedProps,
      htmlBuilder: htmlBuilder ?? this.htmlBuilder,
      assets: assets ?? this.assets,
      ssr: ssr ?? this.ssr,
    );
  }
}

/// Provider used by [InertiaModule] to expose Inertia defaults.
class InertiaService extends Provider {
  /// Creates a new service with module-level [options].
  const InertiaService({this.options = const InertiaOptions()});

  /// The configured module options.
  final InertiaOptions options;
}

/// Manages an optional external SSR runtime for Serinus.
class InertiaSsrProcessManager extends Provider
    with OnApplicationBootstrap, OnApplicationShutdown {
  /// Creates a new managed SSR process provider.
  InertiaSsrProcessManager({
    required this.options,
    StartSsrServerCallback? startSsrServer,
    CheckSsrServerCallback? checkSsrServer,
    StopSsrServerCallback? stopSsrServer,
    StringSink? stdoutSink,
    StringSink? stderrSink,
  }) : _startSsrServer = startSsrServer ?? startSsrServerDefault,
       _checkSsrServer = checkSsrServer ?? checkSsrServerDefault,
       _stopSsrServer = stopSsrServer ?? stopSsrServerDefault,
       _stdoutSink = stdoutSink ?? stdout,
       _stderrSink = stderrSink ?? stderr;

  /// The configured module options.
  final InertiaOptions options;

  final StartSsrServerCallback _startSsrServer;
  final CheckSsrServerCallback _checkSsrServer;
  final StopSsrServerCallback _stopSsrServer;
  final StringSink _stdoutSink;
  final StringSink _stderrSink;

  Process? _process;
  bool _ownsProcess = false;
  int? _exitCode;
  StreamSubscription<String>? _stdoutSubscription;
  StreamSubscription<String>? _stderrSubscription;

  static Future<Process> startSsrServerDefault(
    SsrServerConfig config, {
    bool inheritStdio = false,
  }) => startSsrServer(config, inheritStdio: inheritStdio);

  static Future<bool> checkSsrServerDefault({
    required Uri endpoint,
    Uri? healthEndpoint,
  }) => checkSsrServer(endpoint: endpoint, healthEndpoint: healthEndpoint);

  static Future<bool> stopSsrServerDefault({
    required Uri endpoint,
    Uri? shutdownEndpoint,
  }) => stopSsrServer(endpoint: endpoint, shutdownEndpoint: shutdownEndpoint);

  /// Starts the managed SSR process when this module owns the renderer.
  @override
  Future<void> onApplicationBootstrap() async {
    final ssr = options.ssr;
    if (!ssr.manageProcess) return;

    final baseEndpoint = ssr.resolveBaseEndpoint();
    final healthEndpoint = ssr.resolveHealthEndpoint();
    if (baseEndpoint != null) {
      try {
        final healthy = await _checkSsrServer(
          endpoint: baseEndpoint,
          healthEndpoint: healthEndpoint,
        );
        if (healthy) {
          return;
        }
      } catch (_) {
        // Fall through and attempt to start a managed process.
      }
    }

    final config = ssr.createServerConfig();
    if (config == null) return;

    final process = await _startSsrServer(config, inheritStdio: false);
    _process = process;
    _ownsProcess = true;
    _attachOutput(process);
    unawaited(
      process.exitCode.then((code) async {
        _exitCode = code;
        await _cancelOutputSubscriptions();
        _process = null;
        _ownsProcess = false;
      }),
    );

    if (ssr.waitUntilReady && baseEndpoint != null) {
      await _waitUntilHealthy(
        endpoint: baseEndpoint,
        healthEndpoint: healthEndpoint,
        timeout: ssr.startupTimeout,
        interval: ssr.healthCheckInterval,
      );
    }
  }

  /// Stops the managed SSR process during Serinus shutdown.
  @override
  Future<void> onApplicationShutdown() async {
    final process = _process;
    final ssr = options.ssr;
    if (!_ownsProcess || process == null) {
      await _cancelOutputSubscriptions();
      return;
    }

    final baseEndpoint = ssr.resolveBaseEndpoint();
    final shutdownEndpoint = ssr.resolveShutdownEndpoint();
    var stopped = false;
    if (baseEndpoint != null) {
      stopped = await _stopSsrServer(
        endpoint: baseEndpoint,
        shutdownEndpoint: shutdownEndpoint,
      );
    }

    if (!stopped) {
      _killProcess(process, ProcessSignal.sigterm);
    }

    try {
      await process.exitCode.timeout(const Duration(seconds: 2));
    } catch (_) {
      _killProcess(process, ProcessSignal.sigkill);
      try {
        await process.exitCode.timeout(const Duration(seconds: 1));
      } catch (_) {}
    } finally {
      await _cancelOutputSubscriptions();
      _process = null;
      _ownsProcess = false;
    }
  }

  void _attachOutput(Process process) {
    _stdoutSubscription = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          if (line.trim().isEmpty) return;
          _stdoutSink.writeln(line);
        });
    _stderrSubscription = process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          if (line.trim().isEmpty) return;
          _stderrSink.writeln(line);
        });
  }

  Future<void> _cancelOutputSubscriptions() async {
    await _stdoutSubscription?.cancel();
    await _stderrSubscription?.cancel();
    _stdoutSubscription = null;
    _stderrSubscription = null;
  }

  Future<void> _waitUntilHealthy({
    required Uri endpoint,
    Uri? healthEndpoint,
    required Duration timeout,
    required Duration interval,
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (_exitCode != null) {
        throw StateError(
          'Managed SSR process exited with code $_exitCode before becoming healthy.',
        );
      }

      try {
        final healthy = await _checkSsrServer(
          endpoint: endpoint,
          healthEndpoint: healthEndpoint,
        );
        if (healthy) return;
      } catch (_) {}

      await Future<void>.delayed(interval);
    }

    throw StateError(
      'Managed SSR process did not become healthy within ${timeout.inSeconds}s.',
    );
  }

  void _killProcess(
    Process process, [
    ProcessSignal signal = ProcessSignal.sigterm,
  ]) {
    try {
      process.kill(signal);
    } on UnsupportedError {
      process.kill();
    } on SignalException {
      process.kill();
    }
  }
}

/// Serinus module that registers configurable Inertia defaults.
class InertiaModule extends Module {
  /// Creates a new Inertia module with the provided [options].
  InertiaModule({InertiaOptions options = const InertiaOptions()})
    : super(
        providers: [
          InertiaService(options: options),
          InertiaSsrProcessManager(options: options),
          Provider.forValue<InertiaOptions>(options),
        ],
        exports: [InertiaService],
        isGlobal: true,
      );
}

/// Builds an [InertiaRequest] from a Serinus [Request].
InertiaRequest inertiaRequestFromSerinus(Request request) {
  return InertiaRequest(
    headers: request.headers.asFullMap(),
    url: request.uri.toString(),
    method: request.method.name.toUpperCase(),
    body: request.body,
  );
}

/// Applies an [InertiaResponse] to a Serinus [ResponseContext].
void applyInertiaResponse(
  ResponseContext response,
  InertiaResponse inertiaResponse,
) {
  response.statusCode = inertiaResponse.statusCode;

  for (final entry in inertiaResponse.headers.entries) {
    if (entry.key.toLowerCase() == HttpHeaders.contentTypeHeader) {
      response.contentType = ContentType.parse(entry.value);
      continue;
    }
    response.addHeader(entry.key, entry.value);
  }
}

/// Adds request helpers for adapting Serinus requests to Inertia.
extension SerinusInertiaRequestExtension on Request {
  /// Returns the current request as an [InertiaRequest].
  InertiaRequest get inertiaRequest => inertiaRequestFromSerinus(this);
}

/// Adds Inertia helpers to Serinus route handlers.
extension SerinusInertiaRequestContextExtension<TBody>
    on RequestContext<TBody> {
  /// Returns the configured Inertia service, or fallback defaults.
  InertiaService get inertiaService {
    if (!canUse<InertiaService>()) {
      throw StateError(
        'InertiaService is not available in the current context. '
        'Make sure InertiaModule is imported and registered in the application.',
      );
    }
    return use<InertiaService>();
  }

  /// Returns the configured module options, or fallback defaults.
  InertiaOptions get inertiaOptions => inertiaService.options;

  /// Returns the current request as an [InertiaRequest].
  InertiaRequest get inertiaRequest => request.inertiaRequest;

  /// Creates a [PropertyContext] from the current request headers.
  PropertyContext createInertiaContext({
    List<String> requestedProps = const [],
    List<String> requestedExceptProps = const [],
    List<String> requestedDeferredGroups = const [],
    String? onceKey,
    bool Function(String key)? shouldIncludeProp,
  }) {
    return inertiaRequest.createContext(
      requestedProps: requestedProps,
      requestedExceptProps: requestedExceptProps,
      requestedDeferredGroups: requestedDeferredGroups,
      onceKey: onceKey,
      shouldIncludeProp: shouldIncludeProp,
    );
  }

  /// Resolves page data for the current request.
  Future<PageData> buildInertiaPageData({
    required String component,
    required Map<String, dynamic> props,
    String? url,
    PropertyContext? context,
    String? version,
    bool? encryptHistory,
    bool? clearHistory,
    Map<String, dynamic>? flash,
    List<int>? cache,
    Map<String, dynamic>? sharedProps,
  }) async {
    final resolvedProps = <String, dynamic>{
      ...await _resolveSharedProps(sharedProps),
      ...props,
    };

    return InertiaResponseFactory().buildPageDataAsync(
      component: component,
      props: resolvedProps,
      url: url ?? request.uri.toString(),
      context: context ?? createInertiaContext(),
      version: version ?? inertiaOptions.version,
      encryptHistory: encryptHistory ?? inertiaOptions.encryptHistory,
      clearHistory: clearHistory ?? inertiaOptions.clearHistory,
      flash: flash,
      cache: cache,
    );
  }

  /// Builds an [InertiaResponse] for the current request.
  Future<InertiaResponse> buildInertiaResponse({
    required String component,
    required Map<String, dynamic> props,
    String? url,
    PropertyContext? context,
    String? version,
    bool? encryptHistory,
    bool? clearHistory,
    Map<String, dynamic>? flash,
    List<int>? cache,
    int statusCode = 200,
    String? elementId,
    String? ssrBody,
    Map<String, dynamic>? sharedProps,
    InertiaHtmlBuilder? htmlBuilder,
  }) async {
    final page = await buildInertiaPageData(
      component: component,
      props: props,
      url: url,
      context: context,
      version: version,
      encryptHistory: encryptHistory,
      clearHistory: clearHistory,
      flash: flash,
      cache: cache,
      sharedProps: sharedProps,
    );

    if (inertiaRequest.isInertia) {
      return InertiaResponse.json(page, statusCode: statusCode);
    }

    final ssr = await _resolveSsr(page);
    final bootstrap = renderInertiaBootstrap(
      page,
      id: elementId ?? inertiaOptions.elementId,
      body: ssrBody ?? ssr?.body,
    );
    final resolvedHtmlBuilder = htmlBuilder ?? inertiaOptions.htmlBuilder;
    final html = resolvedHtmlBuilder == null
        ? await _renderDefaultHtml(bootstrap, ssr?.head)
        : await resolvedHtmlBuilder(this, page, bootstrap);

    return InertiaResponse.html(page, html, statusCode: statusCode);
  }

  /// Applies an Inertia response to [res] and returns the response body.
  Future<Object?> inertia({
    required String component,
    required Map<String, dynamic> props,
    String? url,
    PropertyContext? context,
    String? version,
    bool? encryptHistory,
    bool? clearHistory,
    Map<String, dynamic>? flash,
    List<int>? cache,
    int statusCode = 200,
    String? elementId,
    String? ssrBody,
    Map<String, dynamic>? sharedProps,
    InertiaHtmlBuilder? htmlBuilder,
  }) async {
    final response = await buildInertiaResponse(
      component: component,
      props: props,
      url: url,
      context: context,
      version: version,
      encryptHistory: encryptHistory,
      clearHistory: clearHistory,
      flash: flash,
      cache: cache,
      statusCode: statusCode,
      elementId: elementId,
      ssrBody: ssrBody,
      sharedProps: sharedProps,
      htmlBuilder: htmlBuilder,
    );

    applyInertiaResponse(res, response);
    final payload = response.html ?? response.toJson();
    res.body = payload;
    return payload;
  }

  /// Applies an Inertia location response to [res].
  Object? inertiaLocation(String url) {
    applyInertiaResponse(res, InertiaResponse.location(url));
    return null;
  }

  Future<Map<String, dynamic>> _resolveSharedProps(
    Map<String, dynamic>? sharedProps,
  ) async {
    if (sharedProps != null) {
      return sharedProps;
    }

    final builder = inertiaOptions.sharedProps;
    if (builder == null) {
      return const {};
    }

    return await builder(this);
  }

  Future<SsrResponse?> _resolveSsr(PageData page) async {
    final gateway = inertiaOptions.ssr.createGateway();
    if (gateway == null) {
      return null;
    }
    return await gateway.render(jsonEncode(page.toJson()));
  }

  Future<String> _renderDefaultHtml(String bootstrap, String? ssrHead) async {
    final assets = inertiaOptions.assets == null
        ? const InertiaViteAssetTags()
        : await inertiaOptions.assets!.toViteAssets().resolve();
    final headParts = <String>[
      '<meta charset="utf-8">',
      '<meta name="viewport" content="width=device-width, initial-scale=1">',
      if (ssrHead != null && ssrHead.trim().isNotEmpty) ssrHead.trim(),
      if (assets.renderAll().trim().isNotEmpty) assets.renderAll().trim(),
    ];

    return '''
<!doctype html>
<html lang="en">
  <head>
    ${headParts.join('\n    ')}
  </head>
  <body>$bootstrap</body>
</html>''';
  }
}

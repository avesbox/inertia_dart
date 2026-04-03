import 'dart:async';
import 'dart:convert';
import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:inertia_dart/inertia_dart.dart';
import 'package:mime/mime.dart';
import 'package:serinus/serinus.dart';
import 'package:serinus_inertia/serinus_inertia.dart';
import 'package:test/test.dart';

void main() {
  group('extractSerinusHeaders', () {
    test('flattens Serinus headers into a string map', () {
      final headers = SerinusHeaders(
        _FakeHttpHeaders.fromFlatMap({
          'X-Inertia': 'true',
          'X-Inertia-Version': 'v1',
        }),
      );

      expect(headers.asFullMap(), containsPair('x-inertia', 'true'));
      expect(headers.asFullMap(), containsPair('x-inertia-version', 'v1'));
    });
  });

  group('inertiaRequestFromSerinus', () {
    test('captures method, url, headers, and parsed body', () {
      final request = _request(
        method: 'post',
        uri: Uri.parse('http://localhost/users?tab=active'),
        headers: {'X-Inertia': 'true'},
        body: {'name': 'Ada'},
      );

      final inertiaRequest = inertiaRequestFromSerinus(request);

      expect(inertiaRequest.method, 'POST');
      expect(inertiaRequest.url, '/users?tab=active');
      expect(inertiaRequest.isInertia, isTrue);
      expect(inertiaRequest.body, {'name': 'Ada'});
    });
  });

  group('applyInertiaResponse', () {
    test('sets status, headers, and content type on the response context', () {
      final response = ResponseContext({}, {}, {});
      final inertiaResponse = InertiaResponse.json(
        const PageData(component: 'Dashboard', props: {}, url: '/dashboard'),
        statusCode: 202,
      );

      applyInertiaResponse(response, inertiaResponse);

      expect(response.statusCode, 202);
      expect(response.headers, containsPair(InertiaHeaders.inertia, 'true'));
      expect(response.contentType?.mimeType, 'application/json');
    });
  });

  group('RequestContext.inertia', () {
    test('returns json payloads for inertia visits', () async {
      final context = _context(
        headers: {
          'X-Inertia': 'true',
          'X-Inertia-Partial-Component': 'Dashboard',
          'X-Inertia-Partial-Data': 'user.name',
        },
        uri: Uri.parse('http://localhost/dashboard'),
      );

      final payload = await context.inertia(
        component: 'Dashboard',
        props: {
          'user': {'name': 'Ada', 'email': 'ada@example.com'},
          'stats': {'projects': 3},
        },
      );

      expect(payload, isA<Map<String, dynamic>>());
      expect(context.res.statusCode, 200);
      expect(context.res.headers, containsPair(InertiaHeaders.inertia, 'true'));
      expect(context.res.contentType?.mimeType, 'application/json');
      expect(payload, {
        'component': 'Dashboard',
        'props': {
          'user': {'name': 'Ada'},
        },
        'url': '/dashboard',
      });
      expect(context.res.body, payload);
    });

    test('returns bootstrap html for initial visits', () async {
      final context = _context(uri: Uri.parse('http://localhost/dashboard'));

      final payload = await context.inertia(
        component: 'Dashboard',
        props: {
          'user': {'name': 'Ada'},
        },
        htmlBuilder: (context, page, bootstrap) =>
            '''
<!doctype html>
<html>
  <body>$bootstrap</body>
</html>''',
      );

      expect(payload, isA<String>());
      expect(context.res.contentType?.mimeType, 'text/html');
      expect(payload as String, contains('<!doctype html>'));
      expect(payload, contains('<script data-page="app"'));
      expect(payload, contains('<div id="app"></div>'));
      expect(payload, contains('"component":"Dashboard"'));
    });

    test('supports inertia location responses', () {
      final context = _context(uri: Uri.parse('http://localhost/login'));

      final payload = context.inertiaLocation('/signin');

      expect(payload, isNull);
      expect(context.res.statusCode, 409);
      expect(
        context.res.headers,
        containsPair(InertiaHeaders.inertiaLocation, '/signin'),
      );
    });

    test('uses module defaults from InertiaService', () async {
      final context = _context(
        uri: Uri.parse('http://localhost/dashboard'),
        providers: {
          InertiaService: InertiaService(
            options: InertiaOptions(
              version: 'v1',
              elementId: 'root',
              sharedProps: (_) async => {
                'appName': 'Serinus Demo',
                'user': {'name': 'Shared Ada'},
              },
              htmlBuilder: (context, page, bootstrap) async =>
                  '<html data-component="${page.component}">$bootstrap</html>',
            ),
          ),
        },
      );

      final payload = await context.inertia(
        component: 'Dashboard',
        props: {
          'user': {'name': 'Route Ada'},
        },
      );

      expect(payload, isA<String>());
      expect(payload as String, contains('data-component="Dashboard"'));
      expect(payload, contains('data-page="root"'));
      expect(payload, contains('"version":"v1"'));
      expect(payload, contains('"appName":"Serinus Demo"'));
      expect(payload, contains('"name":"Route Ada"'));
      expect(payload, isNot(contains('Shared Ada')));
    });

    test('renders default html with Vite asset settings', () async {
      final context = _context(
        uri: Uri.parse('http://localhost/dashboard'),
        providers: {
          InertiaService: InertiaService(
            options: const InertiaOptions(
              assets: InertiaAssetsOptions(
                entry: 'src/main.jsx',
                clientDirectory: 'web',
                devServerUrl: 'http://localhost:5173',
                includeReactRefresh: true,
              ),
            ),
          ),
        },
      );

      final payload = await context.inertia(
        component: 'Dashboard',
        props: const {'message': 'Hello'},
      );

      expect(payload, isA<String>());
      expect(payload as String, contains('http://localhost:5173/@vite/client'));
      expect(payload, contains('http://localhost:5173/src/main.jsx'));
      expect(payload, contains('@react-refresh'));
      expect(payload, contains('<div id="app"></div>'));
    });

    test('renders SSR body and head using module defaults', () async {
      final context = _context(
        uri: Uri.parse('http://localhost/dashboard'),
        providers: {
          InertiaService: InertiaService(
            options: InertiaOptions(
              ssr: InertiaSsrOptions(
                enabled: true,
                gateway: _FakeSsrGateway(
                  const SsrResponse(
                    body: '<main>SSR dashboard</main>',
                    head: '<title>SSR Dashboard</title>',
                  ),
                ),
              ),
            ),
          ),
        },
      );

      final payload = await context.inertia(
        component: 'Dashboard',
        props: const {'message': 'Hello'},
      );

      expect(payload, isA<String>());
      expect(payload as String, contains('<title>SSR Dashboard</title>'));
      expect(
        payload,
        contains('<div id="app"><main>SSR dashboard</main></div>'),
      );
    });
  });

  group('InertiaSsrProcessManager', () {
    test(
      'skips starting a managed process when the SSR server is healthy',
      () async {
        var startCalls = 0;

        final manager = InertiaSsrProcessManager(
          options: const InertiaOptions(
            ssr: InertiaSsrOptions(enabled: true, manageProcess: true),
          ),
          checkSsrServer: ({required endpoint, healthEndpoint}) async => true,
          startSsrServer: (config, {inheritStdio = false}) async {
            startCalls++;
            return _FakeProcess();
          },
        );

        await manager.onApplicationBootstrap();

        expect(startCalls, 0);
      },
    );

    test(
      'starts a managed process with the configured runtime and bundle',
      () async {
        final process = _FakeProcess();
        late SsrServerConfig startedConfig;

        final manager = InertiaSsrProcessManager(
          options: const InertiaOptions(
            ssr: InertiaSsrOptions(
              enabled: true,
              manageProcess: true,
              runtime: 'bun',
              bundle: 'client/dist/ssr.js',
              runtimeArgs: ['run'],
              waitUntilReady: false,
            ),
          ),
          checkSsrServer: ({required endpoint, healthEndpoint}) async => false,
          startSsrServer: (config, {inheritStdio = false}) async {
            startedConfig = config;
            return process;
          },
        );

        await manager.onApplicationBootstrap();

        expect(startedConfig.runtime, 'bun');
        expect(startedConfig.bundle, 'client/dist/ssr.js');
        expect(startedConfig.runtimeArgs, ['run']);

        process.completeExit(0);
      },
    );

    test('stops an owned managed process on application shutdown', () async {
      final process = _FakeProcess();
      var stopCalls = 0;

      final manager = InertiaSsrProcessManager(
        options: const InertiaOptions(
          ssr: InertiaSsrOptions(
            enabled: true,
            manageProcess: true,
            waitUntilReady: false,
          ),
        ),
        checkSsrServer: ({required endpoint, healthEndpoint}) async => false,
        startSsrServer: (config, {inheritStdio = false}) async => process,
        stopSsrServer: ({required endpoint, shutdownEndpoint}) async {
          stopCalls++;
          process.completeExit(0);
          return true;
        },
      );

      await manager.onApplicationBootstrap();
      await manager.onApplicationShutdown();

      expect(stopCalls, 1);
      expect(process.killSignals, isEmpty);
    });

    test('kills the managed process when graceful shutdown fails', () async {
      final process = _FakeProcess();

      final manager = InertiaSsrProcessManager(
        options: const InertiaOptions(
          ssr: InertiaSsrOptions(
            enabled: true,
            manageProcess: true,
            waitUntilReady: false,
          ),
        ),
        checkSsrServer: ({required endpoint, healthEndpoint}) async => false,
        startSsrServer: (config, {inheritStdio = false}) async => process,
        stopSsrServer: ({required endpoint, shutdownEndpoint}) async => false,
      );

      await manager.onApplicationBootstrap();
      await manager.onApplicationShutdown();

      expect(process.killSignals, contains(ProcessSignal.sigterm));
    });
  });
}

Request _request({
  required String method,
  required Uri uri,
  Map<String, String> headers = const {},
  Object? body,
}) {
  final request = Request(
    _FakeIncomingMessage(
      method: method,
      uri: uri,
      headers: SerinusHeaders(_FakeHttpHeaders.fromFlatMap(headers)),
      bodyBytes: _bodyBytes(body),
      cookies: const [],
      contentType: _contentType(body),
      host: uri.host.isEmpty ? 'localhost' : uri.host,
      port: uri.hasPort ? uri.port : 3000,
    ),
  );
  request.body = body;
  return request;
}

RequestContext<dynamic> _context({
  required Uri uri,
  Map<String, String> headers = const {},
  Object? body,
  Map<Type, Provider> providers = const {},
}) {
  final context = RequestContext<dynamic>.withBody(
    _request(method: 'get', uri: uri, headers: headers, body: body),
    body,
    providers,
    {},
    {},
  );
  context.response = ResponseContext({}, {}, {});
  return context;
}

class _FakeHttpHeaders implements HttpHeaders {
  _FakeHttpHeaders(this._headers);

  _FakeHttpHeaders.fromFlatMap(Map<String, String> headers)
    : _headers = headers.map(
        (key, value) => MapEntry(
          key.toLowerCase(),
          value.split(',').map((item) => item.trim()).toList(),
        ),
      );

  final Map<String, List<String>> _headers;

  @override
  bool chunkedTransferEncoding = false;

  @override
  int contentLength = 0;

  @override
  ContentType? contentType;

  @override
  DateTime? date;

  @override
  DateTime? expires;

  @override
  String? host;

  @override
  DateTime? ifModifiedSince;

  @override
  bool persistentConnection = true;

  @override
  int? port;

  @override
  List<String>? operator [](String name) => _headers[name.toLowerCase()];

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    final values = _headers.putIfAbsent(name.toLowerCase(), () => <String>[]);
    values.add(value.toString());
  }

  @override
  void clear() => _headers.clear();

  @override
  void forEach(void Function(String name, List<String> values) action) {
    _headers.forEach(action);
  }

  @override
  void noFolding(String name) {}

  @override
  void remove(String name, Object value) {
    _headers[name.toLowerCase()]?.remove(value.toString());
  }

  @override
  void removeAll(String name) {
    _headers.remove(name.toLowerCase());
  }

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _headers[name.toLowerCase()] = [value.toString()];
  }

  @override
  String? value(String name) {
    final values = this[name];
    if (values == null || values.isEmpty) {
      return null;
    }
    if (values.length > 1) {
      throw HttpException('Multiple values for header $name');
    }
    return values.first;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpSession extends MapBase<dynamic, dynamic>
    implements HttpSession {
  _FakeHttpSession() : _id = 'session-${_counter++}';

  static int _counter = 0;

  final String _id;
  final Map<dynamic, dynamic> _values = {};
  bool _destroyed = false;

  @override
  String get id => _id;

  @override
  bool get isNew => !_destroyed;

  @override
  set onTimeout(void Function()? callback) {}

  @override
  dynamic operator [](Object? key) => _values[key];

  @override
  void operator []=(dynamic key, dynamic value) {
    _values[key] = value;
  }

  @override
  void clear() => _values.clear();

  @override
  void destroy() {
    _destroyed = true;
    _values.clear();
  }

  @override
  Iterable<dynamic> get keys => _values.keys;

  @override
  dynamic remove(Object? key) => _values.remove(key);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeIncomingMessage extends IncomingMessage {
  _FakeIncomingMessage({
    required String method,
    required Uri uri,
    required SerinusHeaders headers,
    required this.bodyBytes,
    required this.contentType,
    required this.host,
    required this.port,
    this.cookies = const [],
  }) : _method = method.toUpperCase(),
       _requestedUri = uri,
       _uri = Uri(
         path: uri.path.isEmpty ? '/' : uri.path,
         query: uri.hasQuery ? uri.query : null,
       ),
       _headers = headers;

  final String _method;
  final Uri _uri;
  final Uri _requestedUri;
  final SerinusHeaders _headers;
  final Uint8List bodyBytes;
  final Session _session = Session(_FakeHttpSession());

  @override
  String get id => 'request-${_requestedUri.path}';

  @override
  String get path => _uri.path;

  @override
  Uri get uri => _uri;

  @override
  Uri get requestedUri => _requestedUri;

  @override
  String get method => _method;

  @override
  SerinusHeaders get headers => _headers;

  @override
  Map<String, String> get queryParameters => _uri.queryParameters;

  @override
  Session get session => _session;

  @override
  HttpConnectionInfo? get clientInfo => null;

  @override
  final ContentType contentType;

  @override
  final String host;

  @override
  String get hostname => host;

  @override
  final List<Cookie> cookies;

  @override
  final int port;

  @override
  List<String> get segments => _uri.pathSegments;

  @override
  String body() => utf8.decode(bodyBytes);

  @override
  dynamic json() {
    if (bodyBytes.isEmpty) {
      return null;
    }
    return jsonDecode(utf8.decode(bodyBytes));
  }

  @override
  Future<Uint8List> bytes() async => Uint8List.fromList(bodyBytes);

  @override
  Stream<List<int>> stream() {
    if (bodyBytes.isEmpty) {
      return const Stream<List<int>>.empty();
    }
    return Stream<List<int>>.fromIterable([bodyBytes]);
  }

  @override
  Future<FormData> formData({
    Future<void> Function(MimeMultipart part)? onPart,
  }) async {
    if (contentType.mimeType == 'application/x-www-form-urlencoded') {
      return FormData.parseUrlEncoded(body());
    }
    throw BadRequestException(
      'The content type is not supported for form data.',
    );
  }

  @override
  DateTime? get ifModifiedSince {
    final value = headers['if-modified-since'];
    if (value == null) {
      return null;
    }
    return HttpDate.parse(value);
  }

  @override
  int get contentLength => bodyBytes.length;

  @override
  bool get isWebSocket => false;

  @override
  String get webSocketKey => '';

  @override
  bool get fresh => true;
}

class _FakeSsrGateway implements SsrGateway {
  const _FakeSsrGateway(this.response);

  final SsrResponse response;

  @override
  Future<bool> healthCheck() async => true;

  @override
  Future<SsrResponse> render(String pageJson) async => response;
}

class _FakeProcess implements Process {
  final _stdoutController = StreamController<List<int>>.broadcast();
  final _stderrController = StreamController<List<int>>.broadcast();
  final _exitCodeCompleter = Completer<int>();
  final List<ProcessSignal> killSignals = [];

  @override
  int get pid => 4242;

  @override
  IOSink get stdin => throw UnimplementedError();

  @override
  Stream<List<int>> get stdout => _stdoutController.stream;

  @override
  Stream<List<int>> get stderr => _stderrController.stream;

  @override
  Future<int> get exitCode => _exitCodeCompleter.future;

  void completeExit(int code) {
    if (_exitCodeCompleter.isCompleted) {
      return;
    }
    _stdoutController.close();
    _stderrController.close();
    _exitCodeCompleter.complete(code);
  }

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    killSignals.add(signal);
    completeExit(signal == ProcessSignal.sigkill ? -9 : 0);
    return true;
  }
}

Uint8List _bodyBytes(Object? body) {
  if (body == null) {
    return Uint8List(0);
  }
  if (body is Uint8List) {
    return body;
  }
  if (body is List<int>) {
    return Uint8List.fromList(body);
  }
  if (body is String) {
    return Uint8List.fromList(utf8.encode(body));
  }
  return Uint8List.fromList(utf8.encode(jsonEncode(body)));
}

ContentType _contentType(Object? body) {
  if (body == null) {
    return ContentType('text', 'plain', charset: 'utf-8');
  }
  if (body is String) {
    return ContentType('text', 'plain', charset: 'utf-8');
  }
  return ContentType('application', 'json', charset: 'utf-8');
}

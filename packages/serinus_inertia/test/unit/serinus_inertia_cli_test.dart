import 'dart:io';

import 'package:artisanal/args.dart';
import 'package:serinus_inertia/src/cli/serinus_inertia_cli.dart';
import 'package:serinus_inertia/src/cli/ssr_check_command.dart';
import 'package:serinus_inertia/src/cli/ssr_start_command.dart';
import 'package:serinus_inertia/src/cli/ssr_stop_command.dart';
import 'package:test/test.dart';

void main() {
  group('SerinusInertiaSsrCheckCommand', () {
    test('returns success when health endpoint is ok', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        if (request.uri.path == '/health') {
          request.response.statusCode = 204;
        } else {
          request.response.statusCode = 404;
        }
        await request.response.close();
      });
      addTearDown(() => server.close(force: true));

      final runner = CommandRunner<int>(
        'serinus_inertia',
        'Serinus Inertia CLI',
      )..addCommand(SerinusInertiaSsrCheckCommand());

      final result = await runner.run([
        'check',
        '--url',
        'http://127.0.0.1:${server.port}',
      ]);

      expect(result, equals(0));
    });
  });

  group('SerinusInertiaSsrStopCommand', () {
    test('returns success when shutdown endpoint responds', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        request.response.statusCode = 204;
        await request.response.close();
      });
      addTearDown(() => server.close(force: true));

      final runner = CommandRunner<int>(
        'serinus_inertia',
        'Serinus Inertia CLI',
      )..addCommand(SerinusInertiaSsrStopCommand());

      final result = await runner.run([
        'stop',
        '--url',
        'http://127.0.0.1:${server.port}',
      ]);

      expect(result, equals(0));
    });
  });

  group('SerinusInertiaSsrStartCommand', () {
    test('returns failure when the SSR bundle is missing', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'serinus-inertia-cli',
      );
      addTearDown(() => tempDir.delete(recursive: true));

      final cli = SerinusInertiaCli(workingDirectory: tempDir);
      final runner = CommandRunner<int>(
        'serinus_inertia',
        'Serinus Inertia CLI',
      )..addCommand(SerinusInertiaSsrStartCommand(cli));

      final result = await runner.run([
        'start',
        '--working-directory',
        tempDir.path,
      ]);

      expect(result, equals(1));
    });
  });

  group('SerinusInertiaCli', () {
    test('prints usage and succeeds for --help', () async {
      final stdout = StringBuffer();
      final stderr = StringBuffer();
      final cli = SerinusInertiaCli(stdoutSink: stdout, stderrSink: stderr);

      final result = await cli.run(['--help']);

      expect(result, equals(0));
      expect(stdout.toString(), contains('Serinus Inertia SSR utilities.'));
      expect(stderr.toString(), isEmpty);
    });

    test('supports legacy ssr:start aliases', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'serinus-inertia-cli-alias',
      );
      addTearDown(() => tempDir.delete(recursive: true));

      final cli = SerinusInertiaCli(workingDirectory: tempDir);

      final result = await cli.run([
        'ssr:start',
        '--working-directory',
        tempDir.path,
      ]);

      expect(result, equals(1));
    });
  });
}

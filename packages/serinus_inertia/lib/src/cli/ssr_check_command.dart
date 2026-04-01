library;

import 'package:artisanal/args.dart';
import 'package:artisanal/artisanal.dart';
import 'package:inertia_dart/inertia_dart.dart';

import 'ssr_utils.dart';

/// Implements the `ssr:check` command for Serinus Inertia.
class SerinusInertiaSsrCheckCommand extends Command<int> {
  /// Creates the `ssr:check` command.
  SerinusInertiaSsrCheckCommand() : super(aliases: const ['ssr:check']) {
    argParser
      ..addOption(
        'url',
        defaultsTo: 'http://127.0.0.1:13714',
        help: 'SSR server base URL (without /render).',
      )
      ..addOption('health', help: 'Override the health endpoint URL.');
  }

  @override
  String get name => 'check';

  @override
  String get description => 'Check the Serinus Inertia SSR server health.';

  @override
  Future<int> run() async {
    final io = this.io;
    final url = argResults?['url'] as String? ?? 'http://127.0.0.1:13714';
    final health = argResults?['health'] as String?;
    final baseUri = normalizeSsrBase(url);
    io.title('Checking Serinus Inertia SSR');
    io.twoColumnDetail('URL', baseUri.toString());

    try {
      final healthy = await checkSsrServer(
        endpoint: baseUri,
        healthEndpoint: health == null ? null : Uri.parse(health),
      );
      if (healthy) {
        io.success('Serinus Inertia SSR server is running.');
        return 0;
      }

      io.error('Serinus Inertia SSR server is not running.');
      return 1;
    } on UnsupportedError {
      io.error('The SSR gateway does not support health checks.');
      return 1;
    }
  }
}

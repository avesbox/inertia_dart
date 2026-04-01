library;

import 'package:artisanal/args.dart';
import 'package:artisanal/artisanal.dart';
import 'package:inertia_dart/inertia_dart.dart';

import 'ssr_utils.dart';

/// Implements the `ssr:stop` command for Serinus Inertia.
class SerinusInertiaSsrStopCommand extends Command<int> {
  /// Creates the `ssr:stop` command.
  SerinusInertiaSsrStopCommand() : super(aliases: const ['ssr:stop']) {
    argParser
      ..addOption(
        'url',
        defaultsTo: 'http://127.0.0.1:13714',
        help: 'SSR server base URL (without /render).',
      )
      ..addOption('shutdown', help: 'Override the shutdown endpoint URL.');
  }

  @override
  String get name => 'stop';

  @override
  String get description => 'Stop the Serinus Inertia SSR server.';

  @override
  Future<int> run() async {
    final io = this.io;
    final url = argResults?['url'] as String? ?? 'http://127.0.0.1:13714';
    final shutdown = argResults?['shutdown'] as String?;
    final baseUri = normalizeSsrBase(url);
    io.title('Stopping Serinus Inertia SSR');
    io.twoColumnDetail('URL', baseUri.toString());

    final ok = await stopSsrServer(
      endpoint: baseUri,
      shutdownEndpoint: shutdown == null ? null : Uri.parse(shutdown),
    );
    if (!ok) {
      io.error('Unable to connect to Serinus Inertia SSR server.');
      return 1;
    }

    io.success('Serinus Inertia SSR server stopped.');
    return 0;
  }
}

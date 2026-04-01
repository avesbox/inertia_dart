library;

import 'dart:io';

import 'package:artisanal/args.dart';
import 'package:artisanal/artisanal.dart';
import 'package:inertia_dart/inertia_dart.dart';
import 'package:path/path.dart' as p;

import 'serinus_inertia_cli.dart';
import 'ssr_utils.dart';

/// Implements the `ssr:start` command for Serinus Inertia.
class SerinusInertiaSsrStartCommand extends Command<int> {
  /// Creates the `ssr:start` command bound to [SerinusInertiaCli].
  SerinusInertiaSsrStartCommand(this._cli)
    : super(aliases: const ['ssr:start']) {
    argParser
      ..addOption(
        'runtime',
        abbr: 'r',
        defaultsTo: 'node',
        allowed: const ['node', 'bun'],
        help: 'Runtime for the SSR bundle (node or bun).',
      )
      ..addOption(
        'bundle',
        abbr: 'b',
        help: 'Path to the SSR bundle (default: auto-detect).',
      )
      ..addMultiOption(
        'bundle-candidate',
        abbr: 'c',
        help: 'Additional SSR bundle paths to check.',
      )
      ..addMultiOption(
        'runtime-arg',
        abbr: 'a',
        help: 'Extra runtime arguments passed to the SSR process.',
      )
      ..addMultiOption(
        'env',
        abbr: 'e',
        help: 'Environment variables for the SSR process (KEY=VALUE).',
      )
      ..addOption(
        'working-directory',
        abbr: 'w',
        help: 'Directory to resolve bundle paths from.',
      );
  }

  final SerinusInertiaCli _cli;
  static const List<String> _defaultBundleCandidates = [
    'client/dist/ssr.js',
    'client/dist/ssr.mjs',
    'client/dist/server/entry-server.js',
    'client/dist/server/entry-server.mjs',
  ];

  @override
  String get name => 'start';

  @override
  String get description => 'Start the Serinus Inertia SSR server bundle.';

  @override
  Future<int> run() async {
    final io = this.io;
    final runtime = argResults?['runtime'] as String? ?? 'node';
    final bundleOption = argResults?['bundle'] as String?;
    final bundleCandidates =
        (argResults?['bundle-candidate'] as List<String>? ?? const [])
            .where((value) => value.trim().isNotEmpty)
            .toList();
    final runtimeArgs =
        (argResults?['runtime-arg'] as List<String>? ?? const [])
            .where((value) => value.trim().isNotEmpty)
            .toList();
    final environment = parseEnvironment(
      argResults?['env'] as List<String>? ?? const [],
    );
    final workingDirOption = argResults?['working-directory'] as String?;
    final workingDirectory = workingDirOption == null
        ? _cli.workingDirectory
        : Directory(p.normalize(workingDirOption));

    final config = SsrServerConfig(
      runtime: runtime,
      bundle: bundleOption,
      runtimeArgs: runtimeArgs,
      bundleCandidates: [...bundleCandidates, ..._defaultBundleCandidates],
      workingDirectory: workingDirectory,
      environment: environment,
    );
    final bundle = config.resolveBundle();
    if (bundle == null) {
      io.error('Serinus Inertia SSR bundle not found.');
      io.note(
        'Provide --bundle or place it in client/dist/ssr.js or bootstrap/ssr/ssr.mjs.',
      );
      return 1;
    }

    if (bundleOption != null &&
        p.normalize(bundle) != p.normalize(bundleOption)) {
      io.note('Configured bundle not found at $bundleOption.');
      io.note('Using detected bundle: $bundle');
    }

    io.title('Starting Serinus Inertia SSR');
    io.twoColumnDetail('Runtime', runtime);
    io.twoColumnDetail('Bundle', bundle);

    final process = await startSsrServer(config, inheritStdio: false);
    final signalSubscriptions = attachSignals(process, io);

    try {
      return await pipeSsrProcess(
        process,
        stdoutSink: _cli.stdoutSink,
        stderrSink: _cli.stderrSink,
      );
    } finally {
      for (final subscription in signalSubscriptions) {
        await subscription.cancel();
      }
    }
  }
}

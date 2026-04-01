library;

import 'dart:io';

import 'package:serinus_inertia/src/cli/serinus_inertia_cli.dart';

/// Entry point for the `ssr` command line tool.
Future<void> main(List<String> args) async {
  final cli = SerinusInertiaCli(executableName: 'ssr');
  final code = await cli.run(args);
  if (code != 0) {
    exitCode = code;
  }
}

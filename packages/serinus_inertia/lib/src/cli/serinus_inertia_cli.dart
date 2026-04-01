library;

import 'dart:io';

import 'package:artisanal/args.dart';

import 'ssr_check_command.dart';
import 'ssr_start_command.dart';
import 'ssr_stop_command.dart';

/// Implements the `serinus_inertia` command line interface.
class SerinusInertiaCli {
  /// Creates a CLI runner with optional output overrides.
  SerinusInertiaCli({
    StringSink? stdoutSink,
    StringSink? stderrSink,
    Directory? workingDirectory,
    String executableName = 'serinus_inertia',
  }) : _stdout = stdoutSink ?? stdout,
       _stderr = stderrSink ?? stderr,
       _workingDirectory = workingDirectory ?? Directory.current,
       _executableName = executableName;

  final StringSink _stdout;
  final StringSink _stderr;
  final Directory _workingDirectory;
  final String _executableName;

  /// The stdout sink used by the CLI.
  StringSink get stdoutSink => _stdout;

  /// The stderr sink used by the CLI.
  StringSink get stderrSink => _stderr;

  /// The working directory used by the CLI.
  Directory get workingDirectory => _workingDirectory;

  /// The executable name shown in usage output.
  String get executableName => _executableName;

  /// Runs the CLI with the provided [args] and returns an exit code.
  Future<int> run(List<String> args) async {
    if (args.isEmpty || _isHelp(args)) {
      _buildRunner().printUsage();
      return 0;
    }

    int? usageExitCode;
    final runner = _buildRunner(
      setExitCode: (code) {
        usageExitCode = code;
      },
    );

    try {
      final result = await runner.run(args);
      if (result != null) return result;
      return usageExitCode ?? 0;
    } catch (error) {
      _stderr.writeln('Failed to run command: $error');
      return 1;
    }
  }

  bool _isHelp(List<String> args) {
    return args.length == 1 && (args[0] == '--help' || args[0] == '-h');
  }

  CommandRunner<int> _buildRunner({void Function(int code)? setExitCode}) {
    final runner = CommandRunner<int>(
      _executableName,
      'Serinus Inertia SSR utilities.',
      usageExitCode: 64,
      out: (line) => _stdout.writeln(line),
      err: (line) => _stderr.writeln(line),
      setExitCode: setExitCode,
    );

    runner
      ..addCommand(SerinusInertiaSsrStartCommand(this))
      ..addCommand(SerinusInertiaSsrStopCommand())
      ..addCommand(SerinusInertiaSsrCheckCommand());
    return runner;
  }
}

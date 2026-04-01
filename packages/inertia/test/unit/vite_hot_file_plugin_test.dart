library;

import 'dart:io';

import 'package:inertia_dart/inertia_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Inertia Vite hot-file plugin helpers', () {
    test('renders the default hot-file plugin template', () {
      final plugin = renderInertiaViteHotFilePlugin();

      expect(plugin, contains("const hotFile = options.hotFile ?? 'public/hot'"));
      expect(plugin, contains("name: 'inertia-hot-file'"));
    });

    test('renders a custom default hot-file path', () {
      final plugin = renderInertiaViteHotFilePlugin(
        defaultHotFile: 'frontend/public/hot',
      );

      expect(
        plugin,
        contains("const hotFile = options.hotFile ?? 'frontend/public/hot'"),
      );
    });

    test('writes the plugin to disk', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'inertia-hot-plugin-',
      );
      addTearDown(() async {
        await tempDir.delete(recursive: true);
      });

      final file = await writeInertiaViteHotFilePlugin(
        tempDir,
        defaultHotFile: 'frontend/public/hot',
      );

      expect(file.path, endsWith('inertia_hot_file.js'));
      expect(await file.exists(), isTrue);
      expect(
        await file.readAsString(),
        contains("const hotFile = options.hotFile ?? 'frontend/public/hot'"),
      );
    });
  });
}

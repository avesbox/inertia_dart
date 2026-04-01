library;

import 'dart:io';

import 'package:path/path.dart' as p;

/// Default hot file path used by the generated Vite plugin.
const String defaultInertiaViteHotFile = 'public/hot';

/// Default filename used when writing the generated Vite plugin.
const String defaultInertiaViteHotFilePluginFileName = 'inertia_hot_file.js';

/// Base template for the Inertia Vite hot-file plugin.
///
/// The generated plugin writes the active Vite dev-server origin into a single
/// hot file so server-side integrations can discover the running frontend.
const String inertiaViteHotFilePluginTemplate = """import fs from 'node:fs'
import path from 'node:path'

export function inertiaHotFile(options = {}) {
  const hotFile = options.hotFile ?? 'public/hot'

  return {
    name: 'inertia-hot-file',
    configureServer(server) {
      const resolvedHotFile = path.resolve(
        server.config.root ?? process.cwd(),
        hotFile,
      )

      const writeHotFile = () => {
        const origin = resolveOrigin(server, options)
        if (!origin) return
        fs.mkdirSync(path.dirname(resolvedHotFile), { recursive: true })
        fs.writeFileSync(resolvedHotFile, origin)
      }

      const cleanup = () => {
        if (fs.existsSync(resolvedHotFile)) {
          fs.unlinkSync(resolvedHotFile)
        }
      }

      server.httpServer?.once('listening', writeHotFile)
      server.httpServer?.once('close', cleanup)
    },
  }
}

function resolveOrigin(server, options) {
  const resolved = server.resolvedUrls?.local?.[0]
  if (resolved) return trimTrailingSlash(resolved)

  const config = server.config.server ?? {}
  if (config.origin) {
    return trimTrailingSlash(config.origin)
  }

  if (options.origin) {
    return trimTrailingSlash(options.origin)
  }

  const port = config.port ?? 5173
  const hostValue = config.host
  const host = hostValue === true ? 'localhost' : hostValue || 'localhost'
  const protocol = config.https ? 'https' : 'http'
  return `\${protocol}://\${host}:\${port}`
}

function trimTrailingSlash(value) {
  return value.endsWith('/') ? value.slice(0, -1) : value
}
""";

/// Renders the Inertia Vite hot-file plugin source.
///
/// Use [defaultHotFile] to change the fallback hot file path baked into the
/// generated plugin. The plugin still accepts `options.hotFile` at runtime.
String renderInertiaViteHotFilePlugin({
  String defaultHotFile = defaultInertiaViteHotFile,
}) {
  if (defaultHotFile == defaultInertiaViteHotFile) {
    return inertiaViteHotFilePluginTemplate;
  }

  return inertiaViteHotFilePluginTemplate.replaceFirst(
    "'$defaultInertiaViteHotFile'",
    "'${_escapeJavaScriptString(defaultHotFile)}'",
  );
}

/// Writes the Inertia Vite hot-file plugin into [directory].
///
/// Returns the written plugin [File].
Future<File> writeInertiaViteHotFilePlugin(
  Directory directory, {
  String fileName = defaultInertiaViteHotFilePluginFileName,
  String defaultHotFile = defaultInertiaViteHotFile,
}) async {
  final file = File(p.join(directory.path, fileName));
  await file.create(recursive: true);
  await file.writeAsString(
    renderInertiaViteHotFilePlugin(defaultHotFile: defaultHotFile),
  );
  return file;
}

String _escapeJavaScriptString(String value) {
  return value.replaceAll(r'\', r'\\').replaceAll("'", r"\'");
}

import 'dart:io';

import 'package:serinus/serinus.dart';
import 'package:serinus_inertia/serinus_inertia.dart';

import 'asset_controller.dart';
import 'app_controller.dart';

bool _envBool(String name) {
  final value = Platform.environment[name]?.trim().toLowerCase();
  return value == '1' || value == 'true' || value == 'yes' || value == 'on';
}

String? _envString(String name) {
  final value = Platform.environment[name]?.trim();
  if (value == null || value.isEmpty) {
    return null;
  }
  return value;
}

InertiaSsrOptions _resolveSsrOptions() {
  if (!_envBool('SERINUS_INERTIA_ENABLE_SSR')) {
    return const InertiaSsrOptions();
  }

  final endpoint = _envString('SERINUS_INERTIA_SSR_ENDPOINT');
  if (endpoint != null) {
    return InertiaSsrOptions(enabled: true, endpoint: Uri.parse(endpoint));
  }

  return InertiaSsrOptions(
    enabled: true,
    manageProcess: true,
    runtime: _envString('SERINUS_INERTIA_SSR_RUNTIME') ?? 'node',
    bundle: _envString('SERINUS_INERTIA_SSR_BUNDLE') ?? 'client/dist/ssr.js',
  );
}

class AppModule extends Module {
  AppModule()
    : super(
        imports: [
          InertiaModule(
            options: InertiaOptions(
              version: '1.0.0',
              assets: InertiaAssetsOptions(
                entry: 'src/main.jsx',
                clientDirectory: 'client',
                includeReactRefresh: true,
              ),
              ssr: _resolveSsrOptions(),
              // Enable this to have Serinus manage the SSR runtime as a
              // separate Node or Bun process during app startup:
              // ssr: InertiaSsrOptions(
              //   enabled: true,
              //   manageProcess: true,
              //   runtime: 'node', // or 'bun'
              //   bundle: 'client/dist/ssr.js',
              // ),
              //
              // Or keep the SSR runtime separate and point at an existing
              // endpoint started with:
              // dart run serinus_inertia:ssr start
              //   --bundle client/dist/ssr.js
              // ssr: InertiaSsrOptions(
              //   enabled: true,
              //   endpoint: Uri.parse('http://127.0.0.1:13714/render'),
              // ),
              sharedProps: (context) async => {
                'appName': 'Serinus Inertia Example',
              },
            ),
          ),
        ],
        controllers: [AssetController(), AppController()],
      );
}

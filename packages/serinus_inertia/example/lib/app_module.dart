import 'package:serinus/serinus.dart';
import 'package:serinus_inertia/serinus_inertia.dart';

import 'app_controller.dart';

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
              // Enable this to have Serinus manage the SSR runtime as a
              // separate Node or Bun process during app startup:
              // ssr: SerinusInertiaSsrOptions(
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
              // ssr: SerinusInertiaSsrOptions(
              //   enabled: true,
              //   endpoint: Uri.parse('http://127.0.0.1:13714/render'),
              // ),
              sharedProps: (context) async => {
                'appName': 'Serinus Inertia Example',
              },
            ),
          ),
        ],
        controllers: [AppController()],
      );
}

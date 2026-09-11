// PLACEHOLDER — substitua este arquivo rodando `flutterfire configure`
// (veja o plano de implementação). Estes NÃO são valores reais e o login
// com Google não vai funcionar até este arquivo ser regenerado.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      _ => throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform. '
          'Rode `flutterfire configure` para gerar este arquivo.',
        ),
    };
  }

  static const android = FirebaseOptions(
    apiKey: 'placeholder-api-key',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'placeholder-project',
    storageBucket: 'placeholder-project.appspot.com',
  );

  static const ios = FirebaseOptions(
    apiKey: 'placeholder-api-key',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'placeholder-project',
    storageBucket: 'placeholder-project.appspot.com',
  );
}

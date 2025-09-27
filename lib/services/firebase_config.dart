import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

// OBSOLETO: Não usar. Mantido apenas temporariamente para referência.
// Utilize sempre `firebase_options.dart` gerado pelo FlutterFire CLI.
// Este arquivo será removido após validação completa do novo setup.

@deprecated
class FirebaseConfigObsoletoAviso {}

class FirebaseConfig {
  // Configuração do Firebase para o projeto CORTE REAL
  // Baseado no google-services.json fornecido

  static const FirebaseOptions android = FirebaseOptions(
    apiKey:
        'AIzaSyB1w1Qw6Qw1Qw6Qw1Qw6Qw1Qw6Qw1Qw6Q', // Substitua pela API key real do novo projeto
    appId: '1:63227355509:android:7fb27438b65c56bca6733c',
    messagingSenderId: '63227355509',
    projectId: 'corte-real-6b077',
    storageBucket: 'corte-real-6b077.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'SUA_NOVA_API_KEY_IOS', // Preencha com a nova API key do iOS
    appId: '1:63227355509:ios:abcdef', // Preencha com o novo appId do iOS
    messagingSenderId: '63227355509',
    projectId: 'corte-real-6b077',
    storageBucket: 'corte-real-6b077.appspot.com',
    iosClientId:
        'SEU_NOVO_CLIENT_ID_IOS', // Preencha com o novo clientId do iOS
    iosBundleId: 'com.example.barbearia_app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'SUA_NOVA_API_KEY_WEB', // Preencha com a nova API key do Web
    appId: '1:63227355509:web:abcdef', // Preencha com o novo appId do Web
    messagingSenderId: '63227355509',
    projectId: 'corte-real-6b077',
    storageBucket: 'corte-real-6b077.appspot.com',
  );

  // Obtém as opções baseadas na plataforma
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'FirebaseOptions não configurado para esta plataforma.',
        );
    }
  }
}

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseConfig {
  // Configuração do Firebase para o projeto CORTE REAL
  // Baseado no google-services.json fornecido

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBNy2yalqaRA7PzwbPrX-ywe-3JOOb6-lo',
    appId: '1:63227355509:android:7fb27438b65c56bca6733c',
    messagingSenderId: '63227355509',
    projectId: 'corte-real-4d73b',
    storageBucket: 'corte-real-4d73b.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'sua-api-key-ios', // Será preenchido quando criar o app iOS
    appId: '1:63227355509:ios:abcdef', // Será preenchido quando criar o app iOS
    messagingSenderId: '63227355509',
    projectId: 'corte-real-4d73b',
    storageBucket: 'corte-real-4d73b.firebasestorage.app',
    iosClientId: 'seu-client-id-ios', // Será preenchido quando criar o app iOS
    iosBundleId: 'com.example.barbearia_app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'sua-api-key-web', // Será preenchido quando criar o app Web
    appId: '1:63227355509:web:abcdef', // Será preenchido quando criar o app Web
    messagingSenderId: '63227355509',
    projectId: 'corte-real-4d73b',
    storageBucket: 'corte-real-4d73b.firebasestorage.app',
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

// Instruções para configurar o Firebase:
/* 

IMPORTANTE: CONFIGURAÇÃO NECESSÁRIA

Este app usa Firebase para armazenar dados na nuvem. Para funcionar,
você precisa criar seu projeto Firebase:

1. Acesse: https://console.firebase.google.com/
2. Crie um novo projeto chamado "corte-real-app"
3. Ative o Authentication (Email/Password)
4. Ative o Firestore Database
5. Configure as regras de segurança do Firestore:

rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Usuários podem ler/escrever seus próprios dados
    match /usuarios/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Agendamentos podem ser lidos/criados pelo dono
    match /agendamentos/{document} {
      allow read, write: if request.auth != null && 
        (request.auth.uid == resource.data.clienteId || 
         request.auth.uid == get(/databases/$(database)/documents/usuarios/$(request.auth.uid)).data.tipo == 'admin');
    }
    
    // Serviços podem ser lidos por todos usuários autenticados
    match /servicos/{document} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        get(/databases/$(database)/documents/usuarios/$(request.auth.uid)).data.tipo == 'admin';
    }
    
    // Produtos podem ser lidos por todos usuários autenticados
    match /produtos/{document} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        get(/databases/$(database)/documents/usuarios/$(request.auth.uid)).data.tipo == 'admin';
    }
  }
}

6. Baixe os arquivos de configuração:
   - Para Android: google-services.json → android/app/
   - Para iOS: GoogleService-Info.plist → ios/Runner/
   - Para Web: configure as keys no firebase_config.dart

7. Atualize as configurações neste arquivo (firebase_config.dart)

*/

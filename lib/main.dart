import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'services/firebase_config.dart'; // descontinuado - usar DefaultFirebaseOptions
import 'firebase_options.dart';
import 'services/firebase_service.dart';
import 'services/notification_service.dart';
import 'screens/login_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'widgets/app_startup_wrapper.dart';
import 'theme/app_theme.dart';

void main() async {
  // Garante que o Flutter está inicializado antes do Firebase
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Inicializa Firebase usando opções oficiais geradas pelo FlutterFire CLI
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Inicializar serviço de notificações
    await NotificationService.initialize();

    // Agendar promoções semanais automáticas
    await NotificationService.agendarPromocoesSemanas();

    // Inicializa dados mock (apenas para desenvolvimento)
    await FirebaseService.inicializarDadosMock();

    // Inicializar usuário admin se necessário
    await FirebaseService.inicializarAdminSeNecessario();

    print('Firebase inicializado com sucesso!');
  } catch (e) {
    print('Erro ao inicializar Firebase: $e');
    print('AVISO: O app funcionará em modo offline/mock');
  }

  runApp(const BarbeariaApp());
}

class BarbeariaApp extends StatelessWidget {
  const BarbeariaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppStartupWrapper(
      child: MaterialApp(
        title: 'CORTE REAL',
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('pt', 'BR'),
          Locale('en', 'US'),
        ],
        // Sempre exibe a tela admin para todos os usuários
        home: StreamBuilder(
          stream: FirebaseService.authStateChanges,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // Se não há usuário logado, vai para login
            if (!snapshot.hasData) {
              return const LoginScreen();
            }

            // Sempre retorna AdminDashboardScreen para qualquer usuário logado
            return const AdminDashboardScreen();
          },
        ),
      ), // child: MaterialApp
    ); // AppStartupWrapper
  }
}

// Para executar o app, use os comandos:
// flutter pub get
// flutter run

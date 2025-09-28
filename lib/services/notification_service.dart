import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/agendamento.dart';
import '../models/usuario.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  static bool _isInitialized = false;

  /// Inicializar serviço de notificações
  static Future<void> initialize() async {
    if (_isInitialized) return;

    // Inicializar timezone para notificações agendadas
    tz.initializeTimeZones();

    // Configurar notificações locais
    await _initializeLocalNotifications();

    // Configurar Firebase Messaging (apenas para mobile)
    if (!kIsWeb) {
      await _initializeFirebaseMessaging();
    }

    _isInitialized = true;
    print('Serviço de notificações inicializado!');
  }

  /// Inicializar notificações locais
  static Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Solicitar permissões (Android 13+)
    if (!kIsWeb && Platform.isAndroid) {
      final plugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await plugin?.requestExactAlarmsPermission();
      await plugin?.requestNotificationsPermission();
    }
  }

  /// Inicializar Firebase Messaging
  static Future<void> _initializeFirebaseMessaging() async {
    try {
      // Solicitar permissão para notificações push
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            badge: true,
            sound: true,
            carPlay: false,
            criticalAlert: false,
            provisional: false,
            announcement: false,
          );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('Usuário concedeu permissão para notificações');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        print('Usuário concedeu permissão provisória');
      } else {
        print('Usuário negou permissão para notificações');
        return;
      }

      // Obter token FCM
      String? token = await _firebaseMessaging.getToken();
      print('Token FCM: $token');

      // Configurar handlers
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

      // Verificar se app foi aberto via notificação
      RemoteMessage? initialMessage = await _firebaseMessaging
          .getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }
    } catch (e) {
      print('Erro ao inicializar Firebase Messaging: $e');
    }
  }

  /// Callback quando notificação local é tocada
  static void _onNotificationTapped(NotificationResponse response) {
    print('Notificação tocada: ${response.payload}');
    
  }

  /// Handler para mensagens em primeiro plano
  static void _handleForegroundMessage(RemoteMessage message) {
    print(
      'Mensagem recebida em primeiro plano: ${message.notification?.title}',
    );

    // Mostrar notificação local customizada
    _showLocalNotification(
      id: message.hashCode,
      title: message.notification?.title ?? 'CORTE REAL',
      body: message.notification?.body ?? 'Nova mensagem',
      payload: message.data.toString(),
    );
  }

  /// Handler para quando app é aberto via notificação
  static void _handleMessageOpenedApp(RemoteMessage message) {
    print('App aberto via notificação: ${message.notification?.title}');
   
  }

  /// Handler para mensagens em background
  @pragma('vm:entry-point')
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print('Mensagem em background: ${message.notification?.title}');
  }

  /// Mostrar notificação local simples
  static Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'barbearia_channel',
      'Barbearia Notifications',
      channelDescription: 'Notificações da barbearia CORTE REAL',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFFD4AF37), // Cor secundária da barbearia
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(id, title, body, details, payload: payload);
  }

  /// Agendar notificação local para data/hora específica
  static Future<void> _scheduleLocalNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'barbearia_scheduled',
      'Lembretes de Agendamento',
      channelDescription: 'Lembretes automáticos de agendamentos',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFFD4AF37),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Notificação de confirmação de agendamento
  static Future<void> notificarAgendamentoCriado({
    required Agendamento agendamento,
    required Usuario usuario,
  }) async {
    await _showLocalNotification(
      id: agendamento.hashCode,
      title: '✅ Agendamento Confirmado!',
      body:
          'Seu agendamento para ${_formatDateTime(agendamento.dataHora)} foi confirmado com sucesso.',
      payload: 'agendamento_criado:${agendamento.id}',
    );

    // Agendar lembretes automáticos
    await _agendarLembretes(agendamento, usuario);
  }

  /// Notificação de alteração de status
  static Future<void> notificarStatusAlterado({
    required Agendamento agendamento,
    required StatusAgendamento novoStatus,
  }) async {
    String titulo = '';
    String corpo = '';

    switch (novoStatus) {
      case StatusAgendamento.confirmado:
        titulo = '✅ Agendamento Confirmado';
        corpo =
            'Seu agendamento para ${_formatDateTime(agendamento.dataHora)} foi confirmado pela barbearia.';
        break;
      case StatusAgendamento.cancelado:
        titulo = '❌ Agendamento Cancelado';
        corpo =
            'Seu agendamento para ${_formatDateTime(agendamento.dataHora)} foi cancelado.';
        break;
      case StatusAgendamento.emAndamento:
        titulo = '⏳ Serviço Iniciado';
        corpo = 'Seu atendimento começou! Aguarde na barbearia.';
        break;
      case StatusAgendamento.concluido:
        titulo = '🎉 Serviço Concluído';
        corpo =
            'Seu atendimento foi finalizado. Obrigado por escolher a CORTE REAL!';
        break;
      default:
        return;
    }

    await _showLocalNotification(
      id: agendamento.hashCode + novoStatus.index,
      title: titulo,
      body: corpo,
      payload: 'status_alterado:${agendamento.id}:${novoStatus.name}',
    );
  }

  /// Agendar lembretes automáticos para um agendamento
  static Future<void> _agendarLembretes(
    Agendamento agendamento,
    Usuario usuario,
  ) async {
    final dataAgendamento = agendamento.dataHora;
    final agora = DateTime.now();

    // Lembrete 24 horas antes
    final lembrete24h = dataAgendamento.subtract(const Duration(hours: 24));
    if (lembrete24h.isAfter(agora)) {
      await _scheduleLocalNotification(
        id: agendamento.hashCode + 1000,
        title: '⏰ Lembrete: Agendamento Amanhã',
        body:
            'Você tem um agendamento amanhã às ${_formatTime(dataAgendamento)} na CORTE REAL.',
        scheduledDate: lembrete24h,
        payload: 'lembrete_24h:${agendamento.id}',
      );
    }

    // Lembrete 2 horas antes
    final lembrete2h = dataAgendamento.subtract(const Duration(hours: 2));
    if (lembrete2h.isAfter(agora)) {
      await _scheduleLocalNotification(
        id: agendamento.hashCode + 2000,
        title: '🔔 Seu agendamento é em 2 horas!',
        body:
            'Prepare-se! Seu atendimento é às ${_formatTime(dataAgendamento)}.',
        scheduledDate: lembrete2h,
        payload: 'lembrete_2h:${agendamento.id}',
      );
    }

    // Lembrete 30 minutos antes
    final lembrete30min = dataAgendamento.subtract(const Duration(minutes: 30));
    if (lembrete30min.isAfter(agora)) {
      await _scheduleLocalNotification(
        id: agendamento.hashCode + 3000,
        title: '🏃‍♂️ Agendamento em 30 minutos!',
        body:
            'É hora de se dirigir à barbearia. Seu horário é às ${_formatTime(dataAgendamento)}.',
        scheduledDate: lembrete30min,
        payload: 'lembrete_30min:${agendamento.id}',
      );
    }

    print('Lembretes agendados para agendamento ${agendamento.id}');
  }

  /// Notificação de promoção semanal
  static Future<void> enviarPromocaoSemanal() async {
    await _showLocalNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: '🎉 Promoção Especial CORTE REAL!',
      body: 'Esta semana: Pacote Completo com 25% OFF! Agende já seu horário.',
      payload: 'promocao_semanal',
    );
  }

  /// Notificação para administradores sobre novos agendamentos
  static Future<void> notificarNovoAgendamentoAdmin({
    required Agendamento agendamento,
    required Usuario cliente,
  }) async {
    await _showLocalNotification(
      id: agendamento.hashCode + 5000,
      title: '📅 Novo Agendamento Recebido',
      body:
          'Cliente ${cliente.nome} agendou para ${_formatDateTime(agendamento.dataHora)}.',
      payload: 'novo_agendamento_admin:${agendamento.id}',
    );
  }

  /// Cancelar todas as notificações de um agendamento
  static Future<void> cancelarNotificacesAgendamento(
    String agendamentoId,
  ) async {
    final agendamento = agendamentoId.hashCode;

    // Cancelar notificações relacionadas ao agendamento
    await _localNotifications.cancel(agendamento);
    await _localNotifications.cancel(agendamento + 1000); // 24h
    await _localNotifications.cancel(agendamento + 2000); // 2h
    await _localNotifications.cancel(agendamento + 3000); // 30min

    print('Notificações canceladas para agendamento $agendamentoId');
  }

  /// Listar todas as notificações pendentes (para debug)
  static Future<List<PendingNotificationRequest>>
  listarNotificacoesPendentes() async {
    return await _localNotifications.pendingNotificationRequests();
  }

  /// Cancelar todas as notificações
  static Future<void> cancelarTodasNotificacoes() async {
    await _localNotifications.cancelAll();
    print('Todas as notificações foram canceladas');
  }

  /// Obter token FCM atual
  static Future<String?> obterTokenFCM() async {
    if (kIsWeb) return null;
    return await _firebaseMessaging.getToken();
  }

  /// Formatação auxiliares
  static String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.month.toString().padLeft(2, '0')} às '
        '${_formatTime(dateTime)}';
  }

  static String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Agendar promoções semanais recorrentes
  static Future<void> agendarPromocoesSemanas() async {
    // Agendar para toda sexta-feira às 10:00
    final agora = DateTime.now();
    var proximaSexta = DateTime(agora.year, agora.month, agora.day);

    // Encontrar próxima sexta-feira
    while (proximaSexta.weekday != DateTime.friday) {
      proximaSexta = proximaSexta.add(const Duration(days: 1));
    }

    proximaSexta = DateTime(
      proximaSexta.year,
      proximaSexta.month,
      proximaSexta.day,
      10, // 10:00
    );

    if (proximaSexta.isBefore(agora)) {
      proximaSexta = proximaSexta.add(const Duration(days: 7));
    }

    await _scheduleLocalNotification(
      id: 99999, // ID fixo para promoções
      title: '🎉 Sexta-feira de Promoções!',
      body: 'Confira nossas ofertas especiais desta semana na CORTE REAL!',
      scheduledDate: proximaSexta,
      payload: 'promocao_sexta',
    );

    print('Promoção semanal agendada para $proximaSexta');
  }

  /// Método público para testar notificações
  static Future<void> testarNotificacao() async {
    await _showLocalNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: '🧪 Teste - CORTE REAL',
      body: 'Notificações funcionando perfeitamente! ✅',
      payload: 'teste_notificacao',
    );
  }
}

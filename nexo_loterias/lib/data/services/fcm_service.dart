import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FcmService {
  final _fcm = FirebaseMessaging.instance;
  final _localNotif = FlutterLocalNotificationsPlugin();

  static const _channelId = 'nexo_resultados';
  static const _channelName = 'Resultados de Loterias';
  static const _channelDesc = 'Notificações de novos resultados e prêmios acumulados';

  Future<void> inicializar() async {
    await _configurarLocalNotifications();
    await _solicitarPermissao();
    await _configurarHandlers();
  }

  Future<void> _configurarLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);

    await _localNotif.initialize(settings,
        onDidReceiveNotificationResponse: (details) {
      debugPrint('Notificação clicada: ${details.payload}');
    });

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
      playSound: true,
    );

    await _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _solicitarPermissao() async {
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _configurarHandlers() async {
    FirebaseMessaging.onMessage.listen((message) {
      _mostrarNotificacaoLocal(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('App aberto via notificação: ${message.messageId}');
    });

    final initial = await _fcm.getInitialMessage();
    if (initial != null) {
      debugPrint('App iniciado via notificação: ${initial.messageId}');
    }
  }

  Future<void> _mostrarNotificacaoLocal(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(''),
    );

    await _localNotif.show(
      notification.hashCode,
      notification.title ?? 'NEXO LOTERIAS',
      notification.body ?? '',
      const NotificationDetails(android: androidDetails),
      payload: message.data.toString(),
    );
  }

  Future<void> assinarTopico(String topico) async {
    await _fcm.subscribeToTopic(topico);
    debugPrint('FCM: inscrito em $topico');
  }

  Future<void> cancelarTopico(String topico) async {
    await _fcm.unsubscribeFromTopic(topico);
    debugPrint('FCM: cancelado $topico');
  }

  Future<void> assinarTopicoModalidade(String modalidadeId) async {
    await assinarTopico('resultados_$modalidadeId');
  }

  Future<void> assinarTopicoResultados() async {
    await assinarTopico('resultados_todos');
    await assinarTopico('mega_acumulada');
  }

  Future<String?> obterToken() => _fcm.getToken();
}

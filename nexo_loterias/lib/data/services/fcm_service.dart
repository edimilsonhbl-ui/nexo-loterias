import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM Background: ${message.notification?.title}');
}

class FcmService {
  final _messaging = FirebaseMessaging.instance;

  Future<void> inicializar({
    required Function(RemoteMessage) onMensagem,
    required Function(RemoteMessage) onMensagemAberta,
  }) async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('FCM permissão: ${settings.authorizationStatus}');

    FirebaseMessaging.onMessage.listen(onMensagem);
    FirebaseMessaging.onMessageOpenedApp.listen(onMensagemAberta);

    final inicial = await _messaging.getInitialMessage();
    if (inicial != null) onMensagemAberta(inicial);
  }

  Future<String?> obterToken() => _messaging.getToken();

  Future<void> assinarTopico(String topico) =>
      _messaging.subscribeToTopic(topico);

  Future<void> cancelarTopico(String topico) =>
      _messaging.unsubscribeFromTopic(topico);

  Future<void> assinarTopicoModalidade(String modalidadeId) =>
      assinarTopico('resultado_$modalidadeId');

  Future<void> assinarAcumulados() =>
      assinarTopico('acumulados');

  Future<void> assinarNovos() =>
      assinarTopico('novos_concursos');
}

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

class HomeWidgetService {
  static const _appGroupId = 'com.nexoloterias.nexo_loterias';
  static const _providerName = 'NexoWidgetProvider';

  static Future<void> inicializar() async {
    await HomeWidget.setAppGroupId(_appGroupId);
  }

  static Future<void> atualizarPalpite({
    required List<int> numeros,
    required String modalidade,
  }) async {
    try {
      final numerosStr = numeros.map((n) => n.toString().padLeft(2, '0')).join('  ');
      final hoje = DateTime.now();
      final dataStr =
          '${hoje.day.toString().padLeft(2, '0')}/${hoje.month.toString().padLeft(2, '0')}/${hoje.year}';

      await HomeWidget.saveWidgetData('palpite_numeros', numerosStr);
      await HomeWidget.saveWidgetData('palpite_modalidade', modalidade);
      await HomeWidget.saveWidgetData('palpite_data', 'Gerado em $dataStr');

      await HomeWidget.updateWidget(
        androidName: _providerName,
      );
    } catch (e) {
      debugPrint('HomeWidget erro: $e');
    }
  }
}

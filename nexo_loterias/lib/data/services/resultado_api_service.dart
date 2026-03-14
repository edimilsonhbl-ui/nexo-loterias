import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ResultadoApiService {
  static const _baseUrl =
      'https://servicebus2.caixa.gov.br/portaldeloterias/api';

  final _db = FirebaseFirestore.instance;

  static const _apiNomes = {
    'mega-sena': 'megasena',
    'lotofacil': 'lotofacil',
    'quina': 'quina',
    'dupla-sena': 'duplasena',
    'lotomania': 'lotomania',
  };

  Future<bool> sincronizarTodos() async {
    final resultados = await Future.wait([
      sincronizarModalidade('mega-sena'),
      sincronizarModalidade('lotofacil'),
      sincronizarModalidade('quina'),
    ]);
    final sucesso = resultados.any((r) => r);
    if (sucesso) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'ultima_sync', DateTime.now().toIso8601String());
    }
    return sucesso;
  }

  Future<bool> sincronizarModalidade(String modalidadeId) async {
    try {
      final apiNome = _apiNomes[modalidadeId];
      if (apiNome == null) return false;

      final response = await http
          .get(
            Uri.parse('$_baseUrl/$apiNome/'),
            headers: {
              'Accept': 'application/json',
              'User-Agent': 'NexoLoterias/1.0',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return false;

      final data = json.decode(response.body) as Map<String, dynamic>;
      await _salvarNoFirestore(modalidadeId, data);
      return true;
    } catch (e) {
      debugPrint('API Caixa erro [$modalidadeId]: $e');
      return false;
    }
  }

  Future<void> _salvarNoFirestore(
      String modalidadeId, Map<String, dynamic> data) async {
    final numero = data['numero'] as int? ?? 0;
    final dataStr = data['dataApuracao'] as String? ?? '';

    final dezenas = (data['listaDezenas'] as List? ?? [])
        .map((d) => int.tryParse(d.toString()) ?? 0)
        .where((n) => n > 0)
        .toList()
      ..sort();

    final premio =
        (data['valorEstimadoProximoConcurso'] as num?)?.toDouble() ?? 0;
    final acumulado = data['acumulado'] as bool? ?? false;

    DateTime dataSorteio;
    try {
      final parts = dataStr.split('/');
      dataSorteio = DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
    } catch (_) {
      dataSorteio = DateTime.now();
    }

    final docId = '${modalidadeId}_$numero';
    await _db.collection('concursos').doc(docId).set({
      'id': docId,
      'modalidadeId': modalidadeId,
      'numeroConcurso': numero,
      'dataSorteio': dataSorteio.toIso8601String(),
      'dezenasSorteadas': dezenas,
      'premioEstimado': premio,
      'acumulado': acumulado,
      'atualizadoEm': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<DateTime?> ultimaSync() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString('ultima_sync');
    if (str == null) return null;
    return DateTime.tryParse(str);
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/estatistica.dart';
import '../models/modalidade.dart';

class EstatisticaRepository {
  final _db = FirebaseFirestore.instance;

  Stream<EstatisticasModalidade?> stream(String modalidadeId) {
    return _db
        .collection('estatisticas')
        .doc(modalidadeId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      final data = doc.data()!;
      return _fromFirestore(modalidadeId, data);
    });
  }

  Future<EstatisticasModalidade?> buscar(String modalidadeId) async {
    final doc = await _db.collection('estatisticas').doc(modalidadeId).get();
    if (!doc.exists) return null;
    return _fromFirestore(modalidadeId, doc.data()!);
  }

  Future<void> salvar(EstatisticasModalidade stats) async {
    await _db.collection('estatisticas').doc(stats.modalidadeId).set({
      'modalidadeId': stats.modalidadeId,
      'totalConcursos': stats.totalConcursos,
      'maisSorteados': stats.maisSorteados.take(10).map((e) => {
            'numero': e.numero,
            'frequencia': e.frequencia,
          }).toList(),
      'menosSorteados': stats.menosSorteados.take(10).map((e) => {
            'numero': e.numero,
            'frequencia': e.frequencia,
          }).toList(),
      'atrasados': stats.maisAtrasados.take(10).map((e) => {
            'numero': e.numero,
            'atraso': e.atraso,
          }).toList(),
      'mediaParesUltimos10': stats.mediaParesUltimos10,
      'mediaImparesUltimos10': stats.mediaImparesUltimos10,
      'somaMediaUltimos10': stats.somaMediaUltimos10,
      'atualizadoEm': DateTime.now().toIso8601String(),
    });
  }

  EstatisticasModalidade _fromFirestore(String modalidadeId, Map<String, dynamic> data) {
    // Usa o universo real do modelo centralizado — evita hardcode incorreto
    // para Quina (80), Lotomania (100), Dupla-Sena (50), Timemania (80) etc.
    final universo = Modalidade.todas
        .firstWhere(
          (m) => m.id == modalidadeId,
          orElse: () => Modalidade.todas.first,
        )
        .universoNumeros;
    final total = data['totalConcursos'] as int? ?? 0;

    final numeros = List.generate(universo, (i) {
      return EstatisticaNumero(
        numero: i + 1,
        frequencia: 0,
        ultimoConcurso: 0,
        concursoAtual: total,
      );
    });

    final mais = (data['maisSorteados'] as List? ?? []);
    final menos = (data['menosSorteados'] as List? ?? []);
    for (final item in [...mais, ...menos]) {
      final n = item['numero'] as int;
      final idx = n - 1;
      if (idx >= 0 && idx < numeros.length) {
        numeros[idx] = EstatisticaNumero(
          numero: n,
          frequencia: item['frequencia'] as int? ?? 0,
          ultimoConcurso: 0,
          concursoAtual: total,
        );
      }
    }

    return EstatisticasModalidade(
      modalidadeId: modalidadeId,
      totalConcursos: total,
      numeros: numeros,
      mediaParesUltimos10: (data['mediaParesUltimos10'] as num?)?.toDouble() ?? 0,
      mediaImparesUltimos10: (data['mediaImparesUltimos10'] as num?)?.toDouble() ?? 0,
      somaMediaUltimos10: (data['somaMediaUltimos10'] as num?)?.toDouble() ?? 0,
    );
  }
}

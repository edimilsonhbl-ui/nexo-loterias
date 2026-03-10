import 'dart:math';
import '../models/estatistica.dart';
import '../models/concurso.dart';

class EstatisticasService {
  EstatisticasModalidade calcular(String modalidadeId, List<Concurso> concursos) {
    if (concursos.isEmpty) return _vazia(modalidadeId);

    final total = concursos.length;
    final frequencia = <int, int>{};
    final ultimaAparicao = <int, int>{};

    for (final c in concursos) {
      for (final n in c.dezenasSorteadas) {
        frequencia[n] = (frequencia[n] ?? 0) + 1;
        if ((ultimaAparicao[n] ?? 0) < c.numeroConcurso) {
          ultimaAparicao[n] = c.numeroConcurso;
        }
      }
    }

    final concursoAtual = concursos.map((c) => c.numeroConcurso).reduce((a, b) => a > b ? a : b);
    final universo = _universo(modalidadeId);

    final numeros = List.generate(universo, (i) {
      final n = i + 1;
      return EstatisticaNumero(
        numero: n,
        frequencia: frequencia[n] ?? 0,
        ultimoConcurso: ultimaAparicao[n] ?? 0,
        concursoAtual: concursoAtual,
      );
    });

    final ultimos10 = concursos.length >= 10 ? concursos.sublist(0, 10) : concursos;
    double totalPares = 0, totalImpares = 0, totalSoma = 0;
    for (final c in ultimos10) {
      final pares = c.dezenasSorteadas.where((n) => n % 2 == 0).length;
      totalPares += pares;
      totalImpares += c.dezenasSorteadas.length - pares;
      totalSoma += c.dezenasSorteadas.reduce((a, b) => a + b).toDouble();
    }

    return EstatisticasModalidade(
      modalidadeId: modalidadeId,
      totalConcursos: total,
      numeros: numeros,
      mediaParesUltimos10: totalPares / ultimos10.length,
      mediaImparesUltimos10: totalImpares / ultimos10.length,
      somaMediaUltimos10: totalSoma / ultimos10.length,
    );
  }

  EstatisticasModalidade _vazia(String modalidadeId) {
    return EstatisticasModalidade(
      modalidadeId: modalidadeId,
      totalConcursos: 0,
      numeros: [],
      mediaParesUltimos10: 0,
      mediaImparesUltimos10: 0,
      somaMediaUltimos10: 0,
    );
  }

  int _universo(String modalidadeId) {
    switch (modalidadeId) {
      case 'mega-sena': return 60;
      case 'lotofacil': return 25;
      default: return 60;
    }
  }

  List<Concurso> gerarDadosExemplo(String modalidadeId) {
    final rng = Random(42);
    final universo = _universo(modalidadeId);
    final qtdSorteados = modalidadeId == 'lotofacil' ? 15 : 6;

    return List.generate(100, (i) {
      final disponiveis = List.generate(universo, (j) => j + 1)..shuffle(rng);
      final dezenas = disponiveis.take(qtdSorteados).toList()..sort();
      return Concurso(
        id: '${modalidadeId}_${i + 1}',
        modalidadeId: modalidadeId,
        numeroConcurso: 2800 + i,
        dataSorteio: DateTime(2025, 1, 1).add(Duration(days: i * 3)),
        dezenasSorteadas: dezenas,
        premioEstimado: (5000000 + rng.nextInt(50000000)).toDouble(),
        acumulado: rng.nextInt(5) == 0,
      );
    });
  }
}

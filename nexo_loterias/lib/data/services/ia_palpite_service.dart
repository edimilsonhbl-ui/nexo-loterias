import 'dart:math';
import '../models/concurso.dart';
import '../models/modalidade.dart';

enum PerfilIA { conservador, equilibrado, ousado }
enum JanelaAnalise { ultimos10, ultimos30, ultimos50, ultimos100 }

class IaPalpiteService {
  List<int> gerarPalpite({
    required Modalidade modalidade,
    required List<Concurso> historico,
    required PerfilIA perfil,
    required JanelaAnalise janela,
  }) {
    final concursos = _filtrarJanela(historico, janela);
    if (concursos.isEmpty) return _sortearAleatorio(modalidade);

    final frequencia = _calcularFrequencia(concursos, modalidade.universoNumeros);
    final atraso = _calcularAtraso(concursos, modalidade.universoNumeros);

    return _gerarPorPerfil(
      modalidade: modalidade,
      frequencia: frequencia,
      atraso: atraso,
      perfil: perfil,
    );
  }

  List<int> _gerarPorPerfil({
    required Modalidade modalidade,
    required Map<int, int> frequencia,
    required Map<int, int> atraso,
    required PerfilIA perfil,
  }) {
    final universo = modalidade.universoNumeros;
    final qtd = modalidade.numerosMin;
    final todos = List.generate(universo, (i) => i + 1);

    switch (perfil) {
      case PerfilIA.conservador:
        // Prioriza números com alta frequência (mais sorteados)
        todos.sort((a, b) =>
            (frequencia[b] ?? 0).compareTo(frequencia[a] ?? 0));
        return (todos.take(qtd * 2).toList()..shuffle()).take(qtd).toList()..sort();

      case PerfilIA.ousado:
        // Prioriza números mais atrasados
        todos.sort((a, b) =>
            (atraso[b] ?? 0).compareTo(atraso[a] ?? 0));
        return (todos.take(qtd * 2).toList()..shuffle()).take(qtd).toList()..sort();

      case PerfilIA.equilibrado:
        // Mistura frequentes e atrasados
        todos.sort((a, b) =>
            (frequencia[b] ?? 0).compareTo(frequencia[a] ?? 0));
        final frequentes = todos.take(qtd).toList();

        final todosAtraso = List.generate(universo, (i) => i + 1);
        todosAtraso.sort((a, b) =>
            (atraso[b] ?? 0).compareTo(atraso[a] ?? 0));
        final atrasados = todosAtraso.take(qtd).toList();

        final candidatos = {...frequentes, ...atrasados}.toList()..shuffle();
        final selecionados = <int>[];

        final meio = universo ~/ 2;
        final rng = Random();

        for (final n in candidatos) {
          if (selecionados.length >= qtd) break;
          if (selecionados.contains(n)) continue;

          final pares = selecionados.where((x) => x % 2 == 0).length;
          final altos = selecionados.where((x) => x > meio).length;

          final precisaPar = pares < selecionados.length ~/ 2;
          final precisaAlto = altos < selecionados.length ~/ 2;

          if (n % 2 == 0 && !precisaPar && rng.nextDouble() > 0.4) continue;
          if (n > meio && !precisaAlto && rng.nextDouble() > 0.4) continue;

          selecionados.add(n);
        }

        // Completar se não atingiu o mínimo
        for (final n in candidatos) {
          if (selecionados.length >= qtd) break;
          if (!selecionados.contains(n)) selecionados.add(n);
        }

        return selecionados..sort();
    }
  }

  Map<int, int> _calcularFrequencia(List<Concurso> concursos, int universo) {
    final freq = <int, int>{};
    for (final c in concursos) {
      for (final n in c.dezenasSorteadas) {
        freq[n] = (freq[n] ?? 0) + 1;
      }
    }
    return freq;
  }

  Map<int, int> _calcularAtraso(List<Concurso> concursos, int universo) {
    if (concursos.isEmpty) return {};
    final ultimo = concursos.map((c) => c.numeroConcurso).reduce(max);
    final ultimaAparicao = <int, int>{};

    for (final c in concursos) {
      for (final n in c.dezenasSorteadas) {
        if ((ultimaAparicao[n] ?? 0) < c.numeroConcurso) {
          ultimaAparicao[n] = c.numeroConcurso;
        }
      }
    }

    final atraso = <int, int>{};
    for (int n = 1; n <= universo; n++) {
      atraso[n] = ultimo - (ultimaAparicao[n] ?? 0);
    }
    return atraso;
  }

  List<Concurso> _filtrarJanela(List<Concurso> historico, JanelaAnalise janela) {
    final ordenado = List<Concurso>.from(historico)
      ..sort((a, b) => b.numeroConcurso.compareTo(a.numeroConcurso));

    switch (janela) {
      case JanelaAnalise.ultimos10: return ordenado.take(10).toList();
      case JanelaAnalise.ultimos30: return ordenado.take(30).toList();
      case JanelaAnalise.ultimos50: return ordenado.take(50).toList();
      case JanelaAnalise.ultimos100: return ordenado.take(100).toList();
    }
  }

  List<int> _sortearAleatorio(Modalidade modalidade) {
    final todos = List.generate(modalidade.universoNumeros, (i) => i + 1)
      ..shuffle();
    return todos.take(modalidade.numerosMin).toList()..sort();
  }

  String descricaoPerfil(PerfilIA perfil) {
    switch (perfil) {
      case PerfilIA.conservador:
        return 'Baseado nos números mais frequentes do histórico';
      case PerfilIA.ousado:
        return 'Baseado nos números mais atrasados (overdue)';
      case PerfilIA.equilibrado:
        return 'Combinação de frequentes e atrasados com equilíbrio';
    }
  }

  String descricaoJanela(JanelaAnalise janela) {
    switch (janela) {
      case JanelaAnalise.ultimos10: return 'Últimos 10 concursos';
      case JanelaAnalise.ultimos30: return 'Últimos 30 concursos';
      case JanelaAnalise.ultimos50: return 'Últimos 50 concursos';
      case JanelaAnalise.ultimos100: return 'Últimos 100 concursos';
    }
  }
}

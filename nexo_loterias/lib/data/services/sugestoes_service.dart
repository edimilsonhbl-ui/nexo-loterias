import 'dart:math';
import '../models/modalidade.dart';
import '../models/estatistica.dart';

export '../models/estatistica.dart' show EstatisticasModalidade;

enum TipoSugestao { equilibrado, conservador, ousado }

class SugestoesService {
  final _rng = Random();

  /// Gera um jogo com base no tipo e nos filtros selecionados.
  /// Quando [estatisticas] é fornecido, prioriza números do histórico real:
  /// - Conservador → mais sorteados
  /// - Equilibrado  → mix de mais sorteados + aleatórios
  /// - Ousado       → atrasados + aleatórios
  List<int> gerar({
    required Modalidade modalidade,
    required TipoSugestao tipo,
    required bool evitarSequencias,
    required bool equilibrarParesImpares,
    required bool equilibrarAltasBaixas,
    EstatisticasModalidade? estatisticas,
  }) {
    const maxTentativas = 500;
    final qtd = modalidade.numerosMin;
    final universo = modalidade.universoNumeros;

    final candidatos = _montarCandidatos(tipo, universo, estatisticas);

    for (int t = 0; t < maxTentativas; t++) {
      final numeros = _sortearDe(candidatos, universo, qtd);

      if (evitarSequencias && _temSequencia(numeros, 3)) continue;
      if (equilibrarParesImpares && !_paresEquilibrados(numeros, tipo)) continue;
      if (equilibrarAltasBaixas && !_altasBaixasEquilibrados(numeros, universo, tipo)) continue;
      if (!_perfilOk(numeros, universo, tipo)) continue;

      return numeros;
    }
    // Fallback sem filtros caso nenhuma combinação satisfaça
    return _sortearDe(candidatos, universo, qtd);
  }

  /// Constrói a lista de candidatos priorizados conforme o perfil e os dados
  /// do Firestore. Quando não há dados reais, retorna o universo completo.
  List<int> _montarCandidatos(
    TipoSugestao tipo,
    int universo,
    EstatisticasModalidade? stats,
  ) {
    if (stats == null || stats.totalConcursos == 0) {
      return List.generate(universo, (i) => i + 1);
    }

    switch (tipo) {
      case TipoSugestao.conservador:
        // Prioriza os mais sorteados: lista tem peso dobrado
        final mais = stats.maisSorteados.map((e) => e.numero).toList();
        final todos = List.generate(universo, (i) => i + 1);
        return [...mais, ...mais, ...todos]; // peso 3× para os mais frequentes

      case TipoSugestao.ousado:
        // Prioriza os atrasados: lista tem peso dobrado
        final atrasados = stats.maisAtrasados.map((e) => e.numero).toList();
        final todos = List.generate(universo, (i) => i + 1);
        return [...atrasados, ...atrasados, ...todos];

      case TipoSugestao.equilibrado:
        // Mix: metade dos mais sorteados + metade dos neutros
        final mais = stats.maisSorteados.map((e) => e.numero).toList();
        final todos = List.generate(universo, (i) => i + 1);
        return [...mais, ...todos]; // peso 2× para os mais frequentes
    }
  }

  List<List<int>> gerarFechamento({
    required Modalidade modalidade,
    required List<int> numerosBase,
  }) {
    final qtd = modalidade.numerosMin;
    if (numerosBase.length <= qtd) return [numerosBase];

    final combinacoes = <List<int>>[];
    _combinar(numerosBase, qtd, 0, [], combinacoes);

    combinacoes.shuffle(_rng);
    return combinacoes.take(10).toList();
  }

  void _combinar(
    List<int> src,
    int k,
    int start,
    List<int> atual,
    List<List<int>> resultado,
  ) {
    if (atual.length == k) {
      resultado.add(List.from(atual));
      return;
    }
    for (int i = start; i < src.length; i++) {
      atual.add(src[i]);
      _combinar(src, k, i + 1, atual, resultado);
      atual.removeLast();
      if (resultado.length >= 200) return;
    }
  }

  List<int> _sortearDe(List<int> pool, int universo, int qtd) {
    final shuffled = List<int>.from(pool)..shuffle(_rng);
    final resultado = <int>{};
    for (final n in shuffled) {
      if (n >= 1 && n <= universo) resultado.add(n);
      if (resultado.length == qtd) break;
    }
    // Completa com aleatórios se necessário
    if (resultado.length < qtd) {
      final faltantes = List.generate(universo, (i) => i + 1)
        ..shuffle(_rng);
      for (final n in faltantes) {
        resultado.add(n);
        if (resultado.length == qtd) break;
      }
    }
    return resultado.toList()..sort();
  }

  bool _temSequencia(List<int> nums, int tamanho) {
    int seq = 1;
    for (int i = 1; i < nums.length; i++) {
      if (nums[i] == nums[i - 1] + 1) {
        seq++;
        if (seq >= tamanho) return true;
      } else {
        seq = 1;
      }
    }
    return false;
  }

  bool _paresEquilibrados(List<int> nums, TipoSugestao tipo) {
    final pares = nums.where((n) => n % 2 == 0).length;
    final ratioPares = pares / nums.length;
    switch (tipo) {
      case TipoSugestao.equilibrado:
        return ratioPares >= 0.35 && ratioPares <= 0.65;
      case TipoSugestao.conservador:
        return ratioPares >= 0.4 && ratioPares <= 0.6;
      case TipoSugestao.ousado:
        return true;
    }
  }

  bool _altasBaixasEquilibrados(List<int> nums, int universo, TipoSugestao tipo) {
    final meio = universo ~/ 2;
    final altos = nums.where((n) => n > meio).length;
    final ratio = altos / nums.length;
    switch (tipo) {
      case TipoSugestao.equilibrado:
        return ratio >= 0.35 && ratio <= 0.65;
      case TipoSugestao.conservador:
        return ratio >= 0.4 && ratio <= 0.6;
      case TipoSugestao.ousado:
        return true;
    }
  }

  bool _perfilOk(List<int> nums, int universo, TipoSugestao tipo) {
    final soma = nums.reduce((a, b) => a + b);
    final somaMedia = universo * (universo + 1) / 2 * nums.length / universo;
    final desvio = (soma - somaMedia).abs() / somaMedia;
    switch (tipo) {
      case TipoSugestao.equilibrado:
        return desvio <= 0.15;
      case TipoSugestao.conservador:
        return desvio <= 0.1;
      case TipoSugestao.ousado:
        return desvio > 0.15;
    }
  }

  String avaliarJogo(List<int> nums, int universo) {
    final soma = nums.reduce((a, b) => a + b);
    final somaMedia = universo * (universo + 1) / 2 * nums.length / universo;
    final desvio = (soma - somaMedia).abs() / somaMedia;
    final pares = nums.where((n) => n % 2 == 0).length / nums.length;
    final meio = universo ~/ 2;
    final altos = nums.where((n) => n > meio).length / nums.length;
    if (desvio <= 0.1 && pares >= 0.4 && pares <= 0.6 && altos >= 0.4 && altos <= 0.6) {
      return 'Equilibrado';
    } else if (desvio > 0.2 || pares < 0.2 || pares > 0.8) {
      return 'Ousado';
    }
    return 'Conservador';
  }
}

import 'dart:math';
import '../models/modalidade.dart';

enum TipoFechamento { rapido, equilibrado, porOrcamento }

class ResultadoFechamento {
  final List<List<int>> jogos;
  final int totalJogos;
  final double custoTotal;
  final TipoFechamento tipo;
  final List<int> numerosBase;

  const ResultadoFechamento({
    required this.jogos,
    required this.totalJogos,
    required this.custoTotal,
    required this.tipo,
    required this.numerosBase,
  });
}

class FechamentoService {
  final _rng = Random();

  ResultadoFechamento gerar({
    required Modalidade modalidade,
    required List<int> numerosBase,
    required TipoFechamento tipo,
    double orcamento = 0,
  }) {
    final qtdMinima = modalidade.numerosMin;
    final valorJogo = _valorJogo(modalidade, qtdMinima);

    switch (tipo) {
      case TipoFechamento.rapido:
        return _fechamentoRapido(modalidade, numerosBase, qtdMinima, valorJogo);
      case TipoFechamento.equilibrado:
        return _fechamentoEquilibrado(modalidade, numerosBase, qtdMinima, valorJogo);
      case TipoFechamento.porOrcamento:
        return _fechamentoPorOrcamento(modalidade, numerosBase, qtdMinima, valorJogo, orcamento);
    }
  }

  // Gera todas as combinacoes possiveis (limitado a 50 jogos)
  ResultadoFechamento _fechamentoRapido(
      Modalidade modalidade, List<int> base, int k, double valorJogo) {
    final combinacoes = <List<int>>[];
    _combinar(base, k, 0, [], combinacoes, limite: 50);
    return ResultadoFechamento(
      jogos: combinacoes,
      totalJogos: combinacoes.length,
      custoTotal: combinacoes.length * valorJogo,
      tipo: TipoFechamento.rapido,
      numerosBase: base,
    );
  }

  // Gera combinacoes distribuindo os numeros de forma equilibrada
  ResultadoFechamento _fechamentoEquilibrado(
      Modalidade modalidade, List<int> base, int k, double valorJogo) {
    final jogos = <List<int>>[];
    final universo = modalidade.universoNumeros;
    final meio = universo ~/ 2;

    final baixos = base.where((n) => n <= meio).toList();
    final altos = base.where((n) => n > meio).toList();

    const maxJogos = 30;
    int tentativas = 0;

    while (jogos.length < maxJogos && tentativas < 2000) {
      tentativas++;
      baixos.shuffle(_rng);
      altos.shuffle(_rng);

      final qtdBaixos = k ~/ 2;
      final qtdAltos = k - qtdBaixos;

      if (baixos.length < qtdBaixos || altos.length < qtdAltos) break;

      final jogo = [
        ...baixos.take(qtdBaixos),
        ...altos.take(qtdAltos),
      ]..sort();

      if (!_jogoJaExiste(jogos, jogo)) {
        jogos.add(jogo);
      }
    }

    if (jogos.isEmpty) {
      return _fechamentoRapido(modalidade, base, k, valorJogo);
    }

    return ResultadoFechamento(
      jogos: jogos,
      totalJogos: jogos.length,
      custoTotal: jogos.length * valorJogo,
      tipo: TipoFechamento.equilibrado,
      numerosBase: base,
    );
  }

  // Gera o maximo de jogos dentro do orcamento informado
  ResultadoFechamento _fechamentoPorOrcamento(
      Modalidade modalidade, List<int> base, int k, double valorJogo, double orcamento) {
    final maxJogos = orcamento > 0 ? (orcamento / valorJogo).floor() : 10;
    final combinacoes = <List<int>>[];
    _combinar(base, k, 0, [], combinacoes, limite: maxJogos);

    return ResultadoFechamento(
      jogos: combinacoes,
      totalJogos: combinacoes.length,
      custoTotal: combinacoes.length * valorJogo,
      tipo: TipoFechamento.porOrcamento,
      numerosBase: base,
    );
  }

  void _combinar(
    List<int> src,
    int k,
    int start,
    List<int> atual,
    List<List<int>> resultado, {
    required int limite,
  }) {
    if (resultado.length >= limite) return;
    if (atual.length == k) {
      resultado.add(List.from(atual));
      return;
    }
    final restante = src.length - start;
    final precisam = k - atual.length;
    if (restante < precisam) return;

    for (int i = start; i < src.length; i++) {
      if (resultado.length >= limite) return;
      atual.add(src[i]);
      _combinar(src, k, i + 1, atual, resultado, limite: limite);
      atual.removeLast();
    }
  }

  bool _jogoJaExiste(List<List<int>> jogos, List<int> jogo) {
    for (final j in jogos) {
      if (j.length == jogo.length && _listasIguais(j, jogo)) return true;
    }
    return false;
  }

  bool _listasIguais(List<int> a, List<int> b) {
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  double _valorJogo(Modalidade modalidade, int qtd) {
    if (modalidade.id == 'mega-sena') {
      const tabela = {6: 5.0, 7: 35.0, 8: 140.0, 9: 420.0, 10: 1050.0};
      return tabela[qtd] ?? 5.0;
    } else if (modalidade.id == 'lotofacil') {
      const tabela = {15: 3.0, 16: 48.0, 17: 408.0, 18: 2448.0};
      return tabela[qtd] ?? 3.0;
    }
    return 3.0;
  }

  int totalCombinacoes(int n, int k) {
    if (k > n) return 0;
    BigInt num = BigInt.one;
    BigInt den = BigInt.one;
    for (int i = 0; i < k; i++) {
      num *= BigInt.from(n - i);
      den *= BigInt.from(i + 1);
    }
    final result = (num ~/ den).toInt();
    return result > 9999999 ? 9999999 : result;
  }
}

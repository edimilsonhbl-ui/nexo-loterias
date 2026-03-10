import 'dart:math';
import '../../data/models/modalidade.dart';

class ProbabilidadeUtil {
  ProbabilidadeUtil._();

  static BigInt fatorial(int n) {
    if (n <= 1) return BigInt.one;
    BigInt result = BigInt.one;
    for (int i = 2; i <= n; i++) {
      result *= BigInt.from(i);
    }
    return result;
  }

  static BigInt combinacao(int n, int k) {
    if (k > n) return BigInt.zero;
    if (k == 0 || k == n) return BigInt.one;
    return fatorial(n) ~/ (fatorial(k) * fatorial(n - k));
  }

  static double probabilidade(int universo, int sorteados, int escolhidos, int acertos) {
    final num = combinacao(escolhidos, acertos) * combinacao(universo - escolhidos, sorteados - acertos);
    final den = combinacao(universo, sorteados);
    if (den == BigInt.zero) return 0;
    return num.toDouble() / den.toDouble();
  }

  static Map<int, double> calcularProbabilidades(Modalidade modalidade, int qtd) {
    final Map<int, double> resultado = {};
    final sorteados = modalidade.faixasPremio.keys.reduce(max);
    for (final faixa in modalidade.faixasPremio.keys) {
      resultado[faixa] = probabilidade(modalidade.universoNumeros, sorteados, qtd, faixa);
    }
    return resultado;
  }

  static String formatarProbabilidade(double prob) {
    if (prob <= 0) return 'N/A';
    final inverso = (1 / prob).round();
    if (inverso < 1000000) {
      return '1 em ${_formatNum(inverso)}';
    } else if (inverso < 1000000000) {
      return '1 em ${(inverso / 1000000).toStringAsFixed(1)} mi';
    } else {
      return '1 em ${(inverso / 1000000000).toStringAsFixed(1)} bi';
    }
  }

  static String _formatNum(int n) {
    return n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  static double calcularValor(Modalidade modalidade, int qtd) {
    if (modalidade.id == 'mega-sena') {
      const tabela = {6: 5.0, 7: 35.0, 8: 140.0, 9: 420.0, 10: 1050.0, 11: 2310.0, 12: 4620.0, 13: 8580.0, 14: 15015.0, 15: 25025.0, 16: 40040.0, 17: 61880.0, 18: 92820.0, 19: 135660.0, 20: 193800.0};
      return tabela[qtd] ?? 5.0;
    } else if (modalidade.id == 'lotofacil') {
      const tabela = {15: 3.0, 16: 48.0, 17: 408.0, 18: 2448.0, 19: 11628.0, 20: 46512.0};
      return tabela[qtd] ?? 3.0;
    }
    return 3.0;
  }
}

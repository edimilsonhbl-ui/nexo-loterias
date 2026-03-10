import 'package:flutter/material.dart';
import '../data/models/modalidade.dart';
import '../data/models/aposta.dart';
import '../core/utils/probabilidade_util.dart';
import 'package:uuid/uuid.dart';

class JogoProvider extends ChangeNotifier {
  final _uuid = const Uuid();

  Modalidade? _modalidade;
  final List<int> _numerosSelecionados = [];

  Modalidade? get modalidade => _modalidade;
  List<int> get numerosSelecionados => List.unmodifiable(_numerosSelecionados);
  int get quantidade => _numerosSelecionados.length;

  bool get jogoValido =>
      _modalidade != null &&
      quantidade >= _modalidade!.numerosMin &&
      quantidade <= _modalidade!.numerosMax;

  double get valorAposta {
    if (_modalidade == null) return 0;
    return ProbabilidadeUtil.calcularValor(_modalidade!, quantidade);
  }

  Map<int, double> get probabilidades {
    if (_modalidade == null || !jogoValido) return {};
    return ProbabilidadeUtil.calcularProbabilidades(_modalidade!, quantidade);
  }

  void setModalidade(Modalidade modalidade) {
    _modalidade = modalidade;
    _numerosSelecionados.clear();
    notifyListeners();
  }

  void toggleNumero(int numero) {
    if (_numerosSelecionados.contains(numero)) {
      _numerosSelecionados.remove(numero);
    } else if (_modalidade != null && quantidade < _modalidade!.numerosMax) {
      _numerosSelecionados.add(numero);
      _numerosSelecionados.sort();
    }
    notifyListeners();
  }

  void limpar() {
    _numerosSelecionados.clear();
    notifyListeners();
  }

  void surpresinha() {
    if (_modalidade == null) return;
    _numerosSelecionados.clear();
    final todos = List.generate(_modalidade!.universoNumeros, (i) => i + 1);
    todos.shuffle();
    _numerosSelecionados.addAll(todos.take(_modalidade!.numerosMin));
    _numerosSelecionados.sort();
    notifyListeners();
  }

  void completar() {
    if (_modalidade == null || quantidade >= _modalidade!.numerosMin) return;
    final faltam = _modalidade!.numerosMin - quantidade;
    final disponiveis = List.generate(_modalidade!.universoNumeros, (i) => i + 1)
        .where((n) => !_numerosSelecionados.contains(n))
        .toList()
      ..shuffle();
    _numerosSelecionados.addAll(disponiveis.take(faltam));
    _numerosSelecionados.sort();
    notifyListeners();
  }

  Aposta gerarAposta() {
    return Aposta(
      id: _uuid.v4(),
      modalidadeId: _modalidade!.id,
      numerosEscolhidos: List.from(_numerosSelecionados),
      valorAposta: valorAposta,
      probabilidade: probabilidades[_modalidade!.numerosMin] ?? 0,
      criadaEm: DateTime.now(),
    );
  }
}

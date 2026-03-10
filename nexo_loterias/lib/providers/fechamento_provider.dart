import 'package:flutter/material.dart';
import '../data/models/modalidade.dart';
import '../data/services/fechamento_service.dart';

class FechamentoProvider extends ChangeNotifier {
  final _service = FechamentoService();

  Modalidade? _modalidade;
  final List<int> _numerosBase = [];
  TipoFechamento _tipo = TipoFechamento.equilibrado;
  double _orcamento = 50.0;
  ResultadoFechamento? _resultado;
  bool _processando = false;

  Modalidade? get modalidade => _modalidade;
  List<int> get numerosBase => List.unmodifiable(_numerosBase);
  TipoFechamento get tipo => _tipo;
  double get orcamento => _orcamento;
  ResultadoFechamento? get resultado => _resultado;
  bool get processando => _processando;

  int get minimoNumerosBase => (_modalidade?.numerosMin ?? 15) + 1;
  int get maximoNumerosBase => _modalidade?.universoNumeros ?? 25;

  bool get podeGerar =>
      _modalidade != null && _numerosBase.length > (_modalidade!.numerosMin);

  int get totalCombinacoesPossiveis {
    if (_modalidade == null || _numerosBase.length <= _modalidade!.numerosMin) return 0;
    return _service.totalCombinacoes(_numerosBase.length, _modalidade!.numerosMin);
  }

  void setModalidade(Modalidade modalidade) {
    if (_modalidade?.id != modalidade.id) {
      _modalidade = modalidade;
      _numerosBase.clear();
      _resultado = null;
      notifyListeners();
    }
  }

  void toggleNumero(int numero) {
    if (_numerosBase.contains(numero)) {
      _numerosBase.remove(numero);
    } else {
      _numerosBase.add(numero);
      _numerosBase.sort();
    }
    _resultado = null;
    notifyListeners();
  }

  void setTipo(TipoFechamento tipo) {
    _tipo = tipo;
    _resultado = null;
    notifyListeners();
  }

  void setOrcamento(double valor) {
    _orcamento = valor;
    notifyListeners();
  }

  void limpar() {
    _numerosBase.clear();
    _resultado = null;
    notifyListeners();
  }

  Future<void> gerar() async {
    if (!podeGerar || _modalidade == null) return;
    _processando = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));

    _resultado = _service.gerar(
      modalidade: _modalidade!,
      numerosBase: List.from(_numerosBase),
      tipo: _tipo,
      orcamento: _orcamento,
    );

    _processando = false;
    notifyListeners();
  }
}

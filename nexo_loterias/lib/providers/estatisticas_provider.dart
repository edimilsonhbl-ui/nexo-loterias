import 'package:flutter/material.dart';
import '../data/models/estatistica.dart';
import '../data/services/estatisticas_service.dart';
import '../data/repositories/concurso_repository.dart';

class EstatisticasProvider extends ChangeNotifier {
  final _service = EstatisticasService();
  final _repo = ConcursoRepository();

  EstatisticasModalidade? _estatisticas;
  bool _carregando = false;
  String _modalidadeId = '';

  EstatisticasModalidade? get estatisticas => _estatisticas;
  bool get carregando => _carregando;

  Future<void> carregar(String modalidadeId, {bool forcar = false}) async {
    if (!forcar && _modalidadeId == modalidadeId && _estatisticas != null) return;
    _carregando = true;
    _modalidadeId = modalidadeId;
    notifyListeners();

    try {
      final concursos = await _repo.dadosParaEstatisticas(modalidadeId);
      _estatisticas = _service.calcular(modalidadeId, concursos);
    } catch (_) {
      final concursos = _service.gerarDadosExemplo(modalidadeId);
      _estatisticas = _service.calcular(modalidadeId, concursos);
    }

    _carregando = false;
    notifyListeners();
  }

  void limpar() {
    _estatisticas = null;
    _modalidadeId = '';
    notifyListeners();
  }
}

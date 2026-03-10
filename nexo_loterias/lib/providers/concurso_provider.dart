import 'package:flutter/material.dart';
import '../data/models/concurso.dart';
import '../data/repositories/concurso_repository.dart';

class ConcursoProvider extends ChangeNotifier {
  final _repo = ConcursoRepository();

  Concurso? _ultimoConcurso;
  bool _carregando = false;
  String _modalidadeId = '';

  Concurso? get ultimoConcurso => _ultimoConcurso;
  bool get carregando => _carregando;

  int get proximoConcurso =>
      _ultimoConcurso != null ? _ultimoConcurso!.numeroConcurso + 1 : 0;

  DateTime get proximaData {
    if (_ultimoConcurso == null) return DateTime.now().add(const Duration(days: 3));
    return _ultimoConcurso!.dataSorteio.add(const Duration(days: 3));
  }

  Future<void> carregar(String modalidadeId, {bool forcar = false}) async {
    if (!forcar && _modalidadeId == modalidadeId && _ultimoConcurso != null) return;
    _carregando = true;
    _modalidadeId = modalidadeId;
    notifyListeners();

    try {
      _ultimoConcurso = await _repo.ultimoConcurso(modalidadeId);
    } catch (_) {
      _ultimoConcurso = null;
    }

    _carregando = false;
    notifyListeners();
  }

  void limpar() {
    _ultimoConcurso = null;
    _modalidadeId = '';
    notifyListeners();
  }
}

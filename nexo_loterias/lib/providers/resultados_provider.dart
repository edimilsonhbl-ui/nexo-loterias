import 'package:flutter/material.dart';
import '../data/models/concurso.dart';
import '../data/repositories/concurso_repository.dart';

class ResultadosProvider extends ChangeNotifier {
  final _repo = ConcursoRepository();

  final Map<String, Concurso?> _resultados = {
    'mega-sena': null,
    'lotofacil': null,
    'quina': null,
  };
  final Map<String, bool> _carregando = {
    'mega-sena': false,
    'lotofacil': false,
    'quina': false,
  };
  bool _inicializado = false;

  Concurso? resultado(String modalidadeId) => _resultados[modalidadeId];
  bool carregando(String modalidadeId) => _carregando[modalidadeId] ?? false;
  bool get algumCarregando => _carregando.values.any((c) => c);

  Future<void> carregarTodos({bool forcar = false}) async {
    if (_inicializado && !forcar) return;
    _inicializado = true;

    final modalidades = ['mega-sena', 'lotofacil', 'quina'];
    for (final id in modalidades) {
      _carregando[id] = true;
    }
    notifyListeners();

    await Future.wait(modalidades.map((id) => _carregarUm(id)));

    notifyListeners();
  }

  Future<void> _carregarUm(String modalidadeId) async {
    try {
      _resultados[modalidadeId] = await _repo.ultimoConcurso(modalidadeId);
    } catch (_) {
      _resultados[modalidadeId] = null;
    }
    _carregando[modalidadeId] = false;
  }

  Future<void> recarregar() async {
    _inicializado = false;
    await carregarTodos(forcar: true);
  }
}

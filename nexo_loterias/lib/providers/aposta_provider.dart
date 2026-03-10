import 'dart:async';
import 'package:flutter/material.dart';
import '../data/models/aposta.dart';
import '../data/models/concurso.dart';
import '../data/repositories/aposta_repository.dart';

class ApostaProvider extends ChangeNotifier {
  final _repo = ApostaRepository();

  final List<Aposta> _apostasLocais = [];
  StreamSubscription<List<Aposta>>? _subscription;
  bool _usandoFirebase = false;

  List<Aposta> get apostas => _apostasLocais;

  void conectarFirebase(String userId) {
    _subscription?.cancel();
    _usandoFirebase = true;
    _subscription = _repo.stream(userId).listen((lista) {
      _apostasLocais
        ..clear()
        ..addAll(lista);
      notifyListeners();
    });
  }

  void desconectarFirebase() {
    _subscription?.cancel();
    _subscription = null;
    _usandoFirebase = false;
    _apostasLocais.clear();
    notifyListeners();
  }

  Future<void> salvarAposta(Aposta aposta, {String? userId}) async {
    if (_usandoFirebase && userId != null) {
      await _repo.salvar(userId, aposta);
    } else {
      _apostasLocais.insert(0, aposta);
      notifyListeners();
    }
  }

  Future<void> removerAposta(String id, {String? userId}) async {
    if (_usandoFirebase && userId != null) {
      await _repo.remover(id);
    } else {
      _apostasLocais.removeWhere((a) => a.id == id);
      notifyListeners();
    }
  }

  Future<Aposta> conferir(Aposta aposta, Concurso concurso, {String? userId}) async {
    final apostaConferida = _repo.conferir(aposta, concurso);
    if (_usandoFirebase && userId != null) {
      await _repo.atualizar(apostaConferida);
    } else {
      final idx = _apostasLocais.indexWhere((a) => a.id == aposta.id);
      if (idx != -1) {
        _apostasLocais[idx] = apostaConferida;
        notifyListeners();
      }
    }
    return apostaConferida;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

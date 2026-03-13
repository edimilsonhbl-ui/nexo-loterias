import 'dart:async';
import 'package:flutter/material.dart';
import '../data/models/ranking_entry.dart';
import '../data/repositories/ranking_repository.dart';

class RankingProvider extends ChangeNotifier {
  final _repo = RankingRepository();

  List<RankingEntry> _top20 = [];
  StreamSubscription<List<RankingEntry>>? _subscription;
  bool _carregando = false;
  bool _enviando = false;

  List<RankingEntry> get top20 => _top20;
  bool get carregando => _carregando;
  bool get enviando => _enviando;

  void inicializar() {
    _carregando = true;
    notifyListeners();
    _subscription = _repo.streamTop20().listen((lista) {
      _top20 = lista;
      _carregando = false;
      notifyListeners();
    }, onError: (_) {
      _carregando = false;
      notifyListeners();
    });
  }

  Future<bool> registrarGanho(RankingEntry entry) async {
    _enviando = true;
    notifyListeners();
    try {
      await _repo.registrarGanho(entry);
      _enviando = false;
      notifyListeners();
      return true;
    } catch (_) {
      _enviando = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

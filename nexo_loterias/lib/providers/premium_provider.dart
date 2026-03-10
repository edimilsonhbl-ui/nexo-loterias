import 'dart:async';
import 'package:flutter/material.dart';
import '../data/models/usuario.dart';
import '../data/repositories/usuario_repository.dart';
import '../data/services/premium_service.dart';

class PremiumProvider extends ChangeNotifier {
  final _repo = UsuarioRepository();

  Usuario? _usuario;
  StreamSubscription<Usuario?>? _subscription;

  Usuario? get usuario => _usuario;
  bool get isPremium => _usuario?.premiumAtivo ?? false;
  PlanoUsuario get plano => _usuario?.plano ?? PlanoUsuario.free;

  int get limiteApostas =>
      isPremium ? 999999 : PremiumService.limiteApostasFree;

  bool podeSalvarAposta(int total) =>
      isPremium || total < PremiumService.limiteApostasFree;

  bool temAcesso(String recurso) {
    if (isPremium) return true;
    return !PremiumService.recursosExclusivos.containsKey(recurso);
  }

  void carregar(String userId) {
    _subscription?.cancel();
    _subscription = _repo.stream(userId).listen((u) {
      _usuario = u;
      notifyListeners();
    });
  }

  void limpar() {
    _subscription?.cancel();
    _usuario = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

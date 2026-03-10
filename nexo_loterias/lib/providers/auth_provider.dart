import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/services/auth_service.dart';

enum AuthStatus { inicial, carregando, logado, deslogado, erro }

class AuthProvider extends ChangeNotifier {
  final _service = AuthService();

  AuthStatus _status = AuthStatus.inicial;
  User? _usuario;
  String _mensagemErro = '';

  AuthStatus get status => _status;
  User? get usuario => _usuario;
  String get mensagemErro => _mensagemErro;
  bool get estaLogado => _usuario != null;
  String? get userId => _usuario?.uid;

  AuthProvider() {
    _service.usuarioStream.listen((user) {
      _usuario = user;
      _status = user != null ? AuthStatus.logado : AuthStatus.deslogado;
      notifyListeners();
    });
  }

  Future<bool> entrar({required String email, required String senha}) async {
    _status = AuthStatus.carregando;
    _mensagemErro = '';
    notifyListeners();
    try {
      await _service.entrar(email: email, senha: senha);
      return true;
    } on FirebaseAuthException catch (e) {
      _mensagemErro = _service.traduzirErro(e);
      _status = AuthStatus.erro;
      notifyListeners();
      return false;
    }
  }

  Future<bool> cadastrar({required String email, required String senha}) async {
    _status = AuthStatus.carregando;
    _mensagemErro = '';
    notifyListeners();
    try {
      await _service.cadastrar(email: email, senha: senha);
      return true;
    } on FirebaseAuthException catch (e) {
      _mensagemErro = _service.traduzirErro(e);
      _status = AuthStatus.erro;
      notifyListeners();
      return false;
    }
  }

  Future<void> sair() async {
    await _service.sair();
  }

  Future<void> redefinirSenha(String email) async {
    await _service.redefinirSenha(email);
  }

  void limparErro() {
    _mensagemErro = '';
    if (_status == AuthStatus.erro) {
      _status = _usuario != null ? AuthStatus.logado : AuthStatus.deslogado;
      notifyListeners();
    }
  }
}

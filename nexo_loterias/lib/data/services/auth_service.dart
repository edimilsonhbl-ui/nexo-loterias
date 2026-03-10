import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;

  Stream<User?> get usuarioStream => _auth.authStateChanges();

  User? get usuarioAtual => _auth.currentUser;

  bool get estaLogado => _auth.currentUser != null;

  Future<UserCredential> cadastrar({
    required String email,
    required String senha,
  }) async {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: senha,
    );
  }

  Future<UserCredential> entrar({
    required String email,
    required String senha,
  }) async {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: senha,
    );
  }

  Future<void> sair() => _auth.signOut();

  Future<void> redefinirSenha(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  String traduzirErro(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Usuário não encontrado.';
      case 'wrong-password':
        return 'Senha incorreta.';
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado.';
      case 'weak-password':
        return 'Senha muito fraca. Use no mínimo 6 caracteres.';
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'too-many-requests':
        return 'Muitas tentativas. Aguarde e tente novamente.';
      case 'network-request-failed':
        return 'Sem conexão com a internet.';
      default:
        return 'Erro: ${e.message}';
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/usuario.dart';

class UsuarioRepository {
  final _db = FirebaseFirestore.instance;

  Future<Usuario?> buscar(String userId) async {
    final doc = await _db.collection('usuarios').doc(userId).get();
    if (!doc.exists) return null;
    return Usuario.fromMap({...doc.data()!, 'id': doc.id});
  }

  Stream<Usuario?> stream(String userId) {
    return _db.collection('usuarios').doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Usuario.fromMap({...doc.data()!, 'id': doc.id});
    });
  }

  Future<void> criar(Usuario usuario) async {
    await _db.collection('usuarios').doc(usuario.id).set(usuario.toMap());
  }

  Future<void> atualizar(Usuario usuario) async {
    await _db.collection('usuarios').doc(usuario.id).update(usuario.toMap());
  }

  Future<void> salvarOuAtualizar(Usuario usuario) async {
    await _db
        .collection('usuarios')
        .doc(usuario.id)
        .set(usuario.toMap(), SetOptions(merge: true));
  }

  Future<bool> ehPremium(String userId) async {
    final usuario = await buscar(userId);
    return usuario?.premiumAtivo ?? false;
  }
}

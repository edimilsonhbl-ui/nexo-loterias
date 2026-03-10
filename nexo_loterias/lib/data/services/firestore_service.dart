import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/concurso.dart';
import '../models/aposta.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  // ── CONCURSOS ──────────────────────────────────────────

  Stream<List<Concurso>> concursosStream(String modalidadeId, {int limite = 10}) {
    return _db
        .collection('concursos')
        .where('modalidadeId', isEqualTo: modalidadeId)
        .orderBy('numeroConcurso', descending: true)
        .limit(limite)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Concurso.fromMap({...d.data(), 'id': d.id})).toList());
  }

  Future<Concurso?> ultimoConcurso(String modalidadeId) async {
    final snap = await _db
        .collection('concursos')
        .where('modalidadeId', isEqualTo: modalidadeId)
        .orderBy('numeroConcurso', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final d = snap.docs.first;
    return Concurso.fromMap({...d.data(), 'id': d.id});
  }

  Future<List<Concurso>> listarConcursos(String modalidadeId, {int limite = 200}) async {
    final snap = await _db
        .collection('concursos')
        .where('modalidadeId', isEqualTo: modalidadeId)
        .orderBy('numeroConcurso', descending: true)
        .limit(limite)
        .get();
    return snap.docs.map((d) => Concurso.fromMap({...d.data(), 'id': d.id})).toList();
  }

  Future<void> salvarConcurso(Concurso concurso) async {
    await _db.collection('concursos').doc(concurso.id).set(concurso.toMap());
  }

  // ── APOSTAS DO USUARIO ────────────────────────────────

  Stream<List<Aposta>> apostasStream(String userId) {
    return _db
        .collection('apostas_usuario')
        .where('userId', isEqualTo: userId)
        .orderBy('criadaEm', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Aposta.fromMap({...d.data(), 'id': d.id})).toList());
  }

  Future<void> salvarAposta(String userId, Aposta aposta) async {
    final data = {...aposta.toMap(), 'userId': userId};
    await _db.collection('apostas_usuario').doc(aposta.id).set(data);
  }

  Future<void> atualizarAposta(Aposta aposta) async {
    await _db.collection('apostas_usuario').doc(aposta.id).update(aposta.toMap());
  }

  Future<void> removerAposta(String apostaId) async {
    await _db.collection('apostas_usuario').doc(apostaId).delete();
  }

  // ── ESTATISTICAS ──────────────────────────────────────

  Future<Map<String, dynamic>?> estatisticasModalidade(String modalidadeId) async {
    final doc = await _db.collection('estatisticas').doc(modalidadeId).get();
    return doc.exists ? doc.data() : null;
  }

  Stream<Map<String, dynamic>?> estatisticasStream(String modalidadeId) {
    return _db
        .collection('estatisticas')
        .doc(modalidadeId)
        .snapshots()
        .map((d) => d.exists ? d.data() : null);
  }
}

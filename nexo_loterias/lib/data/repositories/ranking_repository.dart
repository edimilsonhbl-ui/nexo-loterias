import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ranking_entry.dart';

class RankingRepository {
  final _db = FirebaseFirestore.instance;

  Stream<List<RankingEntry>> streamTop20() {
    return _db
        .collection('ranking')
        .orderBy('acertos', descending: true)
        .orderBy('criadaEm', descending: true)
        .limit(20)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => RankingEntry.fromMap(d.id, d.data()))
            .toList());
  }

  Future<void> registrarGanho(RankingEntry entry) async {
    await _db.collection('ranking').add(entry.toMap());
  }

  Future<List<RankingEntry>> buscarDoUsuario(String userId) async {
    final snap = await _db
        .collection('ranking')
        .where('userId', isEqualTo: userId)
        .orderBy('criadaEm', descending: true)
        .limit(10)
        .get();
    return snap.docs.map((d) => RankingEntry.fromMap(d.id, d.data())).toList();
  }
}

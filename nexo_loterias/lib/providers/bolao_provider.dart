import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/bolao.dart';

class BolaoProvider extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;

  bool _carregando = false;
  String? _erro;

  bool get carregando => _carregando;
  String? get erro => _erro;

  Stream<List<Bolao>> streamDoUsuario(String uid) {
    return _db
        .collection('bolaos')
        .where('membrosUids', arrayContains: uid)
        .orderBy('criadoEm', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Bolao.fromMap(d.data()))
            .toList());
  }

  Future<Bolao?> criar({
    required String nome,
    required String modalidadeId,
    required String uid,
    required String nomeUsuario,
  }) async {
    try {
      _carregando = true;
      _erro = null;
      notifyListeners();

      final codigo = _gerarCodigo();
      final id = _db.collection('bolaos').doc().id;

      final bolao = Bolao(
        id: id,
        nome: nome.trim(),
        codigo: codigo,
        modalidadeId: modalidadeId,
        criadoPorUid: uid,
        criadoPorNome: nomeUsuario,
        membrosUids: [uid],
        jogosIds: [],
        criadoEm: DateTime.now(),
      );

      await _db.collection('bolaos').doc(id).set(bolao.toMap());
      return bolao;
    } catch (e) {
      _erro = 'Erro ao criar bolão. Tente novamente.';
      return null;
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  Future<Bolao?> entrarPorCodigo(String codigo, String uid) async {
    try {
      _carregando = true;
      _erro = null;
      notifyListeners();

      final snap = await _db
          .collection('bolaos')
          .where('codigo', isEqualTo: codigo.toUpperCase().trim())
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        _erro = 'Código inválido. Verifique e tente novamente.';
        return null;
      }

      final doc = snap.docs.first;
      final bolao = Bolao.fromMap(doc.data());

      if (bolao.membrosUids.contains(uid)) {
        _erro = 'Você já está neste bolão!';
        return bolao;
      }

      await _db.collection('bolaos').doc(bolao.id).update({
        'membrosUids': FieldValue.arrayUnion([uid]),
      });

      return bolao;
    } catch (e) {
      _erro = 'Erro ao entrar no bolão.';
      return null;
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  Future<void> adicionarJogo(String bolaoId, String jogoId) async {
    await _db.collection('bolaos').doc(bolaoId).update({
      'jogosIds': FieldValue.arrayUnion([jogoId]),
    });
  }

  Future<void> sair(String bolaoId, String uid) async {
    await _db.collection('bolaos').doc(bolaoId).update({
      'membrosUids': FieldValue.arrayRemove([uid]),
    });
  }

  String _gerarCodigo() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final buf = StringBuffer();
    for (int i = 0; i < 6; i++) {
      buf.write(chars[(DateTime.now().microsecondsSinceEpoch * (i + 1)) % chars.length]);
    }
    return buf.toString();
  }
}

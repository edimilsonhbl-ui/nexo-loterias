import '../models/aposta.dart';
import '../models/concurso.dart';
import '../services/firestore_service.dart';

class ApostaRepository {
  final _firestore = FirestoreService();

  Stream<List<Aposta>> stream(String userId) => _firestore.apostasStream(userId);

  Future<void> salvar(String userId, Aposta aposta) =>
      _firestore.salvarAposta(userId, aposta);

  Future<void> atualizar(Aposta aposta) => _firestore.atualizarAposta(aposta);

  Future<void> remover(String apostaId) => _firestore.removerAposta(apostaId);

  Aposta conferir(Aposta aposta, Concurso concurso) {
    final acertos = aposta.numerosEscolhidos
        .where((n) => concurso.dezenasSorteadas.contains(n))
        .length;

    String? faixa;
    if (aposta.modalidadeId == 'mega-sena') {
      if (acertos >= 6) faixa = 'Sena';
      else if (acertos == 5) faixa = 'Quina';
      else if (acertos == 4) faixa = 'Quadra';
    } else if (aposta.modalidadeId == 'lotofacil') {
      if (acertos >= 11) faixa = '$acertos acertos';
    }

    return aposta.copyWith(acertos: acertos, faixaPremio: faixa);
  }
}

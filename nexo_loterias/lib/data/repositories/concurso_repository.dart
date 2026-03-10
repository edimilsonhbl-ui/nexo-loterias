import '../models/concurso.dart';
import '../services/firestore_service.dart';
import '../services/estatisticas_service.dart';

class ConcursoRepository {
  final _firestore = FirestoreService();
  final _estatisticasService = EstatisticasService();

  Stream<List<Concurso>> streamUltimos(String modalidadeId, {int limite = 10}) =>
      _firestore.concursosStream(modalidadeId, limite: limite);

  Future<Concurso?> ultimoConcurso(String modalidadeId) =>
      _firestore.ultimoConcurso(modalidadeId);

  Future<List<Concurso>> dadosParaEstatisticas(String modalidadeId) async {
    try {
      final concursos = await _firestore.listarConcursos(modalidadeId, limite: 200);
      if (concursos.isNotEmpty) return concursos;
      return _estatisticasService.gerarDadosExemplo(modalidadeId);
    } catch (_) {
      return _estatisticasService.gerarDadosExemplo(modalidadeId);
    }
  }
}

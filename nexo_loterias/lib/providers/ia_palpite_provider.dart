import 'package:flutter/material.dart';
import '../data/models/modalidade.dart';
import '../data/services/ia_palpite_service.dart';
import '../data/repositories/concurso_repository.dart';
import '../data/services/estatisticas_service.dart';

class IaPalpiteProvider extends ChangeNotifier {
  final _service = IaPalpiteService();
  final _concursoRepo = ConcursoRepository();
  final _dadosExemplo = EstatisticasService();

  List<int> _palpiteAtual = [];
  PerfilIA _perfil = PerfilIA.equilibrado;
  JanelaAnalise _janela = JanelaAnalise.ultimos50;
  bool _gerando = false;
  String _erroUltimoGerar = '';

  List<int> get palpiteAtual => _palpiteAtual;
  PerfilIA get perfil => _perfil;
  JanelaAnalise get janela => _janela;
  bool get gerando => _gerando;
  String get erroUltimoGerar => _erroUltimoGerar;

  void setPerfil(PerfilIA p) {
    _perfil = p;
    notifyListeners();
  }

  void setJanela(JanelaAnalise j) {
    _janela = j;
    notifyListeners();
  }

  Future<void> gerar(Modalidade modalidade) async {
    _gerando = true;
    _palpiteAtual = [];
    _erroUltimoGerar = '';
    notifyListeners();

    try {
      // Busca histórico real do Firestore; cai no fallback se vazio ou offline
      var historico = await _concursoRepo.dadosParaEstatisticas(modalidade.id);
      if (historico.isEmpty) {
        historico = _dadosExemplo.gerarDadosExemplo(modalidade.id);
      }

      _palpiteAtual = _service.gerarPalpite(
        modalidade: modalidade,
        historico: historico,
        perfil: _perfil,
        janela: _janela,
      );
    } catch (e) {
      // Se tudo falhar usa dados de exemplo para não deixar o usuário sem resposta
      final historico = _dadosExemplo.gerarDadosExemplo(modalidade.id);
      _palpiteAtual = _service.gerarPalpite(
        modalidade: modalidade,
        historico: historico,
        perfil: _perfil,
        janela: _janela,
      );
      _erroUltimoGerar = 'Usando dados locais (sem conexão).';
    }

    _gerando = false;
    notifyListeners();
  }

  String get descricaoPerfil => _service.descricaoPerfil(_perfil);
  String get descricaoJanela => _service.descricaoJanela(_janela);
}

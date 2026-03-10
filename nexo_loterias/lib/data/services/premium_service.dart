import '../models/usuario.dart';
import '../repositories/usuario_repository.dart';

class PremiumService {
  static const limiteApostasFree = 10;
  static const precoMensal = 9.90;
  static const precoAnual = 59.90;
  static const precoVitalicio = 97.00;

  final _repo = UsuarioRepository();

  // SEGURANÇA: A ativação real de Premium deve ser feita exclusivamente pela
  // Cloud Function `validarPremium`, que valida o recibo do IAP/RevenueCat
  // antes de gravar `premium`, `plano` e `dataExpiracaoPremium` no Firestore.
  //
  // Este método é apenas um STUB para ambiente de desenvolvimento/teste.
  // Em produção, o cliente NUNCA deve escrever esses campos diretamente —
  // isso é bloqueado pelas regras do Firestore:
  //
  //   allow write: if request.auth.uid == userId
  //     && !request.resource.data.diff(resource.data).affectedKeys()
  //         .hasAny(['premium', 'plano', 'dataExpiracaoPremium']);
  Future<void> ativarPremiumDev({
    required String userId,
    required PlanoUsuario plano,
  }) async {
    final usuario = await _repo.buscar(userId);
    if (usuario == null) return;

    DateTime? expiracao;
    if (plano == PlanoUsuario.mensal) {
      expiracao = DateTime.now().add(const Duration(days: 30));
    } else if (plano == PlanoUsuario.anual) {
      expiracao = DateTime.now().add(const Duration(days: 365));
    }
    // vitalicio: dataExpiracaoPremium = null (sentinel via copyWith)

    await _repo.atualizar(
      usuario.copyWith(
        premium: true,
        plano: plano,
        dataExpiracaoPremium: expiracao,
      ),
    );
  }

  bool podeSalvarAposta(int totalAtual, bool isPremium) {
    if (isPremium) return true;
    return totalAtual < limiteApostasFree;
  }

  static const _recursosGratuitos = {
    'montar_jogo',
    'estatisticas_basicas',
    'conferidor',
    'historico_limitado',
  };

  static const recursosExclusivos = {
    'fechamento_nexo': 'Fechamento NEXO',
    'ia_palpites': 'IA de Palpites',
    'estatisticas_avancadas': 'Estatísticas Avançadas',
    'historico_ilimitado': 'Histórico Ilimitado',
    'exportar_jogos': 'Exportar Jogos',
    'sem_anuncios': 'Sem Anúncios',
  };

  bool acessoPermitido(String recurso, bool isPremium) {
    if (isPremium) return true;
    return _recursosGratuitos.contains(recurso);
  }
}

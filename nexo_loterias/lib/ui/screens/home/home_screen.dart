import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/modalidade_provider.dart';
import '../../../providers/concurso_provider.dart';
import '../../../providers/premium_provider.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/constants/app_constants.dart';
import '../../widgets/banner_ad_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final modalidadeId = context.read<ModalidadeProvider>().modalidadeAtual.id;
      context.read<ConcursoProvider>().carregar(modalidadeId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final modalidade = context.watch<ModalidadeProvider>().modalidadeAtual;
    final concursoProvider = context.watch<ConcursoProvider>();
    final premium = context.watch<PremiumProvider>();
    final primary = Theme.of(context).colorScheme.primary;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('NEXO LOTERIAS',
            style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 2)),
        actions: [
          if (!premium.isPremium)
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, AppRoutes.premium),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.workspace_premium, size: 14, color: Colors.black),
                    SizedBox(width: 4),
                    Text('Premium',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black)),
                  ],
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.conta),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card de modalidade
            GestureDetector(
              onTap: () async {
                await Navigator.pushNamed(context, AppRoutes.modalidades);
                if (!context.mounted) return;
                final id = context.read<ModalidadeProvider>().modalidadeAtual.id;
                context.read<ConcursoProvider>().carregar(id, forcar: true);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primary, primary.withBlue((primary.blue + 40).clamp(0, 255))],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(color: primary.withAlpha(80), blurRadius: 16, offset: const Offset(0, 6)),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.casino_rounded, color: Colors.white, size: 32),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Modalidade atual',
                              style: TextStyle(color: Colors.white70, fontSize: 11)),
                          Text(modalidade.nome,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Cards de resultado e próximo concurso
            Row(
              children: [
                Expanded(
                  child: _InfoConcursoCard(
                    titulo: 'Último resultado',
                    valor: concursoProvider.carregando
                        ? '...'
                        : concursoProvider.ultimoConcurso != null
                            ? 'Concurso ${concursoProvider.ultimoConcurso!.numeroConcurso}'
                            : 'Aguardando',
                    detalhe: concursoProvider.ultimoConcurso != null
                        ? concursoProvider.ultimoConcurso!.dezenasSorteadas
                            .map((n) => n.toString().padLeft(2, '0'))
                            .join(' · ')
                        : '–',
                    icone: Icons.history,
                    primary: primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InfoConcursoCard(
                    titulo: 'Próximo concurso',
                    valor: concursoProvider.proximoConcurso > 0
                        ? 'Concurso ${concursoProvider.proximoConcurso}'
                        : '–',
                    detalhe: _formatarData(concursoProvider.proximaData),
                    icone: Icons.event,
                    primary: primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Prêmio estimado
            if (concursoProvider.ultimoConcurso != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primary.withAlpha(50)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.emoji_events_outlined, color: primary),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Prêmio estimado', style: textTheme.labelSmall),
                        Text(
                          _formatarPremio(concursoProvider.ultimoConcurso!.premioEstimado),
                          style: TextStyle(
                              color: primary, fontWeight: FontWeight.w700, fontSize: 18),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (concursoProvider.ultimoConcurso!.acumulado)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('ACUMULOU',
                            style: TextStyle(
                                color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            Text('O que deseja fazer?', style: textTheme.titleMedium),
            const SizedBox(height: 14),

            // Linha 1 — Montar Jogo + Estatísticas
            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: Icons.grid_on_rounded,
                    label: 'Montar\nJogo',
                    color: primary,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.montarJogo),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.bar_chart_rounded,
                    label: 'Estatísticas',
                    color: primary,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.estatisticas),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Linha 2 — Fechamento NEXO + Meus Jogos
            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: Icons.auto_awesome_mosaic,
                    label: 'Fechamento\nNEXO',
                    color: primary,
                    badge: 'PRO',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.fechamento),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.bookmark_outline,
                    label: 'Meus\nJogos',
                    color: primary,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.historico),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Linha 3 — Resultados + Conferidor
            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: Icons.emoji_events_rounded,
                    label: 'Resultados',
                    color: primary,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.resultados),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.check_circle_outline_rounded,
                    label: 'Conferir\nJogo',
                    color: primary,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.conferidor),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Linha 4 — Bolão + Histórico de Resultados
            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: Icons.groups_rounded,
                    label: 'Bolão',
                    color: primary,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.bolao),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.history_rounded,
                    label: 'Histórico\nResultados',
                    color: primary,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.historicoResultados),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Linha 5 — Palpite do Dia + Ranking
            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: Icons.auto_awesome,
                    label: 'Palpite\ndo Dia',
                    color: primary,
                    badge: 'PRO',
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.palpiteDoDia),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.emoji_events_outlined,
                    label: 'Ranking\nde Sorte',
                    color: primary,
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.ranking),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            _AvisoLegalBanner(),
            const SizedBox(height: 8),
            if (!premium.isPremium) const BannerAdWidget(),
          ],
        ),
      ),
    );
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year}';
  }

  String _formatarPremio(double valor) {
    if (valor >= 1000000) {
      return 'R\$ ${(valor / 1000000).toStringAsFixed(1)} mi';
    }
    return 'R\$ ${valor.toStringAsFixed(2)}';
  }
}

class _InfoConcursoCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final String detalhe;
  final IconData icone;
  final Color primary;

  const _InfoConcursoCard({
    required this.titulo,
    required this.valor,
    required this.detalhe,
    required this.icone,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primary.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, color: primary, size: 16),
              const SizedBox(width: 6),
              Text(titulo, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
          const SizedBox(height: 6),
          Text(valor,
              style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13, color: primary)),
          const SizedBox(height: 2),
          Text(detalhe,
              style: Theme.of(context).textTheme.labelSmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final String? badge;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(height: 6),
                Text(label,
                    style: Theme.of(context).textTheme.labelLarge,
                    textAlign: TextAlign.center,
                    maxLines: 2),
              ],
            ),
            if (badge != null)
              Positioned(
                top: -6,
                right: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(badge!,
                      style: const TextStyle(
                          fontSize: 8, fontWeight: FontWeight.w700, color: Colors.black)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AvisoLegalBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.grey),
      ),
      child: Text(
        AppConstants.avisoLegal,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(fontStyle: FontStyle.italic),
        textAlign: TextAlign.center,
      ),
    );
  }
}

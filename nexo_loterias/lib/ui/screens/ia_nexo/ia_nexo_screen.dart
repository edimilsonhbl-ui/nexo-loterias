import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/ia_palpite_provider.dart';
import '../../../providers/modalidade_provider.dart';
import '../../../providers/aposta_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/premium_provider.dart';
import '../../../data/services/ia_palpite_service.dart';
import '../../../data/models/aposta.dart';
import '../../../core/utils/probabilidade_util.dart';
import '../../../core/routes/app_routes.dart';
import 'package:uuid/uuid.dart';

class IaNexoScreen extends StatelessWidget {
  const IaNexoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final premium = context.watch<PremiumProvider>();

    if (!premium.temAcesso('ia_palpites')) {
      return Scaffold(
        appBar: AppBar(title: const Text('IA NEXO')),
        body: _BloqueadoPremium(
          recurso: 'IA de Palpites',
          onAssinar: () => Navigator.pushNamed(context, AppRoutes.premium),
        ),
      );
    }

    return const _IaNexoConteudo();
  }
}

class _IaNexoConteudo extends StatelessWidget {
  const _IaNexoConteudo();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IaPalpiteProvider>();
    final modalidade = context.watch<ModalidadeProvider>().modalidadeAtual;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.psychology, color: primary, size: 22),
            const SizedBox(width: 8),
            const Text('IA NEXO'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CartaoDescricao(primary: primary),
            const SizedBox(height: 20),
            Text('Perfil de análise', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            _SeletorPerfil(
              selecionado: provider.perfil,
              onSelecionado: context.read<IaPalpiteProvider>().setPerfil,
              primary: primary,
            ),
            const SizedBox(height: 20),
            Text('Janela histórica', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            _SeletorJanela(
              selecionada: provider.janela,
              onSelecionada: context.read<IaPalpiteProvider>().setJanela,
              primary: primary,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primary.withAlpha(15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: primary.withAlpha(40)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Estratégia ativa', style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(height: 4),
                  Text(provider.descricaoPerfil,
                      style: TextStyle(color: primary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(provider.descricaoJanela,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: provider.gerando
                    ? null
                    : () => context.read<IaPalpiteProvider>().gerar(modalidade),
                icon: provider.gerando
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.psychology),
                label: Text(provider.gerando ? 'Analisando...' : 'Gerar Palpite IA'),
              ),
            ),
            if (provider.palpiteAtual.isNotEmpty) ...[
              const SizedBox(height: 28),
              _ResultadoIA(
                numeros: provider.palpiteAtual,
                modalidade: modalidade,
                primary: primary,
                perfil: provider.perfil,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CartaoDescricao extends StatelessWidget {
  final Color primary;
  const _CartaoDescricao({required this.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary.withAlpha(80), primary.withAlpha(30)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: primary, size: 28),
              const SizedBox(width: 10),
              Text('IA NEXO',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700, color: primary)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('PREMIUM',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Analisa padrões dos sorteios históricos para gerar palpites estatisticamente fundamentados.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _SeletorPerfil extends StatelessWidget {
  final PerfilIA selecionado;
  final ValueChanged<PerfilIA> onSelecionado;
  final Color primary;

  const _SeletorPerfil({
    required this.selecionado,
    required this.onSelecionado,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final opcoes = [
      (PerfilIA.conservador, 'Conservador', Icons.shield_outlined, Colors.blue),
      (PerfilIA.equilibrado, 'Equilibrado', Icons.balance, primary),
      (PerfilIA.ousado, 'Ousado', Icons.local_fire_department, Colors.orange),
    ];

    return Row(
      children: opcoes.map((o) {
        final (tipo, label, icone, cor) = o;
        final sel = selecionado == tipo;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelecionado(tipo),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: EdgeInsets.only(right: tipo != PerfilIA.ousado ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: sel ? cor.withAlpha(30) : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: sel ? cor : cor.withAlpha(60), width: sel ? 2 : 1),
              ),
              child: Column(
                children: [
                  Icon(icone, color: sel ? cor : Theme.of(context).colorScheme.onSurface, size: 22),
                  const SizedBox(height: 4),
                  Text(label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: sel ? cor : Theme.of(context).colorScheme.onSurface)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SeletorJanela extends StatelessWidget {
  final JanelaAnalise selecionada;
  final ValueChanged<JanelaAnalise> onSelecionada;
  final Color primary;

  const _SeletorJanela({
    required this.selecionada,
    required this.onSelecionada,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final opcoes = [
      (JanelaAnalise.ultimos10, '10'),
      (JanelaAnalise.ultimos30, '30'),
      (JanelaAnalise.ultimos50, '50'),
      (JanelaAnalise.ultimos100, '100'),
    ];

    return Row(
      children: opcoes.map((o) {
        final (janela, label) = o;
        final sel = selecionada == janela;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelecionada(janela),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: EdgeInsets.only(right: janela != JanelaAnalise.ultimos100 ? 6 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: sel ? primary : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: sel ? primary : primary.withAlpha(40)),
              ),
              child: Column(
                children: [
                  Text(label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: sel ? Colors.white : Theme.of(context).colorScheme.onSurface)),
                  Text('conc.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 10,
                          color: sel ? Colors.white70 : Theme.of(context).colorScheme.onSurface.withAlpha(150))),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ResultadoIA extends StatelessWidget {
  final List<int> numeros;
  final dynamic modalidade;
  final Color primary;
  final PerfilIA perfil;

  const _ResultadoIA({
    required this.numeros,
    required this.modalidade,
    required this.primary,
    required this.perfil,
  });

  @override
  Widget build(BuildContext context) {
    final corPerfil = perfil == PerfilIA.conservador
        ? Colors.blue
        : perfil == PerfilIA.ousado
            ? Colors.orange
            : primary;
    final labelPerfil = perfil.name[0].toUpperCase() + perfil.name.substring(1);
    final probs = ProbabilidadeUtil.calcularProbabilidades(modalidade, numeros.length);
    final probPrincipal = probs[modalidade.numerosMin];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Palpite IA', style: Theme.of(context).textTheme.titleMedium),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: corPerfil.withAlpha(30),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(labelPerfil,
                  style: TextStyle(color: corPerfil, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: numeros.map((n) => Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: primary.withAlpha(80), blurRadius: 6, offset: const Offset(0, 3))],
                ),
                child: Center(
                  child: Text(n.toString().padLeft(2, '0'),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              )).toList(),
        ),
        if (probPrincipal != null) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Probabilidade do prêmio principal',
                  style: Theme.of(context).textTheme.bodyMedium),
              Text(ProbabilidadeUtil.formatarProbabilidade(probPrincipal),
                  style: TextStyle(color: primary, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              final auth = context.read<AuthProvider>().userId;
              final uuid = const Uuid();
              final prob = ProbabilidadeUtil.calcularProbabilidades(modalidade, numeros.length);
              context.read<ApostaProvider>().salvarAposta(
                    Aposta(
                      id: uuid.v4(),
                      modalidadeId: modalidade.id,
                      numerosEscolhidos: numeros,
                      valorAposta: ProbabilidadeUtil.calcularValor(modalidade, numeros.length),
                      probabilidade: prob[modalidade.numerosMin] ?? 0,
                      criadaEm: DateTime.now(),
                    ),
                    userId: auth,
                  );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Palpite IA salvo em Meus Jogos!')),
              );
            },
            icon: const Icon(Icons.bookmark_add_outlined),
            label: const Text('Salvar palpite'),
          ),
        ),
      ],
    );
  }
}

class _BloqueadoPremium extends StatelessWidget {
  final String recurso;
  final VoidCallback onAssinar;

  const _BloqueadoPremium({required this.recurso, required this.onAssinar});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 64, color: primary.withAlpha(120)),
            const SizedBox(height: 20),
            Text('Recurso Premium', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '$recurso está disponível apenas na versão Premium do NEXO LOTERIAS.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAssinar,
                icon: const Icon(Icons.workspace_premium),
                label: const Text('Ver planos Premium'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

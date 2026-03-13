import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/premium_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/usuario.dart';
import '../../../data/services/premium_service.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  PlanoUsuario _planoSelecionado = PlanoUsuario.anual;
  bool _processando = false;

  // ATENÇÃO: Em produção este botão deve chamar RevenueCat / in_app_purchase.
  // A Cloud Function `validarPremium` valida o recibo e grava os campos
  // premium/plano/dataExpiracaoPremium no Firestore.
  // O cliente NUNCA deve gravar esses campos diretamente.
  //
  // O fluxo abaixo usa `ativarPremiumDev` exclusivamente para testes/dev.
  // Em release use `const bool kIsProduction = bool.fromEnvironment('PRODUCTION');`
  // e desabilite este botão quando `kIsProduction == true`.
  static const _isProduction = bool.fromEnvironment('PRODUCTION', defaultValue: true);

  void _mostrarDialogoPagamento() {
    final primary = Theme.of(context).colorScheme.primary;
    final planoNome = _planoSelecionado == PlanoUsuario.mensal
        ? 'Mensal — R\$ 9,90'
        : _planoSelecionado == PlanoUsuario.anual
            ? 'Anual — R\$ 59,90'
            : 'Vitalício — R\$ 97,00';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.star_rounded, color: primary),
            const SizedBox(width: 8),
            const Text('Assinar Premium'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Plano selecionado: $planoNome',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            const Text(
              'O sistema de pagamento estará disponível em breve.\n\n'
              'Para assinar agora, entre em contato:',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.email_outlined, size: 18, color: primary),
                const SizedBox(width: 8),
                const Text('nexoloterias@gmail.com',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Future<void> _assinar() async {
    if (_isProduction) {
      _mostrarDialogoPagamento();
      return;
    }

    final auth = context.read<AuthProvider>();
    if (!auth.estaLogado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faça login para assinar o Premium.')),
      );
      return;
    }

    setState(() => _processando = true);

    try {
      // DEV ONLY — stub até RevenueCat/in_app_purchase estarem integrados
      final service = PremiumService();
      await service.ativarPremiumDev(
          userId: auth.userId!, plano: _planoSelecionado);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao ativar: $e')),
        );
      }
      if (mounted) setState(() => _processando = false);
      return;
    }

    // Verificar mounted antes de qualquer setState ou uso de context pós-await
    if (!mounted) return;
    setState(() => _processando = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('[DEV] Premium ativado com sucesso!')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final premium = context.watch<PremiumProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('NEXO Premium')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CabecalhoPremium(primary: primary, isPremium: premium.isPremium),
            const SizedBox(height: 24),
            Text('Recursos incluídos', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...PremiumService.recursosExclusivos.entries.map((e) => _LinhaRecurso(
                  label: e.value,
                  primary: primary,
                )),
            const SizedBox(height: 8),
            _LinhaRecurso(label: 'Salvar jogos ilimitados', primary: primary),
            const SizedBox(height: 24),
            if (!premium.isPremium) ...[
              Text('Escolha seu plano', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              _CardPlano(
                titulo: 'Mensal',
                preco: 'R\$ 9,90',
                descricao: 'por mês',
                destaque: false,
                selecionado: _planoSelecionado == PlanoUsuario.mensal,
                primary: primary,
                onTap: () => setState(() => _planoSelecionado = PlanoUsuario.mensal),
              ),
              const SizedBox(height: 8),
              _CardPlano(
                titulo: 'Anual',
                preco: 'R\$ 59,90',
                descricao: 'por ano · economia de 50%',
                destaque: true,
                selecionado: _planoSelecionado == PlanoUsuario.anual,
                primary: primary,
                onTap: () => setState(() => _planoSelecionado = PlanoUsuario.anual),
                badge: 'MELHOR OFERTA',
              ),
              const SizedBox(height: 8),
              _CardPlano(
                titulo: 'Vitalício',
                preco: 'R\$ 97,00',
                descricao: 'pagamento único · para sempre',
                destaque: false,
                selecionado: _planoSelecionado == PlanoUsuario.vitalicio,
                primary: primary,
                onTap: () => setState(() => _planoSelecionado = PlanoUsuario.vitalicio),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _processando ? null : _assinar,
                  icon: _processando
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.workspace_premium),
                  label: Text(_processando ? 'Processando...' : 'Assinar agora'),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Pagamento seguro. Cancele quando quiser.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ] else ...[
              _CartaoPremiumAtivo(usuario: premium.usuario!, primary: primary),
            ],
            const SizedBox(height: 32),
            _AvisoLegal(),
          ],
        ),
      ),
    );
  }
}

class _CabecalhoPremium extends StatelessWidget {
  final Color primary;
  final bool isPremium;

  const _CabecalhoPremium({required this.primary, required this.isPremium});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, primary.withAlpha(160)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.workspace_premium, color: Colors.white, size: 48),
          const SizedBox(height: 8),
          const Text('NEXO Premium',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            isPremium
                ? 'Você já tem acesso a todos os recursos!'
                : 'Desbloqueie todo o potencial do NEXO LOTERIAS',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _LinhaRecurso extends StatelessWidget {
  final String label;
  final Color primary;
  const _LinhaRecurso({required this.label, required this.primary});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: primary, size: 18),
          const SizedBox(width: 10),
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _CardPlano extends StatelessWidget {
  final String titulo;
  final String preco;
  final String descricao;
  final bool destaque;
  final bool selecionado;
  final Color primary;
  final VoidCallback onTap;
  final String? badge;

  const _CardPlano({
    required this.titulo,
    required this.preco,
    required this.descricao,
    required this.destaque,
    required this.selecionado,
    required this.primary,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selecionado ? primary.withAlpha(20) : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selecionado ? primary : primary.withAlpha(40),
            width: selecionado ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selecionado ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: selecionado ? primary : Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(titulo,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: selecionado ? primary : Theme.of(context).colorScheme.onSurface)),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(badge!,
                              style: const TextStyle(
                                  fontSize: 9, fontWeight: FontWeight.w700, color: Colors.black)),
                        ),
                      ],
                    ],
                  ),
                  Text(descricao, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            Text(preco,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: selecionado ? primary : Theme.of(context).colorScheme.onSurface)),
          ],
        ),
      ),
    );
  }
}

class _CartaoPremiumAtivo extends StatelessWidget {
  final dynamic usuario;
  final Color primary;

  const _CartaoPremiumAtivo({required this.usuario, required this.primary});

  @override
  Widget build(BuildContext context) {
    final planoLabel = {
      PlanoUsuario.mensal: 'Plano Mensal',
      PlanoUsuario.anual: 'Plano Anual',
      PlanoUsuario.vitalicio: 'Plano Vitalício',
      PlanoUsuario.free: 'Gratuito',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.withAlpha(20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.withAlpha(80), width: 2),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 40),
          const SizedBox(height: 8),
          Text('Premium Ativo',
              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 4),
          Text(planoLabel[usuario.plano] ?? 'Premium',
              style: Theme.of(context).textTheme.bodyMedium),
          if (usuario.dataExpiracaoPremium != null) ...[
            const SizedBox(height: 4),
            Text(
              'Válido até ${_fmt(usuario.dataExpiracaoPremium!)}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ],
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _AvisoLegal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.grey),
      ),
      child: Text(
        'O NEXO LOTERIAS é um aplicativo de apoio estatístico e organização de apostas. '
        'Ele não garante prêmios nem altera a natureza aleatória dos sorteios.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
        textAlign: TextAlign.center,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/resultados_provider.dart';
import '../../../data/models/concurso.dart';
import '../../../data/models/modalidade.dart';
import '../../widgets/banner_ad_widget.dart';
import '../../../providers/premium_provider.dart';

class ResultadosScreen extends StatefulWidget {
  const ResultadosScreen({super.key});

  @override
  State<ResultadosScreen> createState() => _ResultadosScreenState();
}

class _ResultadosScreenState extends State<ResultadosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ResultadosProvider>().carregarTodos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ResultadosProvider>();
    final premium = context.watch<PremiumProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados',
            style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1)),
        actions: [
          if (provider.sincronizando)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            IconButton(
              icon: const Icon(Icons.cloud_sync_rounded),
              tooltip: 'Sincronizar com API da Caixa',
              onPressed: () async {
                final ok = await context
                    .read<ResultadosProvider>()
                    .sincronizarComApi();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok
                      ? 'Resultados atualizados!'
                      : 'Erro ao sincronizar. Verifique a conexão.'),
                ));
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<ResultadosProvider>().sincronizarComApi(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (provider.ultimaSync != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    const Icon(Icons.update, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      'Última sync: ${_formatarDataHoraSync(provider.ultimaSync!)}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            _ResultadoCard(
              modalidade: Modalidade.porId('mega-sena'),
              concurso: provider.resultado('mega-sena'),
              carregando: provider.carregando('mega-sena'),
            ),
            const SizedBox(height: 16),
            _ResultadoCard(
              modalidade: Modalidade.porId('lotofacil'),
              concurso: provider.resultado('lotofacil'),
              carregando: provider.carregando('lotofacil'),
            ),
            const SizedBox(height: 16),
            _ResultadoCard(
              modalidade: Modalidade.porId('quina'),
              concurso: provider.resultado('quina'),
              carregando: provider.carregando('quina'),
            ),
            const SizedBox(height: 16),
            if (!premium.isPremium) const BannerAdWidget(),
          ],
        ),
      ),
    );
  }
}

String _formatarDataHoraSync(DateTime d) {
  final data =
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  final hora =
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  return '$data $hora';
}

class _ResultadoCard extends StatelessWidget {
  final Modalidade modalidade;
  final Concurso? concurso;
  final bool carregando;

  const _ResultadoCard({
    required this.modalidade,
    required this.concurso,
    required this.carregando,
  });

  @override
  Widget build(BuildContext context) {
    final cor = modalidade.corPrimaria;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: cor, width: 4)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                modalidade.nome,
                style: TextStyle(
                    color: cor, fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const Spacer(),
              if (carregando)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: cor),
                )
              else if (concurso != null)
                Text(
                  'Concurso ${concurso!.numeroConcurso}',
                  style: TextStyle(
                      color: cor, fontSize: 12, fontWeight: FontWeight.w600),
                ),
            ],
          ),

          if (carregando) ...[
            const SizedBox(height: 16),
            const Center(child: Text('Carregando...', style: TextStyle(fontSize: 13))),
          ] else if (concurso == null) ...[
            const SizedBox(height: 12),
            const Text('Resultado não disponível',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
          ] else ...[
            const SizedBox(height: 12),
            Text(
              _formatarData(concurso!.dataSorteio),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: concurso!.dezenasSorteadas
                  .map((n) => _BolinhaDezena(numero: n, cor: cor))
                  .toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.emoji_events_outlined, size: 16, color: cor),
                const SizedBox(width: 6),
                Text(
                  'Prêmio: ${_formatarPremio(concurso!.premioEstimado)}',
                  style: TextStyle(
                      color: cor, fontWeight: FontWeight.w600, fontSize: 13),
                ),
                if (concurso!.acumulado) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('ACUMULOU',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatarData(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _formatarDataHora(DateTime d) =>
      '${_formatarData(d)} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  String _formatarPremio(double valor) {
    if (valor >= 1000000) return 'R\$ ${(valor / 1000000).toStringAsFixed(1)} mi';
    return 'R\$ ${valor.toStringAsFixed(2)}';
  }
}

class _BolinhaDezena extends StatelessWidget {
  final int numero;
  final Color cor;

  const _BolinhaDezena({required this.numero, required this.cor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        numero.toString().padLeft(2, '0'),
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
      ),
    );
  }
}

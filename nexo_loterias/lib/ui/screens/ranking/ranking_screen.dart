import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/ranking_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/ranking_entry.dart';
import '../../../core/constants/app_constants.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  @override
  void initState() {
    super.initState();
    context.read<RankingProvider>().inicializar();
  }

  void _mostrarDialogoRegistrar() {
    final auth = context.read<AuthProvider>();
    if (!auth.estaLogado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faça login para registrar um ganho.')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (_) => _DialogoRegistrarGanho(userId: auth.userId!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ranking = context.watch<RankingProvider>();
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ranking de Sorte'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Registrar ganho',
            onPressed: _mostrarDialogoRegistrar,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primary, primary.withAlpha(160)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Column(
              children: [
                Icon(Icons.emoji_events_rounded, color: Colors.white, size: 32),
                SizedBox(height: 6),
                Text('Top 20 Ganhadores',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                SizedBox(height: 4),
                Text(
                  'Registre seus ganhos e apareça no ranking!',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Expanded(
            child: ranking.carregando
                ? const Center(child: CircularProgressIndicator())
                : ranking.top20.isEmpty
                    ? const Center(
                        child: Text('Nenhum ganho registrado ainda.\nSeja o primeiro!',
                            textAlign: TextAlign.center),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: ranking.top20.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _CardRanking(
                          posicao: i + 1,
                          entry: ranking.top20[i],
                          primary: primary,
                        ),
                      ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              AppConstants.avisoLegal,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarDialogoRegistrar,
        icon: const Icon(Icons.add),
        label: const Text('Registrar ganho'),
      ),
    );
  }
}

class _CardRanking extends StatelessWidget {
  final int posicao;
  final RankingEntry entry;
  final Color primary;

  const _CardRanking({
    required this.posicao,
    required this.entry,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final medalha = posicao == 1
        ? '🥇'
        : posicao == 2
            ? '🥈'
            : posicao == 3
                ? '🥉'
                : '#$posicao';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primary.withAlpha(40)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(medalha,
                style: TextStyle(
                    fontSize: posicao <= 3 ? 22 : 14,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.nomeExibicao,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(
                  '${entry.modalidadeId.toUpperCase()} · Concurso ${entry.concursoNumero}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${entry.acertos} acertos',
                  style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
              if (entry.valorGanho > 0)
                Text(
                  _fmtValor(entry.valorGanho),
                  style: const TextStyle(
                      color: Colors.green, fontWeight: FontWeight.w600, fontSize: 12),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmtValor(double v) {
    if (v >= 1000000) {
      return 'R\$ ${(v / 1000000).toStringAsFixed(1)}M';
    }
    if (v >= 1000) {
      return 'R\$ ${NumberFormat('#,##0', 'pt_BR').format(v)}';
    }
    return 'R\$ ${v.toStringAsFixed(2)}';
  }
}

class _DialogoRegistrarGanho extends StatefulWidget {
  final String userId;
  const _DialogoRegistrarGanho({required this.userId});

  @override
  State<_DialogoRegistrarGanho> createState() => _DialogoRegistrarGanhoState();
}

class _DialogoRegistrarGanhoState extends State<_DialogoRegistrarGanho> {
  final _nomeCtrl = TextEditingController();
  final _concursoCtrl = TextEditingController();
  final _valorCtrl = TextEditingController();
  String _modalidadeId = 'megasena';
  int _acertos = 6;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _concursoCtrl.dispose();
    _valorCtrl.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (_nomeCtrl.text.trim().isEmpty) return;
    final entry = RankingEntry(
      id: const Uuid().v4(),
      userId: widget.userId,
      displayName: _nomeCtrl.text.trim(),
      modalidadeId: _modalidadeId,
      acertos: _acertos,
      valorGanho: double.tryParse(_valorCtrl.text.replaceAll(',', '.')) ?? 0,
      concursoNumero: int.tryParse(_concursoCtrl.text) ?? 0,
      criadaEm: DateTime.now(),
    );
    final ok = await context.read<RankingProvider>().registrarGanho(entry);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Ganho registrado!' : 'Erro ao registrar.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.emoji_events_rounded, color: primary),
          const SizedBox(width: 8),
          const Text('Registrar Ganho'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nomeCtrl,
              decoration: const InputDecoration(labelText: 'Seu nome'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _modalidadeId,
              items: const [
                DropdownMenuItem(value: 'megasena', child: Text('Mega-Sena')),
                DropdownMenuItem(value: 'lotofacil', child: Text('Lotofácil')),
              ],
              onChanged: (v) => setState(() => _modalidadeId = v!),
              decoration: const InputDecoration(labelText: 'Modalidade'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _concursoCtrl,
              decoration: const InputDecoration(labelText: 'Número do concurso'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _acertos,
              items: List.generate(
                20,
                (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1} acertos')),
              ),
              onChanged: (v) => setState(() => _acertos = v!),
              decoration: const InputDecoration(labelText: 'Acertos'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _valorCtrl,
              decoration: const InputDecoration(
                  labelText: 'Valor ganho (R\$)', hintText: 'Opcional'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: context.watch<RankingProvider>().enviando
              ? null
              : _registrar,
          child: const Text('Registrar'),
        ),
      ],
    );
  }
}

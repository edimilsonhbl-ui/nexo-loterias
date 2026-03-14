import 'package:flutter/material.dart';
import '../../../data/models/concurso.dart';
import '../../../data/models/modalidade.dart';
import '../../../data/repositories/concurso_repository.dart';

class HistoricoResultadosScreen extends StatefulWidget {
  const HistoricoResultadosScreen({super.key});

  @override
  State<HistoricoResultadosScreen> createState() =>
      _HistoricoResultadosScreenState();
}

class _HistoricoResultadosScreenState extends State<HistoricoResultadosScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _repo = ConcursoRepository();

  static const _modalidades = ['mega-sena', 'lotofacil', 'quina'];
  static const _labels = ['Mega-Sena', 'Lotofácil', 'Quina'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _modalidades.length, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Resultados'),
        bottom: TabBar(
          controller: _tab,
          tabs: _labels.map((l) => Tab(text: l)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: _modalidades
            .map((id) => _ListaConcursos(modalidadeId: id, repo: _repo))
            .toList(),
      ),
    );
  }
}

class _ListaConcursos extends StatelessWidget {
  final String modalidadeId;
  final ConcursoRepository repo;

  const _ListaConcursos({required this.modalidadeId, required this.repo});

  @override
  Widget build(BuildContext context) {
    final modalidade = Modalidade.porId(modalidadeId);
    final cor = modalidade.corPrimaria;

    return StreamBuilder<List<Concurso>>(
      stream: repo.streamUltimos(modalidadeId, limite: 20),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final lista = snap.data ?? [];
        if (lista.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history_toggle_off, size: 64, color: cor.withAlpha(100)),
                const SizedBox(height: 16),
                const Text('Nenhum resultado salvo ainda.\nSincronize na tela Resultados.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: lista.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _ConcursoCard(concurso: lista[i], cor: cor),
        );
      },
    );
  }
}

class _ConcursoCard extends StatelessWidget {
  final Concurso concurso;
  final Color cor;

  const _ConcursoCard({required this.concurso, required this.cor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: cor, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Concurso ${concurso.numeroConcurso}',
                  style: TextStyle(
                      color: cor, fontWeight: FontWeight.w700, fontSize: 14)),
              Row(
                children: [
                  if (concurso.acumulado)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(6)),
                      child: const Text('ACUMULOU',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700)),
                    ),
                  Text(_fmt(concurso.dataSorteio),
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: concurso.dezenasSorteadas
                .map((n) => Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                          color: cor, borderRadius: BorderRadius.circular(8)),
                      alignment: Alignment.center,
                      child: Text(n.toString().padLeft(2, '0'),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12)),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          Text(
            'Prêmio: ${_fmtPremio(concurso.premioEstimado)}',
            style: TextStyle(
                color: cor, fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _fmtPremio(double v) {
    if (v >= 1000000) return 'R\$ ${(v / 1000000).toStringAsFixed(1)} mi';
    return 'R\$ ${v.toStringAsFixed(2)}';
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../providers/estatisticas_provider.dart';
import '../../../providers/modalidade_provider.dart';
import '../../../data/models/estatistica.dart';

class EstatisticasScreen extends StatefulWidget {
  const EstatisticasScreen({super.key});

  @override
  State<EstatisticasScreen> createState() => _EstatisticasScreenState();
}

class _EstatisticasScreenState extends State<EstatisticasScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final modalidadeId =
        context.read<ModalidadeProvider>().modalidadeAtual.id;
    context.read<EstatisticasProvider>().carregar(modalidadeId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final provider = context.watch<EstatisticasProvider>();
    final modalidade = context.watch<ModalidadeProvider>().modalidadeAtual;

    return Scaffold(
      appBar: AppBar(
        title: Text('Estatísticas – ${modalidade.nome}'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primary,
          labelColor: primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurface,
          tabs: const [
            Tab(text: 'Frequência'),
            Tab(text: 'Atraso'),
            Tab(text: 'Distribuição'),
          ],
        ),
      ),
      body: provider.carregando
          ? const Center(child: CircularProgressIndicator())
          : provider.estatisticas == null
              ? const Center(child: Text('Sem dados disponíveis.'))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _FrequenciaTab(stats: provider.estatisticas!),
                    _AtrasoTab(stats: provider.estatisticas!),
                    _DistribuicaoTab(stats: provider.estatisticas!),
                  ],
                ),
    );
  }
}

class _FrequenciaTab extends StatelessWidget {
  final EstatisticasModalidade stats;
  const _FrequenciaTab({required this.stats});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final maisSorteados = stats.maisSorteados.take(10).toList();
    final menosSorteados = stats.menosSorteados.take(10).toList();
    final maxFreq = stats.maisSorteados.first.frequencia.toDouble();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoCard(
            label: 'Total de concursos analisados',
            value: stats.totalConcursos.toString(),
          ),
          const SizedBox(height: 20),
          Text('10 mais sorteados', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ...maisSorteados.map((e) => _BarraFrequencia(
                numero: e.numero,
                valor: e.frequencia,
                maximo: maxFreq,
                color: primary,
                label: '${e.frequencia}x',
              )),
          const SizedBox(height: 24),
          Text('10 menos sorteados', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ...menosSorteados.map((e) => _BarraFrequencia(
                numero: e.numero,
                valor: e.frequencia,
                maximo: maxFreq,
                color: Colors.grey,
                label: '${e.frequencia}x',
              )),
        ],
      ),
    );
  }
}

class _AtrasoTab extends StatelessWidget {
  final EstatisticasModalidade stats;
  const _AtrasoTab({required this.stats});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final maisAtrasados = stats.maisAtrasados.take(15).toList();
    final maxAtraso = maisAtrasados.first.atraso.toDouble();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Números mais atrasados', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Concursos desde a última aparição',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ...maisAtrasados.map((e) => _BarraFrequencia(
                numero: e.numero,
                valor: e.atraso,
                maximo: maxAtraso,
                color: e.atraso > 20 ? Colors.orange : primary,
                label: '${e.atraso} conc.',
              )),
        ],
      ),
    );
  }
}

class _DistribuicaoTab extends StatelessWidget {
  final EstatisticasModalidade stats;
  const _DistribuicaoTab({required this.stats});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final pares = stats.mediaParesUltimos10;
    final impares = stats.mediaImparesUltimos10;
    final total = pares + impares;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Média últimos 10 sorteios', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _InfoCard(
                  label: 'Pares (média)',
                  value: pares.toStringAsFixed(1),
                  color: primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoCard(
                  label: 'Ímpares (média)',
                  value: impares.toStringAsFixed(1),
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoCard(
            label: 'Soma média das dezenas',
            value: stats.somaMediaUltimos10.toStringAsFixed(0),
          ),
          const SizedBox(height: 28),
          Text('Proporção Pares × Ímpares', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 48,
                sections: [
                  PieChartSectionData(
                    value: total > 0 ? pares / total * 100 : 50,
                    title: '${(total > 0 ? pares / total * 100 : 50).toStringAsFixed(0)}%',
                    color: primary,
                    radius: 60,
                    titleStyle: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  PieChartSectionData(
                    value: total > 0 ? impares / total * 100 : 50,
                    title: '${(total > 0 ? impares / total * 100 : 50).toStringAsFixed(0)}%',
                    color: Colors.orange,
                    radius: 60,
                    titleStyle: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Legenda(color: primary, label: 'Pares'),
              const SizedBox(width: 24),
              _Legenda(color: Colors.orange, label: 'Ímpares'),
            ],
          ),
        ],
      ),
    );
  }
}

class _BarraFrequencia extends StatelessWidget {
  final int numero;
  final int valor;
  final double maximo;
  final Color color;
  final String label;

  const _BarraFrequencia({
    required this.numero,
    required this.valor,
    required this.maximo,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final pct = maximo > 0 ? valor / maximo : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              numero.toString().padLeft(2, '0'),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: color.withAlpha(40),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 50,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _InfoCard({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w700, color: c)),
        ],
      ),
    );
  }
}

class _Legenda extends StatelessWidget {
  final Color color;
  final String label;
  const _Legenda({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 14, height: 14, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

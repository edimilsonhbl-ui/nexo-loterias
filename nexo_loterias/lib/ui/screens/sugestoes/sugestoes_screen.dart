import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/modalidade_provider.dart';
import '../../../providers/aposta_provider.dart';
import '../../../data/services/sugestoes_service.dart';
import '../../../core/utils/probabilidade_util.dart';
import '../../../data/models/aposta.dart';
import 'package:uuid/uuid.dart';

class SugestoesScreen extends StatefulWidget {
  const SugestoesScreen({super.key});

  @override
  State<SugestoesScreen> createState() => _SugestoesScreenState();
}

class _SugestoesScreenState extends State<SugestoesScreen> {
  final _service = SugestoesService();
  final _uuid = const Uuid();

  TipoSugestao _tipo = TipoSugestao.equilibrado;
  bool _evitarSequencias = true;
  bool _equilibrarPares = true;
  bool _equilibrarAltasBaixas = true;

  List<int> _numerosGerados = [];
  String _perfil = '';

  void _gerar() {
    final modalidade = context.read<ModalidadeProvider>().modalidadeAtual;
    final nums = _service.gerar(
      modalidade: modalidade,
      tipo: _tipo,
      evitarSequencias: _evitarSequencias,
      equilibrarParesImpares: _equilibrarPares,
      equilibrarAltasBaixas: _equilibrarAltasBaixas,
    );
    setState(() {
      _numerosGerados = nums;
      _perfil = _service.avaliarJogo(nums, modalidade.universoNumeros);
    });
  }

  void _salvar() {
    if (_numerosGerados.isEmpty) return;
    final modalidade = context.read<ModalidadeProvider>().modalidadeAtual;
    final prob = ProbabilidadeUtil.calcularProbabilidades(modalidade, _numerosGerados.length);
    context.read<ApostaProvider>().salvarAposta(Aposta(
      id: _uuid.v4(),
      modalidadeId: modalidade.id,
      numerosEscolhidos: _numerosGerados,
      valorAposta: ProbabilidadeUtil.calcularValor(modalidade, _numerosGerados.length),
      probabilidade: prob[modalidade.numerosMin] ?? 0,
      criadaEm: DateTime.now(),
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sugestão salva em Meus Jogos!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final modalidade = context.watch<ModalidadeProvider>().modalidadeAtual;

    return Scaffold(
      appBar: AppBar(title: const Text('Sugestões Inteligentes')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tipo de jogo', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: TipoSugestao.values.map((t) {
                final labels = {
                  TipoSugestao.equilibrado: 'Equilibrado',
                  TipoSugestao.conservador: 'Conservador',
                  TipoSugestao.ousado: 'Ousado',
                };
                final selecionado = _tipo == t;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _tipo = t),
                    child: Container(
                      margin: EdgeInsets.only(right: t != TipoSugestao.ousado ? 8 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selecionado ? primary : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: selecionado ? primary : primary.withAlpha(60)),
                      ),
                      child: Text(
                        labels[t]!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: selecionado ? Colors.white : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Text('Filtros', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _FiltroSwitch(
              label: 'Evitar sequências de 3+',
              value: _evitarSequencias,
              onChanged: (v) => setState(() => _evitarSequencias = v),
              primary: primary,
            ),
            _FiltroSwitch(
              label: 'Equilibrar pares e ímpares',
              value: _equilibrarPares,
              onChanged: (v) => setState(() => _equilibrarPares = v),
              primary: primary,
            ),
            _FiltroSwitch(
              label: 'Equilibrar números altos e baixos',
              value: _equilibrarAltasBaixas,
              onChanged: (v) => setState(() => _equilibrarAltasBaixas = v),
              primary: primary,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _gerar,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Gerar Sugestão'),
              ),
            ),
            if (_numerosGerados.isNotEmpty) ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Jogo gerado', style: Theme.of(context).textTheme.titleMedium),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: primary.withAlpha(40),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _perfil,
                      style: TextStyle(color: primary, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _numerosGerados.map((n) => Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          n.toString().padLeft(2, '0'),
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ),
                    )).toList(),
              ),
              const SizedBox(height: 16),
              _AnaliseJogo(numeros: _numerosGerados, universo: modalidade.universoNumeros),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _salvar,
                  icon: const Icon(Icons.bookmark_add_outlined),
                  label: const Text('Salvar este jogo'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FiltroSwitch extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color primary;

  const _FiltroSwitch({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyLarge),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: primary,
        ),
      ],
    );
  }
}

class _AnaliseJogo extends StatelessWidget {
  final List<int> numeros;
  final int universo;

  const _AnaliseJogo({required this.numeros, required this.universo});

  @override
  Widget build(BuildContext context) {
    final pares = numeros.where((n) => n % 2 == 0).length;
    final impares = numeros.length - pares;
    final meio = universo ~/ 2;
    final altos = numeros.where((n) => n > meio).length;
    final baixos = numeros.length - altos;
    final soma = numeros.reduce((a, b) => a + b);
    final primary = Theme.of(context).colorScheme.primary;

    int seqMax = 1, seqAtual = 1;
    for (int i = 1; i < numeros.length; i++) {
      if (numeros[i] == numeros[i - 1] + 1) {
        seqAtual++;
        if (seqAtual > seqMax) seqMax = seqAtual;
      } else {
        seqAtual = 1;
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primary.withAlpha(40)),
      ),
      child: Column(
        children: [
          _LinhaAnalise('Pares / Ímpares', '$pares / $impares'),
          _LinhaAnalise('Altos / Baixos', '$altos / $baixos'),
          _LinhaAnalise('Soma total', soma.toString()),
          _LinhaAnalise('Sequência máxima', '$seqMax consecutivos'),
        ],
      ),
    );
  }
}

class _LinhaAnalise extends StatelessWidget {
  final String label;
  final String valor;
  const _LinhaAnalise(this.label, this.valor);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(valor,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary)),
        ],
      ),
    );
  }
}

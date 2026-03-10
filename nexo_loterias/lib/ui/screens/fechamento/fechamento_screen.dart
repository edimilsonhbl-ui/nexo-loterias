import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/fechamento_provider.dart';
import '../../../providers/modalidade_provider.dart';
import '../../../providers/aposta_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/services/fechamento_service.dart';
import '../../../data/models/aposta.dart';
import '../../../core/utils/probabilidade_util.dart';
import 'package:uuid/uuid.dart';

class FechamentoScreen extends StatefulWidget {
  const FechamentoScreen({super.key});

  @override
  State<FechamentoScreen> createState() => _FechamentoScreenState();
}

class _FechamentoScreenState extends State<FechamentoScreen> {
  final _orcamentoCtrl = TextEditingController(text: '50');

  @override
  void initState() {
    super.initState();
    final modalidade = context.read<ModalidadeProvider>().modalidadeAtual;
    context.read<FechamentoProvider>().setModalidade(modalidade);
  }

  @override
  void dispose() {
    _orcamentoCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvarTodos() async {
    final provider = context.read<FechamentoProvider>();
    final apostaProvider = context.read<ApostaProvider>();
    final auth = context.read<AuthProvider>();
    final modalidade = provider.modalidade!;
    final resultado = provider.resultado!;
    final uuid = const Uuid();

    for (final jogo in resultado.jogos) {
      final prob = ProbabilidadeUtil.calcularProbabilidades(modalidade, jogo.length);
      await apostaProvider.salvarAposta(
        Aposta(
          id: uuid.v4(),
          modalidadeId: modalidade.id,
          numerosEscolhidos: jogo,
          valorAposta: ProbabilidadeUtil.calcularValor(modalidade, jogo.length),
          probabilidade: prob[modalidade.numerosMin] ?? 0,
          criadaEm: DateTime.now(),
        ),
        userId: auth.userId,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${resultado.totalJogos} jogos salvos em Meus Jogos!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FechamentoProvider>();
    final primary = Theme.of(context).colorScheme.primary;
    final modalidade = provider.modalidade;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FECHAMENTO NEXO'),
        actions: [
          if (provider.numerosBase.isNotEmpty)
            TextButton(
              onPressed: provider.limpar,
              child: Text('Limpar', style: TextStyle(color: primary)),
            ),
        ],
      ),
      body: modalidade == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CartaoInfo(
                    modalidade: modalidade.nome,
                    minBase: provider.minimoNumerosBase,
                    selecionados: provider.numerosBase.length,
                    combinacoes: provider.totalCombinacoesPossiveis,
                    primary: primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Selecione os números base',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mínimo ${provider.minimoNumerosBase} números',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: modalidade.universoNumeros <= 25 ? 5 : 10,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                      childAspectRatio: 1,
                    ),
                    itemCount: modalidade.universoNumeros,
                    itemBuilder: (_, i) {
                      final numero = i + 1;
                      final selecionado = provider.numerosBase.contains(numero);
                      return GestureDetector(
                        onTap: () => context.read<FechamentoProvider>().toggleNumero(numero),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 130),
                          decoration: BoxDecoration(
                            color: selecionado ? primary : Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(
                              color: selecionado ? primary : primary.withAlpha(50),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              numero.toString().padLeft(2, '0'),
                              style: TextStyle(
                                color: selecionado
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.onSurface,
                                fontWeight:
                                    selecionado ? FontWeight.w700 : FontWeight.w400,
                                fontSize: modalidade.universoNumeros <= 25 ? 15 : 12,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Text('Tipo de fechamento', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  _SeletorTipo(
                    selecionado: provider.tipo,
                    onSelecionado: context.read<FechamentoProvider>().setTipo,
                    primary: primary,
                  ),
                  if (provider.tipo == TipoFechamento.porOrcamento) ...[
                    const SizedBox(height: 16),
                    Text('Orçamento disponível (R\$)',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _orcamentoCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        prefixText: 'R\$ ',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: primary, width: 2),
                        ),
                      ),
                      onChanged: (v) {
                        final valor = double.tryParse(v.replaceAll(',', '.')) ?? 0;
                        context.read<FechamentoProvider>().setOrcamento(valor);
                      },
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: provider.podeGerar && !provider.processando
                          ? () => context.read<FechamentoProvider>().gerar()
                          : null,
                      icon: provider.processando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.auto_awesome_mosaic),
                      label: Text(provider.processando ? 'Gerando...' : 'Gerar Fechamento'),
                    ),
                  ),
                  if (!provider.podeGerar && provider.numerosBase.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Selecione pelo menos ${provider.minimoNumerosBase} números.',
                      style: const TextStyle(color: Colors.orange, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (provider.resultado != null) ...[
                    const SizedBox(height: 28),
                    _ResultadoFechamento(
                      resultado: provider.resultado!,
                      primary: primary,
                      onSalvarTodos: _salvarTodos,
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _CartaoInfo extends StatelessWidget {
  final String modalidade;
  final int minBase;
  final int selecionados;
  final int combinacoes;
  final Color primary;

  const _CartaoInfo({
    required this.modalidade,
    required this.minBase,
    required this.selecionados,
    required this.combinacoes,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primary.withAlpha(20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primary.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_mosaic, color: primary, size: 20),
              const SizedBox(width: 8),
              Text('Fechamento Nexo – $modalidade',
                  style: TextStyle(
                      color: primary, fontWeight: FontWeight.w700, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _InfoItem(
                  label: 'Selecionados',
                  valor: '$selecionados',
                  color: selecionados >= minBase ? Colors.green : Colors.orange,
                ),
              ),
              Expanded(
                child: _InfoItem(
                  label: 'Combinações possíveis',
                  valor: combinacoes > 0
                      ? (combinacoes >= 9999999 ? '9.999.999+' : _fmt(combinacoes))
                      : '–',
                  color: primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(int n) => n.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      );
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String valor;
  final Color color;
  const _InfoItem({required this.label, required this.valor, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        Text(valor,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

class _SeletorTipo extends StatelessWidget {
  final TipoFechamento selecionado;
  final ValueChanged<TipoFechamento> onSelecionado;
  final Color primary;

  const _SeletorTipo({
    required this.selecionado,
    required this.onSelecionado,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final opcoes = [
      (TipoFechamento.rapido, 'Rápido', Icons.bolt, 'Primeiras combinações (até 50 jogos)'),
      (TipoFechamento.equilibrado, 'Equilibrado', Icons.balance, 'Distribui altos e baixos (até 30 jogos)'),
      (TipoFechamento.porOrcamento, 'Por orçamento', Icons.attach_money, 'Máximo de jogos pelo valor disponível'),
    ];

    return Column(
      children: opcoes.map((o) {
        final (tipo, label, icone, descricao) = o;
        final isSel = selecionado == tipo;
        return GestureDetector(
          onTap: () => onSelecionado(tipo),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isSel ? primary.withAlpha(25) : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSel ? primary : primary.withAlpha(40),
                width: isSel ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(icone, color: isSel ? primary : Theme.of(context).colorScheme.onSurface, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isSel ? primary : Theme.of(context).colorScheme.onSurface)),
                      Text(descricao,
                          style: Theme.of(context).textTheme.labelSmall),
                    ],
                  ),
                ),
                if (isSel) Icon(Icons.check_circle, color: primary, size: 20),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ResultadoFechamento extends StatelessWidget {
  final ResultadoFechamento resultado;
  final Color primary;
  final VoidCallback onSalvarTodos;

  const _ResultadoFechamento({
    required this.resultado,
    required this.primary,
    required this.onSalvarTodos,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${resultado.totalJogos} jogos gerados',
                style: Theme.of(context).textTheme.titleMedium),
            Text(
              'R\$ ${resultado.custoTotal.toStringAsFixed(2)}',
              style: TextStyle(
                  color: primary, fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Números base: ${resultado.numerosBase.map((n) => n.toString().padLeft(2, '0')).join(' · ')}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        ...resultado.jogos.asMap().entries.map((e) {
          final idx = e.key;
          final jogo = e.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: primary.withAlpha(40)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    '${idx + 1}',
                    style: TextStyle(
                        color: primary, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
                Expanded(
                  child: Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: jogo.map((n) => Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              n.toString().padLeft(2, '0'),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11),
                            ),
                          ),
                        )).toList(),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onSalvarTodos,
            icon: const Icon(Icons.save_alt),
            label: Text('Salvar todos os ${resultado.totalJogos} jogos'),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

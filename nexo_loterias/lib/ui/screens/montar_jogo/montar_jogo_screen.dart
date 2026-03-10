import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/modalidade_provider.dart';
import '../../../providers/jogo_provider.dart';
import '../../../providers/aposta_provider.dart';
import '../../../core/utils/probabilidade_util.dart';

class MontarJogoScreen extends StatefulWidget {
  const MontarJogoScreen({super.key});

  @override
  State<MontarJogoScreen> createState() => _MontarJogoScreenState();
}

class _MontarJogoScreenState extends State<MontarJogoScreen> {
  @override
  void initState() {
    super.initState();
    final modalidade = context.read<ModalidadeProvider>().modalidadeAtual;
    context.read<JogoProvider>().setModalidade(modalidade);
  }

  void _salvarAposta() {
    final jogo = context.read<JogoProvider>();
    if (!jogo.jogoValido) return;
    context.read<ApostaProvider>().salvarAposta(jogo.gerarAposta());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Aposta salva com sucesso!')),
    );
    jogo.limpar();
  }

  @override
  Widget build(BuildContext context) {
    final jogo = context.watch<JogoProvider>();
    final modalidade = jogo.modalidade;
    if (modalidade == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final primary = Theme.of(context).colorScheme.primary;
    final probs = jogo.probabilidades;

    return Scaffold(
      appBar: AppBar(title: Text('Montar Jogo – ${modalidade.nome}')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: modalidade.universoNumeros <= 25 ? 5 : 10,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    itemCount: modalidade.universoNumeros,
                    itemBuilder: (_, i) {
                      final numero = i + 1;
                      final selecionado = jogo.numerosSelecionados.contains(numero);
                      return GestureDetector(
                        onTap: () => context.read<JogoProvider>().toggleNumero(numero),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            color: selecionado ? primary : Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selecionado ? primary : primary.withOpacity(0.3),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              numero.toString().padLeft(2, '0'),
                              style: TextStyle(
                                color: selecionado ? Colors.white : Theme.of(context).colorScheme.onSurface,
                                fontWeight: selecionado ? FontWeight.w700 : FontWeight.w400,
                                fontSize: modalidade.universoNumeros <= 25 ? 16 : 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  if (jogo.jogoValido) ...[
                    Text('Probabilidades', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...probs.entries.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(modalidade.faixasPremio[e.key] ?? '${e.key} acertos',
                                  style: Theme.of(context).textTheme.bodyMedium),
                              Text(ProbabilidadeUtil.formatarProbabilidade(e.value),
                                  style: TextStyle(color: primary, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        )),
                  ],
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(top: BorderSide(color: Theme.of(context).dividerTheme.color ?? Colors.grey)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${jogo.quantidade} de ${modalidade.numerosMax} números',
                        style: Theme.of(context).textTheme.bodyMedium),
                    Text('R\$ ${jogo.valorAposta.toStringAsFixed(2)}',
                        style: TextStyle(color: primary, fontWeight: FontWeight.w700, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.read<JogoProvider>().surpresinha(),
                        child: const Text('Surpresinha'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.read<JogoProvider>().completar(),
                        child: const Text('Completar'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.read<JogoProvider>().limpar(),
                        child: const Text('Limpar'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: jogo.jogoValido ? _salvarAposta : null,
                    child: const Text('Salvar Aposta'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

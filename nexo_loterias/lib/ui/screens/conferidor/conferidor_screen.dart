import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/aposta_provider.dart';
import '../../../providers/modalidade_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/aposta.dart';
import '../../../data/models/concurso.dart';
import '../../../data/models/modalidade.dart';

class ConferidorScreen extends StatefulWidget {
  const ConferidorScreen({super.key});

  @override
  State<ConferidorScreen> createState() => _ConferidorScreenState();
}

class _ConferidorScreenState extends State<ConferidorScreen> {
  Aposta? _apostaSelecionada;
  final List<int> _resultadoManual = [];
  Aposta? _apostaConferida;

  void _toggleResultado(int numero) {
    setState(() {
      if (_resultadoManual.contains(numero)) {
        _resultadoManual.remove(numero);
      } else {
        _resultadoManual.add(numero);
        _resultadoManual.sort();
      }
      _apostaConferida = null;
    });
  }

  Future<void> _conferir() async {
    if (_apostaSelecionada == null || _resultadoManual.isEmpty) return;
    final modalidade = Modalidade.porId(_apostaSelecionada!.modalidadeId);
    final concurso = Concurso(
      id: 'manual',
      modalidadeId: modalidade.id,
      numeroConcurso: 0,
      dataSorteio: DateTime.now(),
      dezenasSorteadas: _resultadoManual,
      premioEstimado: 0,
    );
    final auth = context.read<AuthProvider>().userId;
    final resultado = await context.read<ApostaProvider>().conferir(
          _apostaSelecionada!,
          concurso,
          userId: auth,
        );
    setState(() => _apostaConferida = resultado);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final apostas = context.watch<ApostaProvider>().apostas;
    final modalidade = context.watch<ModalidadeProvider>().modalidadeAtual;

    return Scaffold(
      appBar: AppBar(title: const Text('Conferidor')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. Escolha uma aposta', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            apostas.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Nenhuma aposta salva. Monte um jogo primeiro.'),
                  )
                : Column(
                    children: apostas.map((a) {
                      final selecionada = _apostaSelecionada?.id == a.id;
                      return GestureDetector(
                        onTap: () => setState(() {
                          _apostaSelecionada = a;
                          _apostaConferida = null;
                        }),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: selecionada
                                ? primary.withAlpha(30)
                                : Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selecionada ? primary : primary.withAlpha(40),
                              width: selecionada ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                a.modalidadeId.toUpperCase(),
                                style: TextStyle(color: primary, fontWeight: FontWeight.w700, fontSize: 11),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: a.numerosEscolhidos.map((n) => Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: selecionada ? primary : primary.withAlpha(60),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Center(
                                        child: Text(
                                          n.toString().padLeft(2, '0'),
                                          style: TextStyle(
                                            color: selecionada ? Colors.white : Theme.of(context).colorScheme.onSurface,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    )).toList(),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
            if (_apostaSelecionada != null) ...[
              const SizedBox(height: 24),
              Text('2. Digite o resultado do sorteio', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                'Selecione as dezenas sorteadas (${Modalidade.porId(_apostaSelecionada!.modalidadeId).numerosMin} números)',
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
                itemCount: Modalidade.porId(_apostaSelecionada!.modalidadeId).universoNumeros,
                itemBuilder: (_, i) {
                  final numero = i + 1;
                  final selecionado = _resultadoManual.contains(numero);
                  final naAposta = _apostaSelecionada!.numerosEscolhidos.contains(numero);
                  Color bgColor;
                  if (selecionado && naAposta) {
                    bgColor = Colors.green;
                  } else if (selecionado) {
                    bgColor = primary;
                  } else {
                    bgColor = Theme.of(context).colorScheme.surface;
                  }
                  return GestureDetector(
                    onTap: () => _toggleResultado(numero),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: naAposta ? primary : primary.withAlpha(50),
                          width: naAposta ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          numero.toString().padLeft(2, '0'),
                          style: TextStyle(
                            color: (selecionado || naAposta) ? Colors.white : Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                            fontSize: modalidade.universoNumeros <= 25 ? 14 : 11,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _resultadoManual.isNotEmpty ? _conferir : null,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Conferir'),
                ),
              ),
              if (_apostaConferida != null) ...[
                const SizedBox(height: 20),
                _ResultadoConferencia(aposta: _apostaConferida!),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _ResultadoConferencia extends StatelessWidget {
  final Aposta aposta;
  const _ResultadoConferencia({required this.aposta});

  @override
  Widget build(BuildContext context) {
    final acertos = aposta.acertos ?? 0;
    final temPremio = aposta.faixaPremio != null;
    final primary = Theme.of(context).colorScheme.primary;
    final corResultado = temPremio ? Colors.green : (acertos > 0 ? primary : Colors.grey);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: corResultado.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: corResultado.withAlpha(80), width: 2),
      ),
      child: Column(
        children: [
          Icon(
            temPremio ? Icons.emoji_events_rounded : Icons.info_outline,
            color: corResultado,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            '$acertos acerto${acertos != 1 ? 's' : ''}',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: corResultado),
          ),
          if (temPremio) ...[
            const SizedBox(height: 6),
            Text(
              aposta.faixaPremio!,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.green),
            ),
          ] else ...[
            const SizedBox(height: 6),
            Text(
              acertos == 0 ? 'Nenhum acerto desta vez.' : 'Não premiado.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

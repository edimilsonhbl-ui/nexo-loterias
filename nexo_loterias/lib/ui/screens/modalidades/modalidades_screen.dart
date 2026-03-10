import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/modalidade.dart';
import '../../../providers/modalidade_provider.dart';

class ModalidadesScreen extends StatelessWidget {
  const ModalidadesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ModalidadeProvider>();
    final selecionada = context.watch<ModalidadeProvider>().modalidadeAtual;

    final modalidades = Modalidade.todas.where((m) => m.disponivel).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Escolha a Modalidade')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: modalidades.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final m = modalidades[i];
          final isSelecionada = m.id == selecionada.id;
          return InkWell(
              onTap: () {
                provider.selecionarModalidade(m);
                Navigator.pop(context);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelecionada ? m.corPrimaria : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelecionada ? m.corPrimaria : m.corPrimaria.withOpacity(0.4),
                    width: isSelecionada ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: m.corPrimaria.withOpacity(isSelecionada ? 0.3 : 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.casino_rounded, color: isSelecionada ? Colors.white : m.corPrimaria),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.nome,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: isSelecionada ? Colors.white : null,
                                ),
                          ),
                          Text(
                            '${m.numerosMin}–${m.numerosMax} números de ${m.universoNumeros}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: isSelecionada ? Colors.white70 : null,
                                ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelecionada)
                      const Icon(Icons.check_circle, color: Colors.white),
                  ],
                ),
              ),
          );
        },
      ),
    );
  }
}

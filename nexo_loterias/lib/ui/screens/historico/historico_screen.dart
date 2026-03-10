import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/aposta_provider.dart';

class HistoricoScreen extends StatelessWidget {
  const HistoricoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final apostas = context.watch<ApostaProvider>().apostas;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Meus Jogos')),
      body: apostas.isEmpty
          ? const Center(child: Text('Nenhuma aposta salva ainda.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: apostas.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final a = apostas[i];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primary.withOpacity(0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(a.modalidadeId.toUpperCase(),
                              style: TextStyle(color: primary, fontWeight: FontWeight.w700, fontSize: 12)),
                          Text(
                            '${a.criadaEm.day.toString().padLeft(2, '0')}/${a.criadaEm.month.toString().padLeft(2, '0')}/${a.criadaEm.year}',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: a.numerosEscolhidos.map((n) {
                          return Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                n.toString().padLeft(2, '0'),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      if (a.acertos != null) ...[
                        const SizedBox(height: 8),
                        Text('${a.acertos} acerto(s)${a.faixaPremio != null ? ' – ${a.faixaPremio}' : ''}',
                            style: TextStyle(color: primary, fontWeight: FontWeight.w600)),
                      ]
                    ],
                  ),
                );
              },
            ),
    );
  }
}

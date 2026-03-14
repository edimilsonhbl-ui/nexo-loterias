import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../providers/aposta_provider.dart';
import '../../../data/models/aposta.dart';
import '../../../data/models/modalidade.dart';

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
              itemBuilder: (_, i) => _CartaoAposta(aposta: apostas[i], primary: primary),
            ),
    );
  }
}

class _CartaoAposta extends StatelessWidget {
  final Aposta aposta;
  final Color primary;
  final GlobalKey _repaintKey = GlobalKey();

  _CartaoAposta({required this.aposta, required this.primary});

  Future<void> _compartilhar(BuildContext context) async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/nexo_jogo_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);

      final modalidade = Modalidade.porId(aposta.modalidadeId);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Meu jogo da ${modalidade.nome} gerado no NEXO LOTERIAS! 🍀\nBaixe o app e gere seus jogos.',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao compartilhar. Tente novamente.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final modalidade = Modalidade.porId(aposta.modalidadeId);
    final cor = modalidade.corPrimaria;

    return RepaintBoundary(
      key: _repaintKey,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cor.withAlpha(64)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      modalidade.nome.toUpperCase(),
                      style: TextStyle(
                          color: cor, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      '${aposta.criadaEm.day.toString().padLeft(2, '0')}/${aposta.criadaEm.month.toString().padLeft(2, '0')}/${aposta.criadaEm.year}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _compartilhar(context),
                      child: Icon(Icons.share_rounded, size: 18, color: cor),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: aposta.numerosEscolhidos.map((n) {
                return Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: cor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    n.toString().padLeft(2, '0'),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12),
                  ),
                );
              }).toList(),
            ),
            if (aposta.acertos != null) ...[
              const SizedBox(height: 8),
              Text(
                '${aposta.acertos} acerto(s)${aposta.faixaPremio != null ? ' – ${aposta.faixaPremio}' : ''}',
                style: TextStyle(color: cor, fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: 6),
            const Text(
              'NEXO LOTERIAS',
              style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

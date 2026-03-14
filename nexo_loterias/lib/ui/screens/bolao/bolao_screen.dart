import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../providers/bolao_provider.dart';
import '../../../providers/auth_provider.dart' as app_auth;
import '../../../data/models/bolao.dart';
import '../../../data/models/modalidade.dart';

class BolaoScreen extends StatelessWidget {
  const BolaoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<app_auth.AuthProvider>();
    final primary = Theme.of(context).colorScheme.primary;

    if (!auth.estaLogado) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bolão')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.group_outlined, size: 64, color: primary.withAlpha(100)),
              const SizedBox(height: 16),
              const Text('Faça login para usar o Bolão',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('BOLÃO NEXO'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Criar bolão',
            onPressed: () => _mostrarDialogCriar(context),
          ),
        ],
      ),
      body: StreamBuilder<List<Bolao>>(
        stream: context.read<BolaoProvider>().streamDoUsuario(auth.userId!),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final lista = snap.data ?? [];
          if (lista.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.groups_rounded, size: 80, color: primary.withAlpha(80)),
                    const SizedBox(height: 20),
                    Text('Você não está em nenhum bolão ainda.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    const Text('Crie um novo bolão ou entre com um código.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _mostrarDialogCriar(context),
                            icon: const Icon(Icons.add),
                            label: const Text('Criar bolão'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _mostrarDialogEntrar(context),
                            icon: const Icon(Icons.login),
                            label: const Text('Entrar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _mostrarDialogCriar(context),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Novo Bolão'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _mostrarDialogEntrar(context),
                        icon: const Icon(Icons.login, size: 16),
                        label: const Text('Entrar com código'),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: lista.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _BolaoCard(
                    bolao: lista[i],
                    uid: auth.userId!,
                    primary: primary,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _mostrarDialogCriar(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _BottomCriarBolao(),
    );
  }

  void _mostrarDialogEntrar(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _BottomEntrarBolao(),
    );
  }
}

// ─── Card do Bolão ───────────────────────────────────────────────────────────

class _BolaoCard extends StatelessWidget {
  final Bolao bolao;
  final String uid;
  final Color primary;

  const _BolaoCard({required this.bolao, required this.uid, required this.primary});

  @override
  Widget build(BuildContext context) {
    final modalidade = Modalidade.porId(bolao.modalidadeId);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: modalidade.corPrimaria, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(bolao.nome,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              GestureDetector(
                onTap: () => _compartilhar(context),
                child: Icon(Icons.share_rounded, size: 18, color: primary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _Chip(label: modalidade.nome, cor: modalidade.corPrimaria),
              const SizedBox(width: 8),
              _Chip(
                label: '${bolao.totalMembros} membro${bolao.totalMembros != 1 ? 's' : ''}',
                cor: Colors.blue,
              ),
              const SizedBox(width: 8),
              _Chip(
                label: '${bolao.totalJogos} jogo${bolao.totalJogos != 1 ? 's' : ''}',
                cor: Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.vpn_key_rounded, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text('Código: ',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: bolao.codigo));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Código copiado!')),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: primary.withAlpha(30),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(bolao.codigo,
                      style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          letterSpacing: 2)),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.copy, size: 13, color: primary),
            ],
          ),
        ],
      ),
    );
  }

  void _compartilhar(BuildContext context) {
    Share.share(
      'Participe do meu bolão no NEXO LOTERIAS!\n'
      'Bolão: ${bolao.nome}\n'
      'Código: ${bolao.codigo}\n'
      'Baixe o app e entre com o código!',
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color cor;
  const _Chip({required this.label, required this.cor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cor.withAlpha(30),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(color: cor, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}

// ─── Bottom Sheets ────────────────────────────────────────────────────────────

class _BottomCriarBolao extends StatefulWidget {
  const _BottomCriarBolao();

  @override
  State<_BottomCriarBolao> createState() => _BottomCriarBolaoState();
}

class _BottomCriarBolaoState extends State<_BottomCriarBolao> {
  final _nomeCtrl = TextEditingController();
  String _modalidadeId = 'mega-sena';

  @override
  void dispose() {
    _nomeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final provider = context.watch<BolaoProvider>();
    final auth = context.read<app_auth.AuthProvider>();

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Criar Bolão', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          TextFormField(
            controller: _nomeCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Nome do bolão',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: primary, width: 2)),
            ),
          ),
          const SizedBox(height: 16),
          Text('Loteria', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['mega-sena', 'lotofacil', 'quina'].map((id) {
              final m = Modalidade.porId(id);
              final sel = _modalidadeId == id;
              return GestureDetector(
                onTap: () => setState(() => _modalidadeId = id),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel ? m.corPrimaria : m.corPrimaria.withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(m.nome,
                      style: TextStyle(
                          color: sel ? Colors.white : m.corPrimaria,
                          fontWeight: FontWeight.w600,
                          fontSize: 12)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: provider.carregando || _nomeCtrl.text.trim().isEmpty
                  ? null
                  : () async {
                      final bolao = await context.read<BolaoProvider>().criar(
                            nome: _nomeCtrl.text,
                            modalidadeId: _modalidadeId,
                            uid: auth.userId!,
                            nomeUsuario: FirebaseAuth.instance.currentUser?.email?.split('@').first ?? 'Usuário',
                          );
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      if (bolao != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Bolão criado! Código: ${bolao.codigo}')),
                        );
                      }
                    },
              child: provider.carregando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Criar Bolão'),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomEntrarBolao extends StatefulWidget {
  const _BottomEntrarBolao();

  @override
  State<_BottomEntrarBolao> createState() => _BottomEntrarBolaoState();
}

class _BottomEntrarBolaoState extends State<_BottomEntrarBolao> {
  final _codigoCtrl = TextEditingController();

  @override
  void dispose() {
    _codigoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final provider = context.watch<BolaoProvider>();
    final auth = context.read<app_auth.AuthProvider>();

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Entrar em Bolão', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text('Solicite o código de 6 letras ao criador do bolão.',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 20),
          TextFormField(
            controller: _codigoCtrl,
            textCapitalization: TextCapitalization.characters,
            maxLength: 6,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 4),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              labelText: 'Código do bolão',
              counterText: '',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: primary, width: 2)),
            ),
          ),
          if (provider.erro != null) ...[
            const SizedBox(height: 8),
            Text(provider.erro!,
                style: const TextStyle(color: Colors.red, fontSize: 12)),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: provider.carregando
                  ? null
                  : () async {
                      final bolao = await context
                          .read<BolaoProvider>()
                          .entrarPorCodigo(_codigoCtrl.text, auth.userId!);
                      if (!context.mounted) return;
                      if (bolao != null) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Entrou no bolão: ${bolao.nome}!')),
                        );
                      }
                    },
              child: provider.carregando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Entrar no Bolão'),
            ),
          ),
        ],
      ),
    );
  }
}

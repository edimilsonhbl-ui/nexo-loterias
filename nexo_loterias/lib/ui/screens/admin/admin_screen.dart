import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/services/resultado_api_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const _adminEmails = ['edimilsonhbl@gmail.com'];

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _api = ResultadoApiService();
  bool _sincronizando = false;
  String _log = '';

  bool get _ehAdmin {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    return _adminEmails.contains(email.toLowerCase());
  }

  Future<void> _sincronizar() async {
    setState(() {
      _sincronizando = true;
      _log = 'Sincronizando com API da Caixa...';
    });

    final ok = await _api.sincronizarTodos();

    setState(() {
      _sincronizando = false;
      _log = ok
          ? 'Sincronização concluída com sucesso!'
          : 'Erro na sincronização. Verifique a conexão.';
    });
  }

  Future<void> _sincronizarModalidade(String id) async {
    setState(() {
      _sincronizando = true;
      _log = 'Sincronizando $id...';
    });
    final ok = await _api.sincronizarModalidade(id);
    setState(() {
      _sincronizando = false;
      _log = ok ? '$id sincronizado!' : 'Erro ao sincronizar $id.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    if (!_ehAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin')),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Acesso restrito', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Text('Apenas administradores podem acessar esta área.',
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('NEXO ADMIN'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('ADMIN',
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Estatísticas do app
            _SecaoAdmin(titulo: 'Estatísticas do App', icone: Icons.bar_chart, primary: primary),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snap) {
                final total = snap.data?.docs.length ?? 0;
                final premium = snap.data?.docs
                        .where((d) => (d.data() as Map)['premium'] == true)
                        .length ?? 0;
                return Row(
                  children: [
                    Expanded(child: _StatCard(label: 'Total usuários', valor: '$total', cor: primary)),
                    const SizedBox(width: 12),
                    Expanded(child: _StatCard(label: 'Usuários Premium', valor: '$premium', cor: Colors.amber)),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('concursos').snapshots(),
              builder: (context, snap) {
                final total = snap.data?.docs.length ?? 0;
                return _StatCard(label: 'Concursos no banco', valor: '$total', cor: Colors.green);
              },
            ),

            const SizedBox(height: 24),

            // Sincronização
            _SecaoAdmin(titulo: 'Sincronização de Resultados', icone: Icons.cloud_sync, primary: primary),
            const SizedBox(height: 12),
            if (_log.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: primary.withAlpha(60)),
                ),
                child: Row(
                  children: [
                    if (_sincronizando)
                      const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    if (_sincronizando) const SizedBox(width: 10),
                    Expanded(child: Text(_log, style: const TextStyle(fontSize: 13))),
                  ],
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _sincronizando ? null : _sincronizar,
                icon: const Icon(Icons.sync_rounded),
                label: const Text('Sincronizar Todas as Loterias'),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _sincronizando ? null : () => _sincronizarModalidade('mega-sena'),
                    child: const Text('Mega-Sena', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _sincronizando ? null : () => _sincronizarModalidade('lotofacil'),
                    child: const Text('Lotofácil', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _sincronizando ? null : () => _sincronizarModalidade('quina'),
                    child: const Text('Quina', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Últimos concursos
            _SecaoAdmin(titulo: 'Últimos Concursos Salvos', icone: Icons.list_alt, primary: primary),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('concursos')
                  .orderBy('numeroConcurso', descending: true)
                  .limit(10)
                  .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) return const LinearProgressIndicator();
                final docs = snap.data!.docs;
                if (docs.isEmpty) {
                  return const Text('Nenhum concurso salvo.',
                      style: TextStyle(color: Colors.grey));
                }
                return Column(
                  children: docs.map((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final dezenas = (data['dezenasSorteadas'] as List? ?? [])
                        .map((n) => n.toString().padLeft(2, '0'))
                        .join(' · ');
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        '${data['modalidadeId']} — Concurso ${data['numeroConcurso']}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      subtitle: Text(dezenas,
                          style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SecaoAdmin extends StatelessWidget {
  final String titulo;
  final IconData icone;
  final Color primary;
  const _SecaoAdmin({required this.titulo, required this.icone, required this.primary});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icone, color: primary, size: 18),
        const SizedBox(width: 8),
        Text(titulo,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: primary)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String valor;
  final Color cor;
  const _StatCard({required this.label, required this.valor, required this.cor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(valor,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: cor)),
        ],
      ),
    );
  }
}

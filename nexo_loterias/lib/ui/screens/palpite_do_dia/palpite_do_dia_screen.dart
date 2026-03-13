import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../providers/premium_provider.dart';
import '../../../providers/modalidade_provider.dart';
import '../../../providers/aposta_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/services/ia_palpite_service.dart';
import '../../../data/repositories/concurso_repository.dart';
import '../../../data/models/concurso.dart';
import '../../../data/models/aposta.dart';
import '../../../core/utils/probabilidade_util.dart';
import '../../../core/routes/app_routes.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class PalpiteDoDialScreen extends StatefulWidget {
  const PalpiteDoDialScreen({super.key});

  @override
  State<PalpiteDoDialScreen> createState() => _PalpiteDoDialScreenState();
}

class _PalpiteDoDialScreenState extends State<PalpiteDoDialScreen> {
  List<int> _numeros = [];
  bool _carregando = false;
  String _dataPalpite = '';

  @override
  void initState() {
    super.initState();
    _carregarOuGerar();
  }

  String get _chavePrefs {
    final modalidadeId =
        context.read<ModalidadeProvider>().modalidadeAtual.id;
    final hoje = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return 'palpite_dia_${modalidadeId}_$hoje';
  }

  Future<void> _carregarOuGerar() async {
    setState(() => _carregando = true);
    final prefs = await SharedPreferences.getInstance();
    final salvo = prefs.getString(_chavePrefs);

    if (salvo != null && salvo.isNotEmpty) {
      _numeros = salvo.split(',').map(int.parse).toList();
    } else {
      await _gerar(prefs);
    }

    _dataPalpite =
        DateFormat('dd/MM/yyyy').format(DateTime.now());
    if (mounted) setState(() => _carregando = false);
  }

  Future<void> _gerar(SharedPreferences prefs) async {
    final modalidade =
        context.read<ModalidadeProvider>().modalidadeAtual;
    final service = IaPalpiteService();

    List<Concurso> historico = [];
    try {
      historico =
          await ConcursoRepository().dadosParaEstatisticas(modalidade.id);
    } catch (_) {}

    _numeros = service.gerarPalpite(
      modalidade: modalidade,
      historico: historico,
      perfil: PerfilIA.equilibrado,
      janela: JanelaAnalise.ultimos50,
    );

    await prefs.setString(_chavePrefs, _numeros.join(','));
  }

  void _compartilhar() {
    final modalidade =
        context.read<ModalidadeProvider>().modalidadeAtual;
    final numerosStr = _numeros.map((n) => n.toString().padLeft(2, '0')).join(' · ');
    Share.share(
      '🍀 Meu Palpite do Dia NEXO LOTERIAS\n'
      '${modalidade.nome} — $_dataPalpite\n\n'
      '$numerosStr\n\n'
      '📲 Baixe grátis: https://play.google.com/store/apps/details?id=com.nexoloterias.nexo_loterias',
    );
  }

  void _salvar() {
    final modalidade =
        context.read<ModalidadeProvider>().modalidadeAtual;
    final auth = context.read<AuthProvider>().userId;
    final probs = ProbabilidadeUtil.calcularProbabilidades(
        modalidade, _numeros.length);
    context.read<ApostaProvider>().salvarAposta(
          Aposta(
            id: const Uuid().v4(),
            modalidadeId: modalidade.id,
            numerosEscolhidos: List.from(_numeros),
            valorAposta:
                ProbabilidadeUtil.calcularValor(modalidade, _numeros.length),
            probabilidade: probs[modalidade.numerosMin] ?? 0,
            criadaEm: DateTime.now(),
          ),
          userId: auth,
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Palpite do Dia salvo!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final premium = context.watch<PremiumProvider>();

    if (!premium.isPremium) {
      return Scaffold(
        appBar: AppBar(title: const Text('Palpite do Dia')),
        body: _BloqueadoPremium(
          onAssinar: () => Navigator.pushNamed(context, AppRoutes.premium),
        ),
      );
    }

    final primary = Theme.of(context).colorScheme.primary;
    final modalidade = context.watch<ModalidadeProvider>().modalidadeAtual;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Palpite do Dia'),
        actions: [
          if (_numeros.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: _compartilhar,
              tooltip: 'Compartilhar',
            ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primary, primary.withAlpha(160)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.auto_awesome,
                            color: Colors.white, size: 36),
                        const SizedBox(height: 8),
                        const Text('Palpite do Dia',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700)),
                        Text(
                          '$_dataPalpite — ${modalidade.nome}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: _numeros
                        .map((n) => _BolinhaNumeroPalpite(
                              numero: n,
                              primary: primary,
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _compartilhar,
                          icon: const Icon(Icons.share_outlined),
                          label: const Text('Compartilhar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _numeros.isNotEmpty ? _salvar : null,
                          icon: const Icon(Icons.bookmark_add_outlined),
                          label: const Text('Salvar'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Novo palpite gerado diariamente com base em análise estatística dos sorteios anteriores.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
    );
  }
}

class _BolinhaNumeroPalpite extends StatelessWidget {
  final int numero;
  final Color primary;
  const _BolinhaNumeroPalpite({required this.numero, required this.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: primary.withAlpha(80),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: Center(
        child: Text(
          numero.toString().padLeft(2, '0'),
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 17),
        ),
      ),
    );
  }
}

class _BloqueadoPremium extends StatelessWidget {
  final VoidCallback onAssinar;
  const _BloqueadoPremium({required this.onAssinar});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 64, color: primary.withAlpha(120)),
            const SizedBox(height: 20),
            Text('Recurso Premium',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'O Palpite do Dia está disponível apenas no plano Premium.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAssinar,
                icon: const Icon(Icons.workspace_premium),
                label: const Text('Ver planos Premium'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

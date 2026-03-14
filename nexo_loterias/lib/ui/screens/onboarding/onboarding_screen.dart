import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/routes/app_routes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _paginaAtual = 0;

  static const _paginas = [
    _PaginaOnboarding(
      icone: Icons.casino_rounded,
      cor: Color(0xFF169B62),
      titulo: 'Bem-vindo ao\nNEXO LOTERIAS',
      descricao: 'Sua ferramenta inteligente para gerar jogos, analisar estatísticas e acompanhar resultados das loterias.',
    ),
    _PaginaOnboarding(
      icone: Icons.grid_on_rounded,
      cor: Color(0xFF8F2DAA),
      titulo: 'Monte seus Jogos',
      descricao: 'Selecione números manualmente, use a Surpresinha ou deixe a IA gerar jogos equilibrados para você.',
    ),
    _PaginaOnboarding(
      icone: Icons.bar_chart_rounded,
      cor: Color(0xFF9C1D1D),
      titulo: 'Estatísticas Reais',
      descricao: 'Veja os números mais sorteados, atrasados, pares e ímpares. Tome decisões baseadas em dados.',
    ),
    _PaginaOnboarding(
      icone: Icons.workspace_premium_rounded,
      cor: Color(0xFFD4370B),
      titulo: 'Premium NEXO',
      descricao: 'Desbloqueie o Fechamento NEXO, IA de palpites, estatísticas avançadas e muito mais!',
    ),
  ];

  Future<void> _concluir() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_concluido', true);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.conta);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _concluir,
                child: const Text('Pular', style: TextStyle(color: Colors.grey)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _paginas.length,
                onPageChanged: (i) => setState(() => _paginaAtual = i),
                itemBuilder: (_, i) => _paginas[i],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _paginas.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _paginaAtual == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _paginaAtual == i
                              ? _paginas[_paginaAtual].cor
                              : Colors.grey.withAlpha(100),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _paginas[_paginaAtual].cor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        if (_paginaAtual == _paginas.length - 1) {
                          _concluir();
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      child: Text(
                        _paginaAtual == _paginas.length - 1
                            ? 'Começar agora'
                            : 'Próximo',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaginaOnboarding extends StatelessWidget {
  final IconData icone;
  final Color cor;
  final String titulo;
  final String descricao;

  const _PaginaOnboarding({
    required this.icone,
    required this.cor,
    required this.titulo,
    required this.descricao,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: cor.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(icone, color: cor, size: 64),
          ),
          const SizedBox(height: 40),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 26, fontWeight: FontWeight.w800, height: 1.3),
          ),
          const SizedBox(height: 16),
          Text(
            descricao,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 15, color: Colors.grey, height: 1.6),
          ),
        ],
      ),
    );
  }
}

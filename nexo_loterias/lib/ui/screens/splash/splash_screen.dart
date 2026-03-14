import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/routes/app_routes.dart';
import '../../../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _main;
  late AnimationController _pulse;
  late Animation<double> _fade;
  late Animation<double> _scale;
  late Animation<double> _pulseAnim;
  late Animation<double> _slideUp;

  @override
  void initState() {
    super.initState();

    _main = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);

    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _main, curve: const Interval(0, 0.5, curve: Curves.easeIn)),
    );
    _scale = Tween<double>(begin: 0.6, end: 1).animate(
      CurvedAnimation(parent: _main, curve: const Interval(0, 0.6, curve: Curves.elasticOut)),
    );
    _slideUp = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _main, curve: const Interval(0.3, 0.8, curve: Curves.easeOut)),
    );
    _pulseAnim = Tween<double>(begin: 0.9, end: 1.08).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );

    _main.forward();
    Future.delayed(const Duration(seconds: 3), _navegar);
  }

  Future<void> _navegar() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final onboardingConcluido = prefs.getBool('onboarding_concluido') ?? false;
    if (!mounted) return;

    if (!onboardingConcluido) {
      Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
      return;
    }
    final auth = context.read<AuthProvider>();
    Navigator.pushReplacementNamed(
        context, auth.estaLogado ? AppRoutes.home : AppRoutes.conta);
  }

  @override
  void dispose() {
    _main.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Fundo gradiente
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  primary.withAlpha(40),
                  Theme.of(context).scaffoldBackgroundColor,
                ],
              ),
            ),
          ),

          // Partículas decorativas
          ...List.generate(12, (i) => _Particula(index: i, primary: primary, size: size)),

          // Logo central
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_main, _pulse]),
              builder: (_, __) => Opacity(
                opacity: _fade.value,
                child: Transform.translate(
                  offset: Offset(0, _slideUp.value),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Ícone com pulse
                      Transform.scale(
                        scale: _scale.value * _pulseAnim.value,
                        child: Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [primary, primary.withBlue(255)],
                            ),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: primary.withAlpha(100),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.casino_rounded,
                              color: Colors.white, size: 60),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'NEXO',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              color: primary,
                              letterSpacing: 8,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      Text(
                        'LOTERIAS',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              letterSpacing: 10,
                              fontWeight: FontWeight.w300,
                            ),
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: 40,
                        child: LinearProgressIndicator(
                          backgroundColor: primary.withAlpha(30),
                          valueColor: AlwaysStoppedAnimation(primary),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Particula extends StatefulWidget {
  final int index;
  final Color primary;
  final Size size;

  const _Particula({required this.index, required this.primary, required this.size});

  @override
  State<_Particula> createState() => _ParticulaState();
}

class _ParticulaState extends State<_Particula> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late double _x, _y, _r;

  @override
  void initState() {
    super.initState();
    final rng = Random(widget.index * 42);
    _x = rng.nextDouble() * widget.size.width;
    _y = rng.nextDouble() * widget.size.height;
    _r = rng.nextDouble() * 8 + 3;

    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500 + rng.nextInt(1500)),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _x,
      top: _y,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Opacity(
          opacity: 0.1 + _ctrl.value * 0.3,
          child: Container(
            width: _r,
            height: _r,
            decoration: BoxDecoration(
              color: widget.primary,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

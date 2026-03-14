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
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0, 0.6, curve: Curves.easeIn)),
    );
    _scaleAnimation = Tween<double>(begin: 0.7, end: 1).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0, 0.6, curve: Curves.elasticOut)),
    );
    _controller.forward();

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
    if (auth.estaLogado) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.conta);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, __) => Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(Icons.casino_rounded,
                        color: Colors.white, size: 56),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'NEXO',
                    style:
                        Theme.of(context).textTheme.displayLarge?.copyWith(
                              color: primary,
                              letterSpacing: 6,
                            ),
                  ),
                  Text(
                    'LOTERIAS',
                    style:
                        Theme.of(context).textTheme.titleMedium?.copyWith(
                              letterSpacing: 8,
                              color:
                                  Theme.of(context).colorScheme.onSurface,
                            ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

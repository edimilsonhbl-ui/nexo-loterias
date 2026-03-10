import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/routes/app_routes.dart';
import 'providers/modalidade_provider.dart';
import 'providers/jogo_provider.dart';
import 'providers/aposta_provider.dart';
import 'providers/estatisticas_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/fechamento_provider.dart';
import 'providers/concurso_provider.dart';
import 'providers/premium_provider.dart';
import 'providers/ia_palpite_provider.dart';
import 'data/services/fcm_service.dart';

final _fcmService = FcmService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // FCM é inicializado após o primeiro frame para evitar diálogo de permissão
  // antes da UI estar visível (experiência ruim especialmente no iOS).
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await _fcmService.inicializar(
      onMensagem: (msg) => debugPrint('FCM Foreground: ${msg.notification?.title}'),
      onMensagemAberta: (msg) => debugPrint('FCM Aberta: ${msg.notification?.title}'),
    );
    await _fcmService.assinarAcumulados();
    await _fcmService.assinarNovos();
  });

  runApp(const NexoApp());
}

class NexoApp extends StatelessWidget {
  const NexoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PremiumProvider()),
        ChangeNotifierProvider(create: (_) => ModalidadeProvider()),
        ChangeNotifierProvider(create: (_) => JogoProvider()),
        ChangeNotifierProvider(create: (_) => ApostaProvider()),
        ChangeNotifierProvider(create: (_) => EstatisticasProvider()),
        ChangeNotifierProvider(create: (_) => FechamentoProvider()),
        ChangeNotifierProvider(create: (_) => ConcursoProvider()),
        ChangeNotifierProvider(create: (_) => IaPalpiteProvider()),
      ],
      child: Consumer<ModalidadeProvider>(
        builder: (context, modalidadeProvider, _) {
          return MaterialApp(
            title: 'Nexo Loterias',
            debugShowCheckedModeBanner: false,
            theme: modalidadeProvider.temaAtual,
            initialRoute: AppRoutes.splash,
            routes: AppRoutes.routes,
            // AppStartup cuida da sincronização de auth — fora do builder
            builder: (context, child) => _AppStartup(child: child!),
          );
        },
      ),
    );
  }
}

/// Widget raiz que escuta mudanças de autenticação UMA VEZ via addListener,
/// sem recriar subscriptions a cada rebuild.
class _AppStartup extends StatefulWidget {
  final Widget child;
  const _AppStartup({required this.child});

  @override
  State<_AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends State<_AppStartup> {
  String? _topicoFcmAtual;

  @override
  void initState() {
    super.initState();
    // Listener registrado uma única vez — não dentro do builder
    context.read<AuthProvider>().addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    context.read<AuthProvider>().removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    final auth = context.read<AuthProvider>();
    final aposta = context.read<ApostaProvider>();
    final premium = context.read<PremiumProvider>();
    final modalidadeId = context.read<ModalidadeProvider>().modalidadeAtual.id;

    if (auth.estaLogado && auth.userId != null) {
      aposta.conectarFirebase(auth.userId!);
      premium.carregar(auth.userId!);
      _atualizarTopicoFcm(modalidadeId);
    } else {
      aposta.desconectarFirebase();
      premium.limpar();
      _cancelarTopicoFcm();
    }
  }

  Future<void> _atualizarTopicoFcm(String modalidadeId) async {
    if (_topicoFcmAtual == modalidadeId) return;
    if (_topicoFcmAtual != null) {
      await _fcmService.cancelarTopico('resultado_$_topicoFcmAtual');
    }
    _topicoFcmAtual = modalidadeId;
    await _fcmService.assinarTopicoModalidade(modalidadeId);
  }

  Future<void> _cancelarTopicoFcm() async {
    if (_topicoFcmAtual != null) {
      await _fcmService.cancelarTopico('resultado_$_topicoFcmAtual');
      _topicoFcmAtual = null;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

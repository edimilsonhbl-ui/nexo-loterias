import 'package:flutter/material.dart';
import '../../ui/screens/splash/splash_screen.dart';
import '../../ui/screens/home/home_screen.dart';
import '../../ui/screens/modalidades/modalidades_screen.dart';
import '../../ui/screens/montar_jogo/montar_jogo_screen.dart';
import '../../ui/screens/estatisticas/estatisticas_screen.dart';
import '../../ui/screens/conferidor/conferidor_screen.dart';
import '../../ui/screens/historico/historico_screen.dart';
import '../../ui/screens/conta/conta_screen.dart';
import '../../ui/screens/sugestoes/sugestoes_screen.dart';
import '../../ui/screens/fechamento/fechamento_screen.dart';
import '../../ui/screens/ia_nexo/ia_nexo_screen.dart';
import '../../ui/screens/premium/premium_screen.dart';
import '../../ui/screens/palpite_do_dia/palpite_do_dia_screen.dart';
import '../../ui/screens/resultados/resultados_screen.dart';
import '../../ui/screens/onboarding/onboarding_screen.dart';
import '../../ui/screens/ranking/ranking_screen.dart';
import '../../ui/screens/historico_resultados/historico_resultados_screen.dart';
import '../../ui/screens/admin/admin_screen.dart';
import '../../ui/screens/bolao/bolao_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const home = '/home';
  static const modalidades = '/modalidades';
  static const montarJogo = '/montar-jogo';
  static const estatisticas = '/estatisticas';
  static const sugestoes = '/sugestoes';
  static const conferidor = '/conferidor';
  static const historico = '/historico';
  static const conta = '/conta';
  static const fechamento = '/fechamento';
  static const iaNexo = '/ia-nexo';
  static const premium = '/premium';
  static const palpiteDoDia = '/palpite-do-dia';
  static const ranking = '/ranking';
  static const resultados = '/resultados';
  static const onboarding = '/onboarding';
  static const historicoResultados = '/historico-resultados';
  static const admin = '/admin';
  static const bolao = '/bolao';

  static Map<String, WidgetBuilder> get routes => {
        splash: (_) => const SplashScreen(),
        home: (_) => const HomeScreen(),
        modalidades: (_) => const ModalidadesScreen(),
        montarJogo: (_) => const MontarJogoScreen(),
        estatisticas: (_) => const EstatisticasScreen(),
        sugestoes: (_) => const SugestoesScreen(),
        conferidor: (_) => const ConferidorScreen(),
        historico: (_) => const HistoricoScreen(),
        conta: (_) => const ContaScreen(),
        fechamento: (_) => const FechamentoScreen(),
        iaNexo: (_) => const IaNexoScreen(),
        premium: (_) => const PremiumScreen(),
        palpiteDoDia: (_) => const PalpiteDoDialScreen(),
        ranking: (_) => const RankingScreen(),
        resultados: (_) => const ResultadosScreen(),
        onboarding: (_) => const OnboardingScreen(),
        historicoResultados: (_) => const HistoricoResultadosScreen(),
        admin: (_) => const AdminScreen(),
        bolao: (_) => const BolaoScreen(),
      };
}

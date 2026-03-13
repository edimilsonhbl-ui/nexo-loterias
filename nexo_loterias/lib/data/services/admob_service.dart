import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// IDs de TESTE — substitua pelos IDs reais após criar conta no AdMob:
// https://admob.google.com
//
// ID do App (Android): ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX
// Para obter os IDs reais:
//   1. Crie conta em https://admob.google.com
//   2. Adicione o app "NEXO LOTERIAS"
//   3. Crie unidades de anúncio Banner e Intersticial
//   4. Substitua os IDs abaixo
class AdmobIds {
  static const _isTest = false;

  static const String banner = _isTest
      ? 'ca-app-pub-3940256099942544/6300978111'
      : 'ca-app-pub-5110454576194734/2751349749';

  static const String intersticial = _isTest
      ? 'ca-app-pub-3940256099942544/1033173712'
      : 'ca-app-pub-5110454576194734/1626950275';
}

class AdmobService {
  static final AdmobService _instance = AdmobService._();
  AdmobService._();
  factory AdmobService() => _instance;

  bool _inicializado = false;

  Future<void> inicializar() async {
    if (_inicializado) return;
    await MobileAds.instance.initialize();
    _inicializado = true;
  }

  BannerAd criarBanner({required AdManagerAdRequest Function()? requestBuilder}) {
    return BannerAd(
      adUnitId: AdmobIds.banner,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad falhou: $error');
          ad.dispose();
        },
      ),
    );
  }

  Future<InterstitialAd?> carregarIntersticial() async {
    InterstitialAd? ad;
    await InterstitialAd.load(
      adUnitId: AdmobIds.intersticial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (loadedAd) => ad = loadedAd,
        onAdFailedToLoad: (error) =>
            debugPrint('Intersticial falhou: $error'),
      ),
    );
    return ad;
  }
}

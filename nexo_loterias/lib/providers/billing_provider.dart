import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/services/billing_service.dart';

enum BillingStatus { inicial, carregando, sucesso, erro, cancelado }

class BillingProvider extends ChangeNotifier {
  final _billing = BillingService();

  BillingStatus _status = BillingStatus.inicial;
  String _mensagemErro = '';
  bool _inicializado = false;

  BillingStatus get status => _status;
  String get mensagemErro => _mensagemErro;
  bool get inicializado => _inicializado;
  bool get disponivel => _billing.disponivel;
  bool get processando => _status == BillingStatus.carregando;

  String preco(String productId, String fallback) =>
      _billing.precoFormatado(productId, fallback);

  void resetarStatus() {
    _status = BillingStatus.inicial;
    _mensagemErro = '';
    notifyListeners();
  }

  Future<void> inicializar() async {
    if (_inicializado) return;
    await _billing.inicializar(onCompraAtualizada: _onCompraAtualizada);
    _inicializado = true;
    notifyListeners();
  }

  Future<void> comprar(String productId) async {
    _status = BillingStatus.carregando;
    _mensagemErro = '';
    notifyListeners();
    final ok = await _billing.comprar(productId);
    if (!ok) {
      _status = BillingStatus.cancelado;
      notifyListeners();
    }
  }

  Future<void> restaurar() async {
    _status = BillingStatus.carregando;
    _mensagemErro = '';
    notifyListeners();
    await _billing.restaurar();
  }

  Future<void> _onCompraAtualizada(PurchaseDetails details) async {
    if (details.status == PurchaseStatus.pending) {
      _status = BillingStatus.carregando;
      notifyListeners();
      return;
    }

    if (details.status == PurchaseStatus.error) {
      _status = BillingStatus.erro;
      _mensagemErro = details.error?.message ?? 'Erro no pagamento.';
      await _billing.completarCompra(details);
      notifyListeners();
      return;
    }

    if (details.status == PurchaseStatus.canceled) {
      _status = BillingStatus.cancelado;
      notifyListeners();
      return;
    }

    if (details.status == PurchaseStatus.purchased ||
        details.status == PurchaseStatus.restored) {
      try {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId == null) throw Exception('Não autenticado');

        final token = details.verificationData.serverVerificationData;
        final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
            .httpsCallable('validarPremium');

        await callable.call({
          'purchaseToken': token,
          'productId': details.productID,
          'platform': 'android',
        });

        await _billing.completarCompra(details);
        _status = BillingStatus.sucesso;
      } catch (e) {
        _status = BillingStatus.erro;
        _mensagemErro =
            'Pagamento aprovado, mas erro ao ativar. Contate: nexoloterias@gmail.com';
      }
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _billing.dispose();
    super.dispose();
  }
}

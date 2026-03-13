import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

const Set<String> _kProductIds = {
  BillingService.mensalId,
  BillingService.anualId,
  BillingService.vitalicioId,
};

class BillingService {
  static const mensalId = 'premium_mensal';
  static const anualId = 'premium_anual';
  static const vitalicioId = 'premium_vitalicio';

  final _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  List<ProductDetails> _produtos = [];
  List<ProductDetails> get produtos => _produtos;

  bool _disponivel = false;
  bool get disponivel => _disponivel;

  Future<void> inicializar({
    required void Function(PurchaseDetails) onCompraAtualizada,
  }) async {
    _disponivel = await _iap.isAvailable();
    if (!_disponivel) {
      debugPrint('BillingService: Google Play indisponível');
      return;
    }

    _subscription = _iap.purchaseStream.listen(
      (purchases) {
        for (final p in purchases) {
          onCompraAtualizada(p);
        }
      },
      onError: (dynamic e) => debugPrint('BillingService stream error: $e'),
    );

    await carregarProdutos();
  }

  Future<void> carregarProdutos() async {
    final response = await _iap.queryProductDetails(_kProductIds);
    _produtos = response.productDetails;
    if (response.error != null) {
      debugPrint('BillingService queryProducts error: ${response.error}');
    }
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('BillingService IDs não encontrados: ${response.notFoundIDs}');
    }
  }

  ProductDetails? produto(String id) {
    try {
      return _produtos.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  String precoFormatado(String id, String fallback) {
    return produto(id)?.price ?? fallback;
  }

  Future<bool> comprar(String productId) async {
    if (!_disponivel) return false;
    final p = produto(productId);
    if (p == null) {
      debugPrint('BillingService: produto $productId não encontrado');
      return false;
    }
    try {
      final param = PurchaseParam(productDetails: p);
      return await _iap.buyNonConsumable(purchaseParam: param);
    } catch (e) {
      debugPrint('BillingService comprar error: $e');
      return false;
    }
  }

  Future<void> restaurar() async {
    await _iap.restorePurchases();
  }

  Future<void> completarCompra(PurchaseDetails details) async {
    if (details.pendingCompletePurchase) {
      await _iap.completePurchase(details);
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}

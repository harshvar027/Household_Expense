import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../config/subscription_config.dart';
import 'entitlement_service.dart';

/// Google Play / App Store billing integration.
class SubscriptionService {
  SubscriptionService._();

  static final SubscriptionService instance = SubscriptionService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  List<ProductDetails> _products = [];
  bool _storeAvailable = false;
  bool _loading = false;

  List<ProductDetails> get products => List.unmodifiable(_products);
  bool get storeAvailable => _storeAvailable;
  bool get isLoading => _loading;

  Future<void> initialize() async {
    _storeAvailable = await _iap.isAvailable();
    if (!_storeAvailable) return;

    _purchaseSub ??= _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (Object e) => debugPrint('Purchase stream error: $e'),
    );

    await loadProducts();
  }

  Future<void> loadProducts() async {
    if (!_storeAvailable) return;
    _loading = true;

    final response = await _iap.queryProductDetails(SubscriptionConfig.productIds);
    if (response.error != null) {
      debugPrint('Product query error: ${response.error}');
    }
    _products = response.productDetails;
    _loading = false;
  }

  ProductDetails? productFor(String id) {
    for (final p in _products) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<bool> buyYearly() async {
    final product = productFor(SubscriptionConfig.yearlyProductId);
    if (product == null) return false;
    return _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
  }

  Future<void> restorePurchases() async {
    if (!_storeAvailable) return;
    await _iap.restorePurchases();
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) continue;

      if (purchase.status == PurchaseStatus.error) {
        debugPrint('Purchase error: ${purchase.error}');
        await _completeIfNeeded(purchase);
        continue;
      }

      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        await _applyPurchase(purchase);
      }

      await _completeIfNeeded(purchase);
    }
  }

  Future<void> _applyPurchase(PurchaseDetails purchase) async {
    if (purchase.productID == SubscriptionConfig.yearlyProductId) {
      await EntitlementService.instance.activateYearly();
    }
  }

  Future<void> _completeIfNeeded(PurchaseDetails purchase) async {
    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
  }

  void dispose() {
    _purchaseSub?.cancel();
    _purchaseSub = null;
  }
}

/// 앱 내 결제 — 광고 제거 1종만 취급한다.
///
/// 설계 근거:
/// - 확률형 아이템, 소모성 재화, 시간 압박형 판매를 넣지 않는다.
///   아동이 이용하는 앱에서 결제 유도는 구글·애플 양쪽 정책과
///   국내 민법 제5조(미성년자 법률행위 취소권) 모두에서 위험 요소다.
/// - 비소모성 1종이므로 애플 심사 지침 3.1.1 이 요구하는 "구매 복원"을 반드시 제공한다.
///   복원 버튼이 없으면 반려된다.
/// - 결제는 보호자 게이트 뒤에서만 노출된다 (parent_gate.dart).
///
/// 스토어 콘솔 등록:
///   구글 플레이 콘솔 > 수익 창출 > 인앱 상품 > 상품 ID: remove_ads (관리형 상품)
///   앱 스토어 커넥트 > 앱 내 구입 > 비소모성 > 상품 ID: remove_ads
/// 양쪽 상품 ID를 반드시 동일하게 맞춘다.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../ads/ad_manager.dart';
import '../storage/prefs.dart';

/// 광고 제거 상품 ID. 두 스토어에 같은 값으로 등록한다.
const String kRemoveAdsProductId = 'remove_ads';

enum PurchaseOutcome { success, canceled, pending, unavailable, error, restored }

class Billing {
  Billing._();
  static final Billing instance = Billing._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  bool _available = false;
  ProductDetails? _product;

  /// 스토어 연결 가능 여부. false 면 결제 버튼을 비활성으로 보여 준다.
  bool get available => _available;

  /// 표시용 가격 문자열. 스토어가 지역 통화로 내려 준다.
  /// 절대 코드에 가격을 적어 두지 않는다 — 지역·환율·세금이 다르다.
  String? get priceLabel => _product?.price;

  final _outcome = StreamController<PurchaseOutcome>.broadcast();
  Stream<PurchaseOutcome> get outcomes => _outcome.stream;

  Future<void> init() async {
    if (_sub != null) return;
    try {
      _available = await _iap.isAvailable();
    } catch (e) {
      debugPrint('IAP unavailable: $e');
      _available = false;
      return;
    }
    if (!_available) return;

    _sub = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (Object e) => debugPrint('Purchase stream error: $e'),
    );

    try {
      final res = await _iap.queryProductDetails({kRemoveAdsProductId});
      if (res.productDetails.isNotEmpty) {
        _product = res.productDetails.first;
      } else {
        debugPrint('상품을 찾지 못함: ${res.notFoundIDs}');
      }
    } catch (e) {
      debugPrint('Product query failed: $e');
    }
  }

  /// 구매 시작. 결과는 outcomes 스트림으로 통지된다.
  Future<void> buyRemoveAds() async {
    if (!_available || _product == null) {
      _outcome.add(PurchaseOutcome.unavailable);
      return;
    }
    try {
      final param = PurchaseParam(productDetails: _product!);
      // 비소모성이므로 buyNonConsumable 을 쓴다.
      await _iap.buyNonConsumable(purchaseParam: param);
    } catch (e) {
      debugPrint('Buy failed: $e');
      _outcome.add(PurchaseOutcome.error);
    }
  }

  /// 구매 복원. 애플 심사 지침 3.1.1 필수 항목이며,
  /// 기기를 바꾼 이용자가 다시 결제하지 않도록 하는 안전장치이기도 하다.
  Future<void> restore() async {
    if (!_available) {
      _outcome.add(PurchaseOutcome.unavailable);
      return;
    }
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('Restore failed: $e');
      _outcome.add(PurchaseOutcome.error);
    }
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> list) async {
    for (final p in list) {
      switch (p.status) {
        case PurchaseStatus.pending:
          _outcome.add(PurchaseOutcome.pending);
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (p.productID == kRemoveAdsProductId) {
            await Prefs.setAdsRemoved(true);
            // 떠 있는 광고를 즉시 내린다.
            AdManager.instance.onAdsRemoved();
          }
          _outcome.add(p.status == PurchaseStatus.restored
              ? PurchaseOutcome.restored
              : PurchaseOutcome.success);
          break;

        case PurchaseStatus.canceled:
          _outcome.add(PurchaseOutcome.canceled);
          break;

        case PurchaseStatus.error:
          debugPrint('Purchase error: ${p.error}');
          _outcome.add(PurchaseOutcome.error);
          break;
      }

      // 완료 처리를 빠뜨리면 구글은 3일 뒤 자동 환불하고,
      // 애플은 결제창을 계속 다시 띄운다. 어떤 결과든 반드시 호출한다.
      if (p.pendingCompletePurchase) {
        try {
          await _iap.completePurchase(p);
        } catch (e) {
          debugPrint('Complete failed: $e');
        }
      }
    }
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}

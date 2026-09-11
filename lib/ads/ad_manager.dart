/// AdMob 단일 SDK로 배너·전면·리워드를 관리한다.
/// 광고 로드 실패는 게임 진행에 절대 영향을 주지 않는다.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../game/curve.dart';
import '../storage/prefs.dart';
import 'ad_config.dart';
import 'consent.dart';

class AdManager {
  AdManager._();
  static final AdManager instance = AdManager._();

  bool _ready = false;
  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  bool _loadingInterstitial = false;
  bool _loadingRewarded = false;

  bool get enabled => !Prefs.adsRemoved;

  /// 광고 제거 구매가 반영된 시점을 화면에 알린다.
  /// 이게 없으면 결제 직후에도 이미 떠 있는 배너가 그대로 남아
  /// "돈을 냈는데 광고가 그대로다"라는 인상을 준다.
  final ValueNotifier<bool> adsRemoved = ValueNotifier<bool>(false);

  /// 결제 성공 시 호출한다. 떠 있는 광고를 모두 내리고 화면에 통지한다.
  void onAdsRemoved() {
    disposeAll();
    adsRemoved.value = true;
  }

  Future<void> init() async {
    if (_ready || !enabled) return;
    try {
      // 유럽 이용자 동의를 먼저 받는다. 실패해도 통과시킨다.
      await ConsentManager.instance.gather();
      await MobileAds.instance.initialize();
      // 전연령 앱이므로 광고 콘텐츠 등급을 G로 제한하고 맞춤형 광고를 끈다.
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          maxAdContentRating: MaxAdContentRating.g,
          tagForChildDirectedTreatment: TagForChildDirectedTreatment.yes,
          tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.yes,
        ),
      );
      _ready = true;
    } catch (e) {
      debugPrint('Ads init failed: $e');
      return;
    }
    _loadInterstitial();
    _loadRewarded();
  }

  // ---------- 배너 ----------

  Future<BannerAd?> createBanner(int widthPx) async {
    if (!_ready || !enabled) return null;
    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(widthPx);
    if (size == null) return null;
    final done = Completer<BannerAd?>();
    final ad = BannerAd(
      adUnitId: AdConfig.bannerId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (a) => done.complete(a as BannerAd),
        onAdFailedToLoad: (a, err) {
          debugPrint('Banner failed: $err');
          a.dispose();
          done.complete(null);
        },
      ),
    );
    ad.load();
    return done.future;
  }

  // ---------- 전면 ----------

  void _loadInterstitial() {
    if (!_ready || !enabled || _loadingInterstitial || _interstitial != null) return;
    _loadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: AdConfig.interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          _loadingInterstitial = false;
        },
        onAdFailedToLoad: (err) {
          debugPrint('Interstitial failed: $err');
          _loadingInterstitial = false;
          Future.delayed(const Duration(seconds: 60), _loadInterstitial);
        },
      ),
    );
  }

  /// 단계 실패 시 호출. 구간과 빈도 정책을 만족할 때만 전면광고를 띄운다.
  Future<void> onStageFailed(Tier tier, {required VoidCallback onDone}) async {
    if (!enabled || !AdConfig.interstitialFor(tier) || _interstitial == null) {
      onDone();
      return;
    }
    final count = Prefs.failCount + 1;
    await Prefs.setFailCount(count);
    final now = DateTime.now().millisecondsSinceEpoch;
    final sinceLast = (now - Prefs.lastInterstitialMs) ~/ 1000;
    if (count % AdConfig.interstitialEveryNFails != 0 ||
        sinceLast < AdConfig.interstitialMinIntervalSec) {
      onDone();
      return;
    }
    final ad = _interstitial!;
    _interstitial = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _loadInterstitial();
        onDone();
      },
      onAdFailedToShowFullScreenContent: (a, e) {
        a.dispose();
        _loadInterstitial();
        onDone();
      },
    );
    await Prefs.setLastInterstitialMs(now);
    ad.show();
  }

  // ---------- 리워드 ----------

  void _loadRewarded() {
    if (!_ready || !enabled || _loadingRewarded || _rewarded != null) return;
    _loadingRewarded = true;
    RewardedAd.load(
      adUnitId: AdConfig.rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded = ad;
          _loadingRewarded = false;
        },
        onAdFailedToLoad: (err) {
          debugPrint('Rewarded failed: $err');
          _loadingRewarded = false;
          Future.delayed(const Duration(seconds: 60), _loadRewarded);
        },
      ),
    );
  }

  bool rewardedReadyFor(Tier tier) =>
      enabled && AdConfig.rewardedFor(tier) && _rewarded != null;

  /// 끝까지 시청하면 true. Families 정책상 5초 후 닫기가 가능해야 하므로
  /// 중도 이탈 시에는 보상을 주지 않는다.
  Future<bool> showRewarded() async {
    final ad = _rewarded;
    if (ad == null) return false;
    _rewarded = null;
    final done = Completer<bool>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _loadRewarded();
        if (!done.isCompleted) done.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (a, e) {
        a.dispose();
        _loadRewarded();
        if (!done.isCompleted) done.complete(false);
      },
    );
    ad.show(onUserEarnedReward: (_, __) => earned = true);
    return done.future;
  }

  void disposeAll() {
    _interstitial?.dispose();
    _rewarded?.dispose();
    _interstitial = null;
    _rewarded = null;
  }
}

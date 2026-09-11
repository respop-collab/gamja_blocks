/// 광고 설정. 출시 전 이 파일만 실제 ID로 교체한다.
/// 기본값은 Google 공식 테스트 ID다.
///
/// 안전장치: 실제 ID는 릴리스 빌드에서만 쓰인다.
/// useRealIds 를 true 로 둔 채 디버그로 실행해도 테스트 ID가 나가므로
/// 개발 중 본인 클릭으로 계정이 정지되는 사고가 구조적으로 막힌다.
///
/// 구간별로 광고 강도를 다르게 두는 것은 수익 최적화가 아니라 규제 대응이다.
/// 아동이 실제로 머무는 초등 구간의 광고를 최소화해야
/// 구글플레이 Families 정책과 애플 심사 지침 양쪽에서 위험이 낮아진다.
library;

import 'dart:io';

import 'package:flutter/foundation.dart';

import '../game/curve.dart';

class AdConfig {
  /// 실제 배포 여부. 릴리스 빌드에서만 의미가 있다.
  ///
  /// const 가 아니라 final 인 이유: const 로 두면 분석기가 값을 미리 계산해
  /// 이 값을 쓰는 조건문을 "닿지 않는 코드"로 보고 경고를 낸다.
  /// 그 경고 하나가 CI 의 analyze 단계를 통째로 실패시킨다.
  static final bool useRealIds = false;

  /// 실제 ID를 쓸 조건. 릴리스 빌드가 아니면 무조건 테스트 ID다.
  static bool get _real => useRealIds && kReleaseMode;

  // AdMob 앱 ID — 코드가 아니라 플랫폼 파일에 주입된다 (tools/patch_platform.py)
  static const String androidAppId = 'ca-app-pub-3940256099942544~3347511713'; // 테스트
  static const String iosAppId = 'ca-app-pub-3940256099942544~1458002511'; // 테스트

  // 실제 광고 단위 ID (AdMob 콘솔에서 발급 후 입력)
  static const String _realBannerAndroid = '';
  static const String _realBannerIos = '';
  static const String _realInterstitialAndroid = '';
  static const String _realInterstitialIos = '';
  static const String _realRewardedAndroid = '';
  static const String _realRewardedIos = '';

  // Google 공식 테스트 ID
  static const String _testBannerAndroid =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _testBannerIos =
      'ca-app-pub-3940256099942544/2934735716';
  static const String _testInterstitialAndroid =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testInterstitialIos =
      'ca-app-pub-3940256099942544/4411468910';
  static const String _testRewardedAndroid =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _testRewardedIos =
      'ca-app-pub-3940256099942544/1712485313';

  static bool get _android => Platform.isAndroid;

  /// 실제 ID를 쓰기로 해 놓고 값을 비워 둔 채 출시하는 사고를 막는다.
  /// 값이 비어 있으면 조용히 테스트 ID로 되돌린다.
  static String _pick(String real, String test) =>
      (_real && real.isNotEmpty) ? real : test;

  static String get bannerId => _android
      ? _pick(_realBannerAndroid, _testBannerAndroid)
      : _pick(_realBannerIos, _testBannerIos);

  static String get interstitialId => _android
      ? _pick(_realInterstitialAndroid, _testInterstitialAndroid)
      : _pick(_realInterstitialIos, _testInterstitialIos);

  static String get rewardedId => _android
      ? _pick(_realRewardedAndroid, _testRewardedAndroid)
      : _pick(_realRewardedIos, _testRewardedIos);

  /// 실제 ID가 모두 채워졌는지. 출시 점검용이며 테스트에서 확인한다.
  static bool get realIdsComplete =>
      _realBannerAndroid.isNotEmpty &&
      _realInterstitialAndroid.isNotEmpty &&
      _realRewardedAndroid.isNotEmpty;

  // ---------- 구간별 노출 정책 ----------

  /// 배너는 모든 구간에서 하단 고정. 광고 제거를 구매하면 사라진다.
  static bool bannerFor(Tier t) => true;

  /// 리워드(이어하기)는 실패가 있는 구간부터. 초등은 실패가 없어 붙일 지점이 없다.
  static bool rewardedFor(Tier t) => t != Tier.elementary;

  /// 전면광고는 고등 구간부터. 초등·중학은 학습 구간이라 넣지 않는다.
  static bool interstitialFor(Tier t) =>
      t == Tier.high || t == Tier.adult || t == Tier.endless;

  /// 실패 N회마다 전면광고 1회
  static const int interstitialEveryNFails = 3;

  /// 전면광고 최소 간격(초). 연속 실패 시 도배를 막는다.
  static const int interstitialMinIntervalSec = 120;

  /// 앱 오프닝 광고. Families 정책 금지 항목이므로 켜지 않는다.
  static const bool appOpenAdEnabled = false;
}

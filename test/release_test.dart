/// 출시 점검. 사람이 기억으로 막던 실수를 테스트로 막는다.
///
/// 상수를 직접 참조하지 않고 소스 파일의 글자를 읽는다.
/// useRealIds 는 컴파일 시점 상수라서 if 문에 그대로 쓰면
/// 분석기가 "닿지 않는 코드"로 보고 경고를 낸다. 그 경고는 빌드를 멈춘다.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _read(String path) => File(path).readAsStringSync();

/// 출시 설정으로 전환했는지 여부를 소스 글자에서 읽는다.
bool get _releaseMode {
  final src = _read('lib/ads/ad_config.dart');
  return RegExp(r'useRealIds\s*=\s*true').hasMatch(src);
}

String? _match(String src, String pattern) =>
    RegExp(pattern).firstMatch(src)?.group(1);

void main() {
  test('실제 광고 ID를 켰다면 광고 단위 ID가 모두 채워져 있어야 한다', () {
    if (!_releaseMode) return;
    final src = _read('lib/ads/ad_config.dart');
    for (final name in [
      '_realBannerAndroid',
      '_realInterstitialAndroid',
      '_realRewardedAndroid',
    ]) {
      final v = _match(src, "$name\\s*=\\s*'([^']*)'");
      expect(v, isNotNull, reason: '$name 를 찾지 못했다');
      expect(v, isNotEmpty, reason: '$name 가 비어 있다');
    }
  });

  test('실제 광고 ID를 켰다면 앱 ID가 구글 테스트 값이 아니어야 한다', () {
    if (!_releaseMode) return;
    final src = _read('lib/ads/ad_config.dart');
    final v = _match(src, "androidAppId\\s*=\\s*'([^']*)'");
    expect(v, isNotNull);
    expect(v!.contains('3940256099942544'), isFalse,
        reason: '구글 테스트 앱 ID 가 그대로 남아 있다');
  });

  test('개인정보 처리방침 주소에 자리표시자가 없다', () {
    final src = _read('lib/ui/parent_gate.dart');
    final url = _match(src, r"kPrivacyPolicyUrl\s*=\s*\n?\s*'([^']+)'");
    expect(url, isNotNull, reason: '주소 상수를 찾지 못했다');
    expect(url!.startsWith('https://'), isTrue);
    expect(url.contains('<'), isFalse, reason: '자리표시자가 남아 있다: $url');
  });

  test('앱 오프닝 광고는 꺼져 있다', () {
    // Families 정책 금지 항목이다. 실수로 켜면 여기서 걸린다.
    final src = _read('lib/ads/ad_config.dart');
    expect(src.contains('appOpenAdEnabled = false'), isTrue);
  });

  test('결제 스텁이 남아 있지 않다', () {
    final src = _read('lib/ui/parent_gate.dart');
    expect(src.contains('결제 연동은 출시 전에 붙입니다'), isFalse,
        reason: '결제 버튼이 아직 스텁이다. 심사에서 반려된다');
    expect(src.contains('구매 복원'), isTrue,
        reason: '비소모성 상품에는 구매 복원 경로가 필요하다');
  });

  test('아동 대상 광고 신호가 설정돼 있다', () {
    // 9.x 부터 아동·청소년 신호가 ageRestrictedTreatment 로 통합됐다.
    final src = _read('lib/ads/ad_manager.dart');
    expect(src.contains('MaxAdContentRating.g'), isTrue);
    expect(src.contains('AgeRestrictedTreatment.child'), isTrue);
  });

  test('유럽 동의 절차가 붙어 있다', () {
    final src = _read('lib/ads/ad_manager.dart');
    expect(src.contains('ConsentManager.instance.gather()'), isTrue,
        reason: '광고 초기화 전에 동의 절차를 거쳐야 한다');
  });

  test('한자가 섞여 있지 않다', () {
    // 한글과 시각적으로 구분되지 않는 한자가 들어가는 사고를 막는다.
    const targets = <String>[
      'lib/main.dart',
      'lib/ads/ad_config.dart',
      'lib/ads/ad_manager.dart',
      'lib/ads/consent.dart',
      'lib/billing/billing.dart',
      'lib/game/cards.dart',
      'lib/game/curve.dart',
      'lib/ui/parent_gate.dart',
    ];
    for (final path in targets) {
      for (final r in _read(path).runes) {
        expect(r >= 0x4E00 && r <= 0x9FFF, isFalse,
            reason: '$path 에 한자 ${String.fromCharCode(r)} 가 있다');
      }
    }
  });
}

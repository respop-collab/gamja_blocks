/// 출시 점검. 사람이 기억으로 막던 실수를 테스트로 막는다.
///
/// 이 테스트들은 개발 중에는 통과하고, 실제 출시 설정으로 바꾼 순간부터
/// 빠진 값이 있으면 실패한다. 그래서 "실제 ID 켜 놓고 값은 비어 있음" 같은
/// 조합으로 스토어에 올라가는 일이 생기지 않는다.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gamja_blocks/ads/ad_config.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  test('실제 광고 ID를 켰다면 값이 모두 채워져 있어야 한다', () {
    if (AdConfig.useRealIds) {
      expect(AdConfig.realIdsComplete, isTrue,
          reason: 'useRealIds 가 true 인데 광고 단위 ID 가 비어 있다');
    }
  });

  test('실제 광고 ID를 켰다면 앱 ID도 테스트 값이 아니어야 한다', () {
    if (AdConfig.useRealIds) {
      expect(AdConfig.androidAppId.contains('3940256099942544'), isFalse,
          reason: '구글 테스트 앱 ID 가 그대로 남아 있다');
    }
  });

  test('개인정보 처리방침 주소에 자리표시자가 남아 있지 않다', () {
    final src = _read('lib/ui/parent_gate.dart');
    final m = RegExp(r"kPrivacyPolicyUrl\s*=\s*\n?\s*'([^']+)'").firstMatch(src);
    expect(m, isNotNull, reason: '주소 상수를 찾지 못했다');
    final url = m!.group(1)!;

    // 실제 광고 ID를 쓰는 출시 설정이라면 자리표시자가 남아 있으면 안 된다.
    if (AdConfig.useRealIds) {
      expect(url.contains('<'), isFalse, reason: '주소에 자리표시자가 남아 있다: $url');
      expect(url.startsWith('https://'), isTrue);
    }
  });

  test('앱 오프닝 광고는 꺼져 있어야 한다', () {
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
    final src = _read('lib/ads/ad_manager.dart');
    expect(src.contains('MaxAdContentRating.g'), isTrue);
    expect(src.contains('TagForChildDirectedTreatment.yes'), isTrue);
    expect(src.contains('TagForUnderAgeOfConsent.yes'), isTrue);
  });

  test('한자가 섞여 있지 않다', () {
    // 한글과 시각적으로 구분되지 않는 한자가 들어가는 사고를 막는다.
    final targets = <String>[
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
      final src = _read(path);
      for (final r in src.runes) {
        expect(r >= 0x4E00 && r <= 0x9FFF, isFalse,
            reason: '$path 에 한자 ${String.fromCharCode(r)} 가 있다');
      }
    }
  });
}

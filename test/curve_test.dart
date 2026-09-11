import 'package:flutter_test/flutter_test.dart';
import 'package:gamja_blocks/game/curve.dart';

void main() {
  group('구간 경계', () {
    test('구간이 단계 범위대로 나뉜다', () {
      expect(tierOf(1), Tier.elementary);
      expect(tierOf(10), Tier.elementary);
      expect(tierOf(11), Tier.middle);
      expect(tierOf(50), Tier.middle);
      expect(tierOf(51), Tier.high);
      expect(tierOf(100), Tier.high);
      expect(tierOf(101), Tier.adult);
      expect(tierOf(1000), Tier.adult);
      expect(tierOf(1001), Tier.endless);
      expect(tierOf(999999), Tier.endless);
    });

    test('목표 줄 수가 구간 경계에서 튀지 않는다', () {
      // 10 → 11 (초등 끝 → 중학 시작)
      expect(paramsFor(10).goal, 8);
      expect(paramsFor(11).goal, 8);
      // 50 → 51 (중학 끝 → 고등 시작)
      expect(paramsFor(50).goal, 18);
      expect(paramsFor(51).goal, 18);
      // 100 → 101 (고등 끝 → 성인 시작)
      expect(paramsFor(100).goal, 25);
      expect(paramsFor(101).goal, 25);
      // 1000 → 1001 (성인 끝 → 무한 시작)
      expect(paramsFor(1000).goal, 25);
      expect(paramsFor(1001).goal, 25);
    });
  });

  group('단조성', () {
    test('목표 줄 수는 감소하지 않는다 (1~1000)', () {
      var prev = 0;
      for (var n = 1; n <= 1000; n++) {
        final g = paramsFor(n).goal;
        expect(g, greaterThanOrEqualTo(prev), reason: '$n단계');
        prev = g;
      }
    });

    test('작은 도형 비율은 구간 안에서 감소한다', () {
      expect(paramsFor(11).smallRatio, greaterThan(paramsFor(50).smallRatio));
      expect(paramsFor(51).smallRatio, greaterThan(paramsFor(100).smallRatio));
    });

    test('성인 구간의 수 제한은 줄어들기만 한다', () {
      var prev = 1 << 30;
      for (var n = 101; n <= 1000; n++) {
        final m = paramsFor(n).moveLimit;
        expect(m, lessThanOrEqualTo(prev), reason: '$n단계');
        prev = m;
      }
      expect(paramsFor(101).moveLimit, 61);
      expect(paramsFor(1000).moveLimit, 54);
    });
  });

  group('안전 범위', () {
    test('보드는 51단계 이후 8x8로 고정된다', () {
      // 실측: 보드를 키우면 배치 여유가 늘어 오히려 쉬워진다
      for (final n in [51, 100, 500, 1000, 5000, 100000]) {
        expect(paramsFor(n).board, 8, reason: '$n단계');
      }
    });

    test('도형은 어느 단계에서도 6칸을 넘지 않는다', () {
      // 실측: 8x8에서 6칸 초과 도형은 생존을 무너뜨린다
      for (final n in [1, 50, 100, 500, 1000, 9999, 100000]) {
        expect(paramsFor(n).maxPiece, lessThanOrEqualTo(6), reason: '$n단계');
      }
    });

    test('수 제한이 바닥(50) 아래로 내려가지 않는다', () {
      for (final n in [101, 500, 1000, 1001, 3000, 10000, 100000]) {
        final m = paramsFor(n).moveLimit;
        if (m > 0) expect(m, greaterThanOrEqualTo(50), reason: '$n단계');
      }
    });

    test('한 판 길이가 상한을 넘지 않는다', () {
      for (final n in [1001, 2000, 5000, 50000]) {
        expect(paramsFor(n).goal, lessThanOrEqualTo(kGoalCap), reason: '$n단계');
      }
    });

    test('작은 도형 비율은 항상 0과 1 사이다', () {
      for (var n = 1; n <= 3000; n++) {
        final s = paramsFor(n).smallRatio;
        expect(s, greaterThan(0.0));
        expect(s, lessThanOrEqualTo(1.0));
      }
    });
  });

  group('무한 구간', () {
    test('회차마다 목표가 올라가고 난이도가 완화된다 (톱니)', () {
      final endOfCycle1 = paramsFor(1300);
      final startOfCycle2 = paramsFor(1301);
      // 회차가 바뀌면 목표는 낮아지고 여유(수 제한/목표 비)는 커진다
      expect(startOfCycle2.cycle, endOfCycle1.cycle + 1);
      final slackBefore = endOfCycle1.moveLimit / endOfCycle1.goal;
      final slackAfter = startOfCycle2.moveLimit / startOfCycle2.goal;
      expect(slackAfter, greaterThan(slackBefore));
    });

    test('목표 상한에 걸린 뒤에는 난이도가 고정된다', () {
      final a = paramsFor(2200);
      final b = paramsFor(5000);
      final c = paramsFor(100000);
      expect(a.saturated, isTrue);
      expect(b.saturated, isTrue);
      expect(c.saturated, isTrue);
      // 포화 후 회차가 늘어도 목표와 수 제한이 같아야 한다.
      // (고치기 전에는 회차 리셋 때문에 난이도가 거꾸로 내려갔다)
      expect(b.goal, a.goal);
      expect(b.moveLimit, a.moveLimit);
      expect(c.goal, a.goal);
      expect(c.moveLimit, a.moveLimit);
    });

    test('돌 블록 수에 상한이 있다', () {
      for (final n in [1001, 3000, 10000, 1000000]) {
        expect(paramsFor(n).stones, lessThanOrEqualTo(6), reason: '$n단계');
      }
    });
  });

  group('실패 규칙', () {
    test('초등 구간만 실패가 없다', () {
      expect(paramsFor(5).canFail, isFalse);
      expect(paramsFor(11).canFail, isTrue);
      expect(paramsFor(500).canFail, isTrue);
    });

    test('도움 횟수가 구간에 따라 줄어든다', () {
      expect(paramsFor(5).unlimitedHelps, isTrue);
      expect(paramsFor(30).helps, 3);
      expect(paramsFor(75).helps, 1);
      expect(paramsFor(500).helps, 0);
      expect(paramsFor(2000).helps, 0);
    });

    test('수 제한은 101단계부터 생긴다', () {
      expect(paramsFor(100).hasMoveLimit, isFalse);
      expect(paramsFor(101).hasMoveLimit, isTrue);
      expect(paramsFor(9999).hasMoveLimit, isTrue);
    });
  });

  test('0 이하 단계도 안전하게 처리된다', () {
    expect(paramsFor(0).stage, 1);
    expect(paramsFor(-5).tier, Tier.elementary);
  });
}

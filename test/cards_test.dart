import 'package:flutter_test/flutter_test.dart';
import 'package:gamja_blocks/game/cards.dart';

void main() {
  test('카드 목록이 비어 있지 않고 시리즈가 모두 정의돼 있다', () {
    expect(kCards, isNotEmpty);
    expect(kCardCount, kCards.length);
    for (final c in kCards) {
      expect(c.asset.startsWith('assets/gamja/'), isTrue, reason: c.name);
      expect(c.name.trim(), isNotEmpty);
      expect(kSeriesOrder.contains(c.series), isTrue, reason: c.series);
    }
  });

  test('카드 이름과 이미지 경로가 중복되지 않는다', () {
    expect(kCards.map((c) => c.name).toSet().length, kCards.length);
    expect(kCards.map((c) => c.asset).toSet().length, kCards.length);
  });

  test('10단계마다 한 장씩 순서대로 준다', () {
    expect(cardIndexForStage(1), isNull);
    expect(cardIndexForStage(9), isNull);
    expect(cardIndexForStage(10), 0);
    expect(cardIndexForStage(20), 1);
    expect(cardIndexForStage(kCardCount * 10), kCardCount - 1);
    // 다 모으면 처음부터 순환한다
    expect(cardIndexForStage((kCardCount + 1) * 10), 0);
  });

  test('31장이면 310단계까지 수집이 이어진다', () {
    expect(kCardCount, greaterThanOrEqualTo(31));
    final lastNewStage = kCardCount * 10;
    expect(lastNewStage, greaterThanOrEqualTo(310));
  });

  test('시리즈 순서에 빈 시리즈가 없다', () {
    for (final s in kSeriesOrder) {
      expect(kCards.any((c) => c.series == s), isTrue, reason: s);
    }
  });
}

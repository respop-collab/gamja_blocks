import 'package:flutter_test/flutter_test.dart';
import 'package:gamja_blocks/game/records.dart';

void main() {
  test('마일스톤은 Play Games 리더보드 한도(70개) 안에 들어간다', () {
    expect(kMilestoneStages.length, lessThanOrEqualTo(70));
    expect(kMilestoneStages, isNotEmpty);
  });

  test('초등 구간에는 기록도 시계도 붙이지 않는다', () {
    for (final s in kMilestoneStages) {
      expect(s, greaterThan(10), reason: '$s단계는 초등 구간이다');
    }
    expect(showTimerForStage(1), isFalse);
    expect(showTimerForStage(10), isFalse);
    expect(showTimerForStage(11), isTrue);
  });

  test('마일스톤 목록은 오름차순이고 중복이 없다', () {
    final sorted = [...kMilestoneStages]..sort();
    expect(kMilestoneStages, sorted);
    expect(kMilestoneStages.toSet().length, kMilestoneStages.length);
  });

  test('시간 표기는 리더보드와 같은 형식이다', () {
    expect(formatMs(0), '-');
    expect(formatMs(-5), '-');
    expect(formatMs(66032), '1:06.03');
    expect(formatMs(5000), '0:05.00');
    expect(formatMs(3600000), '1:00:00');
  });

  test('마일스톤 판정이 정확하다', () {
    expect(isMilestone(50), isTrue);
    expect(isMilestone(51), isFalse);
    expect(isMilestone(1000), isTrue);
  });
}

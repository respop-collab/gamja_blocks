/// 기록 체계.
///
/// 지금은 기기 안에만 남기고 개인 최고 기록을 보여 준다.
/// 나중에 Play Games 리더보드를 켜면 여기 쌓인 기록을 그대로 올릴 수 있도록,
/// 리더보드가 요구하는 형식(밀리초 정수, 작은 값이 상위)에 맞춰 둔다.
///
/// 왜 전 단계가 아니라 마일스톤만 재는가:
/// Play Games 는 게임 하나에 리더보드를 70개까지만 허용한다.
/// 단계가 무한이므로 전 단계 순위는 애초에 불가능하다.
/// 그래서 처음부터 대표 단계만 기록해 저장 용량과 순위 설계를 함께 맞춘다.
library;

/// 순위 대상 단계. 각 구간의 마지막 단계를 대표로 삼는다.
/// 1~10단계(초등)는 실패가 없는 구간이라 시간 경쟁을 붙이지 않는다.
const List<int> kMilestoneStages = [50, 100, 300, 500, 1000];

bool isMilestone(int stage) => kMilestoneStages.contains(stage);

/// 밀리초를 1:06.03 꼴로 바꾼다. 리더보드 표기와 같은 형식이다.
String formatMs(int ms) {
  if (ms <= 0) return '-';
  final totalSec = ms ~/ 1000;
  final h = totalSec ~/ 3600;
  final m = (totalSec % 3600) ~/ 60;
  final s = totalSec % 60;
  final cs = (ms % 1000) ~/ 10;
  final two = (int v) => v.toString().padLeft(2, '0');
  if (h > 0) return '$h:${two(m)}:${two(s)}';
  return '$m:${two(s)}.${two(cs)}';
}

/// 시간을 보여 줄 구간인지. 초등 구간에는 시계를 띄우지 않는다.
/// 아이가 하는 구간에 시간 압박을 붙이면 설계 의도가 깨진다.
bool showTimerForStage(int stage) => stage > 10;

/// 난이도 곡선. 단계 번호 하나로 그 단계의 모든 파라미터를 만든다.
///
/// 이 파일의 숫자는 봇 시뮬레이션 약 4만 판으로 실측해 정한 값이다.
/// 곡선을 바꾸려면 여기만 고치면 되고, 게임 전체가 따라 바뀐다.
///
/// 실측 근거 (2026-09-11):
///  - 8x8 보드에서 6칸 초과 도형(3x3 등)은 어떤 조합에서도 생존을 무너뜨린다 → 최대 6칸 고정
///  - 보드를 키우면 배치 여유가 더 크게 늘어 오히려 쉬워진다 → 51단계 이후 8x8 고정
///  - 목표 1줄당 필요한 도형 개수는 약 2.2개로 일정하다 (목표 50줄까지 선형)
///  - 수 제한의 바닥은 약 50 (그 아래는 성공률 0%)
///  - 돌 블록은 난이도 레버로 약하다 (보조 장치로만 사용)

library;

enum Tier { elementary, middle, high, adult, endless }

extension TierLabel on Tier {
  String get label => switch (this) {
        Tier.elementary => '초등',
        Tier.middle => '중학',
        Tier.high => '고등',
        Tier.adult => '성인',
        Tier.endless => '무한',
      };
}

/// 한 판 길이 상한. 목표 45줄 = 도형 약 100개 = 8~10분.
/// 캐주얼 게임에서 한 판이 이보다 길면 안 되므로 난이도가 아니라 재미가 기준이다.
const int kGoalCap = 45;

/// 실측값: 목표 1줄을 지우는 데 필요한 도형 개수
const double kPiecesPerLine = 2.2;

/// 무한 구간의 한 회차 길이
const int kEndlessCycle = 300;

class StageParams {
  final int stage;
  final Tier tier;

  /// 보드 한 변의 칸 수
  final int board;

  /// 트레이에 나올 수 있는 가장 큰 도형의 칸 수
  final int maxPiece;

  /// 3칸 이하 도형이 뽑힐 확률. 가장 강력한 난이도 레버다.
  final double smallRatio;

  /// 이 단계를 통과하는 데 지워야 할 줄 수
  final int goal;

  /// 놓을 수 있는 도형 개수 제한. 0이면 제한 없음.
  final int moveLimit;

  /// 시작할 때 보드에 박혀 있는 돌 블록 수. 줄이 완성되면 함께 사라진다.
  final int stones;

  /// 감자 도움 횟수. -1이면 무제한.
  final int helps;

  /// 무한 구간의 회차 (0부터). 그 외 구간은 0.
  final int cycle;

  /// 목표가 상한에 걸려 난이도가 포화했는지
  final bool saturated;

  const StageParams({
    required this.stage,
    required this.tier,
    required this.board,
    required this.maxPiece,
    required this.smallRatio,
    required this.goal,
    required this.moveLimit,
    required this.stones,
    required this.helps,
    this.cycle = 0,
    this.saturated = false,
  });

  bool get unlimitedHelps => helps < 0;
  bool get hasMoveLimit => moveLimit > 0;

  /// 초등 구간은 실패가 없다. 막히면 감자가 치워 준다.
  bool get canFail => tier != Tier.elementary;
}

Tier tierOf(int stage) {
  if (stage <= 10) return Tier.elementary;
  if (stage <= 50) return Tier.middle;
  if (stage <= 100) return Tier.high;
  if (stage <= 1000) return Tier.adult;
  return Tier.endless;
}

/// 단계 파라미터를 계산한다. 단계 수에 상한은 없다.
StageParams paramsFor(int stage) {
  final n = stage < 1 ? 1 : stage;
  final tier = tierOf(n);

  switch (tier) {
    // 규칙을 익히는 구간. 절대 막히지 않게 한다.
    case Tier.elementary:
      return StageParams(
        stage: n,
        tier: tier,
        board: 6,
        maxPiece: 4,
        smallRatio: 0.55,
        goal: 3 + ((n - 1) * 0.6).floor(), // 3 → 8
        moveLimit: 0,
        stones: 0,
        helps: -1,
      );

    // 실패를 처음 도입한다. 재도전으로 배운다.
    case Tier.middle:
      return StageParams(
        stage: n,
        tier: tier,
        board: 7,
        maxPiece: 5,
        smallRatio: 0.50 - (n - 10) / 40 * 0.12, // 50% → 38%
        goal: 8 + ((n - 10) * 0.25).floor(), // 8 → 18
        moveLimit: 0,
        stones: 0,
        helps: 3,
      );

    // 돌 블록이 등장하고 공간 관리가 핵심이 된다.
    case Tier.high:
      return StageParams(
        stage: n,
        tier: tier,
        board: 8,
        maxPiece: 6,
        smallRatio: 0.38 - (n - 50) / 50 * 0.08, // 38% → 30%
        goal: 18 + ((n - 50) * 0.14).floor(), // 18 → 25
        moveLimit: 0,
        stones: ((n - 50) / 25).floor(), // 0 → 2
        helps: 1,
      );

    // 수 제한이 난이도 레버가 된다.
    // 작은 도형 비율을 일부러 높게(40%) 두는 이유: 막혀서 지면 운으로 느껴지고,
    // 수를 다 써서 지면 실력으로 느껴진다. 같은 성공률이라도 후자가 납득된다.
    case Tier.adult:
      return StageParams(
        stage: n,
        tier: tier,
        board: 8,
        maxPiece: 6,
        smallRatio: 0.40,
        goal: 25,
        moveLimit: (58 * (1.06 - (n - 100) / 900 * 0.13)).round(), // 61 → 54
        stones: _min(4, 2 + ((n - 100) / 350).floor()),
        helps: 0,
      );

    // 300단계 주기로 목표가 올라가고 난이도가 잠깐 완화됐다 다시 조여진다.
    // 목표가 상한(45줄)에 걸리면 톱니를 멈추고 최고 난도로 고정한다.
    case Tier.endless:
      final m = n - 1000;
      final cycle = ((m - 1) / kEndlessCycle).floor();
      final u = ((m - 1) % kEndlessCycle) / kEndlessCycle;
      final rawGoal = 25 + cycle * 5 + (u * 8).floor();
      final goal = _min(kGoalCap, rawGoal);
      final saturated = rawGoal >= kGoalCap;
      final eff = saturated ? 0.97 : (1.10 - u * 0.13);
      return StageParams(
        stage: n,
        tier: tier,
        board: 8,
        maxPiece: 6,
        smallRatio: 0.40,
        goal: goal,
        moveLimit: (kPiecesPerLine * goal * eff).round(),
        stones: _min(6, 3 + cycle),
        helps: 0,
        cycle: cycle,
        saturated: saturated,
      );
  }
}

int _min(int a, int b) => a < b ? a : b;

/// 게임 엔진. UI·광고·저장에 의존하지 않는 순수 로직이며 단위 테스트 대상이다.
library;

import 'dart:convert';
import 'dart:math';

import 'curve.dart';
import 'piece.dart';

/// 보드 칸 값: 0 = 빈 칸, -1 = 돌 블록, 1 이상 = colorIndex + 1
const int kEmpty = 0;
const int kStone = -1;

const int kTraySize = 3;

enum StageResult { playing, cleared, failedStuck, failedOutOfMoves }

class PlaceOutcome {
  final int clearedLines;
  final List<int> clearedCells; // row * board + col
  final bool goalReached;
  final StageResult result;
  const PlaceOutcome({
    required this.clearedLines,
    required this.clearedCells,
    required this.goalReached,
    required this.result,
  });
}

class GameEngine {
  final StageParams p;
  final List<List<int>> board;
  final List<Piece?> tray;
  final Random _rng;

  int linesCleared;
  int movesLeft;
  int helpsLeft;
  StageResult result;

  /// 뽑기 횟수. 저장·복원 시 도형 순서를 재현하기 위해 센다.
  int draws;

  GameEngine._({
    required this.p,
    required this.board,
    required this.tray,
    required Random rng,
    required this.linesCleared,
    required this.movesLeft,
    required this.helpsLeft,
    required this.result,
    required this.draws,
  }) : _rng = rng;

  factory GameEngine.start(int stage, {int? seed}) {
    final p = paramsFor(stage);
    final s = seed ?? DateTime.now().microsecondsSinceEpoch & 0x7fffffff;
    final rng = Random(s);
    final e = GameEngine._(
      p: p,
      board: List.generate(p.board, (_) => List.filled(p.board, kEmpty)),
      tray: List.filled(kTraySize, null),
      rng: rng,
      linesCleared: 0,
      movesLeft: p.moveLimit,
      helpsLeft: p.helps,
      result: StageResult.playing,
      draws: 0,
    );
    e._seed = s;
    e._placeStones();
    e._refill();
    return e;
  }

  int _seed = 0;
  int get seed => _seed;
  int get size => p.board;

  /// 돌 배치는 별도 난수를 쓴다. 그래야 도형 뽑기 난수열이 오염되지 않아
  /// 저장·복원 시 도형 순서를 정확히 재현할 수 있다.
  void _placeStones() {
    final stoneRng = Random(_seed ^ 0x5f3759df);
    var left = p.stones, guard = 0;
    while (left > 0 && guard < 500) {
      guard++;
      final r = stoneRng.nextInt(size), c = stoneRng.nextInt(size);
      if (board[r][c] != kEmpty) continue;
      board[r][c] = kStone;
      left--;
    }
  }

  // ---------- 도형 뽑기 ----------

  List<Piece> get _pool => kPieces.where((x) => x.size <= p.maxPiece).toList();

  Piece _draw() {
    draws++;
    final pool = _pool;
    final small = pool.where((x) => x.size <= 3).toList();
    final big = pool.where((x) => x.size > 3).toList();
    final useSmall = big.isEmpty || _rng.nextDouble() < p.smallRatio;
    final src = useSmall ? (small.isEmpty ? pool : small) : (big.isEmpty ? pool : big);
    return src[_rng.nextInt(src.length)];
  }

  void _refill() {
    for (var i = 0; i < kTraySize; i++) {
      tray[i] = _draw();
    }
  }

  // ---------- 배치 ----------

  bool canPlace(Piece piece, int row, int col) {
    for (final (dr, dc) in piece.cells) {
      final r = row + dr, c = col + dc;
      if (r < 0 || c < 0 || r >= size || c >= size) return false;
      if (board[r][c] != kEmpty) return false;
    }
    return true;
  }

  bool canPlaceAnywhere(Piece piece) {
    for (var r = 0; r <= size - piece.height; r++) {
      for (var c = 0; c <= size - piece.width; c++) {
        if (canPlace(piece, r, c)) return true;
      }
    }
    return false;
  }

  bool get anyMoveAvailable => tray.any((x) => x != null && canPlaceAnywhere(x));

  PlaceOutcome? place(int trayIndex, int row, int col) {
    final piece = tray[trayIndex];
    if (piece == null || result != StageResult.playing) return null;
    if (!canPlace(piece, row, col)) return null;

    for (final (dr, dc) in piece.cells) {
      board[row + dr][col + dc] = piece.colorIndex + 1;
    }
    tray[trayIndex] = null;
    if (p.hasMoveLimit) movesLeft--;

    final cleared = _clearLines();
    linesCleared += cleared.$1;

    if (tray.every((x) => x == null)) _refill();

    if (linesCleared >= p.goal) {
      result = StageResult.cleared;
    } else if (p.hasMoveLimit && movesLeft <= 0) {
      result = StageResult.failedOutOfMoves;
    } else if (!anyMoveAvailable) {
      // 초등 구간은 실패가 없다. 호출측이 helpClear()를 부른다.
      result = p.canFail ? StageResult.failedStuck : StageResult.playing;
    }

    return PlaceOutcome(
      clearedLines: cleared.$1,
      clearedCells: cleared.$2,
      goalReached: linesCleared >= p.goal,
      result: result,
    );
  }

  /// 가득 찬 행과 열을 동시에 판정한 뒤 소거한다. 교차 칸은 한 번만 센다.
  /// 돌 블록도 줄이 완성되면 함께 사라진다.
  (int, List<int>) _clearLines() {
    final fullRows = <int>[];
    final fullCols = <int>[];
    for (var r = 0; r < size; r++) {
      if (board[r].every((v) => v != kEmpty)) fullRows.add(r);
    }
    for (var c = 0; c < size; c++) {
      var full = true;
      for (var r = 0; r < size; r++) {
        if (board[r][c] == kEmpty) {
          full = false;
          break;
        }
      }
      if (full) fullCols.add(c);
    }
    final cells = <int>{};
    for (final r in fullRows) {
      for (var c = 0; c < size; c++) {
        cells.add(r * size + c);
      }
    }
    for (final c in fullCols) {
      for (var r = 0; r < size; r++) {
        cells.add(r * size + c);
      }
    }
    for (final k in cells) {
      board[k ~/ size][k % size] = kEmpty;
    }
    return (fullRows.length + fullCols.length, cells.toList());
  }

  // ---------- 감자 도움 ----------

  /// 가장 많이 찬 행과 열을 비운다. 초등 구간은 무제한, 그 외는 횟수 제한.
  List<int> helpClear() {
    if (!p.unlimitedHelps) {
      if (helpsLeft <= 0) return const [];
      helpsLeft--;
    }
    final cleared = <int>[];

    var bestRow = 0, best = -1;
    for (var r = 0; r < size; r++) {
      final n = board[r].where((v) => v != kEmpty).length;
      if (n > best) {
        best = n;
        bestRow = r;
      }
    }
    for (var c = 0; c < size; c++) {
      if (board[bestRow][c] != kEmpty) cleared.add(bestRow * size + c);
      board[bestRow][c] = kEmpty;
    }

    var bestCol = 0;
    best = -1;
    for (var c = 0; c < size; c++) {
      var n = 0;
      for (var r = 0; r < size; r++) {
        if (board[r][c] != kEmpty) n++;
      }
      if (n > best) {
        best = n;
        bestCol = c;
      }
    }
    for (var r = 0; r < size; r++) {
      if (board[r][bestCol] != kEmpty) cleared.add(r * size + bestCol);
      board[r][bestCol] = kEmpty;
    }

    if (result == StageResult.failedStuck) result = StageResult.playing;
    if (!anyMoveAvailable) _refill();
    return cleared;
  }

  /// 리워드 광고 보상. 수 제한 구간은 수를 더 주고, 그 외는 도움 1회를 준다.
  void reviveByAd({int extraMoves = 12}) {
    if (p.hasMoveLimit) {
      movesLeft += extraMoves;
      result = StageResult.playing;
      if (!anyMoveAvailable) helpClearForced();
    } else {
      result = StageResult.playing;
      helpClearForced();
    }
  }

  /// 횟수를 차감하지 않는 도움 (광고 보상용)
  void helpClearForced() {
    final saved = helpsLeft;
    helpsLeft = p.unlimitedHelps ? helpsLeft : 1;
    helpClear();
    if (!p.unlimitedHelps) helpsLeft = saved;
  }

  double get progress => p.goal == 0 ? 1 : (linesCleared / p.goal).clamp(0, 1);

  // ---------- 저장 / 복원 ----------

  String toJson() => jsonEncode({
        'v': 1,
        'stage': p.stage,
        'seed': _seed,
        'draws': draws,
        'board': board,
        'tray': tray.map((x) => x?.id).toList(),
        'lines': linesCleared,
        'moves': movesLeft,
        'helps': helpsLeft,
      });

  static GameEngine? fromJson(String raw) {
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final stage = m['stage'] as int;
      final seed = m['seed'] as int;
      final draws = m['draws'] as int? ?? 0;
      final p = paramsFor(stage);

      // Random은 내부 상태를 직렬화할 수 없으므로, 같은 시드로 다시 만들고
      // 지금까지 뽑은 횟수만큼 난수를 소비해 이후 도형 순서를 재현한다.
      final rng = Random(seed);
      final pool = kPieces.where((x) => x.size <= p.maxPiece).toList();
      final smallN = pool.where((x) => x.size <= 3).length;
      final bigN = pool.length - smallN;
      for (var i = 0; i < draws; i++) {
        final useSmall = bigN == 0 || rng.nextDouble() < p.smallRatio;
        final n = useSmall ? (smallN == 0 ? pool.length : smallN) : (bigN == 0 ? pool.length : bigN);
        rng.nextInt(n);
      }

      final e = GameEngine._(
        p: p,
        board: (m['board'] as List).map((r) => (r as List).cast<int>().toList()).toList(),
        tray: (m['tray'] as List)
            .cast<String?>()
            .map((id) => id == null ? null : pieceById(id))
            .toList(),
        rng: rng,
        linesCleared: m['lines'] as int? ?? 0,
        movesLeft: m['moves'] as int? ?? p.moveLimit,
        helpsLeft: m['helps'] as int? ?? p.helps,
        result: StageResult.playing,
        draws: draws,
      );
      e._seed = seed;
      return e;
    } catch (_) {
      return null;
    }
  }
}

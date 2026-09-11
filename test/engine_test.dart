import 'package:flutter_test/flutter_test.dart';
import 'package:gamja_blocks/game/engine.dart';
import 'package:gamja_blocks/game/piece.dart';

void main() {
  group('배치 판정', () {
    test('경계 밖과 겹침은 배치 불가', () {
      final e = GameEngine.start(1, seed: 1);
      final i3 = pieceById('i3h');
      expect(e.canPlace(i3, 0, 4), isFalse); // 6칸 보드에서 4+3 > 6
      expect(e.canPlace(i3, 0, 3), isTrue);
      e.board[0][3] = 1;
      expect(e.canPlace(i3, 0, 3), isFalse);
    });

    test('돌 블록 위에는 놓을 수 없다', () {
      final e = GameEngine.start(75, seed: 1); // 고등 구간, 돌 있음
      e.board[0][0] = kStone;
      expect(e.canPlace(pieceById('dot'), 0, 0), isFalse);
    });

    test('빈 보드에서는 허용된 모든 도형을 놓을 수 있다', () {
      for (final stage in [1, 30, 75, 500, 2000]) {
        final e = GameEngine.start(stage, seed: 3);
        // 돌 배치는 무작위이므로 판정만 보기 위해 보드를 비운다
        for (var r = 0; r < e.size; r++) {
          for (var c = 0; c < e.size; c++) {
            e.board[r][c] = kEmpty;
          }
        }
        for (final p in kPieces.where((x) => x.size <= e.p.maxPiece)) {
          expect(e.canPlaceAnywhere(p), isTrue, reason: '$stage단계 ${p.id}');
        }
      }
    });
  });

  group('줄 소거', () {
    test('행이 가득 차면 소거되고 줄 수가 오른다', () {
      final e = GameEngine.start(1, seed: 1);
      for (var c = 0; c < e.size - 1; c++) {
        e.board[0][c] = 1;
      }
      e.tray[0] = pieceById('dot');
      final out = e.place(0, 0, e.size - 1)!;
      expect(out.clearedLines, 1);
      expect(e.linesCleared, 1);
      expect(e.board[0].every((v) => v == kEmpty), isTrue);
    });

    test('행과 열 동시 소거 시 교차 칸은 한 번만 센다', () {
      final e = GameEngine.start(1, seed: 1);
      final n = e.size;
      for (var c = 0; c < n; c++) {
        e.board[0][c] = 1;
      }
      for (var r = 0; r < n; r++) {
        e.board[r][0] = 1;
      }
      e.board[0][0] = kEmpty;
      e.tray[0] = pieceById('dot');
      final out = e.place(0, 0, 0)!;
      expect(out.clearedLines, 2);
      expect(out.clearedCells.length, n * 2 - 1);
    });

    test('돌 블록도 줄이 완성되면 사라진다', () {
      final e = GameEngine.start(1, seed: 1);
      final n = e.size;
      e.board[0][0] = kStone;
      for (var c = 1; c < n - 1; c++) {
        e.board[0][c] = 1;
      }
      e.tray[0] = pieceById('dot');
      e.place(0, 0, n - 1);
      expect(e.board[0][0], kEmpty);
    });
  });

  group('단계 결과', () {
    test('목표를 채우면 통과', () {
      final e = GameEngine.start(1, seed: 1); // 목표 3줄
      expect(e.p.goal, 3);
      for (var line = 0; line < 3; line++) {
        for (var c = 0; c < e.size - 1; c++) {
          e.board[0][c] = 1;
        }
        e.tray[0] = pieceById('dot');
        e.place(0, 0, e.size - 1);
      }
      expect(e.result, StageResult.cleared);
    });

    test('수를 다 쓰면 실패한다', () {
      final e = GameEngine.start(101, seed: 5); // 수 제한 61
      expect(e.p.hasMoveLimit, isTrue);
      var guard = 0;
      while (e.result == StageResult.playing && guard++ < 500) {
        var placed = false;
        for (var i = 0; i < kTraySize && !placed; i++) {
          final p = e.tray[i];
          if (p == null) continue;
          for (var r = 0; r <= e.size - p.height && !placed; r++) {
            for (var c = 0; c <= e.size - p.width && !placed; c++) {
              if (e.canPlace(p, r, c)) {
                e.place(i, r, c);
                placed = true;
              }
            }
          }
        }
        if (!placed) break;
      }
      expect(e.result, isNot(StageResult.playing));
      if (e.result == StageResult.failedOutOfMoves) {
        expect(e.movesLeft, lessThanOrEqualTo(0));
      }
    });

    test('초등 구간은 막혀도 실패하지 않는다', () {
      final e = GameEngine.start(1, seed: 1);
      final n = e.size;
      for (var r = 0; r < n; r++) {
        for (var c = 0; c < n; c++) {
          e.board[r][c] = 1;
        }
      }
      e.board[0][0] = kEmpty;
      e.tray[0] = pieceById('dot');
      e.tray[1] = pieceById('i5h');
      e.tray[2] = pieceById('i5v');
      e.place(0, 0, 0);
      expect(e.result, isNot(StageResult.failedStuck));
    });
  });

  group('감자 도움', () {
    test('가장 찬 행과 열을 비운다', () {
      final e = GameEngine.start(1, seed: 1);
      for (var c = 0; c < e.size - 1; c++) {
        e.board[2][c] = 1;
      }
      final cleared = e.helpClear();
      expect(cleared, isNotEmpty);
      expect(e.board[2].every((v) => v == kEmpty), isTrue);
    });

    test('횟수 제한이 있는 구간에서는 차감된다', () {
      final e = GameEngine.start(30, seed: 1); // 중학, 도움 3회
      expect(e.helpsLeft, 3);
      e.board[0][0] = 1;
      e.helpClear();
      expect(e.helpsLeft, 2);
    });

    test('도움이 0이면 아무 일도 일어나지 않는다', () {
      final e = GameEngine.start(500, seed: 1); // 성인, 도움 0
      expect(e.helpsLeft, 0);
      expect(e.helpClear(), isEmpty);
    });

    test('초등 구간은 도움이 무제한이다', () {
      final e = GameEngine.start(1, seed: 1);
      for (var i = 0; i < 20; i++) {
        e.board[0][0] = 1;
        expect(e.helpClear(), isNotEmpty);
      }
    });
  });

  group('광고 보상', () {
    test('수 제한 구간에서는 수를 더 준다', () {
      final e = GameEngine.start(500, seed: 1);
      e.movesLeft = 0;
      e.result = StageResult.failedOutOfMoves;
      e.reviveByAd(extraMoves: 12);
      expect(e.movesLeft, 12);
      expect(e.result, StageResult.playing);
    });

    test('수 제한이 없는 구간에서는 보드를 비워 준다', () {
      final e = GameEngine.start(75, seed: 1);
      e.helpsLeft = 0;
      for (var c = 0; c < e.size; c++) {
        e.board[3][c] = 1;
      }
      e.result = StageResult.failedStuck;
      e.reviveByAd();
      expect(e.result, StageResult.playing);
      expect(e.helpsLeft, 0, reason: '광고 보상은 도움 횟수를 소모하지 않는다');
    });
  });

  group('저장과 복원', () {
    test('보드와 진행 상황이 그대로 복원된다', () {
      final a = GameEngine.start(120, seed: 42);
      a.place(0, 0, 0);
      final b = GameEngine.fromJson(a.toJson())!;
      expect(b.p.stage, a.p.stage);
      expect(b.linesCleared, a.linesCleared);
      expect(b.movesLeft, a.movesLeft);
      expect(b.board, a.board);
      expect(b.tray.map((x) => x?.id), a.tray.map((x) => x?.id));
    });

    test('복원 후에도 다음 도형 순서가 같다', () {
      final a = GameEngine.start(120, seed: 77);
      a.place(0, 0, 0);
      final b = GameEngine.fromJson(a.toJson())!;
      // 두 엔진에서 남은 트레이를 같은 자리에 모두 소진시켜 재충전 결과를 비교
      for (var i = 0; i < kTraySize; i++) {
        final p = a.tray[i];
        if (p == null) continue;
        var done = false;
        for (var r = 0; r <= a.size - p.height && !done; r++) {
          for (var c = 0; c <= a.size - p.width && !done; c++) {
            if (a.canPlace(p, r, c)) {
              a.place(i, r, c);
              b.place(i, r, c);
              done = true;
            }
          }
        }
      }
      expect(b.tray.map((x) => x?.id).toList(), a.tray.map((x) => x?.id).toList());
    });

    test('깨진 데이터는 null을 돌려준다', () {
      expect(GameEngine.fromJson('{'), isNull);
      expect(GameEngine.fromJson('{"stage":1}'), isNull);
    });
  });

  test('뽑히는 도형이 단계 상한을 넘지 않는다', () {
    for (final stage in [1, 30, 75, 500, 2000]) {
      // 보드를 매번 비우며 계속 놓아 재충전을 반복시킨다
      final e = GameEngine.start(stage, seed: 9);
      for (var k = 0; k < 300; k++) {
        for (final p in e.tray) {
          if (p != null) {
            expect(p.size, lessThanOrEqualTo(e.p.maxPiece), reason: '$stage단계 ${p.id}');
          }
        }
        for (var r = 0; r < e.size; r++) {
          for (var c = 0; c < e.size; c++) {
            e.board[r][c] = kEmpty;
          }
        }
        e.linesCleared = 0;
        e.movesLeft = 9999;
        e.result = StageResult.playing;
        for (var i = 0; i < kTraySize; i++) {
          final p = e.tray[i];
          if (p == null) continue;
          var done = false;
          for (var r = 0; r <= e.size - p.height && !done; r++) {
            for (var c = 0; c <= e.size - p.width && !done; c++) {
              if (e.canPlace(p, r, c)) {
                e.place(i, r, c);
                done = true;
              }
            }
          }
        }
      }
    }
  });
}

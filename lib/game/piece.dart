/// 도형 정의. 실측 결과 8x8 보드에서 6칸 초과 도형은 생존을 무너뜨리므로
/// 목록 전체를 6칸 이하로만 구성한다. (3x3 정사각형, 7칸, 8칸 도형은 채용하지 않음)
library;

class Piece {
  final String id;
  final List<(int, int)> cells; // (row, col)
  final int colorIndex;
  final int height;
  final int width;

  const Piece._(this.id, this.cells, this.colorIndex, this.height, this.width);

  factory Piece(String id, List<(int, int)> cells, int colorIndex) {
    var h = 0, w = 0;
    for (final (r, c) in cells) {
      if (r + 1 > h) h = r + 1;
      if (c + 1 > w) w = c + 1;
    }
    return Piece._(id, cells, colorIndex, h, w);
  }

  int get size => cells.length;
}

final List<Piece> kPieces = [
  // 1칸
  Piece('dot', [(0, 0)], 0),
  // 2칸
  Piece('i2h', [(0, 0), (0, 1)], 1),
  Piece('i2v', [(0, 0), (1, 0)], 1),
  // 3칸 직선
  Piece('i3h', [(0, 0), (0, 1), (0, 2)], 2),
  Piece('i3v', [(0, 0), (1, 0), (2, 0)], 2),
  // 3칸 L (4방향)
  Piece('l3a', [(0, 0), (1, 0), (1, 1)], 4),
  Piece('l3b', [(0, 0), (0, 1), (1, 0)], 4),
  Piece('l3c', [(0, 0), (0, 1), (1, 1)], 4),
  Piece('l3d', [(0, 1), (1, 0), (1, 1)], 4),
  // 4칸 정사각형
  Piece('o2', [(0, 0), (0, 1), (1, 0), (1, 1)], 3),
  // 4칸 직선
  Piece('i4h', [(0, 0), (0, 1), (0, 2), (0, 3)], 5),
  Piece('i4v', [(0, 0), (1, 0), (2, 0), (3, 0)], 5),
  // 4칸 T (4방향)
  Piece('t4a', [(0, 0), (0, 1), (0, 2), (1, 1)], 6),
  Piece('t4b', [(0, 1), (1, 0), (1, 1), (1, 2)], 6),
  Piece('t4c', [(0, 0), (1, 0), (1, 1), (2, 0)], 6),
  Piece('t4d', [(0, 1), (1, 0), (1, 1), (2, 1)], 6),
  // 5칸 직선
  Piece('i5h', [(0, 0), (0, 1), (0, 2), (0, 3), (0, 4)], 0),
  Piece('i5v', [(0, 0), (1, 0), (2, 0), (3, 0), (4, 0)], 0),
  // 5칸 큰 L (4방향)
  Piece('l5a', [(0, 0), (1, 0), (2, 0), (2, 1), (2, 2)], 2),
  Piece('l5b', [(0, 0), (0, 1), (0, 2), (1, 0), (2, 0)], 2),
  Piece('l5c', [(0, 0), (0, 1), (0, 2), (1, 2), (2, 2)], 2),
  Piece('l5d', [(0, 2), (1, 2), (2, 0), (2, 1), (2, 2)], 2),
  // 6칸 직사각형
  Piece('r23', [(0, 0), (0, 1), (0, 2), (1, 0), (1, 1), (1, 2)], 5),
  Piece('r32', [(0, 0), (0, 1), (1, 0), (1, 1), (2, 0), (2, 1)], 5),
];

Piece pieceById(String id) => kPieces.firstWhere((p) => p.id == id);

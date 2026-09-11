/// 팔레트는 감자 캐릭터 시트에서 직접 추출한 색이다.
/// 아동부터 성인까지 쓰는 게임이므로 밝은 단일 테마로 확정한다.
library;

import 'package:flutter/material.dart';

import '../game/curve.dart';

const kCream = Color(0xFFFFF4E2);
const kCream2 = Color(0xFFFDE9CE);
const kCard = Color(0xFFFFFDF8);
const kBoardBg = Color(0xFFEFD2A8);
const kHole = Color(0xFFDCB684);
const kStoneColor = Color(0xFFA89179);
const kInk = Color(0xFF6B4526);
const kInkSoft = Color(0xFFA5805C);
const kLine = Color(0xFFE3C49C);
const kCarrot = Color(0xFFF2913C);
const kCarrotDark = Color(0xFFC2661A);
const kGrape = Color(0xFF9B7BC8);

/// 블록 색상. 밝고 서로 구분이 뚜렷한 7색.
const List<Color> kBlockColors = [
  Color(0xFFF2913C), // 당근
  Color(0xFFF7C948), // 노랑
  Color(0xFF7CC98E), // 초록
  Color(0xFF63C3E8), // 하늘
  Color(0xFF9B7BC8), // 보라
  Color(0xFFEF7B72), // 빨강
  Color(0xFFCA8753), // 감자 갈색
];

const Map<Tier, Color> kTierColor = {
  Tier.elementary: Color(0xFFF6E3C8),
  Tier.middle: Color(0xFFE9C89B),
  Tier.high: Color(0xFFD9AC70),
  Tier.adult: Color(0xFFD3A263),
  Tier.endless: Color(0xFFB9823F),
};

/// 감자 스프라이트
class Gamja {
  static const wave = 'assets/gamja/wave.png';
  static const carrotEat = 'assets/gamja/carrot_eat.png';
  static const peek = 'assets/gamja/peek.png';
  static const sleep = 'assets/gamja/sleep.png';
  static const hero = 'assets/gamja/hero.png';
  static const head = 'assets/gamja/head.png';
  static const carrot = 'assets/gamja/carrot.png';
  static const paws = 'assets/gamja/paws.png';
  static const bowl = 'assets/gamja/bowl.png';
}

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: kCream,
    colorScheme: const ColorScheme.light(
      primary: kCarrot,
      secondary: kGrape,
      surface: kCard,
      onSurface: kInk,
    ),
    fontFamily: 'GothicA1',
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontFamily: 'Jua', fontSize: 40, color: kInk),
      headlineMedium: TextStyle(fontFamily: 'Jua', fontSize: 26, color: kInk),
      titleLarge: TextStyle(fontFamily: 'Jua', fontSize: 20, color: kInk),
      bodyLarge: TextStyle(fontSize: 15, color: kInk, fontWeight: FontWeight.w500),
      bodyMedium: TextStyle(fontSize: 13, color: kInkSoft, fontWeight: FontWeight.w500),
      labelLarge: TextStyle(fontFamily: 'Jua', fontSize: 18, color: kInk),
    ),
  );
}

/// 감자 스타일 버튼 — 아래쪽에 두께가 있어 눌리는 느낌을 준다
class GbButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool primary;
  final IconData? icon;
  final double? width;

  const GbButton({
    super.key,
    required this.label,
    this.onPressed,
    this.primary = false,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final bg = primary ? kCarrot : Colors.white;
    final fg = primary ? Colors.white : kInk;
    final shadow = primary ? const Color(0xFFC9712A) : const Color(0xFFE3C49C);
    final disabled = onPressed == null;

    return Opacity(
      opacity: disabled ? 0.45 : 1,
      child: SizedBox(
        width: width,
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onPressed,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primary ? const Color(0xFFE0822F) : kLine, width: 2),
                boxShadow: [BoxShadow(color: shadow, offset: const Offset(0, 3))],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[Icon(icon, size: 20, color: fg), const SizedBox(width: 8)],
                  Text(label,
                      style: TextStyle(
                          fontFamily: 'Jua', fontSize: 18, color: fg, height: 1.1)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

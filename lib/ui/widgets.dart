/// 재사용 위젯: 블록 한 칸, 도형 그리기, 배너, 감자 말풍선
library;

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../ads/ad_manager.dart';
import '../game/piece.dart';
import 'theme.dart';

/// 블록 한 칸. 위쪽 하이라이트와 아래쪽 그림자로 입체감을 준다.
class BlockCell extends StatelessWidget {
  final Color color;
  final double opacity;
  const BlockCell({super.key, required this.color, this.opacity = 1});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: LayoutBuilder(
        builder: (context, c) => DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(c.maxWidth * 0.26),
            boxShadow: [
              BoxShadow(
                color: const Color(0x73FFFFFF),
                offset: const Offset(0, 3),
                blurRadius: 0,
                spreadRadius: -3,
              ),
            ],
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(c.maxWidth * 0.26),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0x4DFFFFFF),
                  Colors.transparent,
                  const Color(0x29000000),
                ],
                stops: const [0, 0.45, 1],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 빈 칸 또는 돌 블록
class HoleCell extends StatelessWidget {
  final bool stone;
  const HoleCell({super.key, this.stone = false});

  @override
  Widget build(BuildContext context) {
    if (stone) return const BlockCell(color: kStoneColor);
    return LayoutBuilder(
      builder: (context, c) => DecoratedBox(
        decoration: BoxDecoration(
          color: kHole,
          borderRadius: BorderRadius.circular(c.maxWidth * 0.26),
        ),
      ),
    );
  }
}

/// 도형 하나를 셀 크기 [cell]로 그린다. 트레이와 드래그 미리보기 겸용.
class PieceView extends StatelessWidget {
  final Piece piece;
  final double cell;
  final double opacity;
  const PieceView({super.key, required this.piece, required this.cell, this.opacity = 1});

  @override
  Widget build(BuildContext context) {
    final pad = cell * 0.05;
    return SizedBox(
      width: piece.width * cell,
      height: piece.height * cell,
      child: Stack(
        children: [
          for (final (r, c) in piece.cells)
            Positioned(
              left: c * cell + pad,
              top: r * cell + pad,
              width: cell - pad * 2,
              height: cell - pad * 2,
              child: BlockCell(
                color: kBlockColors[piece.colorIndex % kBlockColors.length],
                opacity: opacity,
              ),
            ),
        ],
      ),
    );
  }
}

/// 하단 고정 적응형 배너. 로드 실패 시 높이 0으로 사라진다.
class BannerSlot extends StatefulWidget {
  const BannerSlot({super.key});

  @override
  State<BannerSlot> createState() => _BannerSlotState();
}

class _BannerSlotState extends State<BannerSlot> {
  BannerAd? _ad;
  bool _asked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_asked) return;
    _asked = true;
    final w = MediaQuery.of(context).size.width.truncate();
    AdManager.instance.createBanner(w).then((ad) {
      if (!mounted) {
        ad?.dispose();
        return;
      }
      setState(() => _ad = ad);
    });
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 광고 제거를 구매하면 즉시 사라져야 한다. 앱 재시작을 기다리게 하지 않는다.
    return ValueListenableBuilder<bool>(
      valueListenable: AdManager.instance.adsRemoved,
      builder: (context, removed, _) {
        final ad = _ad;
        if (removed || ad == null) return const SizedBox.shrink();
        return SafeArea(
          top: false,
          child: SizedBox(
            width: ad.size.width.toDouble(),
            height: ad.size.height.toDouble(),
            child: AdWidget(ad: ad),
          ),
        );
      },
    );
  }
}

/// 감자와 말풍선
class BuddyBar extends StatelessWidget {
  final String sprite;
  final String text;
  final Widget? trailing;
  const BuddyBar({super.key, required this.sprite, required this.text, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Image.asset(sprite, height: 74, filterQuality: FilterQuality.medium),
        const SizedBox(width: 8),
        // Flexible 과 Spacer 를 한 줄에 같이 쓰면 Spacer 가 남은 자리를 먼저
        // 가져가 말풍선이 좁아지고 글자가 여러 줄로 접힌다.
        // 말풍선이 남은 자리를 차지하게 하고, 글자는 한 줄로 고정한다.
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: kLine, width: 2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: const TextStyle(fontFamily: 'Jua', fontSize: 16, color: kInk),
            ),
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ],
    );
  }
}

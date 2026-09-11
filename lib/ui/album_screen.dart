import 'package:flutter/material.dart';

import '../game/cards.dart';
import '../storage/prefs.dart';
import 'theme.dart';
import 'widgets.dart';

class AlbumScreen extends StatelessWidget {
  const AlbumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final counts = Prefs.cards;
    final total = counts.fold<int>(0, (a, b) => a + b);
    final kinds = counts.where((c) => c > 0).length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kCream,
        surfaceTintColor: Colors.transparent,
        title: const Text('감자 카드 앨범',
            style: TextStyle(fontFamily: 'Jua', fontSize: 22, color: kInk)),
        iconTheme: const IconThemeData(color: kInkSoft),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '10단계마다 카드를 한 장 받아요',
                      style: const TextStyle(fontSize: 13, color: kInkSoft),
                    ),
                  ),
                  Text('$kinds / $kCardCount 종',
                      style: const TextStyle(
                          fontFamily: 'Jua', fontSize: 18, color: kInk)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  for (final series in kSeriesOrder) ...[
                    _SeriesHeader(series: series, counts: counts),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 130,
                        childAspectRatio: 3 / 4,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: _indicesOf(series).length,
                      itemBuilder: (context, i) {
                        final idx = _indicesOf(series)[i];
                        return _CardTile(def: kCards[idx], count: counts[idx]);
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                  Text('모두 $total장 모았어요',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: kInkSoft)),
                ],
              ),
            ),
            const BannerSlot(),
          ],
        ),
      ),
    );
  }

  static List<int> _indicesOf(String series) {
    final out = <int>[];
    for (var i = 0; i < kCards.length; i++) {
      if (kCards[i].series == series) out.add(i);
    }
    return out;
  }
}

class _SeriesHeader extends StatelessWidget {
  final String series;
  final List<int> counts;
  const _SeriesHeader({required this.series, required this.counts});

  @override
  Widget build(BuildContext context) {
    final idx = AlbumScreen._indicesOf(series);
    final got = idx.where((i) => counts[i] > 0).length;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(
            color: kCarrot,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text('$series 감자',
              style: const TextStyle(
                  fontFamily: 'Jua', fontSize: 15, color: Colors.white)),
        ),
        const SizedBox(width: 8),
        Text('$got / ${idx.length}',
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: kInkSoft)),
        const Expanded(child: Divider(indent: 10, color: kLine, thickness: 2)),
      ],
    );
  }
}

class _CardTile extends StatelessWidget {
  final CardDef def;
  final int count;
  const _CardTile({required this.def, required this.count});

  @override
  Widget build(BuildContext context) {
    final got = count > 0;
    return Container(
      decoration: BoxDecoration(
        color: got ? kCream : kHole,
        borderRadius: BorderRadius.circular(16),
        border: got ? Border.all(color: kLine, width: 2) : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Center(
            child: got
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Image.asset(def.asset,
                            height: 62, filterQuality: FilterQuality.medium),
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(def.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontFamily: 'Jua', fontSize: 12, color: kInk)),
                      ),
                    ],
                  )
                : const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('?',
                          style: TextStyle(
                              fontFamily: 'Jua',
                              fontSize: 30,
                              color: Color(0xFFC9A87C))),
                      SizedBox(height: 6),
                      Text('아직이야',
                          style: TextStyle(
                              fontFamily: 'Jua', fontSize: 12, color: kInkSoft)),
                    ],
                  ),
          ),
          if (count > 1)
            Positioned(
              top: 6,
              right: 7,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: kCarrot,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('×$count',
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ),
        ],
      ),
    );
  }
}

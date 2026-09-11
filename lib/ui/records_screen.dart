/// 기록 화면. 마일스톤 단계의 개인 최고 클리어 시간을 보여 준다.
///
/// 지금은 이 기기의 기록만 나온다. 나중에 Play Games 리더보드를 켜면
/// 같은 값이 전체 순위로 올라가고, 이 화면에 등수 칸이 하나 더 붙는다.
library;

import 'package:flutter/material.dart';

import '../game/records.dart';
import '../storage/prefs.dart';
import 'theme.dart';
import 'widgets.dart';

class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final best = Prefs.bestStage;
    final done = kMilestoneStages.where((s) => Prefs.bestTimeMs(s) > 0).length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kCream,
        surfaceTintColor: Colors.transparent,
        title: const Text('기록',
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
                  const Expanded(
                    child: Text('대표 단계를 깬 시간을 남겨요',
                        style: TextStyle(fontSize: 13, color: kInkSoft)),
                  ),
                  Text('$done / ${kMilestoneStages.length}',
                      style: const TextStyle(
                          fontFamily: 'Jua', fontSize: 18, color: kInk)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  for (final stage in kMilestoneStages)
                    _RecordTile(
                      stage: stage,
                      ms: Prefs.bestTimeMs(stage),
                      reached: best > stage,
                    ),
                  const SizedBox(height: 18),
                  _SummaryCard(
                    bestStage: best,
                    totalMs: Prefs.totalPlayMs,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '기록은 이 기기에만 저장됩니다.\n'
                    '나중에 전체 순위가 열리면 지금까지의 기록이 그대로 올라갑니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: kInkSoft, height: 1.6),
                  ),
                ],
              ),
            ),
            const BannerSlot(),
          ],
        ),
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  final int stage;
  final int ms;
  final bool reached;
  const _RecordTile({required this.stage, required this.ms, required this.reached});

  @override
  Widget build(BuildContext context) {
    final has = ms > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: has ? kCard : kHole,
        borderRadius: BorderRadius.circular(16),
        border: has ? Border.all(color: kLine, width: 2) : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(
              color: has ? kCarrot : const Color(0xFFD8C4A8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text('$stage단계',
                style: const TextStyle(
                    fontFamily: 'Jua', fontSize: 15, color: Colors.white)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              has ? '최고 기록' : (reached ? '아직 기록이 없어요' : '아직 못 왔어요'),
              style: const TextStyle(fontSize: 13, color: kInkSoft),
            ),
          ),
          Text(
            has ? formatMs(ms) : '-',
            style: TextStyle(
                fontFamily: 'Jua',
                fontSize: 20,
                color: has ? kInk : const Color(0xFFC9A87C)),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int bestStage;
  final int totalMs;
  const _SummaryCard({required this.bestStage, required this.totalMs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kLine, width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                const Text('가장 멀리 간 단계',
                    style: TextStyle(fontSize: 12, color: kInkSoft)),
                const SizedBox(height: 4),
                Text('$bestStage',
                    style: const TextStyle(
                        fontFamily: 'Jua', fontSize: 24, color: kInk)),
              ],
            ),
          ),
          Container(width: 2, height: 38, color: kLine),
          Expanded(
            child: Column(
              children: [
                const Text('모두 놀아 본 시간',
                    style: TextStyle(fontSize: 12, color: kInkSoft)),
                const SizedBox(height: 4),
                Text(totalMs > 0 ? formatMs(totalMs) : '-',
                    style: const TextStyle(
                        fontFamily: 'Jua', fontSize: 24, color: kInk)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../game/cards.dart';
import '../game/curve.dart';
import '../game/records.dart';
import '../storage/prefs.dart';
import 'album_screen.dart';
import 'records_screen.dart';
import 'game_screen.dart';
import 'parent_gate.dart';
import 'theme.dart';
import 'widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _recordSubtitle() {
    final done = kMilestoneStages.where((x) => Prefs.bestTimeMs(x) > 0).toList();
    if (done.isEmpty) return '50단계부터 기록이 남아요';
    final last = done.last;
    return '$last단계 ${formatMs(Prefs.bestTimeMs(last))} · ${done.length}개 기록';
  }

  Future<void> _open(int stage) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GameScreen(stage: stage)),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final stage = Prefs.stage;
    final tier = tierOf(stage);
    final cards = Prefs.cards;
    final collected = cards.fold<int>(0, (a, b) => a + b);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.settings, color: kInkSoft),
                  onPressed: () => showParentGate(context),
                ),
              ),
              const Spacer(),
              Image.asset(Gamja.head, height: 120, filterQuality: FilterQuality.medium),
              const SizedBox(height: 8),
              const Text('감자토끼 블록퍼즐',
                  style: TextStyle(fontFamily: 'Jua', fontSize: 32, color: kInk)),
              const SizedBox(height: 4),
              const Text('빈칸을 채워 줄을 없애요',
                  style: TextStyle(fontSize: 14, color: kInkSoft, fontWeight: FontWeight.w500)),
              const Spacer(),

              _BigCard(
                title: stage > 1 ? '$stage단계 이어하기' : '시작하기',
                subtitle: '${tier.label} 구간 · 최고 ${Prefs.bestStage}단계',
                icon: Icons.play_arrow_rounded,
                onTap: () => _open(stage),
              ),
              const SizedBox(height: 12),
              _BigCard(
                title: '감자 카드 앨범',
                subtitle: '${cards.where((c) => c > 0).length} / $kCardCount 종 · 모두 $collected장',
                icon: Icons.style_rounded,
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AlbumScreen()),
                  );
                  if (mounted) setState(() {});
                },
              ),
              const SizedBox(height: 12),
              _BigCard(
                title: '기록',
                subtitle: _recordSubtitle(),
                icon: Icons.timer_outlined,
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RecordsScreen()),
                  );
                  if (mounted) setState(() {});
                },
              ),

              const Spacer(flex: 2),
              Text('통과한 단계 ${Prefs.stagesCleared}개',
                  style: const TextStyle(fontSize: 13, color: kInkSoft)),
              const SizedBox(height: 4),
              // 어떤 판이 설치돼 있는지 눈으로 확인하기 위한 표시.
              const Text(kVersionLabel,
                  style: TextStyle(fontSize: 11, color: Color(0xFFBFA98F))),
              const SizedBox(height: 12),
              const BannerSlot(),
            ],
          ),
        ),
      ),
    );
  }
}

class _BigCard extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final VoidCallback onTap;
  const _BigCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kCard,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kLine, width: 3),
          ),
          child: Row(
            children: [
              Icon(icon, color: kCarrot, size: 34),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontFamily: 'Jua', fontSize: 21, color: kInk)),
                    Text(subtitle,
                        style: const TextStyle(fontSize: 13, color: kInkSoft)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: kInkSoft),
            ],
          ),
        ),
      ),
    );
  }
}
